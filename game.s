	AREA lib, CODE, READWRITE

	EXTERN BOARD_WIDTH
	EXTERN BOARD_HEIGHT
	EXTERN rand
	EXTERN div_and_mod
	EXTERN set_cursor_pos
	EXPORT keystroke
	EXPORT board
	EXPORT prev_board
	EXPORT initialize_game
	EXPORT update_game
	
BRICK_WALL       EQU '#'
BOMBERMAN        EQU 'B'
ENEMY_SLOW 		 EQU 'x'
ENEMY_FAST       EQU '*'
BOMB             EQU 'o'
BLAST_VERTICAL   EQU '|'
BLAST_HORIZONTAL EQU '-'
BARRIER          EQU 'Z'
FREE             EQU ' '
UP_KEY           EQU 'w'
LEFT_KEY         EQU 'a'
DOWN_KEY         EQU 's'
RIGHT_KEY        EQU 'd'
PLACE_BOMB_KEY   EQU 'x'
	
BOMBERMAN_X_START EQU 1              ; Bomberman starting x-position.
BOMBERMAN_Y_START EQU 1              ; Bomberman starting y-position.
	
ENEMY1_X_START	EQU 23				 ; Enemy 1 starting x-position.
ENEMY1_Y_START	EQU 1                ; Enemy 1 starting y-position.

ENEMY2_X_START	EQU 1				 ; Enemy 2 starting x-position.
ENEMY2_Y_START	EQU 11               ; Enemy 2 starting y-position.
	
ENEMY3_X_START	EQU 23				 ; Enemy 3 (FAST) starting x-position.
ENEMY3_Y_START	EQU 11               ; Enemy 3 (FAST) starting y-position.
	
BOMB_TIMEOUT    EQU 5                ; After many refreshes the bomb should detonate.
BLAST_X_RADIUS  EQU 4                ; Horizontal blast radius.
BLAST_Y_RADIUS  EQU 2                ; Vertical blast radius.
	
bomb_placed		DCD 0x00000000       ; Has a bomb been placed?
bomb_detonated	DCD 0x00000000       ; Has the placed bomb been detonated?
bomb_timer		DCD 0x00000000       ; Bomb detonation timer.
bomb_radius		DCD 0x00000001       ; Bomb blast radius.
bomb_x_pos		DCD 0x00000000       ; Placed bomb x-position.
bomb_y_pos		DCD 0x00000000       ; Placed bomb y-position.

bomberman_x_pos	DCD 0x00000001       ; Bomberman's current x-position.
bomberman_y_pos DCD 0x00000001       ; Bomberman's current y-position.

enemy1_x_pos	DCD 0x00000000
enemy1_y_pos	DCD 0x00000000
enemy1_killed	DCD 0x00000000

enemy2_x_pos	DCD 0x00000000
enemy2_y_pos	DCD 0x00000000
enemy2_killed	DCD 0x00000000

enemy3_x_pos	DCD 0x00000000
enemy3_y_pos	DCD 0x00000000
enemy3_killed	DCD 0x00000000

num_enemies		DCD 0x00000000

num_lives		DCD 0x00000000

level			DCD 0x00000001

time			DCD 0x00000000

score			DCD 0x00000000

game_over		DCD 0x00000000

keystroke		DCD 0x00000000

board 		= "ZZZZZZZZZZZZZZZZZZZZZZZZZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZZZZZZZZZZZZZZZZZZZZZZZZZ"
prev_board 	= "ZZZZZZZZZZZZZZZZZZZZZZZZZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZZZZZZZZZZZZZZZZZZZZZZZZZ"

	ALIGN
	
;-------------------------------------------------------;
; @NAME                                                 ;
; initialize_game                                       ;
;                                                       ;
; @DESCRIPTION                                          ;
; Initialize the game. Add enemies and generate brick   ;
; walls.                                                ;
;-------------------------------------------------------;
initialize_game
	STMFD sp!, {lr, v1}
	BL generate_brick_walls
	
	MOV a1, #BOMBERMAN_X_START
	MOV a2, #BOMBERMAN_Y_START
	MOV a3, #BOMBERMAN
	BL update_pos
	
	MOV a1, #ENEMY1_X_START
	MOV a2, #ENEMY1_Y_START
	MOV a3, #ENEMY_SLOW
	BL update_pos
	
	MOV a1, #ENEMY2_X_START
	MOV a2, #ENEMY2_Y_START
	MOV a3, #ENEMY_SLOW
	BL update_pos
	
	MOV a1, #ENEMY3_X_START
	MOV a2, #ENEMY3_Y_START
	MOV a3, #ENEMY_FAST
	BL update_pos	
	
	LDMFD sp!, {lr, v1}
	BX lr

;-------------------------------------------------------;
; @NAME                                                 ;
; update_game                                           ;
;                                                       ;
; @DESCRIPTION                                          ;
; Advances games simulation one step.                   ;
;-------------------------------------------------------;
update_game
    STMFD sp!, {lr}
	
	LDR a1, =bomb_detonated
	LDR a3, [a1]
	MOV a2, #0
	CMP a3, #1
	BLEQ clear_bomb_detonation   ; Remove remnants from bomb blast.
	
	LDR  a1, =keystroke
	LDR a1, [a1]
	BL move_bomberman            ; Move bomberman.
	
	LDR a1, =keystroke
	LDR a1, [a1]
	CMP a1, #PLACE_BOMB_KEY
	BLEQ place_bomb              ; Place bomb if keystroke is 'x'
	                             ; and a bomb is not already placed.
	
	LDR a1, =bomb_timer
	LDR a1, [a1]
	CMP a1, #BOMB_TIMEOUT        ; Has the bomb timer timed out and is a bomb
    MOVEQ a1, #1                 ; placed? If so, detonate the bomb.
	LDR a2, =bomb_placed
	LDR a2, [a2]
	CMP a2, #0
	MOVEQ a2, #-1
	CMP a1, a2
	BLEQ detonate_bomb
	
	LDR a1, =bomb_timer
	LDR a2, [a1]
	ADD a2, a2, #1               
	STR a2, [a1]                 ; Increment bomb timer.
	
	
	LDR v1, =keystroke
	MOV a1, #0                   ; Reset keystroke.
	STR a1, [v1]
	
	LDMFD sp!, {lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; detonate_bomb                                         ;
;                                                       ;
; @DESCRIPTION                                          ;
; Detonate the placed bomb.                             ;
;-------------------------------------------------------;
detonate_bomb
	STMFD sp!, {lr}
	
	LDR a1, =bomb_detonated
	MOV a2, #1
	STR a2, [a1]                 ; Assert bomb detonated flag.
	
	LDR a1, =bomb_placed
	MOV a2, #0
	STR a2, [a1]                 ; De-assert bomb placed flag.

	LDR a1, =bomb_x_pos
	LDR a1, [a1]
	MOV v1, a1
	LDR a2, =bomb_y_pos
	LDR a2, [a2]
	MOV v2, a2
	
	SUB v3, v1, #BLAST_X_RADIUS  ; Lower bound x-position for blast.
	ADD v4, v1, #BLAST_X_RADIUS  ; Upper bound x-position for blast.
	
	SUB v5, v2, #BLAST_Y_RADIUS  ; Lower bound y-position for blast.
	ADD v6, v2, #BLAST_Y_RADIUS  ; Upper bound y-position for blast.

;-------------------------------------------------------;
; Destroy everything to the left of the placed bomb.    ;
; i.e. ----o                                            ;
;-------------------------------------------------------;
detonate_bomb_west
	MOV v7, v1                   ; Initialize X-detonation loop counter.
	
detonate_bomb_west_loop
	; Add '-' and '|' characters, making sure
	; to not blow up any indestructible stuff. Also need to
	; check if the blast kills an enemy or bomberman.

	MOV a1, v7                   ; Current X-position (decremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #BOMBERMAN           ; Is it bomberman? If so, call game_over.
	; Call game_over
	
	MOV a1, v7                   ; Current X-position (decremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #BARRIER             ; Is it a barrier? If so, break out of loop.
	BEQ detonate_bomb_east
	
	MOV a1, v7                   ; Current X-position (decremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #ENEMY_SLOW          ; Is it a slow enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v7                   ; Current X-position (decremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v7                   ; Current X-position (decremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #BOMB                ; Is it a bomb? If so, do nothing.
	BEQ detonate_bomb_west_next
	
	MOV a1, v7
	MOV a2, v2
	MOV a3, #BLAST_HORIZONTAL
	BL update_pos                ; Otherwise, draw a '-'. (this is the default case of our "switch statement").
	
detonate_bomb_west_next
	SUB v7, v7, #1               ; Decrement X-position.
	CMP v7, v3
	BGE detonate_bomb_west_loop
	
;-------------------------------------------------------;
; Destroy everything to the right of the placed bomb.   ;
; i.e. o----                                            ;
;-------------------------------------------------------;
detonate_bomb_east
	MOV v7, v1                   ; Initialize X-detonation loop counter.
	
detonate_bomb_east_loop
	; Add '-' and '|' characters, making sure
	; to not blow up any indestructible stuff. Also need to
	; check if the blast kills an enemy or bomberman.

	MOV a1, v7                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #BOMBERMAN           ; Is it bomberman? If so, call game_over.
	; Call game_over
	
	MOV a1, v7                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #BARRIER             ; Is it a barrier? If so, break out of loop.
	BEQ detonate_bomb_north
	
	MOV a1, v7                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #ENEMY_SLOW          ; Is it a slow enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v7                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v7                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #BOMB                ; Is it a bomb? If so, do nothing.
	BEQ detonate_bomb_east_next
	
	MOV a1, v7
	MOV a2, v2
	MOV a3, #BLAST_HORIZONTAL
	BL update_pos                ; Otherwise, draw a '-'. (this is the default case of our "switch statement").
	
detonate_bomb_east_next
	ADD v7, v7, #1               ; Increment X-position.
	CMP v7, v4
	BLE detonate_bomb_east_loop
	
;-------------------------------------------------------;
; Destroy everything below the placed bomb.             ;
;-------------------------------------------------------;
detonate_bomb_south
	MOV v7, v2                   ; Initialize Y-detonation loop counter.
	
detonate_bomb_south_loop
	; Add '-' and '|' characters, making sure
	; to not blow up any indestructible stuff. Also need to
	; check if the blast kills an enemy or bomberman.

	MOV a1, v1                   ; X-position (fixed).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #BOMBERMAN           ; Is it bomberman? If so, call game_over.
	; Call game_over
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #BARRIER             ; Is it a barrier? If so, break out of loop.
	BEQ detonate_bomb_north
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #ENEMY_SLOW          ; Is it a slow enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #BOMB                ; Is it a bomb? If so, do nothing.
	BEQ detonate_bomb_south_next
	
	MOV a1, v1
	MOV a2, v7
	MOV a3, #BLAST_VERTICAL
	BL update_pos                ; Otherwise, draw a '-'. (this is the default case of our "switch statement").
	
detonate_bomb_south_next
	ADD v7, v7, #1               ; Increment Y-position.
	CMP v7, v6
	BLE detonate_bomb_south_loop
	
;-------------------------------------------------------;
; Destroy everything above the placed bomb.             ;
;-------------------------------------------------------;
detonate_bomb_north
	MOV v7, v2                   ; Initialize Y-detonation loop counter.
	
detonate_bomb_north_loop
	; Add '-' and '|' characters, making sure
	; to not blow up any indestructible stuff. Also need to
	; check if the blast kills an enemy or bomberman.

	MOV a1, v1                   ; X-position (fixed).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #BOMBERMAN           ; Is it bomberman? If so, call game_over.
	; Call game_over
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #BARRIER             ; Is it a barrier? If so, break out of loop.
	BEQ detonate_bomb_exit
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #ENEMY_SLOW          ; Is it a slow enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	; Call kill_enemy
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #BOMB                ; Is it a bomb? If so, do nothing.
	BEQ detonate_bomb_north_next
	
	MOV a1, v1
	MOV a2, v7
	MOV a3, #BLAST_VERTICAL
	BL update_pos                ; Otherwise, draw a '-'. (this is the default case of our "switch statement").
	
detonate_bomb_north_next
	SUB v7, v7, #1               ; Decrement Y-position.
	CMP v7, v5
	BGE detonate_bomb_north_loop

detonate_bomb_exit
	LDMFD sp!, {lr}
	BX lr

;-------------------------------------------------------;
; @NAME                                                 ;
; clear_bomb_detonation                                 ;
;                                                       ;
; @DESCRIPTION                                          ;
; Detonate the placed bomb.                             ;
;-------------------------------------------------------;
clear_bomb_detonation
	STMFD sp!, {lr}
	
	STR a2, [a1]                ; De-assert bomb detonated flag.
  
    ; Insert code which removes '-' and '|' characters here.  
	
	LDMFD sp!, {lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; place_bomb                                            ;
;                                                       ;
; @DESCRIPTION                                          ;
; Place bomb at bomberman's current position.           ;
;-------------------------------------------------------;
place_bomb
	STMFD sp!, {lr}
	
	LDR a1, =bomberman_x_pos
	LDR a1, [a1]
	MOV v1, a1
	
	LDR a2, =bomberman_y_pos
	LDR a2, [a2]
	MOV v2, a2
	
	LDR a1, =bomb_placed
	LDR a1, [a1]
	CMP a1, #1
	BLEQ place_bomb_exit       ; A bomb is already placed, it must be detonated first before allowing
	                           ; another placement.
	LDR a1, =bomb_placed
	MOV a2, #1
	STR a2, [a1]               ; Assert bomb_placed flag.
	
	MOV a1, v1
	MOV a2, v2
	MOV a3, #BOMB
	BL update_pos              ; Place the bomb.
	
	LDR a1, =bomb_x_pos        ; Set X-Y coordinates of placed bomb.
	STR v1, [a1]
	LDR a1, =bomb_y_pos
	STR v2, [a1]
	
	LDR a1, =bomb_timer
	MOV a2, #0
	STR a2, [a1]               ; Reset bomb timer to 0.
	
place_bomb_exit
	LDMFD sp!, {lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; move_bomberman                                        ;
;                                                       ;
; @DESCRIPTION                                          ;
; Move bomerman based on player keystroke.              ;
;-------------------------------------------------------;
move_bomberman
	STMFD sp!, {lr, v1-v6}
	
	LDR v5, =keystroke
	LDR v5, [v5]
	
	LDR a1, =bomberman_x_pos
	LDR a1, [a1]
	
	LDR a2, =bomberman_y_pos
	LDR a2, [a2]
	
	CMP v5, #0
	BEQ not_valid_move             ; Check for no input.
	
	MOV v1, a1                     ; Temporarily store original X-Y position
	MOV v2, a2                     ; before modifying it based on user keystroke.
	MOV v3, a1
	MOV v4, a2
	
	CMP v5, #UP_KEY                ; Increment bomberman Y-position.
	SUBEQ a2, a2, #1
	
	CMP v5, #DOWN_KEY              ; Decrement bomberman Y-position.
	ADDEQ a2, a2, #1
	
	CMP v5, #RIGHT_KEY             ; Increment bomberman X-position.
	ADDEQ a1, a1, #1
	
	CMP v5, #LEFT_KEY              ; Decrement bomberman Y-position.
	SUBEQ a1, a1, #1
	
	MOV v3, a1
	MOV v4, a2
	
	BL check_pos                   ; Is the destination a free position?
	CMP a1, #0
	BEQ not_valid_move
	
valid_move
	;LDR v5, =keystroke
	;MOV a1, #0
	;STR a1, [v5]
	
	LDR a1, =bomberman_x_pos	   ; Update new bomberman X-position.
	STR v3, [a1]
	LDR a2, =bomberman_y_pos       ; Update new bomerman Y-position.
	STR v4, [a2]
	
	MOV a1, v3
	MOV a2, v4
	MOV a3, #BOMBERMAN             ; Move bomerman to new position.
	BL update_pos
	
	MOV a1, v1                     ; Remove bomberman from old position only if a bomb has not 
	MOV a2, v2                     ; been placed at old position.
	MOV a3, #FREE
	MOV v5, #100                   ; Initialize to two non equal values. Needed to compare two
	MOV v6, #101                   ; X-Y coordinate pairs properly.
	
	LDR v3, =bomb_x_pos
	LDR v3, [v3]
	CMP v3, v1                    ; Compare old x-position to bomb's x-position.
	MOVEQ v5, #1
	
	LDR v4, =bomb_y_pos
	LDR v4, [v4]
	CMP v4, v2                    ; Compare old y-position to bomb's y-position.
	MOVEQ v6, #1
	
	CMP v5, v6                    ; If v5 and v6 are asserted, then the bomb position                    
	BLNE update_pos               ; and old position are the same. Do not remove bomberman
	                              ; from old position in this case.
	
	LDMFD sp!, {lr, v1-v6}
	BX lr
	
not_valid_move
	LDMFD sp!, {lr, v1-v6}
	BX lr

;-------------------------------------------------------;
; @NAME                                                 ;
; return                                                ;
;                                                       ;
; @DESCRIPTION                                          ;
; Pop r14 off the stack and restore program counter.    ;
;-------------------------------------------------------;
return
	LDMFD sp!, {lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; generate_brick_walls                                  ;
;                                                       ;
; @DESCRIPTION                                          ;
; Randomly place brick walls throughout the game board. ;
;-------------------------------------------------------;	
generate_brick_walls
	STMFD sp!, {v1-v4, lr}
	LDR v1, =level          ; Load current level into v1.
	LDR v1, [v1]
	
	MOV v3, #20             ; Number of bricks to generate. Might need
	MUL v4, v1, v3          ; to be tweaked. 
                            ; v2 = number of bricks = level * 10.
	
	MOV v3, #0				; Initialize counter.
	
try_place_brick
	BL rand                 ; Generate two random numbers for
	MOV v1, a1              ; X and Y position (where brick wall
	BL rand                 ; will be placed.
	MOV v2, a1
	
	MOV a1, v1              ; Restrict the range of the random number
	MOV a2, #0              ; such that X is an element of [0, BOARD_WIDTH]
	ADD a2, a2, #BOARD_WIDTH    
	BL div_and_mod
	MOV v1, a2
	
	MOV a1, v2              ; Restrict the range of the random number 
	MOV a2, #0              ; such that Y is an element of [0, BOARD_HEIGHT]
	ADD a2, a2, #BOARD_HEIGHT   
	BL div_and_mod
	MOV v2, a2
	
	MOV a1, v1              ; Check if the randomly generated X-Y
	MOV a2, v2              ; pair is a free spot on the board.
	BL check_pos
	CMP a1, #1
	BNE try_place_brick
	
place_brick
	MOV a1, v1
	MOV a2, v2
	MOV a3, #BRICK_WALL
	BL update_pos           ; Update free position with brick wall.

	ADD v3, v3, #1          ; Increment counter.
	CMP v3, v4
	BNE try_place_brick

	LDMFD sp!, {v1-v4, lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; update_pos			                                ;
;                                                       ;
; DESCRIPTION                                           ;
; Update specified position on game board with provided ;
; character. X is passed in a1. Y is passed in a2.      ;
; The character to insert is passed in a3. No return.   ;
;-------------------------------------------------------;
update_pos
	STMFD sp!, {v1-v3, lr}
	
	MOV v2, #0
	LDR v1, =board
	ADD v2, v2, #BOARD_WIDTH          ; The offset is calculated as (board_width*Y)+X.
	MUL v3, a2, v2
	ADD v3, v3, a1	
	
	ADD v1, v1, v3                    ; Add offset to base address of board string.
	
	STRB a3, [v1]
	
	LDMFD sp!, {v1-v3, lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; check_pos			                                    ;
;                                                       ;
; @DESCRIPTION                                          ;
; Checks whether specified position on game board is    ;
; free. X is passed in a1. Y is passed in a2. Returns 1 ; 
; in a1 if spot is free, otherwise returns 0. Note that ;
; the origin (0,0) is defined as the upper left most    ;
; 'Z'.                                                  ;
;-------------------------------------------------------;
check_pos
	STMFD sp!, {v1-v3, lr}
	MOV v2, #0
	LDR v1, =board
	ADD v2, v2, #BOARD_WIDTH          ; The offset is calculated as (board_width*Y)+X.
	MUL v3, a2, v2
	ADD v3, v3, a1				
	
	ADD v1, v1, v3                    ; Add offset to base address of board string.
	
	LDRB v1, [v1]                     ; Finally, load the character and check if it is 
	CMP v1, #32                       ; a space character (ascii code 32). A space 
	BNE check_pos_assert_false        ; character indicates the position is free.
	
check_pos_assert_true
	MOV a1, #1
	B check_pos_exit
	
check_pos_assert_false
	MOV a1, #0
	
check_pos_exit
	LDMFD sp!, {v1-v3, lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; check_pos_char	                                    ;
;                                                       ;
; @DESCRIPTION                                          ;
; Checks specified position on game board and returns   ;
; the char there. X is passed in a1. Y is passed in a2. ; 
; Returns the char in a1. Note that the origin (0,0)    ; 
; is defined as the upper left most 'Z'.                ;
;-------------------------------------------------------;
check_pos_char
	STMFD sp!, {v1-v3, lr}
	MOV v2, #0
	LDR v1, =board
	ADD v2, v2, #BOARD_WIDTH          ; The offset is calculated as (board_width*Y)+X.
	MUL v3, a2, v2
	ADD v3, v3, a1				
	
	ADD v1, v1, v3                    ; Add offset to base address of board string.
	
	LDRB a1, [v1]                     ; Finally, load the character into a1 
	LDMFD sp!, {v1-v3, lr}
	BX lr
	
	END

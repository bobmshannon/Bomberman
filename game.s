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
	
	EXTERN game_loop
	EXTERN T0MR0
	
BRICK_WALL       EQU '#'
BOMBERMAN        EQU 'B'
ENEMY_SLOW 		 EQU 'x'
ENEMY_FAST       EQU '+'
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
	
MOVE_UP 		 EQU 1
MOVE_RIGHT 		 EQU 2
MOVE_DOWN 		 EQU 3
MOVE_LEFT 		 EQU 4
	
MAX_LEVEL        EQU 8               ; Maximum level user can reach. After the player passes this level,
								     ; the game no longer increases in speed.
NUM_BRICKS       EQU 10
	
BOMBERMAN_X_START EQU 1              ; Bomberman starting x-position.
BOMBERMAN_Y_START EQU 1              ; Bomberman starting y-position.
	
ENEMY1_X_START	EQU 23				 ; Enemy 1 starting x-position.
ENEMY1_Y_START	EQU 1                ; Enemy 1 starting y-position.

ENEMY2_X_START	EQU 1				 ; Enemy 2 starting x-position.
ENEMY2_Y_START	EQU 11               ; Enemy 2 starting y-position.
	
ENEMY3_X_START	EQU 23				 ; Enemy 3 (FAST) starting x-position.
ENEMY3_Y_START	EQU 11               ; Enemy 3 (FAST) starting y-position.
	
BOMB_TIMEOUT    EQU 10               ; After many refreshes the bomb should detonate.
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

enemy1_x_pos	DCD 0x00000017
enemy1_y_pos	DCD 0x00000001
enemy1_killed	DCD 0x00000000

enemy2_x_pos	DCD 0x00000001
enemy2_y_pos	DCD 0x0000000B
enemy2_killed	DCD 0x00000000

enemy3_x_pos	DCD 0x00000017
enemy3_y_pos	DCD 0x0000000B
enemy3_killed	DCD 0x00000000

enemy_slow_moved DCD 0x00000000		 ; Did the slow enemies move last frame?

num_enemies		DCD 0x00000003

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
; walls. Reset positions and flags for gameplay         ;
;-------------------------------------------------------;
initialize_game
	STMFD sp!, {lr, v1}
	
	MOV a1, #0						; Reset bomb placement (Let you place a bomb right away)
	LDR v1, =bomb_placed
	STR a1, [v1]

	MOV a1, #3						; Reset enemy live count to 3
	LDR v1, =num_enemies
	STR a1, [v1]

	MOV a1, #0						; Reset the enemy delay flag
	LDR v1, =enemy_slow_moved
	STR a1, [v1]	

	MOV a1, #BOMBERMAN_X_START
	MOV a2, #BOMBERMAN_Y_START
	MOV a3, #BOMBERMAN
	BL update_pos
	LDR v1, =bomberman_x_pos		; Reset bomberman position  		
	STR a1, [v1]
	LDR v1, =bomberman_y_pos
	STR a2, [v1]
	
	MOV a1, #ENEMY1_X_START
	MOV a2, #ENEMY1_Y_START
	MOV a3, #ENEMY_SLOW
	BL update_pos
	LDR v1, =enemy1_x_pos			; Reset enemy1 position  		
	STR a1, [v1]
	LDR v1, =enemy1_y_pos
	STR a2, [v1]
	LDR v1, =enemy1_killed			; Set enemy1 not killed
	MOV a1, #0
	STR a1, [v1]	

	MOV a1, #ENEMY2_X_START
	MOV a2, #ENEMY2_Y_START
	MOV a3, #ENEMY_SLOW
	BL update_pos
	LDR v1, =enemy2_x_pos			; Reset enemy2 position  		
	STR a1, [v1]
	LDR v1, =enemy2_y_pos
	STR a2, [v1]
	LDR v1, =enemy2_killed			; Set enemy1 not killed
	MOV a1, #0
	STR a1, [v1]
	
	MOV a1, #ENEMY3_X_START
	MOV a2, #ENEMY3_Y_START
	MOV a3, #ENEMY_FAST
	BL update_pos
	LDR v1, =enemy3_x_pos			; Reset enemy3 position  		
	STR a1, [v1]
	LDR v1, =enemy3_y_pos
	STR a2, [v1]
	LDR v1, =enemy3_killed			; Set enemy1 not killed
	MOV a1, #0
	STR a1, [v1]	

	BL generate_brick_walls	
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
	CMP a3, #1
	BLEQ clear_bomb_detonation   ; Remove remnants from bomb blast.
	
	LDR  a1, =keystroke
	LDR a1, [a1]
	BL move_bomberman            ; Move bomberman.
	
	;BL move_enemies				 ; Move all enemies

	LDR a1, =keystroke
	LDR a1, [a1]
	CMP a1, #PLACE_BOMB_KEY
	BLEQ place_bomb              ; Place bomb if keystroke is 'x'
	                             ; and a bomb is not already placed.
	
	LDR a1, =bomb_timer
	LDR a1, [a1]

	LDR a2, =bomb_placed
	LDR a2, [a2]
	CMP a2, #1
	MOVEQ a2, #BOMB_TIMEOUT
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
	STMFD sp!, {lr, v1-v8}
	
	LDR a1, =bomb_placed
	LDR a1, [a1]
	CMP a1, #0
	BEQ detonate_bomb_exit       ; Is a bomb placed? If not, exit.
	
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
	BLEQ kill_enemy
	
	MOV a1, v7                   ; Current X-position (decremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	BLEQ kill_enemy
	
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
	BEQ detonate_bomb_south
	
	MOV a1, v7                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #ENEMY_SLOW          ; Is it a slow enemy? If so, call kill_enemy.
	BLEQ kill_enemy
	
	MOV a1, v7                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v2                   ; Y-position (fixed).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	BLEQ kill_enemy
	
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
	MOV a2, v1
	MOV a3, v2
	CMP a1, #ENEMY_SLOW          ; Is it a slow enemy? If so, call kill_enemy.
	BLEQ kill_enemy
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	BLEQ kill_enemy
	
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
	BLEQ kill_enemy
	
	MOV a1, v1                   ; Current X-position (incremented after each loop iteration).
	MOV a2, v7                   ; Y-position (incremented after each loop iteration).
	BL check_pos_char
	CMP a1, #ENEMY_FAST          ; Is it a fast enemy? If so, call kill_enemy.
	BLEQ kill_enemy
	
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

	LDR a1, =bomb_x_pos
	LDR a1, [a1]
	LDR a2, =bomb_y_pos
	LDR a2, [a2]
	MOV a3, #BOMB
	BL update_pos
	
detonate_bomb_exit
	LDMFD sp!, {lr, v1-v8}
	BX lr

;-------------------------------------------------------;
; @NAME                                                 ;
; kill_enemy                                            ;
;                                                       ;
; @DESCRIPTION                                          ;
; Kill the specified enemy. Enemy X-cord passed in a2.  ;
; Enemy Y-cord passed in a3. No return.                 ;
;-------------------------------------------------------;
kill_enemy
	STMFD sp!, {lr, v1-v8}
	
	LDR a1, =bomb_x_pos
	LDR a1, [a1]
	LDR a2, =bomb_y_pos
	LDR a2, [a2]
	MOV a1, v1
	MOV a2, v1
	
	SUB v3, v1, #BLAST_X_RADIUS  ; Lower bound x-position for blast.
	ADD v4, v1, #BLAST_X_RADIUS  ; Upper bound x-position for blast.
	
	SUB v5, v2, #BLAST_Y_RADIUS  ; Lower bound y-position for blast.
	ADD v6, v2, #BLAST_Y_RADIUS  ; Upper bound y-position for blast.

kill_enemy1
	LDR a1, =enemy1_killed
	LDR a1, [a1]
	CMP a1, #1
	BEQ kill_enemy2				; Is enemy already dead? If so, skip check.
	
	LDR a1, =enemy1_x_pos
	LDR a1, [a1]
	LDR a2, =enemy1_y_pos
	LDR a2, [a2]
	MOV v1, #-1					; Initialize variables for pairwise comparison.
	MOV v2, #-2
	MOV v7, #-3
	MOV v8, #-4
	
	CMP a1, v3                   ; Check if enemy is within x-range of blast.
	MOVGE v1, #1
	CMP a1, v4
	MOVLE v2, #1
	CMP v1, v2
	MOVEQ v7, #1
	
	MOV v1, #-1					 ; Re-initialize variables to non equal values for pairwise comparison.
	MOV v2, #-2
	
	CMP a2, v5                   ; Check if enemy is within y-range of blast.
	MOVGE v1, #1
	CMP a2, v6
	MOVLE v2, #1
	CMP v1, v2
	MOVEQ v8, #1
	
	CMP v7, v8                   ; If enemy is within x-range and y-range, we have a hit.
	BNE kill_enemy2
	
	LDR a1, =enemy1_killed		; Kill enemy #1
	MOV a2, #1
	STR a2, [a1]
	
	LDR a1, =enemy1_x_pos
	LDR a2, =enemy1_y_pos
	MOV a3, #-100
	STR a3, [a1]
	STR a3, [a2]                 ; Move enemy off board.
	
	LDR a1, =num_enemies         ; Decrement enemy count.
	LDR a2, [a1]
	SUB a2, a2, #1
	CMP a2, #0                   ; Is there no enemies left? If so, go to the next level.
	BEQ kill_enemy_exit_level_up
	STR a2, [a1]

kill_enemy2
	LDR a1, =enemy2_killed
	LDR a1, [a1]
	CMP a1, #1
	BEQ kill_enemy3				; Is enemy already dead? If so, skip check.
	
	LDR a1, =enemy2_x_pos
	LDR a1, [a1]
	LDR a2, =enemy2_y_pos
	LDR a2, [a2]
	MOV v1, #-1					; Initialize variables for pairwise comparison.
	MOV v2, #-2
	MOV v7, #-3
	MOV v8, #-4
	
	CMP a1, v3                   ; Check if enemy is within x-range of blast.
	MOVGE v1, #1
	CMP a1, v4
	MOVLE v2, #1
	CMP v1, v2
	MOVEQ v7, #1
	
	MOV v1, #-1
	MOV v2, #-2
	
	CMP a2, v5                   ; Check if enemy is within y-range of blast.
	MOVGE v1, #1
	CMP a2, v6
	MOVLE v2, #1				 ; Re-initialize variables to non equal values for pairwise comparison.
	CMP v1, v2
	MOVEQ v8, #1
	
	CMP v7, v8                   ; If enemy is within x-range and y-range, we have a hit.
	BNE kill_enemy3
	
	LDR a1, =enemy2_killed       ; Kill enemy #2.
	MOV a2, #1
	STR a2, [a1]	
	
	LDR a1, =enemy2_x_pos
	LDR a2, =enemy2_y_pos
	MOV a3, #-100
	STR a3, [a1]
	STR a3, [a2]                 ; Move enemy off board.

	LDR a1, =num_enemies         ; Decrement enemy count.
	LDR a2, [a1]
	SUB a2, a2, #1
	CMP a2, #0                   ; Is there no enemies left? If so, go to the next level.
	BEQ kill_enemy_exit_level_up
	STR a2, [a1]

kill_enemy3
	LDR a1, =enemy3_killed
	LDR a1, [a1]
	CMP a1, #1
	BEQ kill_enemy_exit			 ; Is enemy already dead? If so, skip check.
	
	LDR a1, =enemy3_x_pos
	LDR a1, [a1]
	LDR a2, =enemy3_y_pos
	LDR a2, [a2]
	MOV v1, #-1					 ; Initialize variables for pairwise comparison.
	MOV v2, #-2
	MOV v7, #-3
	MOV v8, #-4
	
	CMP a1, v3                   ; Check if enemy is within x-range of blast.
	MOVGE v1, #1
	CMP a1, v4
	MOVLE v2, #1
	CMP v1, v2
	MOVEQ v7, #1
	
	MOV v1, #-1					 ; Re-initialize variables to non equal values for pairwise comparison.
	MOV v2, #-2
	
	CMP a2, v5                   ; Check if enemy is within y-range of blast.
	MOVGE v1, #1
	CMP a2, v6
	MOVLE v2, #1
	CMP v1, v2
	MOVEQ v8, #1
	
	CMP v7, v8                   ; If enemy is within x-range and y-range, we have a hit.
	BNE kill_enemy_exit
	
	LDR a1, =enemy3_killed		 ; Kill enemy #3.
	MOV a2, #1
	STR a2, [a1]
	
	LDR a1, =enemy3_x_pos
	LDR a2, =enemy3_y_pos
	MOV a3, #-100
	STR a3, [a1]
	STR a3, [a2]                 ; Move enemy off board.
	
	LDR a1, =num_enemies         ; Decrement enemy count.
	LDR a2, [a1]
	SUB a2, a2, #1
	CMP a2, #0                   ; Is there no enemies left? If so, go to the next level.
	BEQ kill_enemy_exit_level_up
	STR a2, [a1]
	
kill_enemy_exit
	LDMFD sp!, {lr, v1-v8}
	BX lr
	
kill_enemy_exit_level_up
	LDMFD sp!, {lr, v1-v8}
	B level_up

;-------------------------------------------------------;
; @NAME                                                 ;
; level_up                                              ;
;                                                       ;
; @DESCRIPTION                                          ;
; Re-initialize board and increase game diffulculty by  ; 
; increasing speed                                      ;
;-------------------------------------------------------;
level_up
	BL clear_bomb_detonation
	
	LDR a1, =bomberman_x_pos
	LDR a1, [a1]
	LDR a2, =bomberman_y_pos
	LDR a2, [a2]
	MOV a3, #FREE
	BL update_pos
	
	LDR a1, =level
	LDR a2, [a1]
	ADD a2, a2, #1
	STR a2, [a1]
	CMP a2, #MAX_LEVEL
	BGT begin_next_level
	
increase_speed
	LDR a1, =T0MR0
	LDR a2, [a1]
	LSR a2, a2, #1			
	STR a2, [a1]				; Double the speed of the game.	
	

begin_next_level
	BL initialize_game
	B game_loop


;-------------------------------------------------------;
; @NAME                                                 ;
; clear_bomb_detonation                                 ;
;                                                       ;
; @DESCRIPTION                                          ;
; Detonate the placed bomb.                             ;
;-------------------------------------------------------;
clear_bomb_detonation
	STMFD sp!, {lr, v1-v8}
	
	LDR a1, =bomb_detonated
	LDR a2, [a1]
	CMP a2, #0
	BEQ clear_bomb_detonation_exit  ; Has the bomb detonated? If not, exit.
	
	MOV a2, #0
	STR a2, [a1]                    ; De-assert bomb detonated flag.
  
	LDR a1, =bomb_x_pos
	LDR a1, [a1]
	MOV v1, a1
	LDR a2, =bomb_y_pos
	LDR a2, [a2]
	MOV v2, a2
	
	SUB v3, v1, #BLAST_X_RADIUS  ; Lower bound x-position for blast.
	CMP v3, #0
	MOVLT v3, #0
	ADD v4, v1, #BLAST_X_RADIUS  ; Upper bound x-position for blast.
	CMP v4, #0
	MOVLT v4, #0
	
	SUB v5, v2, #BLAST_Y_RADIUS  ; Lower bound y-position for blast.
	CMP v5, #0
	MOVLT v5, #0
	ADD v6, v2, #BLAST_Y_RADIUS  ; Upper bound y-position for blast.
	CMP v6, #0
	MOVLT v6, #0
	
clear_bomb_detonation_west
	MOV v7, v1
	
clear_bomb_detonation_west_loop
	MOV a1, v7
	MOV a2, v2
	BL check_pos_char
	CMP a1, #BARRIER
	BEQ clear_bomb_detonation_east
	
	MOV a1, v7
	MOV a2, v2
	MOV a3, #FREE
	BL update_pos
	
	ADD v7, v7, #1
	CMP v7, v4
	BLE clear_bomb_detonation_west_loop

clear_bomb_detonation_east
	MOV v7, v1
	
clear_bomb_detonation_east_loop
	MOV a1, v7
	MOV a2, v2
	BL check_pos_char
	CMP a1, #BARRIER
	BEQ clear_bomb_detonation_north
	
	MOV a1, v7
	MOV a2, v2
	MOV a3, #FREE
	BL update_pos
	
	SUB v7, v7, #1
	CMP v7, v3
	BGE clear_bomb_detonation_east_loop
	
clear_bomb_detonation_north
	MOV v7, v2
	
clear_bomb_detonation_north_loop
	MOV a1, v1
	MOV a2, v7
	BL check_pos_char
	CMP a1, #BARRIER
	BEQ clear_bomb_detonation_south
	
	MOV a1, v1
	MOV a2, v7
	MOV a3, #FREE
	BL update_pos
	
	SUB v7, v7, #1
	CMP v7, v5
	BGE clear_bomb_detonation_north_loop
	
clear_bomb_detonation_south
	MOV v7, v2
	
clear_bomb_detonation_south_loop
	MOV a1, v1
	MOV a2, v7
	BL check_pos_char
	CMP a1, #BARRIER
	BEQ clear_bomb_detonation_exit
	
	MOV a1, v1
	MOV a2, v7
	MOV a3, #FREE
	BL update_pos
	
	ADD v7, v7, #1
	CMP v7, v6
	BLE clear_bomb_detonation_south_loop
	
	LDR a1, =bomb_x_pos
	MOV a2, #-100
	STR a2, [a1]
	
	LDR a1, =bomb_y_pos
	MOV a2, #-100
	STR a2, [a1]
	
	LDR a1, =bomb_detonated
	MOV a2, #0
	STR a2, [a1]					; De-assert bomb_detonated flag.
	
	LDR a1, =bomb_placed            ; De-assert bomb_placed flag.
	MOV a2, #0
	STR a2, [a1]

clear_bomb_detonation_exit
	LDMFD sp!, {lr, v1-v8}
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
	
	MOV v5, #-1
	MOV v6, #-2
	
	LDR a1, =bomberman_x_pos	   ; Update new bomberman X-position.
	STR v3, [a1]
	LDR a2, =bomberman_y_pos       ; Update new bomerman Y-position.
	STR v4, [a2]
	
	MOV a1, v3
	MOV a2, v4
	MOV a3, #BOMBERMAN             ; Move bomerman to new position.
	BL update_pos
	
	MOV a1, v1                     ; Skip moving bomberman from old position only if a bomb has 
	MOV a2, v2                     ; occupied old position AND is currently placed.
	MOV a3, #FREE
	MOV v5, #100                   ; Initialize to two non equal values. Needed to compare two
	MOV v6, #101                   ; X-Y coordinate pairs properly.
	MOV v7, #102
	MOV v8, #103
	
	LDR v3, =bomb_x_pos
	LDR v3, [v3]
	CMP v3, v1                    ; Compare old x-position to bomb's x-position.
	MOVEQ v5, #1
	
	LDR v4, =bomb_y_pos
	LDR v4, [v4]
	CMP v4, v2                    ; Compare old y-position to bomb's y-position.
	MOVEQ v6, #1
	
	CMP v5, v6
	MOVEQ v7, #1                  ; Is a bomb placed at the old position?
	
	LDR v8, =bomb_placed
	LDR v8, [v8]
	CMP v8, #1
	MOVEQ v8, #1                  ; Is the bomb currently placed (not detonated)?
	
	CMP v7, v8					  ; Does a bomb occupy the old position? Is is currently placed?
	BEQ not_valid_move
	
	BL update_pos                 ; Otherwise, remove bomberman from old position.
	
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
; move_enemies                                          ;
;                                                       ;
; @DESCRIPTION                                          ;
; Move the enemies if any open space is available       ;
; them. Skip moving if the enemy is killed              ;
;-------------------------------------------------------;
move_enemies
	STMFD SP!, {lr, v1-v3}
	
	LDR v1, =enemy_slow_moved		; Check if the slow enemies moved last frame
	LDR a1, [v1]
	CMP a1, #1
	MOVEQ a1, #0					; If they did, reset the flag and skip to enemy three
	STREQ a1, [v1]
	BEQ enemy2_move_skip
	MOV a1, #1						; If they didn't, set the flag and continue execution
	STR a1, [v1]


	LDR v1, =enemy1_killed 			; Check if enemy 1 is dead
	LDR a1, [v1]
	CMP a1, #1						; If dead, skip moving it
	BEQ enemy1_move_skip
	LDR v1, =enemy1_x_pos			; Load enemy position into v1 and v2
	LDR v1, [v1]
	LDR v2, =enemy1_y_pos
	LDR v2, [v2]
	MOV a1, v1						; Copy location to argument registers and see if we can move
	MOV a2, v2
	BL check_enemy_moves
	CMP a1, #0
	BEQ enemy1_move_skip			; If no move available, skip
	
	;If we're here, we have a valid move.  Erase the previous character and write the new one
	MOV v3, a1						; Save selected direction
	MOV a1, v1
	MOV a2, v2
	MOV a3, #FREE
	BL update_pos					; Clear the previous space
	
	CMP v3, #MOVE_UP				; See which direction we're going
	SUBEQ v2, v2, #1				; Going up! (Y - 1)
	CMP v3, #MOVE_RIGHT
	ADDEQ v1, v1, #1				; Going right! (X + 1)
	CMP v3, #MOVE_DOWN
	ADDEQ v2, v2, #1				; Going down! (Y + 1)  (13 degrees down angle!)
	CMP v3, #MOVE_LEFT
	SUBEQ v1, v1, #1				; Going left! (X - 1)

	LDR v3, =enemy1_x_pos		   	; Update enemy's position
	STR v1, [v3]
	LDR v3, =enemy1_y_pos
	STR v2, [v3]
	
	MOV a1, v1						; Put new location in argument registers
	MOV a2, v2
	MOV a3, #ENEMY_SLOW
	BL update_pos				    ; Draw new position

enemy1_move_skip

	LDR v1, =enemy2_killed 			; Check if enemy 2 is dead
	LDR a1, [v1]
	CMP a1, #1						; If dead, skip moving it
	BEQ enemy2_move_skip
	LDR v1, =enemy2_x_pos			; Load enemy position into v1 and v2
	LDR v1, [v1]
	LDR v2, =enemy2_y_pos
	LDR v2, [v2]
	MOV a1, v1						; Copy location to argument registers and see if we can move
	MOV a2, v2
	BL check_enemy_moves
	CMP a1, #0
	BEQ enemy2_move_skip			; If no move available, skip
	
	;If we're here, we have a valid move.  Erase the previous character and write the new one
	MOV v3, a1						; Save selected direction
	MOV a1, v1
	MOV a2, v2
	MOV a3, #FREE
	BL update_pos					; Clear the previous space
	
	CMP v3, #MOVE_UP				; See which direction we're going
	SUBEQ v2, v2, #1				; Going up! (Y - 1)
	CMP v3, #MOVE_RIGHT
	ADDEQ v1, v1, #1				; Going right! (X + 1)
	CMP v3, #MOVE_DOWN
	ADDEQ v2, v2, #1				; Going down! (Y + 1)  (13 degrees down angle!)
	CMP v3, #MOVE_LEFT
	SUBEQ v1, v1, #1				; Going left! (X - 1)
	
	LDR v3, =enemy2_x_pos		   	; Update enemy's position
	STR v1, [v3]
	LDR v3, =enemy2_y_pos
	STR v2, [v3]

	MOV a1, v1						; Put new location in argument registers
	MOV a2, v2
	MOV a3, #ENEMY_SLOW
	BL update_pos

enemy2_move_skip

	LDR v1, =enemy3_killed 			; Check if enemy 3 is dead
	LDR a1, [v1]
	CMP a1, #1						; If dead, skip moving it
	BEQ enemy3_move_skip
	LDR v1, =enemy3_x_pos			; Load enemy position into v1 and v2
	LDR v1, [v1]
	LDR v2, =enemy3_y_pos
	LDR v2, [v2]
	MOV a1, v1						; Copy location to argument registers and see if we can move
	MOV a2, v2
	BL check_enemy_moves
	CMP a1, #0
	BEQ enemy3_move_skip			; If no move available, skip
	
	;If we're here, we have a valid move.  Erase the previous character and write the new one
	MOV v3, a1						; Save selected direction
	MOV a1, v1
	MOV a2, v2
	MOV a3, #FREE
	BL update_pos					; Clear the previous space
	
	CMP v3, #MOVE_UP				; See which direction we're going
	SUBEQ v2, v2, #1				; Going up! (Y - 1)
	CMP v3, #MOVE_RIGHT
	ADDEQ v1, v1, #1				; Going right! (X + 1)
	CMP v3, #MOVE_DOWN
	ADDEQ v2, v2, #1				; Going down! (Y + 1)  (13 degrees down angle!)
	CMP v3, #MOVE_LEFT
	SUBEQ v1, v1, #1				; Going left! (X - 1)
	
	LDR v3, =enemy3_x_pos		   	; Update enemy's position
	STR v1, [v3]
	LDR v3, =enemy3_y_pos
	STR v2, [v3]

	MOV a1, v1						; Put new location in argument registers
	MOV a2, v2
	MOV a3, #ENEMY_FAST
	BL update_pos

enemy3_move_skip

	LDMFD SP!, {lr, v1-v3}
	BX lr

;-------------------------------------------------------;
; @NAME                                                 ;
; check_enemy_moves                                     ;
;                                                       ;
; @DESCRIPTION                                          ;
; Determines if an enemy can move anywhere.  X position ;
; is passed in a1 and Y position in a2.  Direction to   ;
; move is returned, or 0 if no valid moves are possible ;
; (1=up, 2=right, 3=down, 4=left)                       ;
;-------------------------------------------------------;
check_enemy_moves
	STMFD SP!, {lr, v1-v3}
	MOV a1, v1			;Save x and y position to v1-v2
	MOV a2, v2
	MOV v3, #0			;v3 keeps track of the valid directions (Bit0=UP, Bit1=RIGHT, Bit2=DOWN, Bit3=LEFT)

	;Check up
	SUB a2, v2, #1		;Check y-1
	BL check_pos_char
	CMP a1, #FREE		;Is it a space?  Valid move if so
	ORREQ v3, v3, #0x01
	CMP a1, #BOMBERMAN	;Is it bomberman?  Valid move if so
	ORREQ v3, v3, #0x01
	

	;Check right
	ADD a1, v1, #1		;Check x+1
	MOV a2, v2   		;Check y
	BL check_pos_char
	CMP a1, #' '		;Is it a space?  Valid move if so
	ORREQ v3, v3, #0x02
	CMP a1, #'B'		;Is it bomberman?  Valid move if so
	ORREQ v3, v3, #0x02

	;Check down
	MOV a1, v1		    ;Check x
	ADD a2, v2, #1   	;Check y+1
	BL check_pos_char
	CMP a1, #' '		;Is it a space?  Valid move if so
	ORREQ v3, v3, #0x04
	CMP a1, #'B'		;Is it bomberman?  Valid move if so
	ORREQ v3, v3, #0x04

	;Check left
	SUB a1, v1, #1		;Check x-1
	MOV a2, v2      	;Check y
	BL check_pos_char
	CMP a1, #' '		;Is it a space?  Valid move if so
	ORREQ v3, v3, #0x08
	CMP a1, #'B'		;Is it bomberman?  Valid move if so
	ORREQ v3, v3, #0x08

	CMP v3, #0				 	;If we have no valid moves, just return 0 and quit
	MOVEQ a1, #0
	BEQ check_enemy_moves_exit

	;If we're here, we have valid moves.  Pick a random one
check_enemy_moves_pick_rand
	BL rand				;get a random number
	AND a1, a1, #0xC000	;Keep the upper 2 bits
	MOV a1, a1, LSR #14	 ;Move the bits to the lower digits for a number from 0-3
	MOV a2, v3, LSR a1	;Copy valid moves and shift right to examine selected move
	ANDS a2, #0x01		;Keep only LSB.  If it's one, we have a valid move.
	BEQ check_enemy_moves_pick_rand		;result is zero, selected move is not zero
	ADD a1, a1, #1		;Increment the move number to shift from 0-3 to 1-4
	;a1 contains the number of the valid move.  Return it

check_enemy_moves_exit
	LDMFD SP!, {lr, v1-v3}
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
	
	MOV v3, #NUM_BRICKS     ; Number of bricks to generate. Might need
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
	CMP v1, #FREE                     ; a space character (ascii code 32). A space 
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

	AREA lib, CODE, READWRITE

	EXTERN BOARD_WIDTH
	EXPORT keystroke
	EXPORT board
	
bomb_placed		DCD 0x00000000
bomb_detonated	DCD 0x00000000
bomb_timer		DCD 0x00000000
bomb_radius		DCD 0x00000001
bomb_x_pos		DCD 0x00000000
bomb_y_pos		DCD 0x00000000

bomberman_x_pos	DCD 0x00000000
bomberman_y_pos DCD 0x00000000

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

level			DCD 0x00000000

time			DCD 0x00000000

score			DCD 0x00000000

game_over		DCD 0x00000000

keystroke		DCD 0x00000000

board = "ZZZZZZZZZZZZZZZZZZZZZZZZZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZ Z Z Z Z Z Z Z Z Z Z Z ZZ                       ZZZZZZZZZZZZZZZZZZZZZZZZZZ"

	ALIGN
	
;-------------------------------------------------------;
; NAME                                                  ;
; generate_brick_walls                                  ;
;                                                       ;
; DESCRIPTION                                           ;
; Randomly place brick walls throughout the game board. ;
;-------------------------------------------------------;	
generate_brick_walls
	STMFD sp!, {v1-v3, lr}
	LDR v1, =level			; Load current level into v1.
	LDR v1, [v1]
	
	MOV v3, #10
	MUL v2, v1, v3			; v2 = number of bricks = level * 10.
	
	MOV v3, #0				; Initialize counter.
	
place_brick_wall
	LDMFD sp!, {v1-v3, lr}
	BX lr
	
;-------------------------------------------------------;
; NAME                                                  ;
; check_pos			                                    ;
;                                                       ;
; DESCRIPTION                                           ;
; Checks whether specified position on game board is    ;
; free. X is passed in a1. Y is passed in a2. Returns 1 ; 
; in a1 if spot if free, otherwise returns 0. Note that ;
; the origin (0,0) is defined as the upper left most    ;
; 'Z'.                                                  ;
;-------------------------------------------------------;
check_pos
	STMFD sp!, {a2,v1-v3, lr}
	MOV v2, #0
	LDR v1, =board
	ADD v2, v2, #BOARD_WIDTH	; The offset is calculated as (board_width*Y)+X.
	MUL v3, a2, v2
	ADD v3, v3, a1				
	
	ADD v1, v1, v3				; Add offset to base address of board string.
	
	LDRB v1, [v1]				; Finally, load the character and check if it is 
	CMP v1, #32					; a space character (ascii code 32). A space 
	BNE check_pos_assert_false  ; character indicates the position is free.
	
check_pos_assert_true
	MOV a1, #1
	B check_pos_exit
	
check_pos_assert_false
	MOV a1, #0
	
check_pos_exit
	LDMFD sp!, {a2, v1-v3, lr}
	BX lr
	END
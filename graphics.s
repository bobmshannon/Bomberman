	AREA lib, CODE, READWRITE
	
	EXTERN board
	EXTERN set_cursor_pos
	EXTERN output_character
	EXPORT draw

draw
	STMFD sp!, {lr}
	BL draw_board
	LDMFD sp!, {lr}
	BX lr

draw_board
	STMFD sp!, {lr}
	
	MOV v1, #0			; row_counter = 0
	MOV v2, #0			; column_counter = 0;
	
	MOV a1, #0
	MOV a2, #3
	BL set_cursor_pos	; Set cursor position to (0,3).

	LDR v3, =board
	
	
print_loop
	LDR a2, [v3]
	MOV a1, a2
	BL output_character
	ADD v3, v3, #1
	ADD v2, v2, #1
	CMP v2, #25
	BNE print_loop
	
	MOV v2, #0
	ADD v1, v1, #1
	
	MOV a1, #'\n'
	BL output_character
	MOV a1, #'\r'
	BL output_character
	
	CMP v1, #13
	BNE print_loop
	
	LDMFD sp!, {lr}
	BX lr
	
	END
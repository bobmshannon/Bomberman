	AREA lib, CODE, READWRITE
	
	EXTERN board
	EXTERN set_cursor_pos
	EXTERN output_character
	EXPORT draw
	EXPORT BOARD_WIDTH
	EXPORT BOARD_HEIGHT
		
BOARD_WIDTH    EQU 25
BOARD_HEIGHT   EQU 13
BOARD_X_OFFSET EQU 0
BOARD_Y_OFFSET EQU 3

;-------------------------------------------------------;
; NAME                                                  ;
; draw                                                  ;
;                                                       ;
; DESCRIPTION                                           ;
; Draw current game state to screen.                    ;
;-------------------------------------------------------;
draw
	STMFD sp!, {lr}
	BL draw_board
	LDMFD sp!, {lr}
	BX lr

draw_board
	STMFD sp!, {a1-a2, v1-v3, lr}
	
	MOV v1, #0				; row_counter = 0
	MOV v2, #0				; column_counter = 0;
	
	MOV a1, #BOARD_X_OFFSET
	MOV a2, #BOARD_Y_OFFSET
	BL set_cursor_pos		; Set cursor position to (0,3).

	LDR v3, =board			; Load base address of board string.
	
print_loop
	LDR a2, [v3]
	MOV a1, a2	
	BL output_character	
	ADD v3, v3, #1			; board += 1
	ADD v2, v2, #1			; column_counter +=1
	CMP v2, #BOARD_WIDTH	; Does column_counter == board width?
	BNE print_loop			; If not, continue printing the row.
	
	MOV v2, #0				; column_counter = 0
	ADD v1, v1, #1			; row_counter += 1
	
	MOV a1, #'\n'			; We're ready to print the next row.
	BL output_character		; Print a newline and carriage return.
	MOV a1, #'\r'
	BL output_character
	
	CMP v1, #BOARD_HEIGHT	; Does row_counter == board height?
	BNE print_loop			; If not, we need to print the next row.
	
	LDMFD sp!, {a1-a2, v1-v3, lr}
	BX lr
	
	END
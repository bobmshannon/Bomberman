	AREA lib, CODE, READWRITE
	
	EXTERN board
	EXTERN prev_board
	EXTERN set_cursor_pos
	EXTERN output_character
	EXTERN score
	EXTERN print_integer
	EXTERN output_string
	EXTERN time_left
	EXPORT draw
	EXPORT draw_changes
	EXPORT BOARD_WIDTH
	EXPORT BOARD_HEIGHT
	EXPORT draw_game_over
		
BOARD_WIDTH    EQU 25
BOARD_HEIGHT   EQU 13
BOARD_X_OFFSET EQU 0
BOARD_Y_OFFSET EQU 3
	
score_message = "Score: ", 0
time_message = "\rTime:    ", 0
game_over = "\f\n\r               ������+  �����+ ���+   ���+�������+     ������+ ��+   ��+�������+������+ ��+ \n\r              ��+----+ ��+--��+����+ �������+----+    ��+---��+���   �����+----+��+--��+��� \n\r              ���  ���+����������+����+��������+      ���   ������   ��������+  ������++��� \n\r              ���   �����+--������+��++�����+--+      ���   ���+��+ ��++��+--+  ��+--��++-+ \n\r              +������++���  ������ +-+ ����������+    +������++ +����++ �������+���  �����+ \n\r               +-----+ +-+  +-++-+     +-++------+     +-----+   +---+  +------++-+  +-++-+", 0
game_over_score = "\n\r				                                          YOUR SCORE WAS: ", 0
play_again = "\n\r������+ ������+ �������+�������+�������+    �������+���+   ��+��������+�������+������+     ��������+ ������+     \n\r��+--��+��+--��+��+----+��+----+��+----+    ��+----+����+  ���+--��+--+��+----+��+--��+    +--��+--+��+---��+    \n\r������++������++�����+  �������+�������+    �����+  ��+��+ ���   ���   �����+  ������++       ���   ���   ���    \n\r��+---+ ��+--��+��+--+  +----���+----���    ��+--+  ���+��+���   ���   ��+--+  ��+--��+       ���   ���   ���    \n\r���     ���  ����������+����������������    �������+��� +�����   ���   �������+���  ���       ���   +������++    \n\r+-+     +-+  +-++------++------++------+    +------++-+  +---+   +-+   +------++-+  +-+       +-+    +-----+     \n\r                                                                                                                 \n\r            ������+ ��+      �����+ ��+   ��+     �����+  ������+  �����+ ��+���+   ��+��+                       \n\r            ��+--��+���     ��+--��++��+ ��++    ��+--��+��+----+ ��+--��+�������+  ������                       \n\r            ������++���     �������� +����++     �����������  ���+�������������+��+ ������                       \n\r            ��+---+ ���     ��+--���  +��++      ��+--������   �����+--���������+��+���+-+                       \n\r            ���     �������+���  ���   ���       ���  ���+������++���  ��������� +�������+                       \n\r            +-+     +------++-+  +-+   +-+       +-+  +-+ +-----+ +-+  +-++-++-+  +---++-+", 0  

	ALIGN

;-------------------------------------------------------;
; @NAME                                                 ;
; draw                                                  ;
;                                                       ;
; @DESCRIPTION                                          ;
; Draw current game state to screen.                    ;
;-------------------------------------------------------;
draw
	STMFD sp!, {lr}
	MOV a1, #16
	MOV a2, #2
	BL set_cursor_pos
	BL draw_score

	MOV a1, #1
	MOV a1, #2
	BL set_cursor_pos
	BL draw_time

	BL draw_board
	LDMFD sp!, {lr}
	BX lr
	
draw_game_over
	STMFD sp!, {lr, v1}
	
	MOV a1, #'\f'
	BL output_character
	
	LDR v1, =game_over
	BL output_string
	
	LDR v1, =game_over_score
	BL output_string
	LDR v1, =score
	LDR a1, [v1]
	BL print_integer
	
	LDR v1, =play_again
	BL output_string
	
	LDMFD sp!, {lr, v1}
	BX lr
	
draw_score
	STMFD sp!, {lr, v1}
	
	LDR v1, =score_message
	BL output_string
	LDR a1, =score
	LDR a1, [a1]
	BL print_integer
	
	LDMFD sp!, {lr, v1}
	BX lr
	
draw_time
	STMFD sp!, {lr, v1}
	
	LDR v1, =time_message
	BL output_string
	MOV a1, #7
	MOV a2, #2
	BL set_cursor_pos
	LDR a1, =time_left
	LDR a1, [a1]
	BL print_integer
	
	LDMFD sp!, {lr, v1}
	BX lr

draw_board
	STMFD sp!, {a1-a2, v1-v3, lr}
	
	MOV v1, #0				; row_counter = 0
	MOV v2, #0				; column_counter = 0;
	
	MOV a1, #BOARD_X_OFFSET
	MOV a2, #BOARD_Y_OFFSET
	BL set_cursor_pos		; Set cursor position to (0,3).

	LDR v3, =board			; Load base address of board array.
	
draw_board_loop
	LDRB a2, [v3]
	MOV a1, a2	
	BL output_character	
	ADD v3, v3, #1			; board += 1
	ADD v2, v2, #1			; column_counter +=1
	CMP v2, #BOARD_WIDTH	; Does column_counter == board width?
	BNE draw_board_loop		; If not, continue printing the row.
	
	MOV v2, #0				; column_counter = 0
	ADD v1, v1, #1			; row_counter += 1
	
	MOV a1, #'\n'			; We're ready to print the next row.
	BL output_character		; Print a newline and carriage return.
	MOV a1, #'\r'
	BL output_character
	
	CMP v1, #BOARD_HEIGHT	; Does row_counter == board height?
	BNE draw_board_loop			; If not, we need to print the next row.
	
	LDMFD sp!, {a1-a2, v1-v3, lr}
	BX lr
	
;-------------------------------------------------------;
; @NAME                                                 ;
; draw_changes                                          ;
;                                                       ;
; @DESCRIPTION                                          ;
; Draw current game state to screen, only printing      ;
; characters that have changed since last refresh. This ;
; is a faster alternative to draw.                      ;
;-------------------------------------------------------;
draw_changes
	STMFD sp!, {lr}
	BL draw_board_changes
	LDMFD sp!, {lr}
	BX lr

draw_board_changes
	STMFD sp!, {a1-a2, v1-v3, lr}
	
	MOV v1, #0				; row_counter = 0
	MOV v2, #0				; column_counter = 0;
	
	MOV a1, #BOARD_X_OFFSET
	MOV a2, #BOARD_Y_OFFSET
	BL set_cursor_pos		; Set cursor position to (0,3).

	LDR v3, =board			; Load base address of board array.
	LDR v4, =prev_board     ; Load base address of prev_board array.
	
draw_changes_loop
	LDRB a1, [v3]
	LDRB a2, [v4]
	
	CMP a1, a2
	BLNE draw_change        ; Has this position changed since last refresh? If so,
	                        ; print it.
	
	STRB a1, [v4]           ; Save a copy of current board state into prev_board.
	
	ADD v3, v3, #1			; board += 1
	ADD v2, v2, #1			; column_counter +=1
	CMP v2, #BOARD_WIDTH	; Does column_counter == board width?
	BNE draw_changes_loop	; If not, continue printing the row.
	
	MOV v2, #0				; column_counter = 0
	ADD v1, v1, #1			; row_counter += 1
	
	MOV a1, v2
	MOV a2, v1
	BL set_cursor_pos
	MOV a1, #'\n'			; We're ready to print the next row.
	BL output_character		; Print a newline and carriage return.
	MOV a1, #'\r'
	BL output_character
	
	CMP v1, #BOARD_HEIGHT	; Does row_counter == board height?
	BNE draw_changes_loop	; If not, we need to print the next row.
	
	LDMFD sp!, {a1-a2, v1-v3, lr}
	BX lr
	
draw_change
    STMFD sp!, {lr}
	
	MOV a3, a1
	MOV a1, v2
	MOV a2, v1
	BL set_cursor_pos
	MOV a1, a3
	BL output_character
	
	LDMFD sp!, {lr}
	BX lr
	END
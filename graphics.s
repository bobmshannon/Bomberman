	AREA lib, CODE, READWRITE
	
	EXTERN board
	EXTERN prev_board
	EXTERN set_cursor_pos
	EXTERN output_character
	EXTERN score
	EXTERN print_integer
	EXTERN output_string
	EXTERN time_left
	EXTERN is_paused
	EXTERN div_and_mod
	EXTERN game_title

	EXPORT draw_time
	EXPORT draw_score
	EXPORT draw
	EXPORT draw_changes
	EXPORT BOARD_WIDTH
	EXPORT BOARD_HEIGHT
	EXPORT draw_game_over
	EXPORT draw_paused
		
BOARD_WIDTH    EQU 25
BOARD_HEIGHT   EQU 13
BOARD_X_OFFSET EQU 0
BOARD_Y_OFFSET EQU 3
	
score_message = "Score: ", 0
time_message = "\rTime:    ", 0
game_over = "\f\n\r               ¦¦¦¦¦¦+  ¦¦¦¦¦+ ¦¦¦+   ¦¦¦+¦¦¦¦¦¦¦+     ¦¦¦¦¦¦+ ¦¦+   ¦¦+¦¦¦¦¦¦¦+¦¦¦¦¦¦+ ¦¦+ \n\r              ¦¦+----+ ¦¦+--¦¦+¦¦¦¦+ ¦¦¦¦¦¦¦+----+    ¦¦+---¦¦+¦¦¦   ¦¦¦¦¦+----+¦¦+--¦¦+¦¦¦ \n\r              ¦¦¦  ¦¦¦+¦¦¦¦¦¦¦¦¦¦+¦¦¦¦+¦¦¦¦¦¦¦¦+      ¦¦¦   ¦¦¦¦¦¦   ¦¦¦¦¦¦¦¦+  ¦¦¦¦¦¦++¦¦¦ \n\r              ¦¦¦   ¦¦¦¦¦+--¦¦¦¦¦¦+¦¦++¦¦¦¦¦+--+      ¦¦¦   ¦¦¦+¦¦+ ¦¦++¦¦+--+  ¦¦+--¦¦++-+ \n\r              +¦¦¦¦¦¦++¦¦¦  ¦¦¦¦¦¦ +-+ ¦¦¦¦¦¦¦¦¦¦+    +¦¦¦¦¦¦++ +¦¦¦¦++ ¦¦¦¦¦¦¦+¦¦¦  ¦¦¦¦¦+ \n\r               +-----+ +-+  +-++-+     +-++------+     +-----+   +---+  +------++-+  +-++-+", 0
game_over_score = "\n\r				                                          YOUR SCORE WAS: ", 0
;play_again = "\n\r¦¦¦¦¦¦+ ¦¦¦¦¦¦+ ¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+    ¦¦¦¦¦¦¦+¦¦¦+   ¦¦+¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+¦¦¦¦¦¦+     ¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+     \n\r¦¦+--¦¦+¦¦+--¦¦+¦¦+----+¦¦+----+¦¦+----+    ¦¦+----+¦¦¦¦+  ¦¦¦+--¦¦+--+¦¦+----+¦¦+--¦¦+    +--¦¦+--+¦¦+---¦¦+    \n\r¦¦¦¦¦¦++¦¦¦¦¦¦++¦¦¦¦¦+  ¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+    ¦¦¦¦¦+  ¦¦+¦¦+ ¦¦¦   ¦¦¦   ¦¦¦¦¦+  ¦¦¦¦¦¦++       ¦¦¦   ¦¦¦   ¦¦¦    \n\r¦¦+---+ ¦¦+--¦¦+¦¦+--+  +----¦¦¦+----¦¦¦    ¦¦+--+  ¦¦¦+¦¦+¦¦¦   ¦¦¦   ¦¦+--+  ¦¦+--¦¦+       ¦¦¦   ¦¦¦   ¦¦¦    \n\r¦¦¦     ¦¦¦  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦    ¦¦¦¦¦¦¦+¦¦¦ +¦¦¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦+¦¦¦  ¦¦¦       ¦¦¦   +¦¦¦¦¦¦++    \n\r+-+     +-+  +-++------++------++------+    +------++-+  +---+   +-+   +------++-+  +-+       +-+    +-----+     \n\r                                                                                                                 \n\r            ¦¦¦¦¦¦+ ¦¦+      ¦¦¦¦¦+ ¦¦+   ¦¦+     ¦¦¦¦¦+  ¦¦¦¦¦¦+  ¦¦¦¦¦+ ¦¦+¦¦¦+   ¦¦+¦¦+                       \n\r            ¦¦+--¦¦+¦¦¦     ¦¦+--¦¦++¦¦+ ¦¦++    ¦¦+--¦¦+¦¦+----+ ¦¦+--¦¦+¦¦¦¦¦¦¦+  ¦¦¦¦¦¦                       \n\r            ¦¦¦¦¦¦++¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++     ¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦+¦¦¦¦¦¦¦¦¦¦¦¦¦+¦¦+ ¦¦¦¦¦¦                       \n\r            ¦¦+---+ ¦¦¦     ¦¦+--¦¦¦  +¦¦++      ¦¦+--¦¦¦¦¦¦   ¦¦¦¦¦+--¦¦¦¦¦¦¦¦¦+¦¦+¦¦¦+-+                       \n\r            ¦¦¦     ¦¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦       ¦¦¦  ¦¦¦+¦¦¦¦¦¦++¦¦¦  ¦¦¦¦¦¦¦¦¦ +¦¦¦¦¦¦¦+                       \n\r            +-+     +------++-+  +-+   +-+       +-+  +-+ +-----+ +-+  +-++-++-+  +---++-+", 0  
play_again = "\r\n                                  Press [ENTER] to play again or [ESC] to quit.", 0
is_paused_msg = "        PAUSED             ", 0

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
	
	LDR v1, =board						; Copy current board state into prev_board.
	LDR v2, =prev_board
	BL strcpy
	
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

draw_paused
	STMFD sp!, {lr, v1}
	
	LDR a3, =is_paused
	LDR a3, [a3]
	CMP a3, #1
	BEQ draw_paused_show
	B draw_paused_hide

draw_paused_show
	MOV a1, #0
	MOV a2, #0
	BL set_cursor_pos
	LDR v1, =is_paused_msg
	BL output_string
	B draw_paused_exit

	
draw_paused_hide
	MOV a1, #0
	MOV a2, #0
	BL set_cursor_pos
	LDR v1, =game_title
	BL output_string

draw_paused_exit
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
	STMFD sp!, {lr, v1-v4}
	
	LDR v1, =board
	LDR v2, =prev_board
	MOV v3, #0							; Position counter.
	
draw_changes_loop
	LDRB a1, [v1]						; Load character at current position from current game board into a1.
	LDRB a2, [v2]						; Load character at current position from previous game board into a2.
	
	CMP a1, #0
	BEQ draw_changes_exit				; Is the character a NULL? If so, stop.
	
	CMP a1, a2							; Are they different? If so, draw the change.
	MOVNE a1, a1						; Pass in the new character to draw
	MOVNE a2, v3						; Pass in current value of position counter.
	BLNE draw_change
	
	ADD v3, v3, #1						; Increment position counter.
	ADD v1, v1, #1
	ADD v2, v2, #1
	B draw_changes_loop

	
draw_changes_exit
	LDR v1, =board						; Copy current board state into prev_board.
	LDR v2, =prev_board
	BL strcpy
	
	LDMFD sp!, {lr, v1-v4}
	BX lr
	
draw_change
	STMFD sp!, {lr, v1-v4}
		; Character to draw is passed in a1
		; The value of the position counter is passed in a2.
		; Goal: overwrite position with character passed in a1.
		MOV v1, a1
		MOV v2, a2
		MOV v3, #0			; X-position (relative to top left corner of board)
		MOV v4, #0			; Y-position (relative to top left corner of board).
		MOV a3, #0
		MOV a4, #0
		
calculate_pos
	MOV a1, a2
	MOV a2, #25
	BL div_and_mod
	MOV v4, a1				; Y-position = divedend
	MOV v3, a2				; X-position = remainder
	ADD v4, v4, #3			; Y board offset
	ADD v3, v3, #1			; X board offset
	
	MOV a1, v3
	MOV a2, v4
	BL set_cursor_pos
	MOV a1, v1
	BL output_character
	

	

	LDMFD sp!, {lr, v1-v4}
	BX lr

;-------------------------------------------------------;
; @NAME                                                 ;
; strcpy                                                ;
;                                                       ;
; @DESCRIPTION                                          ;
; Copy null terminated string into another. The address ;
; of the string to copy is passed in v1. The desination ;
; address is passed in v2. No return.                   ;
;-------------------------------------------------------;
strcpy
    STMFD sp!, {lr}

strcpy_loop

	LDRB a1, [v1]
	CMP a1, #0
	BEQ strcpy_exit
	STRB a1, [v2]
	ADD v1, v1, #1
	ADD v2, v2, #1
	B strcpy_loop
	
strcpy_exit
	LDMFD sp!, {lr}
	BX lr
	END
	AREA interrupts, CODE, READWRITE

	EXPORT lab7
	EXPORT FIQ_Handler
	EXPORT game_loop
	EXPORT T0MR0
	EXPORT time_left
		
	EXTERN draw
	EXTERN draw_changes
	EXTERN initialize_game
	EXTERN update_game
	EXTERN keystroke
	EXTERN uart_init
	EXTERN pin_connect_block_setup
	EXTERN output_string
	EXTERN output_character
	EXTERN print_integer
	EXTERN set_cursor_pos
	EXTERN seed
	EXTERN life_lost_flag
	EXTERN game_over
	EXTERN draw_game_over
	EXTERN reset_game


U0BASE  EQU 0xE000C000	; UART0 Base Address	
U0IER   EQU 0xE000C004	; UART0 Interrupt Enable Register
	
T0IR	EQU 0xE0004000	; Timer 0 Interrupt Register
T0TCR	EQU 0xE0004004	; Timer 0 Timer Control Register
T0TC	EQU 0xE0004008	; Timer 0 Timer Count
T0MCR	EQU 0xE0004014	; Timer 0 Match Control Register
T0MR0	EQU 0xE0004018	; Timer 0 Match Register 0
T0MR	EQU 0xE0004018	; Timer 0 Match Register 0

T1IR	EQU 0xE0008000	; Timer 1 Interrupt Register
T1TCR	EQU 0xE0008004	; Timer 1 Timer Control Register
T1TC	EQU 0xE0008008	; Timer 1 Timer Count
T1MCR	EQU 0xE0008014	; Timer 1 Match Control Register
T1MR0	EQU 0xE0008018	; Timer 1 Match Register 0
T1MR	EQU 0xE0008018	; Timer 1 Match Register 0
	
PAUSE_KEY EQU 'p'
	
refresh_timer_fired DCD 0x00000000
is_paused DCD 0x00000000
time_left DCD 120

	ALIGN
		
;intro_message = "Update this message!\n\rPress <SPACE> to begin game",0
hide_cursor = "\x1B[?25l", 0
game_title = "       Bomberman", 0
game_over_message = "Game Over!", 0
paused_message = "PAUSED", 0
title = "\n\r|-----------------------------------------------------------------------------------------------------------------------| \n\r|  __________   ___________  __       __  __________   ___________  ___________  __       __  ___________  __        _  | \n\r| ¦¦¦¦¦¦¦¦¦¦¦¦ ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦     ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦      ¦¦¦ | \n\r| ¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦¦¦   ¦¦¦¦¦¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦¯¯¯¯¯¯¯¯¯ ¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦¦¦   ¦¦¦¦¦¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦¦¦     ¦¦¦ | \n\r| ¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦¦¦¦ ¦¦¦¦¦¦¦¦¦       ¦¦¦¦¦¦          ¦¦¦       ¦¦¦¦¦¦¦¦¦ ¦¦¦¦¦¦¦¦¦       ¦¦¦¦¦¦¦¦¦    ¦¦¦ | \n\r| ¦¦¦_______¦¦¦¦¦¦       ¦¦¦¦¦¦ ¦¦¦¦¦ ¦¦¦¦¦¦_______¦¦¦¦¦¦_________ ¦¦¦_______¦¦¦¦¦¦ ¦¦¦¦¦ ¦¦¦¦¦¦_______¦¦¦¦¦¦ ¦¦¦   ¦¦¦ | \n\r| ¦¦¦¦¦¦¦¦¦¦¦¦ ¦¦¦       ¦¦¦¦¦¦  ¦¦¦  ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦  ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦  ¦¦¦  ¦¦¦ | \n\r| ¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦       ¦¦¦¦¦¦   ¯   ¦¦¦¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦¯¯¯¯¯¯¯¯¯ ¦¦¦¯¯¯¯¦¦¦¯¯ ¦¦¦   ¯   ¦¦¦¦¦¦¯¯¯¯¯¯¯¦¦¦¦¦¦   ¦¦¦ ¦¦¦ | \n\r| ¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦          ¦¦¦     ¦¦¦  ¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦    ¦¦¦¦¦¦ | \n\r| ¦¦¦_______¦¦¦¦¦¦_______¦¦¦¦¦¦       ¦¦¦¦¦¦_______¦¦¦¦¦¦_________ ¦¦¦      ¦¦¦ ¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦     ¦¦¦¦¦ | \n\r| ¦¦¦¦¦¦¦¦¦¦¦¦ ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦       ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦       ¦¦¦¦¦¦      ¦¦¦¦ | \n\r|  ¯¯¯¯¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯¯¯  ¯         ¯  ¯¯¯¯¯¯¯¯¯¯   ¯¯¯¯¯¯¯¯¯¯¯  ¯         ¯  ¯         ¯  ¯         ¯  ¯        ¯¯  | \n\r|-----------------------------------------------------------------------------------------------------------------------|", 0
instructions = "\n\r| To play, use the 'w', 'a', 's', and 'd' keys to move Bomberman around the map.                                        | \n\r|                                                                                                                       | \n\r| To place a bomb, use the 'x' key. Once a bomb detonates, everything within the blast radius will be destroyed.        | \n\r|                                                                                                                       | \n\r| To win the game, destroy as many enemies and brick walls as possible without running out of lives.                    | \n\r|                                                                                                                       | \n\r| The legend for each entity on the map is shown below.                                                                 | \n\r|                                                                                                                       | \n\r|                                                   B - Bomberman                                                       | \n\r|                                                   + - Fast Enemy                                                      | \n\r|                                                   ð - Bomb                                                            | \n\r|                                                   Z - Indestructible Barrier                                          | \n\r|                                                   # - Destructible Brick Wall                                         | \n\r|-----------------------------------------------------------------------------------------------------------------------|", 0		
enter_to_play = "\n\r \n\r            \n\r                 ¦¦¦¦¦¦+ ¦¦¦¦¦¦+ ¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+    ¦¦¦¦¦¦¦+¦¦¦+   ¦¦+¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+¦¦¦¦¦¦+     \n\r                 ¦¦+--¦¦+¦¦+--¦¦+¦¦+----+¦¦+----+¦¦+----+    ¦¦+----+¦¦¦¦+  ¦¦¦+--¦¦+--+¦¦+----+¦¦+--¦¦+    \n\r                 ¦¦¦¦¦¦++¦¦¦¦¦¦++¦¦¦¦¦+  ¦¦¦¦¦¦¦+¦¦¦¦¦¦¦+    ¦¦¦¦¦+  ¦¦+¦¦+ ¦¦¦   ¦¦¦   ¦¦¦¦¦+  ¦¦¦¦¦¦++    \n\r                 ¦¦+---+ ¦¦+--¦¦+¦¦+--+  +----¦¦¦+----¦¦¦    ¦¦+--+  ¦¦¦+¦¦+¦¦¦   ¦¦¦   ¦¦+--+  ¦¦+--¦¦+    \n\r                 ¦¦¦     ¦¦¦  ¦¦¦¦¦¦¦¦¦¦+¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦    ¦¦¦¦¦¦¦+¦¦¦ +¦¦¦¦¦   ¦¦¦   ¦¦¦¦¦¦¦+¦¦¦  ¦¦¦    \n\r                 +-+     +-+  +-++------++------++------+    +------++-+  +---+   +-+   +------++-+  +-+    \n\r                                                                                                                \n\r                                 ¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+     ¦¦¦¦¦¦+ ¦¦+      ¦¦¦¦¦+ ¦¦+   ¦¦+¦¦+                     \n\r                                 +--¦¦+--+¦¦+---¦¦+    ¦¦+--¦¦+¦¦¦     ¦¦+--¦¦++¦¦+ ¦¦++¦¦¦                     \n\r                                    ¦¦¦   ¦¦¦   ¦¦¦    ¦¦¦¦¦¦++¦¦¦     ¦¦¦¦¦¦¦¦ +¦¦¦¦++ ¦¦¦                     \n\r                                    ¦¦¦   ¦¦¦   ¦¦¦    ¦¦+---+ ¦¦¦     ¦¦+--¦¦¦  +¦¦++  +-+                     \n\r                                    ¦¦¦   +¦¦¦¦¦¦++    ¦¦¦     ¦¦¦¦¦¦¦+¦¦¦  ¦¦¦   ¦¦¦   ¦¦+                     \n\r                                    +-+    +-----+     +-+     +------++-+  +-+   +-+   +-+", 0   

	ALIGN
		
lab7	 	
	STMFD sp!, {lr, r0-r4}

	; Initialize interrupt and peripherals.
	BL pin_connect_block_setup
	BL uart_init
	BL interrupt_init
	BL timer_init
	
	 
	LDR v1, =hide_cursor
	BL output_string
	
	LDR v1, =title
	BL output_string
	
	LDR v1, =instructions
	BL output_string
	
	LDR v1, =enter_to_play
	BL output_string
	
	MOV a1, #0		; Init counter to create seed value
	LDR a2, =keystroke
info_loop
	ADD a1, a1, #1
	LDR a3, [a2]	; Check for a keypress (Enter key)
	CMP a3, #'\r'
	BNE info_loop
	
	LDR a2, =seed
	STR a1, [a2]	; Save the seeded value (Comment this out to have constant seed)
	
	MOV a1, #'\f'	;Clear the screen to display the game
	BL output_character

	BL initialize_game
	
	;Start the timers.  Let the games begin!
	LDR a1, =T0TCR
	MOV a2, #1
	STR a2, [a1]

	LDR a1, =T1TCR
	MOV a2, #1
	STR a2, [a1]
	
	LDR v1, =game_title
	BL output_string
	
game_loop	
	LDR a1, =refresh_timer_fired		; Reset the refresh timer flag
	MOV a2, #0
	STR a2, [a1]

	LDR a1, =game_over					; Check for game over condition
	LDR v1, [a1]
	CMP v1, #1
	BLEQ draw_game_over
	CMP v1, #1
	BLEQ reset_game	
	CMP v1, #1 
	BEQ end_screen
	
	LDR a1, =is_paused
	LDR a1, [a1]
	CMP a1, #1
	BLEQ pause_game
	
	BL update_game						; Update game logic
	BL draw								; Draw board state
	
	LDR a1, =life_lost_flag				; Check if we lost a life last tick
	LDR a1, [a1]
	CMP a1, #1
	BLEQ initialize_game				; If we did, reset the game state
	
wait
	LDR a1, =refresh_timer_fired
	LDR a1, [a1]
	CMP a1, #1
	BNE wait
	
	B game_loop
	
pause_game
	STMFD sp!, {lr}
	
pause_loop
	LDR a1, =is_paused
	LDR a1, [a1]
	CMP a1, #1
	BEQ pause_loop
	
resume_game
	LDMFD sp!, {lr}
	BX lr
	

end_screen
	MOV a1, #0		; Init counter to create seed value
	LDR a2, =keystroke
end_screen_loop
	ADD a1, a1, #1
	LDR a3, [a2]	; Check for a keypress (Enter key)
	CMP a3, #'\r'
	BNE info_loop
	
	LDR a2, =seed
	STR a1, [a2]	; Save the seeded value (Comment this out to have constant seed)
	
	MOV a1, #'\f'	 ;Clear the screen to display the game
	BL output_character

	BL initialize_game
	B game_loop
	
exit
	LDMFD sp!, {lr, r0-r4}
	BX lr
	
; ---------------------------------------------;
; Interrupt initialization code.               ;
; ---------------------------------------------;
interrupt_init       
	STMFD SP!, {r0-r2, lr}   ; Save registers 

	; Classify sources as IRQ or FIQ
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0xC]
	LDR r2, =0x0070
	ORR r1, r1, r2 ; UART0 FIQ, Timer0 FIQ, Timer1 FIQ
	STR r1, [r0, #0xC]

	; UART0 Interrupt set-up for RX
	LDR r0, =U0IER
	LDR r1, [r0]
	ORR r1, r1, #1  ; Enable Receive Data Available Interrupt
	STR r1, [r0]
	
	; Enable Interrupts
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0x10]
	LDR r2, =0x0070
	ORR r1, r1, r2 ; UART0 Enabled, Timer0 Enabled, Timer1 Enabled
	STR r1, [r0, #0x10]

	; Enable FIQ's, Disable IRQ's
	MRS r0, CPSR
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0

	LDMFD SP!, {r0-r2, lr} ; Restore registers
	BX lr             	   ; Return
		
timer_init
	STMFD SP!, {r0-r3, lr}
	
	LDR r0, =T0MCR			;Init Match register 0
	MOV r1, #3				;Interrupt and Reset on Match Register 0
	STR r1, [r0]
	
	LDR r0, =T0MR0
	LDR r1, =0x46514E		;Set MR0 to .25 second intervals
	;LDR r1, =0x1C2000       ;Set MR0 to 0.1 second intervals
	;LDR r1, =0x1194538		; Set MR0 to 1s intervals
	STR r1, [r0]

	LDR r0, =T1MCR			;Init Match register 0
	MOV r1, #3				;Interrupt and Reset on Match Register 0
	STR r1, [r0]

	LDR r0, =T1MR0
	;LDR r1, =0x46514E		;Set MR0 to .25 second intervals
	;LDR r1, =0x1C2000       ;Set MR0 to 0.1 second intervals
	LDR r1, =0x1194538		; Set MR0 to 1s intervals
	STR r1, [r0]
	
	LDMFD SP!, {r0-r3, lr}
	BX lr

; ---------------------------------------------;
; Interrupt handler code.                      ;
; ---------------------------------------------;
FIQ_Handler
		STMFD SP!, {r0-r12, lr}   ; Save registers 

		LDR r0, =0xE000C008		;Check if FIQ is caused by UART0
		LDR r0, [r0]
		AND r0, #0x0000000F		;Isolate bits 1-3
		CMP r0, #4
		BEQ UART0INT

		LDR r0, =T1IR		;Check if FIQ is caused by Timer1
		LDR r0, [r0]
		AND r0, r0, #1			; Isolate bit 0
		CMP r0, #1
		BEQ TIMER1INT

; ---------------------------------------------;		
; Timer0 interrupt handler.                     ;
; ---------------------------------------------;
		LDR a1, =refresh_timer_fired
		MOV a2, #1
		STR a2, [a1]
		
		LDR a1, =T0IR				; Reset Match Register 0 interrupt flag
	    MOV a2, #1	
		STR a2, [a1]
		
		B FIQ_Exit

; ---------------------------------------------;		
; Timer1 interrupt handler.                     ;
; ---------------------------------------------;
TIMER1INT
		LDR a1, =time_left	 		; Decrement timer by 1
		LDR a2, [a1]
		SUB a2, a2, #1
		STR a2, [a1]
		
		LDR a1, =game_over
		CMP a2, #0					; Did we run out of time?
		MOVEQ a2, #1
		STREQ a2, [a1]				; Set game_over
		
		LDR a1, =T1IR				; Reset Match Register 0 interrupt flag
	    MOV a2, #1	
		STR a2, [a1]
		
		B FIQ_Exit

; ---------------------------------------------;
; UART interrupt handler.                      ;
; ---------------------------------------------;
UART0INT
		LDR r0, =keystroke
		LDR r1, =U0BASE
		LDR r2, [r1]
		
		STR r2, [r0]			; Store user keystroke.
		
		B FIQ_Exit

; ---------------------------------------------;
; Interrupt handler exit.                      ;
; ---------------------------------------------;		
FIQ_Exit
		LDMFD SP!, {r0-r12, lr}
		SUBS pc, lr, #4

	END
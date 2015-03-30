	AREA interrupts, CODE, READWRITE

	EXPORT lab7
	EXPORT FIQ_Handler

	EXTERN  display_digit
	EXTERN	uart_init
	EXTERN  pin_connect_block_setup
	EXTERN  output_string
	EXTERN  output_character
	EXTERN 	rand
	EXTERN  seed
	EXTERN  print_integer
	EXTERN  set_output_xy
	EXTERN  div_and_mod

U0BASE EQU 0xE000C000	; UART0 Base Address	
U0IER EQU 0xE000C004	; UART0 Interrupt Enable Register
	
T0IR	EQU 0xE0004000	;Timer 0 Interrupt Register
T0TCR	EQU 0xE0004004	;Timer 0 Timer Control Register
T0TC	EQU 0xE0004008	;Timer 0 Timer Count
T0MCR	EQU 0xE0004014	;Timer 0 Match Control Register
T0MR0	EQU 0xE0004018	;Timer 0 Match Register 0
T0MR	EQU 0xE0004018	;Timer 0 Match Register 0


	ALIGN

timer_fired DCD 0x00000000
move_direction DCD 0x00000000
	
    ALIGN

score_message = "SCORE: ",0

	ALIGN
		
lab7	 	
	STMFD sp!, {lr, r0-r4}

	;One time init
	BL pin_connect_block_setup		;Set up IO
	BL uart_init
	BL interrupt_init
	BL timer_init

	;Set up variables

wait_begin				;Wait until an input is received to begin the game
	LDR a1, =move_direction
	LDR a1, [a1]
	CMP a1, #'\n'
	BNE wait_begin

	;Start the timer.  Let the games begin!
	LDR a1, =T0TCR
	MOV a2, #1
	STR a2, [a1]	

	;Main Loop
	;Loop continuously
	

interrupt_init       
	STMFD SP!, {r0-r2, lr}   ; Save registers 

	; Classify sources as IRQ or FIQ
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0xC]
	LDR r2, =0x0050
	ORR r1, r1, r2 ; UART0 FIQ, Timer0 FIQ
	STR r1, [r0, #0xC]

	; UART0 Interrupt setup for RX
	LDR r0, =U0IER
	LDR r1, [r0]
	ORR r1, r1, #1  ; Enable Receive Data Available Interrupt
	STR r1, [r0]
	
	; Enable Interrupts
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0x10]
	LDR r2, =0x0050
	ORR r1, r1, r2 ; UART0 Enabled, Timer0 Enabled
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
	STR r1, [r0]
	
	LDMFD SP!, {r0-r3, lr}
	BX lr
	
generate_frame
	;Pass X position in v3
	;Pass Y position in v2
	;Pass score in v4
	STMFD SP!, {a1-v4, lr}
	
	MOV a1, #'\f'	;Clear page to begin next frame
	BL output_character
	
	LDR v1, =score_message	;Print the score message above the board
	BL output_string
	
	MOV a1, v4				;Print score
	BL print_integer
	
	LDR v1, =board			;Print board to screen
	BL output_string
	
	;print * to screen using at proper location
	MOV a1, v2
	MOV a2, v3
	BL set_output_xy
	MOV a1, #'*'
	BL output_character

	LDMFD SP!, {a1-v4, lr}
	BX lr


FIQ_Handler
		STMFD SP!, {r0-r12, lr}   ; Save registers 

		LDR r0, =0xE000C008		;Check if FIQ is caused by UART0
		LDR r0, [r0]
		AND r0, #0x0000000F		;Isolate bits 1-3
		CMP r0, #4
		BEQ UART0INT
		
		;FIQ not caused by UART0, handle Timer0 interrupt
		LDR r0, =timer_fired		;Set timer_fired to 1
		MOV r1, #1
		STR r1, [r0]
		LDR r0, =T0IR				;Reset Match Register 0 interrupt flag
	    MOV r1, #1	
		STR r1, [r0]
		B FIQ_Exit

UART0INT
		LDR r0, =move_direction
		LDR r1, =U0BASE
		LDR r2, [r1]
		
		CMP r2, #'i'
		BEQ move_dir_valid
		CMP r2, #'j'
		BEQ move_dir_valid
		CMP r2, #'k'
		BEQ move_dir_valid
		CMP r2, #'m'
		BEQ move_dir_valid
		
		B FIQ_Exit
		
move_dir_valid		
		STR r2, [r0]	

FIQ_Exit
		LDMFD SP!, {r0-r12, lr}
		SUBS pc, lr, #4

	END
	AREA interrupts, CODE, READWRITE

	EXPORT lab7
	EXPORT FIQ_Handler

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
	EXTERN set_output_xy

U0BASE  EQU 0xE000C000	; UART0 Base Address	
U0IER   EQU 0xE000C004	; UART0 Interrupt Enable Register
	
T0IR	EQU 0xE0004000	; Timer 0 Interrupt Register
T0TCR	EQU 0xE0004004	; Timer 0 Timer Control Register
T0TC	EQU 0xE0004008	; Timer 0 Timer Count
T0MCR	EQU 0xE0004014	; Timer 0 Match Control Register
T0MR0	EQU 0xE0004018	; Timer 0 Match Register 0
T0MR	EQU 0xE0004018	; Timer 0 Match Register 0
	
refresh_timer_fired DCD 0x00000000
		
lab7	 	
	STMFD sp!, {lr, r0-r4}

	; Initialize interrupt and peripherals.
	BL pin_connect_block_setup
	BL uart_init
	BL interrupt_init
	BL timer_init
	
	BL initialize_game
	
game_loop	
	BL update_game
	BL draw

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
	LDR r2, =0x0050
	ORR r1, r1, r2 ; UART0 FIQ, Timer0 FIQ
	STR r1, [r0, #0xC]

	; UART0 Interrupt set-up for RX
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
	LDR r1, =0x2328A7		;Set MR0 to .125 second intervals
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

; ---------------------------------------------;		
; Timer interrupt handler.                     ;
; ---------------------------------------------;
		LDR a1, =refresh_timer_fired
		MOV a2, #1
		STR a2, [a1]
		
		LDR a1, =T0IR				; Reset Match Register 0 interrupt flag
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
	AREA	lib, CODE, READWRITE	
	EXPORT 	string_to_int
	EXPORT	output_string
	EXPORT	read_string
	EXPORT	output_character
	EXPORT	read_character
	EXPORT	leds
	EXPORT	uart_init
	EXPORT  pin_connect_block_setup
	EXPORT  display_digit
	EXPORT  rgb_led
	EXPORT  read_push_btns
	EXPORT  rand
	EXPORT  seed
	EXPORT  div_and_mod
	EXPORT  set_cursor_pos
	EXPORT  print_integer


U0BASE EQU 0xE000C000	; UART0 Base Address
U0LSR EQU 0x14			; UART0 Line Status Register
U0DLA EQU 0x0C			; UART0 Divisor Latch Access
U0DLL EQU 0x00			; UART0 Divisor Latch Lower
U0DLU EQU 0x04			; UART0 Divisor Latch Upper
U0IER EQU 0xE000C004	; UART0 Interrupt Enable Register

PINSEL0 EQU 0xE002C000   ; Port 0 Pin Connect Block 0.
PINSEL1 EQU 0xE002C004   ; Port 0 Pin Conenct Block 1.
PINSEL2 EQU 0xE002C014   ; Port 1 Pin Connect Block

IO0PIN EQU 0xE0028000	 ; GPIO port 0 pin value register.
IO0SET EQU 0xE0028004    ; GPIO port 0 output set register.
IO0DIR EQU 0xE0028008    ; GPIO port 0 direction control register.
IO0CLR EQU 0xE002800C    ; GPIO port 0 output clear register.

IO1PIN EQU 0xE0028010	 ; GPIO port 1 pin value register.
IO1SET EQU 0xE0028014    ; GPIO port 1 output set register.
IO1DIR EQU 0xE0028018    ; GPIO port 1 direction control register.
IO1CLR EQU 0xE002801C    ; GPIO port 1 output clear register.

seed 		DCD  0xFC3BECED	; Seed value X_n. Updated with the next number in the pseudo 
							; random sequence each time the rand routine is called.
	
digits_SET	
	DCD 0x00001F80  ; 0
	DCD 0x00000300  ; 1 
	DCD 0x00002D80  ; 2
	DCD 0x00002780  ; 3
	DCD 0x00003300  ; 4
	DCD 0x00003680  ; 5
	DCD 0x00003E80  ; 6
	DCD 0x00000380  ; 7
	DCD 0x00003F80  ; 8
	DCD 0x00003780  ; 9
	DCD 0x00003B80  ; A
	DCD 0x00003E00  ; B
	DCD 0x00001C80  ; C
	DCD 0x00002F00  ; D
	DCD 0x00003C80  ; E
	DCD 0x00003880  ; F

	ALIGN

;---------STRING TO INT-----------
;String address is stored in r4
;Resulting int is stored in r6
string_to_int
	STMFD SP!,{lr}	
	MOV r5, r4						;Initalize string read address to string base address
	MOV r6, #0						;Initalize result register to 0
	MOV r7, #0						;Initalize intermidiate register to 0
string_to_int_loop
	LDRB r7, [r5], #+1				;Load character from string to intermidiate reg, increment pointer to next char
	CMP r7, #0						;Compare value to char Null (0)
	BEQ string_to_int_end			;If Null, we have parsed entire string
	CMP r7, #48						;Compare value to char '0' (48)
	BLT string_to_int_loop			;Skip this char if less than char '0' (Non-numeric)
	SUB r7, r7, #48					;Subtract 48 to get actual numeric value from ascii value
	MOV r6, r6, LSL #3				;Shift r6 left 3 (Multiply by 8)
	ADD r6, r6, LSR #2				;Add r6 shifted right 2 to itself (Add r6/4 to itself)(Net result: (r6*8) + (r6*8/2) = r6*10)
	ADD r6, r6, r7					;Add new number to result register
	B string_to_int_loop			;Start loop over
string_to_int_end
	LDMFD SP!,{lr}
	BX lr

;---------OUTPUT STRING---------
;Output the null terminated string pointed to by r4
output_string
	STMFD SP!,{lr, r0, r4}	;Store lr, r0, r4 on stack

output_string_loop
	LDRB r0, [r4], #+1		;Load character from pointer, increment pointer
	CMP r0, #0				;Compare loaded char to NULL
	BEQ output_string_end	;If char is NULL, entire string has been read
	BL output_character		;Output character to UART0
	B output_string_loop

output_string_end
	LDMFD SP!,{lr, r0, r4}	;restore lr, r0, r4
	BX lr


;----------READ STRING------------
;Read user input until carriage return(ENTER) is received
;Input is stored as a null terminated string at address pointed to by r4
read_string
	STMFD SP!,{lr, r4}			; Save memory address pointing to input

read_string_loop
	BL read_character		; Char is returned in to r0
	BL output_character		; Echo char
	
	CMP r0, #13				; Was the character a CR? If so store a null 
	BEQ read_string_exit 	; Otherwise store the character and loop.
	
	STRB r0, [r4], #1		; Store character then increment memory address
	
	B read_string_loop
	
read_string_exit
	MOV r0, #0				; Store NULL then increment memory address
	STRB r0, [r4], #1		
	
	LDMFD SP!,{lr, r4}			; Restore memory address pointing to input. Needed
								; so string_to_int knows where to look.
	BX lr


;--------READ CHARACTER---------
; wait for character to be read on UART0
; input is stored in r0
;
; When data is ready to be transmitted, it should be written to the register 
; located at memory address 0xE000C000
;
; The status register is polled at memory location 0xE000C014 until bit 5 the 
; Transmitter Holding Register (THRE) is 1, indicating that data is ready to be 
; sent.

read_character
	STMFD SP!,{lr, r1, r2}			;Save link register

	LDR r1, =U0BASE			;r1 stores UART0 base address
check_loop_read
	LDRB r2, [r1, #U0LSR]	;r2 contains Line Status Register
	AND r2, r2, #1			;Isolate data ready bit (bit 1)
	CMP r2, #0				;Check bit status	
	BEQ check_loop_read		;If data ready == 0, check again
	LDRB r0, [r1]			;If data ready != 0, read character (located in base address)
	
	LDMFD SP!,{lr, r1, r2}			;Restore link register
	BX lr					;Branch back to previous routine


; ---------OUTPUT CHARACTER-----------
; Character stored in r0 is written to UART0
;
; When data is ready to be transmitted,
; it should be written to the register 
; located at memory address 0xE000C000
;
; The status register is polled at memory
; location 0xE000C014 until bit 5 the 
; Transmitter Holding Register (THRE) is
; 1, indicating that data is ready to be 
; sent.
output_character
	STMFD SP!,{lr, r0-r2}
check_loop_write
	; Fetch status register
	LDR r1, =0xE000C014
	LDRB r1, [r1] 
	
	; Shift THRE bit 5 into bit position 0
	AND r1, #32
	
	; Check if THRE indicates device is ready for transmission
	CMP r1, #0
	BEQ check_loop_write
	
	; Store byte in transmit register
	LDR r2, =0xE000C000
	STRB r0, [r2]
	
	LDMFD sp!, {lr, r0-r2}
	BX lr

;---------LEDS---------------
;The 4 LEDs on the board are set according to the 4 bit value in r0
leds
	STMFD SP!,{lr, r0, r1, r2}
	MOV r1, #0

	AND r2, r0, #1			;Reverse the bits so they display properly on the board
	ADD r1, r1, r2
	MOV r0, r0, LSR #1
	MOV r1, r1, LSL #1
	AND r2, r0, #1
	ADD r1, r1, r2			
	MOV r0, r0, LSR #1
	MOV r1, r1, LSL #1
	AND r2, r0, #1
	ADD r1, r1, r2			
	MOV r0, r0, LSR #1
	MOV r1, r1, LSL #1
	AND r2, r0, #1
	ADD r1, r1, r2			
	
	MVN r1, r1, LSL #16		;Invert the bits because the LEDs are active low
	
	LDR r0, =IO1CLR			;Clear the leds
	LDR r2, =0xFFFFFFFF
	STR r2, [r0]
	  
	LDR r0, =IO1SET			;Set the leds on if they are ones
	STR r1, [r0]

	LDMFD SP!,{lr, r0, r1, r2}
	BX lr


;-------DISPLAY DIGIT------------------------
;Displays the hex digit passed in r0 on the 7-segment display
display_digit
	STMFD SP!,{lr, r0, r1, r2}
	LDR r1, =digits_SET			;load the base address for the lookup table
	MOV r0, r0, LSL #2			;Multiply lookup index by 4 to load 4 byte wide values
	LDR r2, [r1, r0]			;load the value from base address + digit
	LDR r1, =IO0CLR				;Clear the display
	MOV r0, #0x00003F80
	STR r0, [r1]
	LDR r1, =IO0SET				;Set the display
	STR r2, [r1]				
	LDMFD SP!,{lr, r0, r1, r2}
	BX lr

;---------RGB LED----------------------
rgb_led
	STMFD sp!, {r0, r1, r4, lr}
	
check_red
	CMP r0, #0 ; Is the argument 0 (red)?
	BNE check_green 
	BL set_led_off ; Reset RGB LED.
	BL set_led_red 
	B done
	
check_green
	CMP r0, #1	 ; Is the argument 1 (green)?
	BNE check_blue 
	BL set_led_off ; Reset RGB LED.
	BL set_led_green 
	B done
	
check_blue
	CMP r0, #2 ; Is the argument 2 (blue)?
	BNE check_purple
	BL set_led_off ; Reset RGB LED.
	BL set_led_blue
	B done

check_purple
	CMP r0, #3 ; Is the argument 3 (purple)?
	BNE check_yellow
	BL set_led_off ; Reset RGB LED.
	BL set_led_purple
	; (branching to label 'done' completed in subroutine.)
	
check_yellow
	CMP r0, #4 ; Is the argument 4 (yellow)?
	BNE check_white
	BL set_led_off ; Reset RGB LED.
	BL set_led_yellow
	; (branching to label 'done' completed in subroutine.)
	
check_white
	CMP r0, #5 ; Is the argument 5 (white)?
	BNE check_off
	BL set_led_off ; Reset RGB LED.
	BL set_led_white
	; (branching to label 'done' completed in subroutine.)
	
check_off
	CMP r0, #6 ; Is the argument 6 (off)?
	BNE done ; Well, the user didn't give valid input! Exit with no change.
	BL set_led_off ; Turn off RGB LED.
	B done
	
set_led_red
	; Clear port 0, pin 17 (turn on red LED)
	LDR r0, =IO0CLR
	LDR r1, [r0]
	LDR r2, =0x20000
	ORR r1, r1, r2
	STR r1, [r0]

	BX lr
	
set_led_blue
	; Clear port 0, pin 18 (turn on blue LED)
	LDR r0, =IO0CLR
	LDR r1, [r0]
	LDR r2, =0x40000
	ORR r1, r1, r2
	STR r1, [r0]

	BX lr
	
set_led_green
	; Clear port 0 pin 21 (turn on green LED)
	LDR r0, =IO0CLR
	LDR r1, [r0]
	LDR r2, =0x200000
	ORR r1, r1, r2
	STR r1, [r0]

	BX lr
	
set_led_purple
	BL set_led_red
	BL set_led_blue
	B done
	
set_led_yellow
	BL set_led_red
	BL set_led_green
	B done
	
set_led_white
	BL set_led_red
	BL set_led_green
	BL set_led_blue
	B done
	
set_led_off
	; Set port 0, pin 17, 18, 21 (turns off all colors)
	LDR r0, =IO0SET
	LDR r1, [r0]
	LDR r2, =0x260000
	ORR r1, r1, r2
	STR r1, [r0]
	BX lr
	
done
	; Add branch to main menu here...
	LDMFD sp!, {r0, r1, r4, lr}
	BX lr


;----------READ PUSH BUTTONS---------------
read_push_btns
	STMFD sp!, {r1, r2, r3, r4, lr}
					   
	LDR r0, =IO1PIN
	LDR r1, [r0]
	
	; Now, isolate bits 20-23, where 23 is LSB and 20 is MSB
	LDR r2, =0xFF0FFFFF
	BIC r1, r1, r2 ; Clear all bits except for 20-23.
	LSR r1, r1, #20 ; Shift bits 20-23 into lowest position
	;MOV r1, r1, ROR #3 ; Reverse 4 bit string by rotating right 3. 
	;LSR r1, r1, #28 ; Shift top 4 MSB bits in to lowest position.

	MOV r3, #0
	AND r2, r1, #1			;Reverse the bits so they read properly from the board
	ADD r3, r3, r2
	MOV r1, r1, LSR #1
	MOV r3, r3, LSL #1
	AND r2, r1, #1
	ADD r3, r3, r2			
	MOV r1, r1, LSR #1
	MOV r3, r3, LSL #1
	AND r2, r1, #1
	ADD r3, r3, r2			
	MOV r1, r1, LSR #1
	MOV r3, r3, LSL #1
	AND r2, r1, #1
	ADD r3, r3, r2
	
	MVN r0, r3				;Invert bits because buttons are pulled low when pressed			
	AND r0, r0, #0xF		;Mask off upper bits
	
	LDMFD sp!,{r1, r2, r3, r4, lr}
	BX lr
	
; -----------------------------------------------------------------------------------;
; rand is a linear congruence generator which returns a pseudo-random 32bit number   ;
; in register r0. 																     ;
;                                                                                    ;
; For more info, see: http://en.wikipedia.org/wiki/Linear_congruential_generator	 ;													 	 ;
;------------------------------------------------------------------------------------;																					 ;
; DESCRIPTION                                                                        ;
; The next number returned X_{n+1} is determined by the formula X_{n+1}=(aX_n+c)mod  ; 
; m, where X_n is the current seed loaded from memory. The values of a, c, and m     ;
; have been carefully chosen to provide sufficient randomness for this lab. However, ;
; an inital seed value must be generated first before using this routine.			 ;
;																					 ;
; For example, with an initial seed of 5, the sequence X={2,A,A,6,7,E,C,9,6,7,C,C,   ;
; 9,2,4,5,F,1,4,0 8,8,0,B,A,0,0,8,F,6,F,F,5,A,D,A,E,...}, which produces a decently  ;
; random sequence that is sufficient for this lab assignment.						 ;
; -----------------------------------------------------------------------------------;
rand
	STMFD sp!, {r1-r5, lr}
	
	; ---------------------------------------------;
	; Load current seed value from memory to r0.   ;
	; ---------------------------------------------;
	LDR r0, =seed
	LDR r0, [r0]

	; ---------------------------------------------;
	; Initialize offset, multiplier, and mod value ;
	; The offset goes in r1, multiplier in r2, and ;
	; the mod value in r3.						   ;
	; ---------------------------------------------;
	LDR r1, =0x3619		; c = 13,849
	LDR r2, =0x6255		; a = 25,173
	LDR r3, =0x10000	; m = 2^16
	
	; ---------------------------------------------;
	; Generate next number in pseudo-random        ;
 	; sequence, where X_{n+1}=(aX_n+c)mod m.	   ;
	; ---------------------------------------------;	
	MUL r4, r0, r2			; (tmp = a * X_n)
	ADD r4, r4, r1			; (tmp = tmp + c)
	
	SUB r5, r3, #1			; Modulo rule: (X % 2^n) == X & (2^n - 1). 
	AND r4, r4, r5			; This effectively takes the mod using 2^16. 
							; No going through div_and_mod required. Boom.
							
	; Evaluation of X{n+1} complete, result stored in r4. Next, store new seed
    ; back in memory and then shift to get a single hex digit.
	
	LDR r0, =seed			; Store new seed back into memory. Used for
	STR r4, [r0]			; calculating the next number in the sequence.
	
	MOV r0, r4
							
	LDMFD sp!, {r1-r5, lr}
	
	BX lr

;------------------------DIV AND MOD---------------------
;Dividend passed in r0
;Divisor passed in r1
;Quotient returned in r0
;Remainder returned in r1
div_and_mod
	STMFD r13!, {r2-r12, r14}
			  
	; The dividend is passed in r0 and the divisor in r1.
	; The quotient is returned in r0 and the remainder in r1.
	
    ;Normalize inputs and determine output sign
    MOV r5, #0				;Initialize r5 to 0 (Keeps track of negative numbers)
	
	CMP r0, #0				;Is dividend negative?
	RSBLT r0, r0, #0		;0 - dividend if negative
	ADDLT r5, r5, #1		;Add 1 to r5 if negative
	
	CMP r1, #0				;Is divisor negative?
	RSBLT r1, r1, #0		;0 - divisor if negative
	ADDLT r5, r5, #1		;Add 1 to r5 if negative
    
    ;Initalize registers for division loop
	MOV r2, #16				;Initialize Counter (r2) to 16
	MOV r3, #0				;Initalize Quotient (r3) to 0
	MOV r1, r1, LSL #16		;Shift Divisor 16 places
	MOV r4, r0				;Initalize Remainder(r4) to Dividend(r0)

    ;Begin division loop
DIVLOOP
	SUB r4, r4, r1			;Remainder = Remainder - Divisor
	CMP r4, #0				;Compare Remainder to 0
	BLT REMMOD				;Remainder modification if less than 0 (Branch to REMMOD)
	MOV r3, r3, LSL #1		;Shift Quotient left 1
	ORR r3, r3, #1			;Set Quotient LSB to 1
	B   REMDONE				;Branch to end of split
REMMOD
	ADD r4, r4, r1			;Add divisor back to remainder
	MOV r3, r3, LSL #1		;Shift Quotient left 1
REMDONE
	MOV r1, r1, LSR #1		;Shift Divisor right 1
    
    ;Determine if loop should be exited
	CMP r2, #0				;Compare Counter (r2) to 0
	BLE DIVEND 				;Branch out of loop if Counter <= 0
	SUB r2, r2, #1			;Decrement Counter (r2)
	B 	DIVLOOP				;Loop back to start of algorithm
	
    ;Move results to proper registers
    ;and apply proper sign
DIVEND
	MOV r0, r3				;Copy Quotient to r0
	MOV r1, r4				;Copy Remainder to r1
	CMP r5, #1				;Is r5 equal to  1? (Only one of the inputs was negative)
	RSBEQ r0, #0			;If so, answer should be negative
	
	LDMFD r13!, {r2-r12, r14}
	BX lr      ; Return to the caller
	
	
;-------------------SET CURSOR POS------------------	
;Sets the cursor location in the terminal
;a2 is Y location
;a1 is X location
set_cursor_pos
	STMFD SP!, {a1-a4, lr}

	MOV a3, a2			;Save x and y locations
	MOV a4, a1
	; ESC[r;cH    where r is row number and c is column number
	;0x1B is char ESC
	MOV a1, #0x1B
	BL output_character
	MOV a1, #'['
	BL output_character
	MOV a1, a3
	BL print_integer
	MOV a1, #';'
	BL output_character
	MOV a1, a4
	BL print_integer
	MOV a1, #'H'
	BL output_character

	LDMFD SP!, {a1-a4, lr}
	BX lr


;----------------------PIN CONNECT BLOCK SETUP---------------------------
pin_connect_block_setup
    STMFD sp!, {r0, r1, r2, lr}

    ; ---------------------------------------------;
    ; Setup port 0 for GPIO. Pins 7-13 outbound    ;
    ; for 7 segment, pins 17, 18, 21 outbound for  ;
    ; RGB LED.                                        ;
    ; ---------------------------------------------;
    LDR r0, =PINSEL0
    LDR r1, [r0]
    LDR r2, =0x00000000 ; 0b00001111111111111100000000000000b
    MOV r1,  r2 ; Set up port 0 pins 7-13 for 7 segment.
    STR r1, [r0]

    LDR r0, =IO0DIR
    LDR r2, =0xFFFFFFFF ; 0b00000000001001100011111110000000
    MOV r1, r2 ; Set ports 7-13, 17, 18, 21 to outbound.
    STR r1, [r0]

    LDR r0, =PINSEL1
    LDR r1, [r0]
    LDR r2, =0x00000000 ; 0b00000000000000000000110000111100
    MOV r1, r2 ; Set up port 0 pins 17, 18, 21.
    STR r1, [r0]

    ; ---------------------------------------------;
    ; Setup port 1 for GPIO. Pins 16-19 outbound   ;
    ; for LED array, pins 20-23 inbound for push   ;
    ; buttons.                                       ;
    ; ---------------------------------------------;
    LDR r0, =PINSEL2
    LDR r1, [r0]
    LDR r2, =0x8 ; 0b00000000000000000000000000001000
    BIC r1, r1, r2 ; Set up port 1 pins 16-25.
    STR r1, [r0]

    LDR r0, =IO1DIR
    LDR r2, =0x000F0000 ; 0b00000000000111100000000000000000
    MOV r1, r2 ; Set ports 16-18 outbound, 20-23 inbound.
    STR r1, [r0]

	LDR r0, =IO0SET
	MOV r2, #0x264000 ;Set P0.14 High
	STR r2, [r0]

    LDR r0, =IO1SET
	MOV r2, #0xF0000 ;Set P1.14 High
	STR r2, [r0]



	LDMFD SP!,{r0, r1, r2, lr}
	BX lr

;---------PRINT INTEGER-----------
;Integer is passed in a1
;The integer is printed out to console
print_integer
	STMFD SP!,{lr, a1-a4}
	MOV a3, #0         ; counter = 0
	
calculate_ascii
	MOV a2, #10
	BL div_and_mod     ; a1 / 10
	
	ADD a4, a2, #48    ; ascii_code = remainder + 42
	
	ADD a3, a3, #1     ; counter += 1
	
	CMP a1, #0         ; Is the quotient equal to zero?
	BEQ print_ascii
	
	STMFD SP!, {a4}          ; Push ascii_code to the stack.
	
	B calculate_ascii
	
print_ascii
	SUB a3, a3, #1      ; counter -= 1
	
	MOV a1, a4          ; Pass ascii_code to output_character.
	BL output_character
	
	CMP a3, #0          ; Does counter = 0?
	BEQ stop_print_integer  
	
	LDMFD SP!, {a4}            ; Pop ascii_code off the stack.
	B print_ascii       ; Print the (popped) ascii_code.
	
stop_print_integer
	LDMFD SP!,{lr, a1-a4}
	BX lr               ; Return to caller.


;---------UART INIT----------
; Sets up UART0 for 9600 baud
uart_init
	STMFD sp!, {r0, r1, lr}

	BL pin_connect_block_setup_for_uart0

	;/* 8-bit word length, 1 stop bit, no parity,  */
	;/* Disable break control                      */
	;/* Enable divisor latch access                */
	LDR r0, =U0BASE  ; Uart 0 setup
	MOV r1, #131
	STRB r1, [r0, #U0DLA]	;Divisor latch access = 131
	MOV r1, #8
	STRB r1, [r0, #U0DLL]	;Divisor latch lower = 10
	MOV r1, #0
	STRB r1, [r0, #U0DLU]	;Divisor latch upper = 0
	MOV r1, #3
	STRB r1, [r0, #U0DLA]	;Divisor latch access = 3
	LDMFD sp!, {r0, r1, lr}
	BX lr

;-----------PIN CONNECT BLOCK SETUP FOR UART0------------
pin_connect_block_setup_for_uart0
	STMFD sp!, {r0, r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA
	STR r1, [r0]
	LDMFD sp!, {r0, r1, lr}
	BX lr

	END
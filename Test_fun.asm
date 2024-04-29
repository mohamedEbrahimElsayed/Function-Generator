ORG 00H

KEYPAD EQU P3 
RO1 BIT P3.7 
RO2 BIT P3.6
RO3 BIT P3.5
RO4 BIT P3.4
C4 BIT P3.0
C3 BIT P3.1
C2 BIT P3.2
C1 BIT P3.3
;configure port 3,most 4 bits are output to rows least 4 bits are inputs of cloumns
LCD_PORT EQU P1
OSC BIT P2.4
RS BIT P2.1
E BIT P2.2
MOV P0,#0
;initilize input and outputs
MOV P1, #00H
CLR RS
CLR E
CLR OSC
MOV KEYPAD, #0FH
INITIAL:
ACALL LCD_INIT 

MOV DPTR,#FREQ_RANGE_MESG
LCALL MESG_DESPLAY
MAIN:
ACALL SELECTION_MSG
ACALL READ_FREQ
ANL A,#0FH 
MOV 10H,A 
ACALL FREQUANCY
ACALL READ_FREQ             ;READ FIRST DIGIT FREQUANCY [2 KHZ --> 10 KHZ]
CHECK:CJNE A,#30H,CHECK1           ;CHECK IF WRITE NUM OR OPERATION
MOV 22H,#0
RETURN1:
ACALL CLEAR_COMAND
ACALL LCD_DATA                   ;SHOW FRIST OPERAND DIGIT 1
ACALL DELAY
ANL A,#0FH             ;CONVERT FROM ASCII TO DECIMAL
MOV R3,A                ;STORE 1ST DIGIT IN R3

ACALL READ_FREQ             ;READ DIGIT 2
CJNE A,#30H,CHECK2
MOV 23H,#0
RETURN2:
ACALL CLEAR_COMAND

CJNE A,#'=',CONT
LJMP ONE
CONT:
ACALL LCD_DATA                 ;SHOW DIGIT 2
ACALL DELAY
ANL A,#0FH             ;CONVERT FROM ASCII TO DECIMAL
MOV R4,A                    ;SAVE 2ND DIGIT IN R4

ACALL READ_FREQ               ;READ DIGIT 3
CJNE A,#30H,CHECK3
MOV 24H,#0
RETURN3:
ACALL CLEAR_COMAND
CJNE A,#'=',CONT2
LJMP TWO
CONT2:
ACALL LCD_DATA
ACALL DELAY
ANL A,#0FH             ;CONVERT FROM ASCII TO DECIMAL
MOV R5,A                 ;SAVE 3RD DIGIT IN R5

ACALL READ_FREQ              ;READ '='
CJNE A,#'=',OVER1          ;IF NOT EQUAL DISPLAY TOO MUCH           
RESULT:
MOV A,22H
CJNE A,#0,ERROR
MOV A,23H
CJNE A,#0,ERROR
MOV A,24H
CJNE A,#0,ERROR
SKIP:
LCALL KHZ
ACALL FREQ
ACALL INITIAL_VALUE

;part 4

GO2:
MOV A,R0
CJNE A,#1,GO3              ;IF 2ND BIT IN DUTY NOT EQUAL 0 OR 5        
LJMP ERROR
GO3:

ACALL OUTPUT

OVER1:LJMP OVER

CHECK1:
MOV 22H,#0
JNC RETURN1
MOV 22H,#5           ;IF WRITE */-+ 
LJMP RETURN1
CHECK2:
MOV 23H,#0
JNC RETURN2
MOV 23H,#5
LJMP RETURN2
CHECK3:
MOV 24H,#0
JNC RETURN3
MOV 24H,#5
LJMP RETURN3
ONE:
MOV A,R3
MOV R5,A
MOV R3,#0
MOV R4,#0
LJMP RESULT

TWO:
MOV A,R4
MOV R5,A
MOV A,R3
MOV R4,A
MOV R3,#0
LJMP RESULT

ERROR:
ACALL LCD_CLEAR
ACALL DELAY
MOV DPTR,#ERROR_MESG
B3:CLR A
MOVC A,@ A + DPTR
JZ NEW_VALUE
ACALL LCD_DATA
ACALL DELAY
INC DPTR
SJMP B3
 
 
OVER:
ACALL LCD_CLEAR
ACALL DELAY
MOV DPTR,#OVERFLOW
B1:CLR A
MOVC A,@ A + DPTR
JZ NEW_VALUE
ACALL LCD_DATA
ACALL DELAY
INC DPTR
SJMP B1

KHZ:
MOV DPTR,#MSG2
LCALL MESG_DESPLAY
RET 
NEW_VALUE:              ;TO ADD NEW VALUE
ACALL READ_FREQ            ;READ FIRST DIGIT FREQUANCY [2 KHZ --> 250 KHZ]
MOV R3,A
ACALL LCD_CLEAR  
ACALL DELAY
ACALL FREQUANCY
MOV A,R3
LJMP CHECK

;part 2

FREQ:               ;CONVERT DIGITS TO DECIMAL
	MOV B,#100
	MOV A,R3         ;GET 1ST DIGIT 
	MUL AB               ;IF OVER FLOW WILL BE VALUE IN B  
	MOV R6,A
	MOV A,B
	CJNE A,#0,OVER            ;IF NOT EQUAL DISPLAT "TOO MUCH"
	MOV A,R4          ;GET 2ND DIGIT   
	MOV B,#10
	MUL AB
	CLR C
	ADD A,R6
	JC OVER
	ADD A,R5
	MOV R6,A          ;SAVE FREQ IN DECIMAL IN R6
RET

INITIAL_VALUE:
	MOV A,R6            ;GET DECIMAL FREQ
	MOV B,A
	MOV A,#250
	DIV AB
	MOV 21H,B           
	MOV B,#2
	MUL AB
	MOV R0,A 
	MOV A,21H
	MOV B,#2
	MUL AB             ;MUL REMINDER IN 2 --> IN THE EQUATION
	MOV B,R6
	DIV AB             ;DIV RESULT INTO 2ND OPERAND --> FREQ
	ADD A,R0 
	CPL A
	ADD A,#4
	MOV R3,A           ;SAVE INITIAL VALUE IN R3
RET

OUTPUT:
MOV A,10H
CJNE A,#1,NXT1
MOV TMOD,#00000010B
MOV A,R3            ;GET INITIAL VALUE
MOV TH0,A
SQUARE_LOOP:
MOV P0,#255               ;MAKE WAVE HIGH

SETB TR0                  ;START TIMER
HERE1:JNB TF0,HERE1         ;POLLING
CLR TR0                   ;STOP TIMER
CLR TF0

MOV P0,#0                         ;MAKE WAVE LOW

SETB TR0
HERE2:JNB TF0,HERE2
CLR TR0
CLR TF0

SJMP SQUARE_LOOP

NXT1:
CJNE A,#2,SINE_LOOP
MOV B,R6
MOV A,#0
SAWTOOTH_LOOP:
ADD A,B
MOV P0,A 
SJMP SAWTOOTH_LOOP

SINE_LOOP:
CJNE A,#3,INVALID_MESG
MOV A,R6
MOV R0,A 
MOV R5,#10
LABLES:
MOV B,R5
CJNE A,B,LABLE

MOV B,R6
MOV A,#120
DIV AB
MOV R2,A
MOV 9H,A 
SINE_TEST:
MOV R2,9H  
MOV DPTR,#4000
LOOP:
MOV A,R7
MOVC A,@ A+DPTR
MOV P0,A 
INC DPTR 
DJNZ R2,LOOP 
SJMP SINE_TEST
LABLE:
MOV B,R5
MOV A,#120
DIV AB
ADD A,R7
MOV R7,A 
MOV A,R6 
DEC R5
SJMP LABLES

INVALID_MESG:
LCALL LCD_CLEAR
MOV DPTR,#ERROR_MESG
LCALL MESG_DESPLAY
LCALL READ_FREQ
LJMP MAIN 

;part one
RET
SINE_DIS:
	B7:CLR A
	MOVC A,@ A + DPTR
	MOV P0,A 
	INC DPTR
	DJNZ R0,B7
RET
;part 3 

FREQUANCY:
ACALL LCD_CLEAR
MOV DPTR,#MSG8
LCALL MESG_DESPLAY
RET

SELECTION_MSG:
ACALL LCD_CLEAR
MOV DPTR,#SQUARE
LCALL MESG_DESPLAY
	ACALL Delay
	ACALL Delay
	ACALL Delay
	ACALL Delay
	;TO KEEP THE SELECTION ON THE SCREEN 

	ACALL LCD_CLEAR
	MOV DPTR,#SAWTOOTH
	LCALL MESG_DESPLAY

	ACALL Delay
	ACALL Delay
	ACALL Delay
	ACALL Delay

	ACALL LCD_CLEAR
	MOV DPTR,#SINE
	LCALL MESG_DESPLAY

	ACALL Delay
	ACALL Delay
	ACALL Delay
	ACALL Delay

	ACALL LCD_CLEAR
	MOV DPTR,#SELECTED
	LCALL MESG_DESPLAY

RET



CLEAR_COMAND:
		CJNE A,#'c',CONT1
		ACALL LCD_CLEAR
		LJMP MAIN
CONT1:
RET


READ_FREQ:
	K1: 
		CLR RO1            ;Ground all columns at first
		CLR RO2 
		CLR RO3
		CLR RO4

		MOV A, KEYPAD                   ; Read keypad inputs
		ANL A, #0FH                    ;mask left 4 bits, check only right left bits
		CJNE A,#00001111B,K2         ;if any zero at any column so there is a press
			
	;if A equal 0000 1111 so no press, REPEAT AGAIN 
	Sjmp K1
	;if it is a press,make sure this press is real,, debouncing 
		K2: 
			ACALL Delay
			;repeat check again
			MOV A, KEYPAD              ;Read keypad inputs
			ANL A, #0FH
			CJNE A, #00001111B, check_row            ;if any zero at least 4 bits, a key is pressed
			;go to check which row ?
			;not a real press, go again 
	SJMP K1

	check_row: 
	CLR RO1            ;check first row
	SETB RO2
	SETB RO3
	SETB RO4

	MOV A, KEYPAD               ;READ VALUE ON PORT
	CJNE A,#01111111B, ROW_1      ;if there is a zero on any of the column, there is a press in rowl
	;if not scan second row
	SETB RO1           ; check second row
	CLR RO2
	SETB RO3
	SETB RO4
	MOV A, KEYPAD         ;READ VALUE ON PORT
	CJNE A, #10111111B, ROW_2             ;if there is a zero on any of the column, there is a press in rowl 
	;if not scan third row
	SETB RO1            ; check third row
	SETB RO2
	CLR RO3
	SETB RO4

	MOV A, KEYPAD            ;READ VALUE ON PORT
	CJNE A, #11011111B, ROW_3        ;if there is a zero on any of the column ,there is a press in rowl
	;if not scan fourth row
	SETB RO1
	SETB RO2          ; check fourth row
	SETB RO3
	CLR RO4
	MOV A, KEYPAD              ;READ VALUE ON PORT
	CJNE A,#11101111B, ROW_4          ;if there is a zero on any of the column, there is a press in rowl
	;if not repeat again
	LJMP K1

	ROW_1: MOV DPTR,#ROW1            ;access memory at this row but which column
			SJMP FIND
	ROW_2: MOV DPTR,#ROW2 
			SJMP FIND
	ROW_3: MOV DPTR,#ROW3 
			SJMP FIND
	ROW_4: MOV DPTR,#ROW4 
			SJMP FIND
			
	FIND: MOV R7,#4             ; check which bit is zero
	AGAIN: RRC A
	JNC MATCH                 ;if lsb is zero so it is in first column
	INC DPTR                  ;if not increment next location
	SJMP AGAIN

	MATCH: CLR A
	MOVC A,@ A+DPTR             ; key read now in accumlator
	RET

	Delay: MOV R7, #255
	LL:MOV R6, #255
	LL2:DJNZ R6, LL2
	DJNZ R7,LL
RET




 
;LCD CODE


LCD_INIT: 
	MOV A, #38h
	ACALL LCD_COMM 
	ACALL DELAY 
	MOV A, #0EH
	ACALL LCD_COMM 
	ACALL DELAY

	MOV A, #01
	ACALL LCD_COMM
	ACALL DELAY 
RET





LCD_CLEAR:
    MOV A, #01
    ACALL LCD_COMM
    ACALL DELAY
RET  

	;clear the screen
	LCD_COMM: MOV LCD_PORT, A       ;write command to D0-D7
	CLR RS
	SETB E                    ;RS=0 for sending commands give a pulse of enable to LCD
	NOP
	NOP
	NOP
	CLR E
RET

LCD_DATA:
	MOV LCD_PORT, A
	SETB RS
	SETB E
	NOP
	NOP
	NOP
	NOP
	CLR E
RET

MESG_DESPLAY:
	CONT_DIS:CLR A
		MOVC A,@ A + DPTR
		JZ STOP_DIS
		ACALL LCD_DATA
		ACALL DELAY
		INC DPTR
		SJMP CONT_DIS 
		STOP_DIS:
RET 

                    ;Delay subroutine

ORG 300H
	ROW1:DB '-', '3', '2','1' 
	ROW2:DB '*', '6', '5','4' 
	ROW3:DB '/', '9', '8','7'
	ROW4:DB '+', '=', '0','c'
			
		
			
ORG 400H
	OVERFLOW:DB " TOO MUCH",0
	MSG2:DB " KHZ",0
	ERROR_MESG:DB "INVALID",0
	FREQ_RANGE_MESG:DB "2KHZ TO 10KHZ",0
	MSG8:DB "FREQ=",0
	SQUARE:DB "1-SQUARE",0
	SAWTOOTH:DB"2-SAWTOOTH",0
	SINE:DB"3-SINE",0
	SELECTED:DB "SELECTED= ",0 
ORG 4000
    SINE_10K: DB 128, 191, 238, 255, 238, 191, 128, 64, 17, 0, 17, 64
ORG 4012
    SINE_9K:DB 128, 187, 232, 254, 247, 212, 158, 97, 43, 8, 1, 23, 68
ORG 4025
    SINE_8K:DB 128, 179, 222, 249, 254, 238, 202, 154, 101, 53, 17, 1, 6, 33, 76
ORG 4040
    SINE_7K: DB 128, 174, 213, 242, 254, 250, 229, 195, 151, 104, 60, 26, 5, 1, 13, 42, 81
ORG 4057
    SINE_6K:DB 128, 167, 202, 231, 249, 255, 249, 231, 202, 167, 128, 88, 53, 24, 6, 0, 6, 24, 53, 88
ORG 4077
    SINE_5K:DB 128, 160, 191, 218, 238, 251, 255, 251, 238, 218, 191, 160, 128, 95, 64, 37, 17, 4, 0, 4, 17, 37, 64, 95
ORG 4101  
	SINE_4K: DB 128, 154, 179, 202, 222, 238, 249, 254, 254, 249, 238, 222, 202, 179, 154, 128, 101, 76, 53, 33, 17, 6, 1, 1, 6, 17, 33, 53, 76, 101
ORG 4131
	SINE_3K:DB 128, 147, 167, 185, 202, 218, 231, 241, 249, 253, 255, 253, 249, 241, 231, 218, 202, 185, 167, 147, 128, 108, 88, 70, 53, 37, 24, 14, 6, 2, 0, 2, 6, 14, 24, 37, 53, 70, 88, 108
ORG 4171
	SINE_2K:DB 128, 141, 154, 167, 179, 191, 202, 213, 222, 231, 238, 244, 249, 252, 254, 255, 254, 252, 249, 244, 238, 231, 222, 213, 202, 191, 179, 167, 154, 141, 128, 114, 101, 88, 76, 64, 53, 42, 33, 24, 17, 11, 6, 3, 1, 0, 1, 3, 6, 11, 17, 24, 33, 42, 53, 64, 76, 88, 101, 114
	

END 

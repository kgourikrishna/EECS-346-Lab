;Lab 4
;Gourikrishna - 2017_05_14


; Include definitions of standard 8051 registers, bits, etc.
$MOD51



; Layout internal data area
DSEG	AT	20h



; Internal variables 
min:	DS	1
sec:	DS	1
timercount: DS   1
segmentarray: DS 3
timearray: DS 4
keypresscount: DS 1
column1: DS 1
column2: DS 1
column3: DS 1
keyvalue: DS 1
adcarray: DS 4
channelnumber: DS 1



;set up stk area for call and interrupt functions
stkarea:	DS	32





; Lay out external data memory
XSEG	AT	8000h

RTCsc:		DS	1
RTCscal: 	DS	1
RTCmn:		DS	1
RTCmnal: 	DS	1
RTChr:		DS	1
RTChral: 	DS	1
RTCday:		DS	1
RTCdate: 	DS	1
RTCmon:		DS	1
RTCyr:	 	DS	1
RTCa:		DS	1
RTCb: 		DS	1
RTCc:		DS	1
RTCd: 		DS	1





; Code space
CSEG	AT	0

start:	ljmp	init	; Jump around interrupt handlers



; Interrupt handlers

CSEG	AT	0003h
; External 0
	reti		;end of external 0 interrupt handler


CSEG	AT	000bh
;Timer 0 interrupt function
	ajmp	t0int		;jump to timer 0 interrupt function


CSEG	AT	0013h
;External 1 - should never happen.
	reti		;end of external 1 interrupt handler


CSEG	AT	001bh
;Timer 1 - should never happen
	reti		;end of timer 1 interrupt handler


CSEG	AT	0023h
;Serial
	clr		TI
	clr		RI
	reti		;end of serial interrupt handler






CSEG	AT	40h
; Main body of code.

; Initializations.
init:
    mov	sp, #stkarea	;set up stack area
    
    MOV    DPTR,#RTCa       
    MOV A,#00100000b     
    MOVX  @DPTR,A    

    mov DPTR, #RTCb
    mov A, #00000100b
    movx @DPTR,A
    
;Initialize variables
	mov timercount, #0
    mov keypresscount, #0
    mov keyvalue, #0
    mov channelnumber, #0
    

; Set up timers.
	mov	TL0,#0			    ;Timer 0 init to 0
	mov	TH0,#0

    mov	TMOD,#00000001b		;Timer 0 in 8-bit auto reload mode
                            ;internal clock mode
	mov	TCON,#00010000b		    ;timer 0 running



;Set up interrupt system only after all else is set up
	mov	ie,#10000010b		; timer0 interrupt

loop:
    acall readadc
    acall read	
    
    mov r0,#timearray	      
    mov a,sec
    acall convert
    mov a, min 
    acall convert
    
    acall keyboardread
    
    mov r0, #adcarray
    
    mov a, #0
    CJNE a, keyvalue, adc1
    mov a, @r0
    acall convertadc
    jmp display
    
    adc1:
    mov a, #1
    CJNE a, keyvalue, adc2
    inc r0
    mov a, @r0
    acall convertadc
    jmp display
    
    adc2:
    mov a, #2
    CJNE a, keyvalue, adc3
    inc r0
    inc r0
    mov a, @r0
    acall convertadc
    jmp display
    
    adc3:
    mov a, #3
    CJNE a, keyvalue, time
    inc r0
    inc r0
    inc r0
    mov a, @r0
    acall convertadc
    jmp display

time:
    acall transfer
 
;movekeypress:
;   mov r0, #segmentarray
;    inc r0
;    inc r0
;    mov @r0, keypresscount
;    jmp cont
    
;offcheck:  
;    CJNE a, #0, increment
;    mov keyvalue, #0
;    jmp movekeypress

;increment:
;    mov keyvalue, a
;    inc keypresscount
;    mov a, keypresscount
;    CJNE a,#10, movekeypress
;    mov keypresscount,#0
;    jmp movekeypress

;cont:
    ;acall transfer
display:
    acall dsp
	
loop1:
	sjmp	loop



; Timer 0 overflow interrupt handler
t0int:
    push    acc
    push    PSW
    inc     timercount
    mov     a,timercount
	CJNE    a,#3,continue
    mov     timercount,#0
    pop     PSW
    pop     acc
    reti

continue:
    pop PSW
    pop acc
    reti

	
	; Display function
dsp:	
	mov A, #segmentarray
	add A, timercount
    
	mov r0, A
	mov A, @r0
    mov r3,A
    
	mov a,#0
	CJNE  a,timercount,case1
    mov a, r3
	orl a,#01000000b
	jmp next
    
    case1:
        mov a,#1
        CJNE  a,timercount, case2
        mov a, r3
		orl a,#00100000b
		jmp next
    
    case2:
        mov a, r3
		orl a, #00010000b
		jmp next

	next:
        mov P1, A
		anl P3, #11001111b
		orl P3, #00110000b
		ret
            
convert:
    mov b, #10
    div ab
    mov @r0, b
    inc r0
    mov @r0, a
    inc r0
    ret


read:
    mov DPTR, #RTCsc
    movx a, @DPTR
    mov sec,a
    
    mov DPTR, #RTCmn
    movx, a, @DPTR
    mov min, a
    ret
    
    
transfer:
    mov r0,#timearray
    mov a, @r0
    mov r0, #segmentarray
    mov @r0,a
    
    mov a,#timearray
    add a,#1
    mov r0,a
    mov b, @r0
    mov a, #segmentarray
    add a, #1
    mov r0,a
    mov @r0,b
    
    mov a,#timearray
    add a,#2
    mov r0,a
    mov b, @r0
    mov a, #segmentarray
    add a, #2
    mov r0,a
    mov @r0,b
  
    ret
    
keyboardread:
   mov b, #0
   acall column1read
   mov column1, a
   acall column2read
   mov column2, a
   acall column3read
   mov column3, a
   jmp check

reset1:
    mov column1,a
    mov b,#0
    jmp check

reset2:
    mov column2, a
    mov b, #0
    jmp check
    
reset3:
    mov column3, a
    mov b, #0
    jmp check

check:   
   acall column1read
   CJNE a,column1,reset1
   acall column2read
   CJNE a, column2, reset2
   acall column3read
   CJNE a,column3, reset3
   inc b
   mov a,b
   CJNE a, #10, check
   jmp proceed
   
column1read:
   mov P1, #00000100b
   anl P3, #11101111b
   orl P3, #00010000b
   
   mov P1, #11111111b
   
   anl P3, #11011111b
   mov a, P1
   orl P3, #00100000b
   
   ret
   
column2read:
   mov P1, #00000010b
   anl P3, #11101111b
   orl P3, #00010000b
   
   mov P1, #11111111b

   anl P3, #11011111b
   mov a, P1
   orl P3, #00100000b
   
   ret
   
column3read:
   mov P1, #00000001b
   anl P3, #11101111b
   orl P3, #00010000b
   
   mov P1, #11111111b
   
   anl P3, #11011111b
   mov a, P1
   orl P3, #00100000b
   
   ret
   
proceed:   
     
   mov a, column1
   CJNE a,#10001111b, four
   mov keyvalue,#1
;   mov r0, #segmentarray
;   mov @r0, #1
;   inc r0
;   mov @r0, #0
   ret

four:
    mov a,column1
    CJNE a,#10010111b, seven
    mov keyvalue, #4
;    mov r0, #segmentarray
;    mov @r0, #4
;    inc r0
;    mov @r0, #0
    ret

seven:
    mov a,column1
    CJNE a, #10100111b, ten
    mov keyvalue, #7
;    mov r0, #segmentarray
;    mov @r0, #7
;    inc r0
;    mov @r0, #0
    ret

ten:
    mov a,column1
    CJNE a, #11000111b, two
    mov keyvalue, #10
;    mov r0, #segmentarray
;    mov @r0, #0
;    inc r0
;    mov @r0, #1
    ret

two:
    mov a,column2
    CJNE a,#10001111b, five
    mov keyvalue, #2
;    mov r0, #segmentarray
;    mov @r0, #2
;    inc r0
;    mov @r0, #0
    ret
   
five:
    mov a,column2
    CJNE a,#10010111b, eight
    mov keyvalue, #5
;    mov r0, #segmentarray
;    mov @r0, #5
;    inc r0
;    mov @r0, #0
    ret

eight:
    mov a,column2
    CJNE a,#10100111b, zero
    mov keyvalue, #8
;    mov r0, #segmentarray
;    mov @r0, #8
;    inc r0
;    mov @r0, #0
    ret

zero:
    mov a,column2
    CJNE a,#11000111b, three
    mov, keyvalue, #0
;    mov r0, #segmentarray
;    mov @r0, #0
;    inc r0
;    mov @r0, #0
    ret
    
three:
    mov a,column3
    CJNE a, #10001111b, six
    mov keyvalue, #3
;    mov r0, #segmentarray
;    mov @r0, #3
;    inc r0
;    mov @r0, #0
    ret

six:
    mov a,column3
    CJNE a, #10010111b, nine
    mov keyvalue, #6
;    mov r0, #segmentarray
;    mov @r0, #6
;    inc r0
;    mov @r0, #0
    ret

nine:
    mov a, column3
    CJNE a, #10100111b, eleven
    mov keyvalue, #9
;    mov r0, #segmentarray
;    mov @r0, #9
;    inc r0
;    mov @r0, #0
    ret

eleven:
    mov column3, a
    CJNE a, #11000111b, done
    mov keyvalue, #11
;    mov r0, #segmentarray
;    mov @r0, #1
;    inc r0
;    mov @r0, #1
    ret

done:
    ret
    
wait:
    nop
    nop
    nop
    nop
    nop
    ret
    
iicstart:
    anl P3, #11110111b
    acall wait
    anl P3, #11111011b
    acall wait
    ret

iicstop:
    anl P3, #11110111b
    acall wait
    orl P3, #00000100b
    acall wait
    orl P3, #00001000b
    acall wait
    ret
    
writeiic:

mov r4, #8

loop1check:
mov b, a
mov a,r4
CJNE a,#0,loopone
jmp finishtransfer

loopone:
    mov a,b
    anl a, #10000000b
    CJNE a,#10000000b, SDAlow
    orl P3, #00001000b
    jmp loop1continue
    
    SDAlow:
       anl P3, #11110111b
       
    loop1continue:
       orl P3, #00000100b
       acall wait
       anl P3, #11111011b
       orl P3, #00001000b

       acall wait
       mov a, b
       rl a
       mov b, a
       dec r4
       jmp loop1check

finishtransfer:
    mov a, b
    orl P3, #00000100b 
    acall wait
    anl P3, #11111011b
    acall wait
    ret

readiic:
    mov a, #0
    orl P3, #00001000b
    mov r4, #8
    
    loop2check:
    mov b, a
    mov a,r4
    CJNE a,#0,loop2
    jmp loop2finish

    loop2:
        orl P3, #00000100b
        acall wait
        mov a, b
        rl a
        mov b, a
        ;mov a, P3
        ;anl a,#00001000b
        jnb P3.3, donothing
        ;CJNE a,#00001000b, donothing
        ;mov a,b
        orl a,#00000001b
        
        donothing:
            anl P3, #11111011b
            acall wait
            mov b, a
            dec r4
            jmp loop2check
            
    loop2finish:
        mov a, r3
        CJNE a, #1, SDAhigh
        anl P3, #11110111b
        jmp loop2continue
        
        SDAhigh:
            orl P3, #00001000b
        
        loop2continue:        
            orl P3, #00000100b
            acall wait
            anl P3, #11111011b
            orl P3, #00001000b
            acall wait
            mov a, b
            ret
            

getadc:
    mov r2, channelnumber
    acall iicstart
    mov a, #90h
    acall writeiic
    mov a, r2
    anl a, #00000011b
    acall writeiic
    acall iicstop
    
    acall iicstart
    mov a, #91h
    acall writeiic
    mov r3, #1
    acall readiic
    mov r3, #0
    acall readiic
    acall iicstop
    ret
    
convertadc:
    mov r0, #segmentarray
    mov b, #10
    div ab
    mov @r0, b
    inc r0
    mov b, #10
    div ab
    mov @r0, b
    inc r0
    mov @r0, a
    ret

readadc:
    mov channelnumber, #0
    mov r0, #adcarray
    acall getadc
    mov @r0, a
    inc r0
    mov channelnumber, #1
    acall getadc
    mov @r0, a
    inc r0
    mov channelnumber, #2
    acall getadc
    mov @r0, a
    inc r0
    mov channelnumber, #3
    acall getadc
    mov @r0, a
    ret
    
	end	start
;
; Motor Speed Control Example Program
; Author: Tom Almy
; Date:   May 22, 2007
; Copyright 2007, Tom Almy. Permission given to copy for use
; in Wytec Dragon12-plus board.

; Function:
; The user enters the desired speed and direction using the keypad.
; 0 through 9 set the speed (stop to full speed). The * button sets
; forward direction and the # button sets reverse direction. The lower
; right button on the keypad turns the driver off.

; In the DC motor version, the motor connects between the MOT1 and MOT2 terminals.
; In the (bipolar) stepper motor version, one winding connects between the MOT1 and MOT2
; terminals while the second winding connects between the MOT3 and MOT4 terminals.
; For the stepper motor, this code will by default give a step rate of 10 to 90 steps/second.

; The board must be configured for the desired motor power voltage and source. 

; Implementation:
; An RTI interrupt at roughly 1mSec rate does the keypad polling and LCD display driving.
; This code is taken from the keypad and frequency meter examples in the Designing with
; Microcontrollers textbook. The subroutine getkey reads the keypad value and blocks if no
; key is available. There is a single byte buffer for the keypad value. The LCD display driver
; is interrupt driven so that the timing delays won't interfere with the control of the motors.
; The subroutines lcd_line1 and lcd_line2 position the cursor at the start of the first and
; second lines, respectively, while msg_out displays the 0-byte terminated character string
; passed to it in X, and putlcd displays the character passed to it in A. These functions will
; block only if the 32 byte buffer is filled, so typically an entire message can be queued for
; display without blocking.

; The main routine ("idle process") reads the key presses, saves the command in variables running, 
; reverse, and speed, then updates the LCD display by writing a new status message.

; In the DC motor version, a PWM channel is used to control the speed. Since the PWM generates a
; continuous pulse train without program intervention, the main routine has additional code to
; set the direction (by changing the H-Bridge inputs) and speed (by changing the pulse width).

; In the stepper motor version, a timer channel interrupt is used to advance the H-Bridge through the
; four phases. The LED row display shows the values for the driver enables (bits 7 and 6) and
; the motor drives (bits 3 to 0).

;DC_MOTOR 	equ 1          	; Define for DC motor version
STEPPER_MOTOR 	equ 1   	; Define for Stepper motor version

;RTI_DIVIDER	equ	$13     ; use this for 4 MHz crystal, RTI divider is 4096, about 1 mSec
RTI_DIVIDER	equ	$17     ; use this for 8 MHz crystal, RTI divider is 8192, about 1 mSec

#include        registers.inc   ; include register equates

        org     DATASTART
; Variables for motor control
running:        ds      1       ; 1 -- motor on, 0 -- motor off
reverse:        ds      1       ; 1 -- forward, 0 -- reverse
speed:          ds      1       ; 0 to 9 for speed

; Variables and equates for motor interface
EN12:           equ     %00000001  ; Port P Enable MOT1,2
EN34:           equ     %00000010  ; Port P Enable MOT3,4
MOT1:           equ     %00000001  ; Port B MOT1
MOT2:           equ     %00000010  ; Port B MOT2
MOT3:           equ     %00000100  ; Port B MOT3
MOT4:           equ     %00001000  ; PORT B MOT4
#ifdef STEPPER_MOTOR
phase:          ds      1       ; phase value, 0,1,2, or 3
fraction:       ds      2       ; fraction of time until phase change
#endif

; Equates and Variables for LCD interface
REG_SEL:        equ     %00000001       ; 0=reg, 1=data (LCD)
ENABLE:         equ     %00000010
LCDBUFLEN:      equ     32              ; Size of LCD output buffer
lcdbuf:         ds   LCDBUFLEN  ; LCD output buffer
lcdbufin:       ds   2          ; Pointer to buffer input
lcdbufout:      ds   2          ; pointer to buffer output
lcdstate:       ds   2          ; LCD state machine state
lcddelay:       ds   1          ; LCD state machine delay counter

; Variables for keyboard interface
keybuf:         ds      1
temp:           ds      1
tempcnt:        ds      1
lastval:        ds      1
debcnt:         ds      1

        org     PRSTART
;
; Start of program -- Initialization
;
start:  
        ; Initialize stack pointer
        lds     #DATAEND

        ; Initialize motor contol
        clr     running
        clr     reverse
        clr     speed

        ; Initialize motor interface
        clr     PTP     ; make sure motor interface is disabled
        bset    DDRP #EN12+EN34
        bset    DDRJ #2         ; Enable LEDs for pretty display
        clr     PTJ
#ifdef STEPPER_MOTOR
        clr     PORTB
        bset    DDRB #MOT1+MOT2+MOT3+MOT4+$c0 ; last for pretty display
        bset    TIOS #1         ; We will use timer channel 0
        bset    TSCR1 #$90      ; TEN=1, TFFCA=1
        bset    TIE #1          ; C0I=1
        movw    #TC0ISR UserTimerCh0    ; Initialize vector
        clr     phase
        movw    #0 fraction

#endif
#ifdef DC_MOTOR
        bset    DDRB #MOT1+MOT2
        movb    #MOT1 PORTB     ; Initialize to forward direction
        ; Initialize PWM channel 0
        ; we want PWM clock period to be 50us/9
        ; to run at 20kHz so we can't hear the motor windings
        ; This means a divisor of 133.
        movb    #66 PWMSCLA     ; use clock SA
        bset    PWME #$01       ; PWME0=1
        bset    PWMPOL #$01     ; PPOL0=1
        bset    PWMCLK #$01     ; PCLK0=1
        movb    #9 PWMPER0
;       movb    #0 PWMDTY0      ; duty cycle = 0%
#endif
        ; Initilize LCD driver data RAM
        movw    #lcdbuf lcdbufin
        movw    #lcdbuf lcdbufout
        movw    #LCDCLEARDELAY lcdstate   ; 15 msec delay before using LCD
        movb    #14 lcddelay              ; gives 15 msec delay (one more than value)

        ; Initialize microcontroller interface to LCD
        movb    #$ff,DDRK       ; port K = output
        clr     PORTK

        ; Initialize RTI
        movw    #rtiisr,UserRTI ; initialize the RTI vector
        movb    #RTI_DIVIDER,RTICTL   ; RTI divider for 1 mSec
        bset    CRGINT,#$80     ; enable RTI interrupts

        ; Initialize microcontroller interface to keypad
        movb    #$0f,ddra       ; pa0 to pa3 are outputs while 4 to 7 are inputs
        bset    PUCR #1         ; enable pullup for keypad

        ; Initialize keypad variables
        movb    #(-1)&$ff,keybuf      ; no key
        ldaa    #$f7            ; template for msb of output being low
        staa    porta
        staa    temp            ; save it
        staa    lastval
        movb    #3,tempcnt      ; counter
        movb    #10,debcnt      ; poll every 10mSec for good debouncing

        ; Enable Interrupts and initialize LCD display hardware
        cli
        jsr     lcd_ini
        jmp     help            ; start with HELP
;
; Idle Process -- read and process keystrokes
;
loop:   jsr     getkey          ; Check out a keystroke
        cmpa    #9              ; 0 - 9 are numeric
        bhi     not_numeric
        staa    speed           ; save speed value
        movb    #1,running
        bra     lcd_update
not_numeric:
        cmpa    #$1f            ; * key is forward
        bne     not_forward
        clr     speed           ; Don't change direction if running
        clr     reverse         ; set direction to forward
        movb    #1,running
        bra     lcd_update
not_forward:
        cmpa    #$11            ; # key is backwards
        bne     not_backwards
        clr     speed           ; don't change direction if running
        movb    #1,reverse      ; set direction to reverse
        movb    #1,running
        bra     lcd_update
not_backwards:
        cmpa    #$d             ; lower right key is motor off
        bne     help            ; other keys not used -- go to help
        clr     running         ; clear everything when off
        clr     speed
        clr     reverse
        
        ; update the LCD display
lcd_update:
        jsr     lcd_line1
        tst     running         ; are we off?
        bne     we_are_running
        ldx     #omsg
        jsr     msg_out
        bra     finish_LCD
we_are_running:
        tst     reverse         ; Are we in reverse?
        bne     we_are_backing
        ldx     #fmsg
        jsr     msg_out
        bra     we_are_moving
we_are_backing:
        ldx     #bmsg
        jsr     msg_out
we_are_moving:
        ldaa    speed           ; Display speed value
        adda    #'0             ; convert to ASCII character
        jsr     putlcd
        ldaa    #' 
        jsr     putlcd
finish_LCD:

#ifdef DC_MOTOR
        ; update the DC Motor driver settings
        ldaa    #MOT1           ; forward
        tst     reverse
        beq     not_reverse
        ldaa    #MOT2           ; reverse
not_reverse:
        staa    PORTB
        movb    speed PWMDTY0   ; If we aren't running, speed is 0
#endif

        jmp     loop

; Display instructions
help:   jsr     lcd_line1
        ldx     #imsg
        jsr     msg_out
help2:  jsr     lcd_line2
        ldx     #ins1
        jsr     msg_out
        jsr     long_delay
        tst     keybuf                  ; finish if key hit
        bge     help3
        jsr     lcd_line2
        ldx     #ins2
        jsr     msg_out
        jsr     long_delay
        tst     keybuf                  ; finish if key hit
        bge     help3
        jsr     lcd_line2
        ldx     #ins3
        jsr     msg_out
        jsr     long_delay
        tst     keybuf                  ; finish if key hit
        bge     help3
        jsr     lcd_line2
        ldx     #ins4
        jsr     msg_out
        jsr     long_delay
help3:  jsr     lcd_line2               ; last line tells how to get help
        ldx     #ins5
        jsr     msg_out
        jsr     long_delay
        tst     keybuf                  ; key hit?
        blt     help2
        jsr     lcd_line1
        ldx     #insc
        jsr     msg_out
        jmp     lcd_update              ; update display and process key
;
; Subroutines used for keypad and LCD access
;
getkey: ; Get character from keypad and place in accumulator A
        ; If none available, wait.
        ldaa    keybuf
        bge     gotone          ; branch if key available
        wai                     ; wait if not
        bra     getkey          ; then try again
gotone: movb    #-1,keybuf      ; mark buffer as empty
        rts

putlcd: ; Write character in register A to LCD
        pshx
        tfr     d x             ; save A:B in X, X on stack
putlcd2: ldd     lcdbufin       ; calculate # characters in buffer
        subd    lcdbufout
        bpl     putlcd3
        addd    #LCDBUFLEN      ; If negative, adjust (circular arithmetic)
putlcd3: cpd     #LCDBUFLEN-1   ; Is there room?
        bne     putlcd4
        wai                     ; no room -- wait and try again 
        bra     putlcd2
putlcd4: tfr     x d            ; a has character 
        ldx     lcdbufin        ; get bufin again
        staa    1,x+            ; store character, increment buffer position
        cpx     #lcdbuf+LCDBUFLEN ; check for wrap
        bne     putlcd5         ; not needed?
        ldx     #lcdbuf         ; wrap to start
putlcd5: stx    lcdbufin        ; save new bufin value
        pulx
        rts

lcd_line1:      ; Position cursor at start of first line
        ldaa    #$ff                    ; indicate instruction
        bsr     putlcd
        ldaa    #$80                    ; starting address for the line1
        bsr     putlcd
        rts

lcd_line2:    ; position cursor at start of second line
       ldaa    #$ff                    ; indicate instruction
       bsr     putlcd
       ldaa    #$C0                    ; starting address for the line2
       bsr     putlcd
       rts

msg_out: ; Write out 0 terminated string at X to LCD
        ldaa    1,x+
        beq     msg_end
        bsr     putlcd
        bra     msg_out
msg_end: rts

; Initialize the LCD display module. All registers preserved
lcd_ini:
        ldx     #inidsp
        ldab    #6
lcd_ini_loop:
        ldaa    #$ff            ; $ff means following byte is command
        jsr     putlcd
        ldaa    1,X+
        jsr     putlcd
        dbne    b lcd_ini_loop
        rts

; Long Delay
long_delay: ; about two seconds
        pshx
        pshd
        ldx     #0
ld1:    clrb
ld2:    dbne    b,ld2           ; 32 us delay
        tst     keybuf          ; cancel delay if key hit
        bge     ld3
        dbne    x,ld1
ld3:    puld
        pulx
        rts

rtiisr: ; RTI Interrupt Service Routine
        bset    CRGFLG,#$80     ; clear RTI interrupt flag
        cli                     ; allow other interrupts to occur 
        ;first -- handle the keyboard
        dec     debcnt          ; debcnt is counter for debouncing
        bne     lcdgo           ; don't do a thing 9 of 10 times ("low pass filter")
        movb    #10,debcnt
        ldaa    PORTA           ; check keyboard
        cmpa    lastval
        beq     samelast        ; might mean to go to next row
        staa    lastval
        anda    #$f0            ; get only upper bits
        lsra
        lsra
        adda    tempcnt         ; table index
        cmpa    #28             ; values less than 28 are invalid
        blt     lcdgo
        tfr     a,x
        ldaa    valtbl-28,x     ; get value
        bmi     lcdgo           ; no value so do nothing
        staa    keybuf          ; represents next keystroke!
        bra     lcdgo
samelast:       ; if no depression, then go to next row for next interrupt
        anda    #$f0
        cmpa    #$F0            ; any depression?
        bne     lcdgo           ; then do nothing for now
        ldaa    temp
        asra                    ; shift mask
        dec     tempcnt
        bge     nowrap
        movb    #3,tempcnt
        ldaa    #$f7            ; reset mask
nowrap: staa    temp
        staa    lastval
        staa    PORTA

        ; Now handle the LCD driver
lcdgo:
        ldx     lcdstate        ; go to current state
        jmp     0,x

LCDIDLE: ; Wait for next character
        ldx     lcdbufout
        cpx     lcdbufin
        beq     lcdfin
        ldaa    1,x+ 
        cpx     #lcdbuf+LCDBUFLEN
        bne     lcdin2
        ldx     #lcdbuf
lcdin2: stx     lcdbufout
        cmpa    #(-1)&$ff
        beq     iscmd
        psha            ; save temporarily
        anda   #$f0                     ; mask out 4 low bits.           
        lsra
        lsra                            ; 4 MSB bits go to pk2-pk5                              
        bsr     lcdnibble
        pula
        lsla                            ; move low bits over.
        lsla
        bsr     lcdnibble
lcdfin: rti                             ; done with interrupt routine

LCDCLEARDELAY: ; waiting on clear delay
        dec     lcddelay
        bne     lcdfin
        movw    #LCDIDLE lcdstate
        rti

LCDRESETDELAY: ; waiting on reset delay
        dec     lcddelay
        bne     lcdfin
        ldaa    #$0c                    ; reset lower nibble shifted left
        bsr     lcdnibble
        bset    PORTK,#REG_SEL          ; select data
        movw    #LCDIDLE lcdstate
        rti

iscmd:  movw    #LCDCMD lcdstate
;       bra     LCDCMD
LCDCMD:   ; Wait for command
        ldx     lcdbufout
        cpx     lcdbufin
        beq     lcdfin
        ldaa    1,x+ 
        cpx     #lcdbuf+LCDBUFLEN
        bne     lcdcin2
        ldx     #lcdbuf
lcdcin2: stx    lcdbufout
        psha                            ; save the command
        bclr    PORTK,#REG_SEL          ; select instruction
        anda   #$f0                     ; mask out 4 low bits.           
        lsra
        lsra                            ; 4 MSB bits go to pk2-pk5                              
        bsr     lcdnibble
        pula
        cmpa    #$33                    ; Reset requires a 5msec delay
        beq     lcdreset
        psha
        lsla                            ; move low bits over.
        lsla
        bsr     lcdnibble
        bset    PORTK,#REG_SEL  ; select data
        pula
        cmpa    #$03                    ; clear requires 5 msec delay
        bls     lcdclear
        movw    #LCDIDLE lcdstate
        rti
lcdreset: movw #LCDRESETDELAY lcdstate   ; must delay before second part
        movb    #5 lcddelay             ; gives 5 msec delay
        rti
lcdclear: movw #LCDCLEARDELAY lcdstate   ; must delay before next command
        movb    #1 lcddelay             ; gives 2 msec delay (one more than value)
        rti

        ; Subroutine used by LCD driver -- drives the hardware
lcdnibble: ; nibble to send is in a
        psha                            ; save nibble value.
        ldaa   PORTK                    ; get LCD port image.
        anda   #$03                     ; need low 2 bits.
        oraa   1,sp+                    ; add in low 4 bits. 
        staa   PORTK                    ; output data          
        bset    PORTK,#ENABLE   ; ENABLE=high
        nop
        nop                     ; make pulse 250nsec wide
        bclr    PORTK,#ENABLE   ; ENABLE=low
        rts

#ifdef STEPPER_MOTOR
tc0isr: ; 1ms Timer interrupt
        ldd     TC0
        addd    #24000
        std     TC0
        tst     running
        bne     t1
        clr     PTP             ; force drive off
        clr     PORTB
        movw    #0 fraction     ; just in case, clear these
        clr     phase
        rti
t1:     bsr     set_motor       ; set current position
        ldab    speed           ; look up in speed table
        lslb                    ; multiply index by 2
        tfr     b x
        ldd     speed_table,x
        addd    fraction
        std     fraction
        bcc     t2              ; done if no carry
        tst     reverse         ; if reverse, decrement phase
        bne     t3
        inc     phase
t2:     rti
t3:     dec     phase
        bra     t2

set_motor:      ; subroutine to set motor controller to correct phase
        ldab    phase
        andb    #3      ; ignore all but 2 LSBs
        lslb            ; multiply by 2
        tfr     b x
        tst     reverse
        bne     set_motor_reverse
        ldaa    fmotion+1,x ; for display not motor
        clrb
        lsrd
        lsrd
        orab    fmotion,x 
        stab    PORTB
        ldab    fmotion+1,x
        stab    PTP
        rts
set_motor_reverse:
        ldaa    bmotion+1,x
        clrb
        lsrd
        lsrd
        orab    bmotion,x 
        stab    PORTB
        ldab    bmotion+1,x
        stab    PTP
        rts
#endif

; 
; Tables and other constants
;

inidsp: 
        fcb     $33             ; reset (4 nibble sequence)  
        fcb     $32             ; reset 
        fcb     $28             ; 4bit, 2 line, 5X7 dot
        fcb     $06             ; cursor increment, disable display shift
        fcb     $0c             ; display on, cursor off, no blinking
        fcb     $01             ; clear display memory, set cursor to home pos

fmsg:   fcc     /Forward /
        db      0

bmsg:   fcc     /Backward /
        db      0

omsg:   fcc     /OFF       /
        db      0

imsg:   fcc     / *INSTRUCTIONS* /
        db      0
ins1:   fcc     /0-9 for speed   /
        db      0
ins2:   fcc     /* for forward   /
        db      0
ins3:   fcc     /# for backward  /
        db      0
ins4:   fcc     /D for OFF       /
        db      0
ins5:   fcc     /HELP - keypad A /
        db      0
insc:   fcc     /                /
        db      0

valtbl: ; Each table column represents a keyboard scan row, while the table rows represent
        ; the scan values (rows of keys) - only rows 7, 11, 13, and 14 are valid
        ;       (A321)(B654)(C987)(D#0*)
;       db      -1,-1,-1,-1
;       db      -1,-1,-1,-1
;       db      -1,-1,-1,-1
;       db      -1,-1,-1,-1
;       db      -1,-1,-1,-1
;       db      -1,-1,-1,-1
;       db      -1,-1,-1,-1
        db      $1f,0,$11,$d    ; scan value 7  (0111) * 0 # D
        db      -1,-1,-1,-1
        db      -1,-1,-1,-1
        db      -1,-1,-1,-1
        db      7,8,9,$c        ; scan value 11 (1011) 7 8 9 C
        db      -1,-1,-1,-1
        db      4,5,6,$b        ; scan value 13 (1101) 4 5 6 B
        db      1,2,3,$a        ; scan value 14 (1110) 1 2 3 A
        db      -1,-1,-1,-1

#ifdef STEPPER_MOTOR
; The goal in these tables is to move smoothly from one phase to the
; next by only changing the MOT levels while the output is disabled.
; Separate tables are necessary for the different directions to achieve
; this.
fmotion: ; Forward motion table Port B, Port P pairs
        db      MOT1+MOT4,EN12  ; + X
        db      MOT1+MOT3,EN34  ; x +
        db      MOT2+MOT3,EN12  ; - x
        db      MOT2+MOT4,EN34  ; x -
bmotion: ; Backwards motion, same outputs
        db      MOT1+MOT3,EN12  ; + X
        db      MOT2+MOT3,EN34  ; x +
        db      MOT2+MOT4,EN12  ; - x
        db      MOT1+MOT4,EN34  ; x -
; Lookup table of value to add to fraction. We need to get to 65536 to
; move to next phase. Fraction is incremented by this value every millisecond.
speed_table: 
        dw      0       ; setting of 0
        dw      10*65536/1000   ; setting of 1 (10 phases per second)
        dw      20*65536/1000
        dw      30*65536/1000
        dw      40*65536/1000
        dw      50*65536/1000
        dw      60*65536/1000
        dw      70*65536/1000
        dw      80*65536/1000
        dw      90*65536/1000
#endif
        end

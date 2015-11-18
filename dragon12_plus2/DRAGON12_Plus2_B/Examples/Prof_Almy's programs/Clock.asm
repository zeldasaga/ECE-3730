;
; clock -- An alarm clock example
;   Author - Tom Almy
;   Date - February 2003
;
;   NOTE - DIP Switches must be up (open)
;    Switch SW2 -- toggles alarm arming (indicated by right decimal point LED), also
;    stops the alarm (without disarming) if it is sounding. Also used to view alarm
;    time and (when held down) will allow setting the alarm time.
;    Switch SW3 -- Depress and hold while setting the time.
;    Switch SW4 -- In combination with SW2 sets the alarm hour and with SW3 set the time hour
;    Switch SW5 -- In combination with SW2 sets the alarm minute and with SW3 sets the alarm hour
; Setting the time minutes or hours will also reset the internal seconds counter to zero. The
; buttons are debounced and the hour/minute setting have auto-repeat every half second.
; The Left decimal point LED indicates "pm". The center decimal point LEDs flash once per second.
; The right decimal point LED indicates the alarm is armed.
AMPM            equ     0       ; Comment out for a 24 hour clock (no AM/PM indication)
#include        registers.inc   ; include register equates and memory map
;
MULTI_MODE      equ     $10
SINGLE_MODE     equ     0
SCAN_MODE       equ     $20
NO_SCAN_MODE    equ     0
CHANNEL_NUM:    equ     7       ; reading input from AN07

ALARM_SW        equ     %1000   ; Alarm switch (0 if depressed)
TIME_SW         equ     %100    ; Time set switch (0 if depressed)
HOUR_SW         equ     %10     ; Hour switch (0 if depressed)
MINUTE_SW       equ     %1      ; Minute Switch (0 if depressed)


TB1MS:  equ     24000           ; 1ms time base of 24,000 instruction cycles
;                               ; 24,000 x 1/24MHz = 1ms at 24 MHz bus speed

        org     DATASTART
;
select:         rmb     1       ; current digit being displayed
disptn:         rmb     4       ; Normal display digits
dispdp:         rmb     4       ; decimal point display digits
normalpm:       equ     dispdp
flashsec        equ     dispdp+1
flashsec2       equ     dispdp+2
alarmon         equ     dispdp+3
dispta:         rmb     4       ; alarm display digits
dispadp:        rmb     4       ;  decimal point display for alarm
alarmpm:        equ     dispadp
alarmon2:       equ     dispadp+3 
milisecs        rmb     2       ; Millisecond counter (reset every second)
seconds         rmb     1       ; Seconds counter, reset every minute
debounce        rmb     1       ; time for debounce
lastbuttons     rmb     1       ; last button values
repeat          rmb     2       ; repeat time
brtness:        rmb     1
isoff:          rmb     1
buzzing:        rmb     1

;
; Segment conversion table:
;
; Binary number:                0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
; Converted to 7-segment char:  0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
;
; Binary number:                $10,$11,$12,$13,$14,$15,$16,$17
; Converted to 7-segment char:   G   H   h   J   L   n   o   o
;
; Binary number:                $18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$20
; Converted to 7-segment char:   P   r   t   U   u   y   _  --  Blank
;

        org     PRSTART
;
        jmp     start
segm_ptrn:                                              ; segment pattern
        fcb     $3f,$06,$5b,$4f,$66,$6d,$7d,$07         ; 0-7
;                0,  1,  2,  3,  4,  5,  6,  7
        fcb     $7f,$6f,$77,$7c,$39,$5e,$79,$71         ; 8-$0f
;                8,  9,  A,  b,  C,  d,  E,  F
        fcb     $3d,$76,$74,$1e,$38,$54,$63,$5c         ; 10-17
;                G,  H,  h,  J   L   n   o   o
        fcb     $73,$50,$78,$3e,$1c,$6e,$08,$40         ; 18-1f
;                P,  r,  t,  U,  u   Y   -   -
        fcb     $00,$01,$48,$41,$09,$49                 ; 20-23
;               blk, -,  =,  =,  =,  =
;
;
; this routine will read adc input on the pin AN07 and store the result at adr07h
;
;
adc_conv:
        adda    #SINGLE_MODE+NO_SCAN_MODE
;
; if you want to read multi-channel input, change above statement to
;       adda    #MULTI_MODE+NO_SCAN_MODE
;
        staa    ATD0CTL5
not_ready:
        brclr   ATD0STAT $80 not_ready
        rts

start:
        lds     #DATAEND
#ifdef INITIALIZEVECTORS
        movw    #timer5,UserTimerCh5    ; initialize the int vector
        movw    #timer6,UserTimerCh6    ; initialize the int vector
        movw    #timer7,UserTimerCh7    ; initialize the int vector
#endif

        ldaa    #$ff            ; turn off 7-segment display
        staa    PTP             ; portp = 11111111
;
        staa    DDRB            ; portb = output
        staa    DDRP            ; portp = output
        clr     DDRH            ; porth = input

        ldaa    #$80
        staa    TSCR            ; enable timer
        ldaa    #$E0
        staa    TIOS            ; select t5, t6, t7 as an output compares
        staa    TMSK1
        bset    tctl1,#$4       ; t5 in toggle mode
        bset    tctl1,#$8       ; turn off alarm sound

        bset    ATD0CTL2 $80    ; enable adc operation
        bset    ATD0CTL3 $40    ; 8 conversion needed for an07

        clr     isoff
        clr     select
        movb    #$ff,brtness
        ldaa    #$20
        ldx     #disptn         ; flashing 8s on display
        staa    1,x+            ; reset to flashing 8s
        staa    1,x+
        staa    1,x+
        staa    1,x+
        clr     1,x+            ; clear the status decimal points
        clr     1,x+
        clr     1,x+
        clr     1,x+
        ldx     #dispta
        movb    #1,1,x+         ; 12:00 is setting for alarm
        movb    #2,1,x+
        ldaa    #11             ; 0 in alarm minutes and decimal points, milliseconds, seconds
l1:     clr     1,x+
        dbne    a,l1
        movw    #$8080,dispadp+1        ; show static colon in alarm time
        clr     buzzing
        
        cli
;
begin:  ldaa    #CHANNEL_NUM    ; set channel number before calling 
        jsr     adc_conv        
        movb    ADR07H,brtness
        jmp     begin

timer5:
        ; speaker
        bclr    TFLG1,#~$20     ; clear flag
        ldd     #TB1MS*2
        addd    TC5
        std     TC5
        rti

timer6:
        ; Timer 6 keeps display refreshed

        bclr    TFLG1,#~$40     ; clear flag
        com     isoff
        beq     noton
        ldd     #TB1MS          ; reload the count for 1 ms time base
        addd    TC6     
        std     TC6
        cli                     ; allow other interrupts to occur 
        ldab    select
        incb
        andb    #3
        stab    select
        tfr     b,x             ; select value in X
        ldaa    PTP             ; only alter port p bits we are using
        anda    #$f0
        oraa    dspmap,x
        staa    PTP
        brclr   PTH,ALARM_SW,dispalarm  ; display alarm time?
        leax    disptn,x
        bra     dispnorm
dispalarm: leax dispta,x
dispnorm:
        ldaa    0,x
        ldy     #segm_ptrn
        ldaa    a,y             ; get converted value
        oraa    4,x             ; set dp if required
        staa    PORTB
        rti
noton:  clr     PORTB
        ldaa    brtness
        ldab    #$ff
        addd    TC6
        std     TC6
        rti

timer7: 
        ; Timer 7 runs handles the user interface and updates the time
        bclr    TFLG1,#~$80
        ldd     #TB1MS
        addd    TC7
        std     TC7
        cli                     ; allow other interrupts to occur
        ldx     milisecs
        inx                     ; increment miliseconds
        stx     milisecs
        cpx     #500
        beq     halfsec
        cpx     #1000           ; on the second
        bne     noflash         ; no -- handle buttons
secactivity:
        movw    #0,milisecs
        inc     seconds
        ldaa    seconds
        cmpa    #60             ; Update minute display
        bne     halfsec         ; no -- do half second activity
        clr     seconds
        ldx     #disptn
        jsr     incrementM      ; increment minute
        bne     tcheck          ; returns having set CCR on minutes
        jsr     incrementH      ; increment hours
tcheck: jsr     alarmcheck      ; check alarm every minute after correcting time
halfsec: ldx    #disptn
        ldaa    flashsec-disptn,x ; do flashing
        eora    #$80
        staa    flashsec-disptn,x
        staa    flashsec2-disptn,x
        ldaa    disptn          ; check to see if blank or 8
        cmpa    #$20
        beq     flash
        cmpa    #$08
        bne     noflash
flash:  ldab    #4              ; flash the display
flashl: ldaa    0,x
        eora    #$28
        staa    1,x+
        dbne    b,flashl
; handle buttons
noflash: ldaa   PTH             ; get port h (button) value
        cmpa    lastbuttons     ; changed value?
        beq     nochange
        staa    lastbuttons     ; new buttons
        movb    #10,debounce    ; Do something after 10 counts
        movw    #-1,repeat      ; Signify first entry
        rti
nochange: ldab  debounce        ; are we debouncing
        beq     nobounce        ; zero if not
        decb
        stab    debounce        ; wait for debouncing period to be over
        rti
nobounce: anda  #$0f            ; only look at bottom switches
        cmpa    #15-TIME_SW-MINUTE_SW   ; Minute time?
        bne     notmintime
        ldx     repeat
        cpx     #0
        ble     processmintime
        dex
        stx     repeat
        rti
processmintime:
        movw    #500,repeat     ; delay until repeat
        ldx     #disptn
        jsr     powoncheck
        clr     seconds
        movw    #0,milisecs
        jsr     incrementM
        rti
notmintime:
        cmpa    #15-TIME_SW-HOUR_SW     ; Hour time?
        bne     nothourtime
        ldx     repeat
        cpx     #0
        ble     processhourtime
        dex
        stx     repeat
        rti
processhourtime:
        movw    #500,repeat     ; delay until repeat
        ldx     #disptn
        jsr     powoncheck
        clr     seconds
        movw    #0,milisecs
        jsr     incrementH
        rti
nothourtime:
        cmpa    #15-ALARM_SW-MINUTE_SW  ; Minute alarm?
        bne     notminalarm
        ldx     repeat
        cpx     #0
        ble     processminalarm
        dex
        stx     repeat
        rti
processminalarm:
        movw    #500,repeat     ; delay until repeat
        ldx     #dispta
        jsr     incrementM
        rti
notminalarm:
        cmpa    #15-ALARM_SW-HOUR_SW    ; Hour alarm?
        bne     nothouralarm
        ldx     repeat
        cpx     #0
        ble     processhouralarm
        dex
        stx     repeat
        rti
processhouralarm:
        movw    #500,repeat     ; delay until repeat
        ldx     #dispta
        jsr     incrementH
        rti
nothouralarm:
        cmpa    #15-ALARM_SW    ; just the alarm button
        bne     nobutton
        ldx     repeat          ; don't allow repeats
        bge     nobutton
        movw    #0,repeat       ; only one performance
        tst     buzzing         ; is it buzzing?
        bne     killbuzz
        ldaa    alarmon         ; else toggle alarm
        eora    #$80
        staa    alarmon
        staa    alarmon2
        rti
killbuzz:
        jsr     alarmoff
        
nobutton:
        rti

alarmcheck:
        tst     alarmon
        beq     alarmoff        ; if alarm is turned off, make sure sound is off
        ldy     #dispta
        ldaa    1,x+
        cmpa    1,y+
        bne     alarmoff
        ldaa    1,x+
        cmpa    1,y+
        bne     alarmoff
        ldaa    1,x+
        cmpa    1,y+
        bne     alarmoff
#ifdef AMPM
        ldaa    1,x+
        cmpa    1,y+
        bne     alarmoff
#endif
        ldaa    0,x
        cmpa    0,y
        bne     alarmoff
alarmsound:
        bclr    TCTL1,#$8       ; turn on alarm sound
        inc     buzzing
        rts
alarmoff:
        bset    TCTL1,#$8       ; turn off alarm sound
        clr     buzzing
        rts
        
powoncheck:			; Resets time if flashing 8's
        ldaa    0,x
        cmpa    #8
        beq     pon2
        cmpa    #$20
        bne     pon3
pon2:   
#ifdef AMPM
        movw    #1,0,x
#else
        movw    #0,0,x
#endif
        movw    #0,2,x
pon3:   rts

incrementM:			; Increment the minute value
				; X has address of buffer for time display or alarm display
        ldd     2,x             ; get minute value into A:B
        incb
        cmpb    #10
        bne     doneinc
        clrb
        inca
        cmpa    #6
        bne     doneinc
        clra
doneinc: std    2,x		; condition code will be Z=1 if hour to be incremented
        rts

incrementH:			; increment the hour value
				; X has address of buffer for time display or alarm display
        ldd     0,x
        incb
        cmpb    #10
        bne     chk24
        clrb
        inca
chk24:  
#ifdef  AMPM
        cpd     #$0102          ; 12 - toggle AMPM
        bne     not12
        psha
        ldaa    4,x             ; get AMPM indicator
        eora    #$80            ; toggle it
        staa    4,x
        pula
        bra     doneinch
not12:  cpd     #$0103          ; 13 -- make it 1
        bne     doneinch
        ldd     #$1
#else
        cpd     #$0204
        bne     doneinch
        ldd     #0
#endif
doneinch: std   0,x
        rts

dspmap: db      $0e,$0d,$0b,$07

#ifdef STATICVECTORS
        org     UserTimerCh5
        dw      timer5
        org     UserTimerCh6
        dw      timer6
        org     UserTimerCh7
        dw      timer7
#endif
        end

; Ex5.asm  ---- Example program 5 for the DRAGON12-Plus2 Rev. A board
;               (c)2012, EVBplus.com
;     Author: Wayne Chu
;     Date: 4/12/12
;
;     The new Dragon12-Plus2 board added a 3.3V power supply, a Micro SD memory
;     card holder, Bluetooth, Xbee and Nordic nRF24L01+ wireless interfaces.
;     It also provides Arduino Shield Compatible headers and an automatic power
;     switching circuit for selecting power from USB port or external AC
;     adapter.
;
;     Function: This example program is not intended for teaching a user how to
;               write HCS12 code. In fact it was ported from our 68HC11
;               test program, so most instructions were written in 68HC11 code.
;
;               Adjust the trimmer pot VR2 to vary the voltage on
;               AN07 of ADC and to change brightness of the 7 segment
;               LED display
;
MULTI_MODE      equ        $10
SINGLE_MODE     equ        0
SCAN_MODE       equ        $20
NO_SCAN_MODE    equ        0
CHANNEL_NUM:    equ        7        ; reading input from AN07
;        
;
DB6             equ        $40
DIG0:           equ        8        ; PP3
DIG1:           equ        4        ; PP2
DIG2:           equ        2        ; PP1
DIG3:           equ        1        ; PP0

TB1MS:          equ        24000    ; 1ms time base of 24,000 instruction cycles
;                                   ; 24,000 x 1/24MHz = 1ms at 24 MHz bus speed

REGBLK:         equ        $0
#include        reg9s12.h           ; include register equates

                org        $1000
;
select:         rmb        1
d1ms_flag:      rmb        1
disp_data:      rmb        4
disptn:         rmb        4
adctl_image:    rmb        1
brtness:        rmb        1
turn_led_on:    rmb        1

STACK:          equ        $2000
;
; Segment conversion table:
;
; Binary number:                 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
; Converted to 7-segment char:         0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
;
; Binary number:                $10,$11,$12,$13,$14,$15,$16,$17
; Converted to 7-segment char:   G   H   h   J   L   n   o   o
;
; Binary number:                  $18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$20
; Converted to 7-segment char:   P   r   t   U   u   y   _  --  Blank
;
;
;
        org        $2000
        jmp        start

segm_ptrn:                                                ; segment pattern
        fcb     $3f,$06,$5b,$4f,$66,$6d,$7d,$07                ; 0-7
;                 0,  1,  2,  3,  4,  5,  6,  7
        fcb     $7f,$6f,$77,$7c,$39,$5e,$79,$71                ; 8-$0f
;                 8,  9,  A,  b,  C,  d,  E,  F
        fcb     $3d,$76,$74,$1e,$38,$54,$63,$5c                ; 10-17
;                 G,  H,  h,  J   L   n   o   o
        fcb     $73,$50,$78,$3e,$1c,$6e,$08,$40                ; 18-1f
;                 P,  r,  t,  U,  u   Y   -   -
        fcb     $00,$01,$48,$41,$09,$49                        ; 20-23
;                blk, -,  =,  =,  =,  =
;
seven_segment:
        pshx
        pshb
        ldx        #segm_ptrn
        psha
        anda        #$3f
        tab
        abx
        ldaa        0,x                ; get segment
        pulb
        andb        #$80                ; add DP
        aba
        pulb
        pulx
        rts

;
; this routine will read adc input on AN07 and store the result at adr07h
;
;
adc_conv:
        adda        #SINGLE_MODE+NO_SCAN_MODE
;
; if you want to read multi-channel input, change above statement to
;        adda        #MULTI_MODE+NO_SCAN_MODE
;
        staa        adctl_image
        ldx        #REGBLK
        jsr        conv
        rts
;        
conv:   ldaa       adctl_image
        staa       atd0ctl5,x
not_ready:
        brclr      atd0stat,x $80 not_ready
        rts
start:  lds        #STACK
        ldx        #timer6
        stx        $3E62                ; initialize int vetctor

        ldx        #REGBLK
        ldaa       #$ff                 ; turn off 7-segment display
        staa       ddrb,x               ; portb = output
        staa       ddrp,x               ; portp = output

        staa       ddrj,x               ; make port J an output port
        staa       ptj,x                ; make PJ1 high to disable LEDs
        
        ldaa       #$0f                 ; portp = 00001111
        staa       ptp,x           ; turn off 7-segment display and RGB LED

        ldaa       #$80
        staa       tscr,x               ; enable timer
        ldaa       #DB6
        staa       tios,x               ; select t6 as an output compare
        staa       tmsk1,x

        bset       atd0ctl2,x $80       ; enable adc operation
        bset       atd0ctl3,x $40       ; 8 conversion needed for an07
        
        cli
;
begin:  ldaa       #CHANNEL_NUM         ; set channel number before calling
        jsr        adc_conv
        ldaa       adr07h+REGBLK
        staa       brtness
;        
        ldab       #1
        stab       disp_data
        incb
        stab       disp_data+1
        incb
        stab       disp_data+2
        incb
        stab       disp_data+3


        ldx        #disp_data
        jsr        move
        ldaa       #1
        staa       turn_led_on        ; turn_on_led
        jsr        sel_digit

        ldaa       brtness                ; was read from adc
        beq        turn_off        ; if =0, turn off display
 
back:   ldx        #13                ; make approx. 3.25 us delay
;
; approx. 250 ns delay
;
back1:  dex
        inx
        dex                        ; 1 cycles
        bne        back1                ; 3 cycles
        deca
        bne        back

turn_off:
        clr        turn_led_on
        dec        select
        jsr        sel_digit
;
wait:   tst        d1ms_flag
        beq        wait
        clr        d1ms_flag
        jmp        begin
;
;
;    this routine moves 4 bytes of data into display
;    pattern and converts the pattern to seven segment code.
;    @ enter, x points the source address
;
move:   ldy        #disptn
mnext:  ldaa       0,x
        jsr        seven_segment   ; convert Accu A to segment pattern, bit 7= DP
        staa       0,y
        inx
        iny
        cpy        #disptn+4
        bne        mnext
        rts
;
; multiplexing display one digit at a time
;
sel_digit:
        ldx        #REGBLK
        inc        select
        ldab        select
        andb        #3
        tstb
        beq        digit3
        decb
        beq        digit2
        decb
        beq        digit1

digit0: 
        ldaa       disptn+3
        staa       portb,x
        tst        turn_led_on
        bne        dig0_on
        clr        portb,x
dig0_on:
        bclr       ptp,x,DIG0                ; turn on digit 0
        bset       ptp,x,DIG1                ; turn off all other digits
        bset       ptp,x,DIG2
        bset       ptp,x,DIG3
        rts

digit1: 
        ldaa       disptn+2
        staa       portb,x
        tst        turn_led_on
        bne        dig1_on
        clr        portb,x
dig1_on:
        bset       ptp,x,DIG0
        bclr       ptp,x,DIG1                ; turn on digit 1
        bset       ptp,x,DIG2                ; turn off all other digits
        bset       ptp,x,DIG3
        rts

digit2: 
        ldaa       disptn+1
        staa       portb,x
        tst        turn_led_on
        bne        dig2_on
        clr        portb,x
dig2_on:
        bset       ptp,x,DIG0
        bset       ptp,x,DIG1
        bclr       ptp,x,DIG2                ; turn on digit 2
        bset       ptp,x,DIG3                ; turn off all other digits
        rts

digit3: 
        ldaa       disptn
        staa       portb,x
        tst        turn_led_on
        bne        dig3_on
        clr        portb,x
dig3_on:
        bset       ptp,x,DIG0
        bset       ptp,x,DIG1
        bset       ptp,x,DIG2
        bclr       ptp,x,DIG3                ; turn on digit 3
        rts

timer6:
        ldx        #REGBLK
; in an interrupt servicing routine the x register will be saved automatically
; the rti instruction will pop the x register off stack.

        inc        d1ms_flag
        ldd        #TB1MS                ; reload the count for 1 ms time base
        addd       tc6,x
        std        tc6,x
        ldaa       #DB6
        staa       tflg1,x                ; clear flag
        rti

        org        $3E62
        fdb        timer6

        end
; 5s_delay.asm --- 5 second delay timer for the DRAGON12-Plus2 Rev. A board
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
;               5 second delay routine using output comparator 6
;               The PB0 LED will be turned on immediately after running
;               this program. It will be turned off after 5 second delay.
;               Change the DELAY_TIME to 36000 will delay 3 minutes.

 
PB0:        equ        1
DB6:        equ        $40
;
TB1MS:      equ        24000     ; 1ms time base of 24,000 instruction cycles
;                                ; 24,000 x 1/24MHz = 1ms at 24 MHz bus speed

;DELAY_TIME: equ        36000    ; 36000 X 5 ms= 180 sec = 3 min
DELAY_TIME: equ        5000      ; 5000 X 1 ms= 5 sec

REGBLK:     equ        $0
#include    reg9s12.h            ; include register equates

            org        $1000
;
flag_5s:    rmb        1
cnt_5s:     rmb        2

STACK:      equ        $2000

            org        $2000
start:
        lds        #STACK
        ldx        #timer6
        stx        $3E62                ; initialize the int vetctor

        ldx        #REGBLK
        ldaa       #$ff
        staa       ddrb,x                ; make port B an output port
        staa       ddrp,x                ; make port P an output port
        staa       ddrj,x                ; make port J an output port
        clr        ptj,x                ; make PJ1 low to enable LEDs
        
        ldaa       #$0f                 ; portp = 00001111
        staa       ptp,x           ; turn off 7-segment display and RGB LED

        ldaa       #$80
        staa       tscr,x                ; enable timer
        ldaa       #DB6
        staa       tios,x                ; select t6 as an output compare
        staa       tmsk1,x

        cli

        bset       portb,x PB0     ; turn on LED PB0
        jsr        delay_5s
        bclr       portb,x PB0     ; turn off LED PB0

stp:    jmp        stp


delay_5s:
        clr        cnt_5s
        clr        cnt_5s+1
        clr        flag_5s
delay:  ldaa       flag_5s
        beq        delay
        rts

timer6:
        ldx        cnt_5s
        inx
        stx        cnt_5s
        cpx        #DELAY_TIME
        bne        tmr6
        clr        cnt_5s
        clr        cnt_5s+1
        ldaa       #1
        staa       flag_5s
        rti

tmr6:   ldx        #REGBLK
        ldd        #TB1MS                ; reload the count for 1 ms time base
        addd       tc6,x
        std        tc6,x
        ldaa       #DB6
        staa       tflg1,x               ; clear flag
        rti

        org        $3E62
        fdb        timer6
        end
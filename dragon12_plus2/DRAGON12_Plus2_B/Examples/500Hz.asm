; 500Hz.asm --- Square wave generator for the DRAGON12-Plus2 Rev. A board
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
;               500 Hz square wave routine using output comparator 6
;               It generates a 500Hz square wave on the PB0 LED (pin 24 of the MCU)
;               and a 2Hz square wave on the PB7 LED (pin 31 of the MCU).
;
PB0:        equ        1
DB6:        equ        $40

TB1MS:      equ        24000        ; 1ms time base of 24,000 instruction cycles
;                                   ; 24,000 x 1/24MHz = 1ms at 24 MHz bus speed

REGBLK:     equ        $0
#include    reg9s12.h               ; include register equates


STACK:      equ        $2000

            org        $1000
count250:   rmb        1


        org        $2000
start:
        lds        #STACK
        ldx        #timer6
        stx        $3E62                ; initialize the int vetctor

        ldx        #REGBLK
        ldaa       #$ff
        staa       ddrb,x               ; make port B an output port
        staa       ddrp,x               ; make port P an output port
        staa       ddrj,x               ; make port J an output port
        clr        ptj,x                ; make PJ1 low to enable LEDs
        
        ldaa       #$0f                 ; portp = 00001111
        staa       ptp,x           ; turn off 7-segment display and RGB LED

        ldaa       #$80
        staa       tscr,x               ; enable timer
        ldaa       #DB6
        staa       tios,x               ; select t6 as an output compare
        staa       tmsk1,x

        cli

back:   ldaa       count250
        cmpa       #250
        bne        back
        clr        count250
        ldaa       portb
        eora       #$80                  ; toggle the PB7 ever 250ms
        staa       portb
        jmp        back
        
timer6:
        ldx        #REGBLK
        inc        count250
        ldd        #TB1MS                ; reload the count for 1 ms time base
        addd       tc6,x
        std        tc6,x

        ldaa       #DB6
        staa       tflg1,x               ; clear flag
        ldaa       portb
        eora       #1                    ; toggle the PB0
        staa       portb
        rti

        org        $3E62
        fdb        timer6
        end
; Ex2.asm  ---- Example program 2 for the DRAGON12-Plus2 Rev. A board
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
;               Makes port B as a binary counter and outputs '*' to PC screen.
;
;
#include        reg9s12.h
REGBLK: equ     $0000
SPEED:  equ     $FFFF           ; change this number to change counting speed
;
STACK:  equ     $2000
;
        org     $2000           ; program code
start:
        lds     #STACK
        ldx     #REGBLK

        ldaa    #$ff
        staa    ddrj,x          ; make port J an output port
        staa    ddrb,x          ; make port B an output port
        staa    ddrp,x          ; make port P an output port
        
        ldaa    #$0f            ; portp = 00001111
        staa    ptp,x           ; turn off 7-segment display and RGB LED
        
        clra
        staa    ptj,x           ; make PJ1 low to enable LEDs

back:   inca
        staa    portb,x
        jsr     d_10ms
        psha
        pshx
        ldab    #'*'            ; output '*' to PC screen
        ldx     #$ee86
        movb    2,x,PPAGE
        ldx     $ee86
        jsr     0,x
        pulx
        pula
        jmp     back
*
d_10ms: ldab    #10             ; delay 10 ms
        jmp     dly1

delay:  ldab    #1              ; delay 1 ms
dly1:   ldy     #6000           ; 6000 x 4 = 24,000 cycles = 1ms
dly:    dey                     ; 1 cycle
        bne     dly             ; 3 cycles
        decb
        bne     dly1
        rts
        end
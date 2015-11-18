; Ex1.asm  ---- Example program 1 for the DRAGON12-Plus2 Rev. A board
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
;               Reads the DIP switch via port H and displays its states
;               on port B LEDs PB0-PB7.
        
;
#include        reg9s12.h
REGBLK: equ     $0000
STACK:  equ     $2000

        org     $2000              ; program code starts here
start:
        lds     #STACK

        
        ldaa    #$ff
        staa    ddrb+REGBLK        ; make port B an output port
        staa    ddrj+REGBLK        ; make port J an output port
        staa    ddrp+REGBLK        ; make port P an output port
        
        ldaa    #$0f               ; turn off 7-segment display and RGB LED
        staa    ptp+REGBLK         ; portp = 00001111

        clra
        staa    ptj+REGBLK         ; make PJ1 low to enable LEDs
        staa    ddrh+REGBLK        ; make port H an input port
back:   ldaa    ptih+REGBLK        ; read from DIP sw.
        staa    portb+REGBLK       ; output it to LEDs PB0-PB7
        jmp     back

        end
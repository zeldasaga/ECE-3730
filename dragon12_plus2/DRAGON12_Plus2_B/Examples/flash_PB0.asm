; Flash_PB0.asm - Source code for the simple program on chapter 3
;                 of the User's manual.
;                 (c)2012, EVBplus.com
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
;               Flash the PB0 LED at 2 Hz


#include        reg9s12.h
REGBLK:         equ        $0000
STACK:          equ        $4000
;
                org        $1000
counter:        rmb        1

                org        $2000                ; program code
start:          lds        #STACK
                ldx        #REGBLK

                ldaa       #$ff
                staa       ddrj,x               ; make port J an output port
                staa       ddrb,x               ; make port B an output port
                staa       ddrp,x               ; make port P an output port
                ldaa       #$0f
                staa       ptp,x      ; turn off 7-segment LED display and RGB

                clr        ptj,x                ; make PJ1 low to enable LEDs
back:           clr        portb,x              ; turn off PB0
                jsr        d250ms               ; delay 250ms
                inc        portb,x              ; turn on PB0
                jsr        d250ms               ; delay 250ms
                jmp        back
*
d250ms:         ldaa       #250                ; delay 250 ms
                staa       counter

delay1:         ldy        #6000           ; 6000 x 4 = 24,000 cycles = 1ms
delay:          dey                        ; this instruction  takes 1 cycle
                bne        delay           ; this instruction  takes 3 cycles
                dec        counter
                bne        delay1          ; not 250ms yet, delay again
                rts

                end

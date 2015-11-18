; RGB.asm  ---- Example program of RGB LED for the DRAGON12-Plus2 Rev. A board
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
;               Flash RGB LED at 0.5 second rate


#include        reg9s12.h
REGBLK:         equ     $0000
STACK:          equ     $2000
ONE_MS:         equ     4000          ; 4000 x 250ns = 1 ms at 24 MHz bus speed
FIVE_MS:        equ     20000
TEN_MS:         equ     40000
FIFTY_US:       equ     200

RED:            EQU     $10          ; PP4
BLUE:           EQU     $20          ; PP5
GREEN:          EQU     $40          ; PP6


        org     $2000                ; program code starts here
        jmp     start
delay_500ms:
        psha
        ldaa    #50
dly:    jsr     delay_10ms
        deca
        bne     dly
        pula
        rts
        
delay_10ms:
        pshx
        ldx     #TEN_MS
        bsr     del1
        pulx
        rts
delay_5ms:
        pshx
        ldx     #FIVE_MS
        bsr     del1
        pulx
        rts
delay_50us:
        pshx
        ldx     #200
        bsr     del1
        pulx
        rts
;
; 250ns delay at 24MHz bus speed
;
del1:   dex                             ; 1 cycle
        inx                             ; 1 cycle
        dex                             ; 1 cycle
        bne     del1                    ; 3 cylce
        rts

start:
        lds     #STACK
        ldx     #REGBLK
        ldaa    #RED+GREEN+BLUE         ; make pp4-pp6 outputs
        staa    ddrp,x
;
        bset    ddrm,x 4                ; make PM2 as output
        bclr    ptm,x 4                 ; make PM2 low to enable RGB
        
back:   ldaa    #RED
        staa    ptp
        jsr     delay_500ms
        ldaa    #GREEN
        staa    ptp
        jsr     delay_500ms
        ldaa    #BLUE
        staa    ptp
        jsr     delay_500ms
        jmp     back
        end
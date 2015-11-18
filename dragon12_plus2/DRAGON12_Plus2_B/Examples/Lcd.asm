; LCD.asm  ---- LCD example program for the DRAGON12-Plus2 Rev. A board
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
;               This is the simplest way to display a message on the
;               16X2 LCD display module. The cursor is off.
;
;  This sample program uses 4-bit transfer via port K:
;  PK0 ------- RS ( register select, 0 = register transfer, 1 = data transfer).
;  PK1 ------- Enable ( write pulse )
;  PK2 ------- Data Bit 4 of LCD
;  PK3 ------- Data Bit 5 of LCD
;  PK4 ------- Data Bit 6 of LCD
;  PK5 ------- Data Bit 7 of LCD
;
; Timing of 4-bit data transfer is shown on page 11 of the Seiko LCD
; application note on the distribution CD. The file name is Seikolcd.pdf
;

ONE_MS:         equ        4000        ; 4000 x 250ns = 1 ms at 24 MHz bus speed
FIVE_MS:        equ        20000
TEN_MS:         equ        40000
FIFTY_US:       equ        200


DB0:            equ        1
DB1:            equ        2
REG_SEL:        equ        DB0        ; 0=reg, 1=data
NOT_REG_SEL:    equ        $FE
ENABLE:         equ        DB1
NOT_ENABLE:     equ        $FD

LCD:            equ        portk
LCD_RS:         equ        portk
LCD_EN:         equ        portk

REGBLK:         equ        $0
#include        reg9s12.h        ; include register equates

STACK:          equ        $2000

                org        $1000

pkimg:          rmb        1
temp1:          rmb        1

LCDimg:         equ        pkimg
LCD_RSimg:      equ        pkimg
LCD_ENimg:      equ        pkimg

        org     $2000
        jmp     start

lcd_ini:
        ldaa    #$ff
        staa    ddrk                ; port K = output
        clra        
        staa    pkimg
        staa    portk

        ldx     #inidsp         ; point to init. codes.
        pshb                    ; output instruction command.
        jsr     sel_inst
        ldab    0,x
        inx
onext:  ldaa    0,x
        jsr     wrt_nibble         ; initiate write pulse.
        inx
        jsr     delay_5ms       ; every nibble is delayed for 5ms
        decb                    ; in reset sequence to simplify coding
        bne     onext
        pulb
        rts
              
inidsp: fcb     12                ; number of high nibbles
*                                ; use high nibbles only, low nibbles are ignored
        fcb     $30                ; 1st reset code, must delay 4.1ms after sending
        fcb     $30                ; 2nd reste code, must delay 100us after sending
        
; all following 10 nibbles must be delay 40us each after sending
        fcb     $30             ; 3rd reset code,
        fcb     $20                ; 4th reste code,
        fcb     $20                   ; 4 bit mode, 2 line, 5X7 dot
        fcb     $80                   ; 4 bit mode, 2 line, 5X7 dot
        fcb     $00                ; cursor increment, disable display shift
        fcb     $60                ; cursor increment, disable display shift
        fcb     $00                ; display on, cursor off, no blinking
        fcb     $C0                ; display on, cursor off, no blinking
        fcb     $00                ; clear display memory, set cursor to home pos
        fcb     $10                ; clear display memory, set cursor to home pos
*
sel_data:
        psha
;        bset    LCD_RSimg REG_SEL        ; select instruction
        ldaa    LCD_RSimg
        oraa    #REG_SEL
        bra     sel_ins
sel_inst:
        psha
;        bclr    LCD_RSimg REG_SEL        ; select instruction
        ldaa    LCD_RSimg
        anda    #NOT_REG_SEL
sel_ins:
        staa    LCD_RSimg
        staa    LCD_RS
        pula
        rts

lcd_line1:
        jsr     sel_inst                ; select instruction
        ldaa    #$80                     ; starting address for the line1
        bra     line3
lcd_line2:
        jsr     sel_inst
        ldaa    #$C0                     ; starting address for the line2
line3:  jsr     wrt_byte

        jsr     sel_data
        jsr     msg_out
        rts        
;
; at entry, x must point to the begining of the message,
;           b = number of the character to be sent out
           
msg_out:
        ldaa    0,x
        jsr     wrt_byte
        inx
        decb
        bne     msg_out
        rts

wrt_nibble:
        anda    #$f0                     ; mask out 4 low bits
        lsra
        lsra                             ; 4 MSB bits go to pk2-pk5
        staa    temp1                         ; save high nibble
        ldaa    LCDimg                   ; get LCD port image
        anda    #$03                     ; need low 2 bits
        oraa    temp1                    ; add it with high nibble
        staa    LCDimg                   ; save it
        staa    LCD                      ; output data to LCD port
        jsr     enable_pulse
        rts
*

;       @ enter, a=data to output 
;
wrt_byte:
        pshx
        psha                             ; save it tomporarily.
        anda    #$f0                     ; mask out 4 low bits.
        lsra
        lsra                             ; 4 MSB bits go to pk2-pk5
        staa    temp1                    ; save nibble value.
        ldaa    LCDimg                   ; get LCD port image.
        anda    #$03                     ; need low 2 bits.
        oraa    temp1                    ; add in low 4 bits.
        staa    LCDimg                   ; save it
        staa    LCD                      ; output data
;
        bsr     enable_pulse
        pula
        asla                             ; move low bits over.
        asla
        staa    temp1                    ; store temporarily.
;
        ldaa    LCDimg                   ; get LCD port image.
        anda    #$03                     ; need low 2 bits.
        oraa    temp1                    ; add in loiw 4 bits.
        staa    LCDimg                   ; save it
        staa    LCD                      ; output data
;
        bsr     enable_pulse
        jsr     delay_50us
        pulx
        rts
;
enable_pulse:
;        bset    LCD_ENimg ENABLE        ; ENABLE=high
        ldaa    LCD_ENimg
        oraa    #ENABLE
        staa    LCD_ENimg
        staa    LCD_EN
        
;        bclr    LCD_ENimg ENABLE        ; ENABLE=low
        ldaa    LCD_ENimg
        anda    #NOT_ENABLE
        staa    LCD_ENimg
        staa    LCD_EN
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
        ldx     #FIFTY_US
        bsr     del1
        pulx
        rts
;
; 250ns delay at 24MHz bus speed
;
del1:   dex                                ; 1 cycle
        inx                                ; 1 cycle
        dex                                ; 1 cycle
        bne     del1                       ; 3 cylce
        rts

start:
        lds     #STACK
        jsr     delay_10ms                 ; delay 20ms during power up
        jsr     delay_10ms

        jsr     lcd_ini                    ; initialize the LCD
                              
back:   ldx     #MSG1                      ; MSG1 for line1, x points to MSG1
        ldab    #16                        ; send out 16 characters
        jsr     lcd_line1

        ldx     #MSG2                      ; MSG2 for line2, x points to MSG2
        ldab    #16                        ; send out 16 characters
        jsr     lcd_line2
        jsr     delay_10ms
        jsr     delay_10ms
        jmp     back
                       
MSG1:   FCC     "DRAGON12 TRAINER"
MSG2:   FCC     "(C)2012, EVBPLUS"
        end



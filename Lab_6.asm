;Programmers Zachary Hall, Andrew Bowns
;Class: ECE 3730
;Program 6.9 from the book
;

#include "Reg9s12.H"

;****************** DATA SECTION ******************
                org     $1000
LCD_DATA        equ     PORTK
LCD_CTRL        equ     PORTK
RS              equ     %00000001
EN              equ     %00000010
R1              equ     $1001
R2              equ     $1002
R3              equ     $1003
TEMP            equ     $1200

THRSH           equ     $55
ONE_MS:         equ     4000            ; 4000 x 250ns = 1 ms at 24 MHz bus speed
FIVE_MS:        equ     20000
TEN_MS:         equ     40000
FIFTY_US:       equ     200

;****************** LAB 2 CODE ******************
LAB2                                    ; Lab 2 Subroutine
;Read data from $4000 and store it in $0800
ONE             LDAA    $4000
                STAA    $0800
                CMPA    #$55
                BLS     TWO
                BRA     SUB1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Read data from $4001 and store it in $0801
TWO             LDAA    $4001
                STAA    $0801
                CMPA    #$55
                BLS     THREE
                BRA     SUB2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Read data from $4002 and store it in $0802
THREE           LDAA    $4002
                STAA    $0802
                CMPA    #$55
;                BLS    END
                BRA     SUB3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Subroutine on first data set
SUB1            LDAB    #$01
                LDAA    #$00
AGAIN           ABA
                STAA                    $0800
                CMPB                    #$05
                BEQ                     TWO
                INCB
                BRA                     AGAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB2            LDAA                    #$00
                STAA                    $0801
                BRA                     THREE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB3            LDAA                     $0802
                SUBA                     #$10
                STAA                     $0802
                RTS

;****************** MAIN PROGRAM ******************
MAIN            org     $2000
                lds     #$2000          ; Set Stack Top
                ldaa    #$FF            ; Set port K as output
                staa    DDRK            ;
                bra     LCD_INI         ; Initialize LCD

                ; Wait for push button
                ; Acknowledge Message on LCD

                LDAA  #'Y'
                JSR   LCDDATW
                JSR   LCD_DELAY
                ; Delay 2 seconds
                ; Execute Chapter 2 Lab Code
                ; bra     LAB2
                ; Check interupt flag
                ; IF Interrupt flag is set
                ; THEN BRA                     PRINT_LCD       ; Branch to subroutine that prints to LCD
END
;****************** FUNCTIONS ******************
LCD_INI:
                ldaa    #$33
                jsr     LCDCOMW
                jsr     LCD_DELAY
                ldaa    #$32
                jsr     LCDCOMW
                jsr     LCD_DELAY
                LDAA    #$28
                JSR     LCDCOMW
                JSR     LCD_DELAY
                LDAA    #$0E
                JSR     LCDCOMW
                JSR     LCD_DELAY
                LDAA    #$01
                JSR     LCDCOMW
                JSR     LCD_DELAY
                LDAA    #$06
                JSR     LCDCOMW
                JSR     LCD_DELAY
                LDAA    #$80
                JSR     LCDCOMW
                JSR     LCD_DELAY
                RTS
LCD_DELAY:
                psha                    ; Store Reg A on Stack
                ldaa    #1              ;
                staa    R3
;-- 1 msec delay. The D-Bug12 works at speed of 48MHz with XTAL=8MHz on Dragon12+ board
;Freq. for Instruction Clock Cycle is 24MHz (1/2 of 48Mhz).
;(1/24MHz) x 10 Clk x240x100=1 msec. Overheads are excluded in this calculation.
L3              LDAA    #100
                STAA    R2
L2              LDAA    #240
                STAA    R1
L1              NOP                     ;1 Clk
                NOP                     ;1 Clk
                NOP                     ;1
                DEC     R1              ;4
                BNE     L1              ;3
                DEC     R2              ;Total Instr.Clk=10
                BNE     L2
                DEC     R3
                BNE     L3
                PULA                    ; Restore Reg A
                RTS
;----------------------------
LCDCOMW:
                STAA    TEMP            ; Save a copy of A in a memory location
                ANDA    #$F0
                LSRA
                LSRA
                STAA    LCD_DATA
                BCLR    LCD_CTRL,RS     ; Clear the LCD Control
                BSET    LCD_CTRL,EN     ; Enable the LCD Control
                NOP
                NOP
                NOP
                BCLR    LCD_CTRL,EN     ; Clear the LCD Control
                LDAA    TEMP            ; Restore the memory value to A
                ANDA    #$0F
                LSLA
                LSLA
                STAA    LCD_DATA
                BCLR    LCD_CTRL,RS
                BSET    LCD_CTRL,EN
                NOP
                NOP
                NOP
                BCLR    LCD_CTRL,EN
                RTS
;--------------
LCDDATW:
                STAA    TEMP
                ANDA   #$F0
                LSRA
                LSRA
                STAA   LCD_DATA
                BSET   LCD_CTRL,RS
                BSET   LCD_CTRL,EN
                NOP
                NOP
                NOP
                BCLR   LCD_CTRL,EN
                LDAA   TEMP
                ANDA   #$0F
                LSLA
                LSLA
                STAA   LCD_DATA
                BSET   LCD_CTRL,RS
                BSET   LCD_CTRL,EN
                NOP
                NOP
                NOP
                BCLR   LCD_CTRL,EN
                RTS
;-------------------
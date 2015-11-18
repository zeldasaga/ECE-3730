DO_THE_SET equ 1    ; COMMENT OUT THIS LINE IF YOU ONLY WANT TO READ THE TIME
*
* Dragon12-plus DS1307 test
* Author: Tom Almy
* Date: April 20, 2007
* Copyright 2007 by Tom Almy. Purchasers of the Dragon12-plus
* board may use this code freely in their own applications.
*hhhhh
#include "registers.inc"
*
* Constants for setting the time/date. Values are all BCD
*
CURRENT_YEAR equ $07
CURRENT_MONTH equ $04
CURRENT_DATE equ $20
CURRENT_DAY equ $06       ; Range is 1 to 7
CURRENT_HOUR equ $08     ; Also sets 12 vs 24 hour mode -- 24 hour mode shown
CURRENT_MINUTE equ $20
CURRENT_SECOND equ $00
*
*
*
	org DATASTART
year:   db  0			; READ TIME SAVED HERE
month:  db  0
date:   db  0
day:    db  0
hour:   db  0
minute: db  0
second: db  0
	org PRSTART
start:	lds	#DATAEND
	jsr	IICINIT
#ifdef DO_THE_SET
	ldaa	#%11010000
	jsr	IICSTART
	brclr	IBCR #$20 *   ; loop on failure
	ldaa	#0	; register address
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#CURRENT_SECOND
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#CURRENT_MINUTE
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#CURRENT_HOUR
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#CURRENT_DAY
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#CURRENT_DATE
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#CURRENT_MONTH
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#CURRENT_YEAR
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa	#0	; control
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	jsr	IICSTOP
#endif
read:
	ldaa	#%11010000
	jsr	IICSTART
	brclr	IBCR #$20 *   ; loop on failure
	ldaa	#$00	; register address
	jsr	IICTRANSMIT
	brclr	IBCR #$20 *
	ldaa    #%11010001
	jsr     IICRESTART
	brclr   IBCR #$20 *
	jsr     IICSWRCV        ; switch to receive
	jsr     IICRECEIVE
	staa    second
	jsr     IICRECEIVE
	staa    minute
	jsr     IICRECEIVE
	staa    hour
	jsr     IICRECEIVE
	staa    day
	jsr     IICRECEIVE
	staa    date
	jsr     IICRECEIVEM1
	staa    month
	jsr     IICRECEIVELAST
	staa    year
	swi

; IIC Module Library
; Author - Tom Almy
; Date - January 28, 2005
; Subroutines for controlling the IIC interface. HCS12 as slave is not supported
; by this code. Polled interface (not interrupt driven)

; **** Always call IICINIT first to perform initialization.

; ***** Procedure to transmit:
;	ldaa	#control_byte	; Address in bits 7-1, direction in bit 0 
				; (0-write/transmit)
;	jsr	IICSTART
;	brclr	IBCR #$20 fail	; branch if address NAKs. Bus is released

;	ldaa	#data_byte	; Repeat this and next two lines for each byte
;	jsr	IICTRANSMIT
;	brclr	IBCR #$20 fail	; branch if data NAKs, bus is released

;	jsr	IICSTOP		; Release bus

; ***** Procedure to receive a single byte
;	ldaa	#control_byte	; Address in bits 7-1, direction in bit 0 
				; (1-read/receive)
;	jsr	IICSTART
;	brclr	IBCR #$20 fail	; branch if address NAKs. Bus is released
;	jsr	IICRECEIVEONE	; bus is released afterwards
;	staa	data		; received byte in A

; ***** Procedure to receive two bytes
;	ldaa	#control_byte	; Address in bits 7-1, direction in bit 0 
				; (1-read/receive)
;	jsr	IICSTART
;	brclr	IBCR #$20 fail	; branch if address NAKs. Bus is released
;	jsr	IICSWRCV	
;	jsr	IICRECEIVEM1
;	staa	data		; received byte in A
;	jsr	IICRECEIVELAST	; bus is released afterwards
;	staa	data		; received byte in A

; ***** Procedure to receive three or more bytes
;	ldaa	#control_byte	; Address in bits 7-1, direction in bit 0 
				; (1-read/receive)
;	jsr	IICSTART
;	brclr	IBCR #$20 fail	; branch if address NAKs. Bus is released
;	jsr	IICSWRCV	

;	jsr	IICRECEIVE	; Repeat these two lines to receive all but
;	staa	data		; last two bytes

;	jsr	IICRECEIVEM1
;	staa	data		; received byte in A
;	jsr	IICRECEIVELAST	; bus is released afterwards
;	staa	data		; received byte in A

; A transmit can be immediately followed by a receive by omitting the call
; to IICSTOP in the transmit and calling IICRESTART instead of IICSTART for
; the receive.

IICINIT:	; Initialize IIC
	movb	#$23,IBFD	; Set to 100KHz operation
;	movb	#$35,IBFD	; Set to 20KHz operation
	movb	#$2,IBAD	; Slave address 1 (never address ourself, please!)
	bset	IBCR,#$80	; set IBEN
	rts

IICSTART:	; Issue start and address the slave. Control byte in A
		; Calling routine checks IBCR $20 clear for failure
	brset	IBSR,#$20,*  	; wait for IBB flag to clear
	bset	IBCR,#$30	; Set XMIT and MASTER mode, emit START
	staa	IBDR		; Calling address
	brclr	IBSR,#$20,*  	; Wait for IBB flag to set
IICRESPONSE:
	brclr	IBSR,#$2,*  	; Wait for IBIF to set
	bclr	IBSR,#~$2	; Clear IBIF
	brset	IBSR,#$1,IICSTOP	; Stop if NAK
	rts

IICSTOP:	; Release bus and stop (only if transmitting)
	bclr	IBCR,#$20
	rts

IICRESTART:	; Issue restart and address the slave. Control byte in A
		; Calling routine checks IBCR $20 clear for failure
	bset	IBCR,#$04	; Generate restart
;	staa	IBDR
;	bra	IICRESPONSE

IICTRANSMIT:	; Data byte to send in A
		; Calling routine checks IBCR $20 clear for failure
	staa	IBDR
	bra	IICRESPONSE
	
IICSWRCV:       ; Switch to receive
	bclr    IBCR,#$10	; put in receive mode
	ldaa    IBDR            ; dummy read
	rts


IICRECEIVE:	; Call for all but last two bytes of a read sequence 3 or more bytes long
		; Data byte returned in A
	brclr	IBSR,#$2,*  	; Wait for IBIF
	bclr	IBSR,#~2	; clear IBIF
	ldaa	IBDR		; read byte (and start next read)
	rts

IICRECEIVEM1:	; Call to receive next to last byte of multibyte receive sequence
		; Data byte returned in A
	brclr	IBSR,#$2,*  	; Wait for IBIF
	bclr	IBSR,#~2	; clear IBIF
	bset	IBCR,#$8	; Disable ACK for last read
	ldaa	IBDR		; read byte (and start last read)
	rts

IICRECEIVELAST:	; Call to receive last byte of multibyte receive sequence
		; Data byte returned in A, Bus released
	brclr	IBSR,#$2,*  	; Wait for IBIF
	bclr	IBSR,#~2	; clear IBIF
	bclr    IBCR,#$08        ; REENABLE ACK
	bclr	IBCR,#$20	; Generate STOP
	bset    IBCR,#$10       ; Set transmit
	ldaa	IBDR		; read byte
	rts

IICRECEIVEONE:	; Call to receive a single byte
		; Data byte returned in A, Bus released
	bset	IBCR,#$08	; Disable ACK
	bclr	IBCR,#$10	; Put in receive mode
	ldaa    IBDR            ; dummy read
	bra	IICRECEIVELAST
	end

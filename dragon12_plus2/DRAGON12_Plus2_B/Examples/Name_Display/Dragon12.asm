
	ORG	$0FDE
	FCC	"WC"			;ID word

; The following 16 bytes will be displayed at the 1st line of the LCD
	FCC     "DRAGON12 TRAINER"	; $0FE0-$0FEE
;               "1234567890123456"	; 16 dummy bytes for alignment purpose
;
; This file should only contain 18 bytes ( 2 ID bytes and 16 data bytes).  Do not add more data.
; The content at $0FFD gets copied into BPROT ($114) upon reset 
; Be careful not to adversely write anything at $0FFD to write-protect EEPROM 
; or you may have to use a BDM to unprotect it.

 	end




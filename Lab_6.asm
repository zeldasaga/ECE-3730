;Programmers Zachary Hall, Andrew Bowns
;Class: ECE 3730
;Program 6.9 from the book
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		ORG			$4000
THRSH           EQU			$55
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                ORG                     $4100
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Read data from $4000 and store it in $0800
ONE             LDAA                	$4000
                STAA            	$0800
                CMPA               	#$55
                BLS             	TWO
                BRA             	SUB1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Read data from $4001 and store it in $0801
TWO             LDAA                	$4001
                STAA            	$0801
                CMPA                	#$55
                BLS             	THREE
                BRA             	SUB2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Read data from $4002 and store it in $0802
THREE           LDAA	                $4002
                STAA    	        $0802
                CMPA            	#$55
                BLS             	END
                BRA             	SUB3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Subroutine on first data set
SUB1            LDAB			#$01
                LDAA			#$00
AGAIN           ABA
                STAA			$0800
                CMPB			#$05
                BEQ			TWO
                INCB
                BRA			AGAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB2            LDAA			#$00
                STAA			$0801
                BRA			THREE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUB3            LDAA			$0802
                SUBA			#$10
                STAA			$0802
END
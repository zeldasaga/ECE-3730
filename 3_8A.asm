;Lab 3.8
;Programmer Name: Zachary Hall
;Purpose: Simulates control of two DC motors.  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
 					ORG    $0800
T_A					FDB	   $0000					;Memory locations $0800-$0801
T_C					FDB	   $0000					;Memory locations $0802-$0803
T_TOTAL				FDB	   $0000					;Memory locations $0804-$0805
DELTA_VELOCITY_LOC	FDB	   $0000    				;Memory locations $0806-$0807
FILLER				FDB	   $0000					;Memory locations $0808-$0809
V_CONSTANT_Loc		FDB	   $0000					;Memory locations $080A-$080B
T_TOTAL_Loc			FDB	   $0000					;Memory locations $080C-$080D

;T_TOTAL				FDB	   $03E8

;main program that calls two subroutines
	  		  	   	ORG	   $4200
					;Load .s19 info into T_TOTAL_LOC
	  				LDD	   $T_TOTAL
;	  				MUL
;Subroutine 1: call-by-value using registers A,B,X, and Y
;			   		LDD	   #$T_TOTAL_LOC
;					MULT   
;Subroutine 2: call-by-reference using the address of the parameter
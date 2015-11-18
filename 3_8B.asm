;Lab 3.8 B
;Programmer Name: Zachary Hall
;Purpose: Simulates control of two DC motors. Output to the console 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
 					ORG    $4000
;MOTOR_SPEED_RIGHT  FDB    
;MOTOR_SPEED_LEFT	FDB	   
LEFT_MOTOR			EQU	   ;some output pin
RIGHT_MOTOR			EQU	   ;some output pin
V_CONSTANT			EQU	   $080A
T_TOTAL_Loc			EQU	   $080C
T_TOTAL				FDB	   $03E8
T_ACCELERATION		EQU	   $0800
T_VELOCITY			EQU	   $0802
P_ACCELERATION		FDB	   
P_VELOCITY			FDB	   

;main program that calls two subroutines
	  ORG	  $4200
	  LDD	  T_TOTAL
	  STD	  T_TOTAL_LOC
;Subroutine 1: call-by-value using registers A,B,X, and Y

;Subroutine 2: call-by-reference using the address of the parameter
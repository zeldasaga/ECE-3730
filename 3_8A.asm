;Lab 3.8
;Programmer Name: Zachary Hall, Andrew Bowns
;Purpose: Simulates control of two DC motors.  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;$HC12
                        ORG             $1000
T_A                     FDB             $0000           ;Memory locations $1000-$1001
T_C                     FDB             $0000           ;Memory locations $1002-$1003
T_TOTAL                 FDB             $0000           ;Memory locations $1004-$1005
DELTA_VELOCITY_LOC      FDB             $0000           ;Memory locations $1006-$1007
FILLER                  FDB             $0000           ;Memory locations $1008-$1009
V_CONSTANT_Loc          FDB             $0000           ;Memory locations $100A-$100B
T_TOTAL_Loc             FDB                $0000                ;Memory locations $100C-$100D
INCREM_NUM                FDB                $0000           ;Memory location to store the incremental value $100E-$100F
RT_MOTOR_VEL_LOC        EQU             $4000           ;Starting memory of right motor
LFT_MOTOR_VEL_LOC       EQU             $4100           ;Starting memory of left motor

;main program that calls two subroutines
                        ORG                $2000                ;Begin Program address
                        JSR                SUB1                ;Go to subroutine 1
                        JSR                SUB2                ;Go to subroutine 2
                        END
                                                
;Subroutine 1: call-by-value using registers D, X, and Y
SUB1                    LDD                T_TOTAL_LOC        ;Load location of total time into register D
                        STD                T_TOTAL                ;Store the total time into memory
                        LDX                #$0005                ;Load the divisor to find 20% of the total time
                        IDIV                                ;Divide D by X and store in register X
                        STX                T_A                ;Store register X in memory
                        LDY                T_A                ;Load the acceleration/deceleration time into register y
                        LDD                #$0003                ;Load 3 into register D
                        EMUL                                ;Multiply the 20% value in Y by 3 to get the 60% constant velocity time
                        STD                T_C                ;Store that constant velocity time into memory
                        RTS
                                                
;Subroutine 2: call-by-reference using the address of the parameter
;Calculate 10 velocity values for each of the acceleration, constant, and deceleration intervals
SUB2			LDX                #$000A                ;Store 10 into register x for the number of time intervals
RT_MOTOR                LDD                V_CONSTANT_LOC        ;Load the constant velocity number into register D
                        IDIV                                ;Divide D by x and store the result in X
                        STX                INCREM_NUM        ;store the result into memory
                        LDD                #0
                        STD                RT_MOTOR_VEL_LOC ;Store D into memory
                        LDY                #RT_MOTOR_VEL_LOC;Load the address of the right motor velocity profile into register Y
                                                
;Add $0064 to each memory location until reaching $03E8
ACCEL                   ADDD		INCREM_NUM		;Add the velocity increment value to D and store it in D
                        STD		$2,+Y			;Increment the memory location and store register D into memory
                        CPD		V_CONSTANT_LOC   	;Compare D to the final velocity
                        BMI		ACCEL                           ;If D is less, repeat the process
                        TFR		D,X                           ;Move contents of register D into X
                        LDAA		#$08                           ;Load accumulator A with a count of 8
                                                
CONST                   STX                          $2,+Y                           ;Store the constant velocity into 9 more memory locations
                        CMPA                  #$00
                        BEQ                          DECEL
                        DECA
                        BRA                          CONST
                                                
DECEL                   TFR                          X,D                             ;Transfer the final velocity back into D
DEC_LOOP                SUBD                  INCREM_NUM           ;Subtract the increment value from D
                        STD                          $2,+Y                           ;Store the values in subsequent memory locations
                        CPD                          #0
                        BNE                          DEC_LOOP
                                                
LFT_MOTOR               LDY                          #LFT_MOTOR_VEL_LOC
                        LDX                          #RT_MOTOR_VEL_LOC
                        LDAA                  #$1E
LFT_MOTOR_LOOP          MOVW                  $2,X+,$2,Y+           ;Copy the velocity profile of the right motor into the left motor
                        DECA
                        BNE                          LFT_MOTOR_LOOP
                        RTS
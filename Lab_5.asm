;Lab 3.8B
;Programmer Name: Zachary Hall, Andrew Bowns
;Purpose: Use D-Bug12 subroutines to interface with HC12/S12

;Deliverables: Flow chart with problems encountered, team document thingy, program check off
;************************** DATA VALUES **************************
                        ORG           $1000            ;12K RAM Space
T_A                     FDB           $0000            ;Memory locations $0800-$0801
T_C                     FDB           $0000            ;Memory locations $0802-$0803
T_TOTAL                 FDB           $0000            ;Memory locations $0804-$0805
DELTA_VELOCITY_LOC      FDB           $0000            ;Memory locations $0806-$0807
FILLER                  FDB           $0000            ;Memory locations $0808-$0809
V_CONSTANT_Loc          FDB           $0000            ;Memory locations $080A-$080B
T_TOTAL_Loc             FDB           $0000            ;Memory locations $080C-$080D
INCREM_NUM              FDB           $0000            ;Memory location to store the incremental value
RT_MOTOR_VEL_LOC        EQU           $1100            ;Starting memory of right motor
LFT_MOTOR_VEL_LOC       EQU           $1200            ;Starting memory of left motor

GETCHAR                 EQU           $EE84            ;Vector address of GETCHAR subroutine
PUTCHAR                 EQU           $EE86            ;Vector address of PUTCHAR subroutine
PRINTF                  EQU           $EE88            ;Vector address of PRINTF subroutine

TARGET_SPD              FDB           $0000
TARGET_TIME             FDB           $0000
STACK                   EQU           $2000               ;Stack start point

HIGH                    FDB           $2710               ;High Value 10k Decimal
MEDIUM                  FDB           $03E8               ;Medium Value 1k Decimal
LOW                     FDB           $0064               ;Low Value 100 Decimal

;************************** SCREEN MESSAGES **************************
PRINT_WELCOME           FCC           'MOTOR CONTROL SOFTWARE'
                        FDB           $0D0A
                        FDB           $00

PRINT_LN_1              FCC           'Please choose a constant velocity:'
                        FDB           $0D0A
                        FCC           'High(1), Medium(2), or Low(3)'
                        FDB           $0D0A
                        FDB           $00

PRINT_TOT_TIME          FCC           'Please choose a total time period:'
                        FDB           $0D0A
                        FCC           'High(1), Medium(2), or Low(3)'
                        FDB           $0D0A
                        FDB           $00

PRINT_LN_3              FCC           'Velocity Profile'
                        FDB           $0D0A
                        FDB           $00

PRINT_BLANK             FCC           ''
                        FDB           $0D0A
                        FDB           $00

PRINT_VEL_LNS           FCC           'VELOCITY %u:  %X'
                        FDB           $0D0A
                        FDB           $00

PRINT_TA                FCC           'TA: '
PRINT_TC                FCC           'TC: '
PRINT_TTOTAL            FCC           'TTOTAL: '
PRINT_DELTA_V           FCC           'DELTAV: '
;***************************Push Button***************************

;************************** MAIN PROGRAM **************************
MAIN                    ORG           $2000               ;Begin Program address
                        LDS           #STACK              ;Load Stack with max address

                        LDD           #PRINT_WELCOME      ;Print welcome message
                        LDX           PRINTF              ;
                        JSR           0,X                 ;

                        LDD           #PRINT_LN_1         ;Query for Constant Velocity
                        LDX           PRINTF              ;*
                        JSR           0,X                 ;*

INPUT_SPEED             LDX           GETCHAR             ;Get user input for Constant Velocity
                        JSR           0,X                 ;*
                        LDX           PUTCHAR             ;Echo user input
                        JSR           0,X                 ;*
                        LDD           #PRINT_BLANK        ;Print a blank line
                        LDX           PRINTF              ;*
                        JSR           0,X                 ;*

                        STAB          TARGET_SPD          ;?
                        LDAA          $31                 ;?
                        CBA                               ;
                        BEQ           STORE_HIGH          ;
                        INCA                              ;
                        CBA                               ;
                        BEQ           STORE_MED           ;
                        INCA                              ;
                        CBA                               ;
                        BEQ           STORE_LOW           ;
                        ;BNE           INPUT_SPEED
STORE_HIGH              LDD           HIGH                ; Store HIGH Value to TARGET_SPD
                        STD           TARGET_SPD          ;
                        BRA           TIME_SLCT           ; Move on to time select
STORE_MED               LDD           MEDIUM              ; Store MEDIUM Value to TARGET_SPD
                        STD           TARGET_SPD          ;
                        BRA           TIME_SLCT           ; Move on to time select
STORE_LOW               LDD           LOW                 ; Store LOW value to TARGET_SPD
                        STD           TARGET_SPD          ;

TIME_SLCT               LDD           #PRINT_TOT_TIME     ;Query Total Time Period
                        LDX           PRINTF              ;
                        JSR           0,X                 ;
                        LDX           GETCHAR             ;Get user input
                        JSR           0,X                 ;
                        LDX           PUTCHAR             ;Echo user input
                        JSR           0,X                 ;
                        LDD           #PRINT_BLANK        ;Print blank line
                        LDX           PRINTF              ;
                        JSR           0,X                 ;
                        STAB          TARGET_TIME         ;?
                        LDAA          $31                 ;?
                        CBA                               ;?
                        BEQ           STORE_HIGH_T        ; Branch to store High Time
                        INCA                              ;?
                        CBA                               ;?
                        BEQ           STORE_MED_T         ; Branch to store Med Time
                        INCA
                        CBA
                        BEQ           STORE_LOW_T
STORE_HIGH_T            LDD           HIGH                ; TARGET_TIME = HIGH
                        STD           TARGET_TIME         ;
                        BRA           SUBROUTINES         ; GOTO SUBROUTINES
STORE_MED_T             LDD           MEDIUM              ; TARGET_TIME = MEDIUM
                        STD           TARGET_TIME         ;
                        BRA           SUBROUTINES         ; GOTO SUBROUTINES
STORE_LOW_T             LDD           LOW                 ; TARGET_TIME = LOW
                        STD           TARGET_TIME         ;

SUBROUTINES             LDY           TARGET_SPD          ; Load Y with TARGET_SPEED
                        LDD           TARGET_TIME         ; Load D with TARGET_TIME
                        JSR           SUB1                ; SUB1(Y=TARGET_SPEED,D=TARGET_TIME)
                        ;JSR           SUB2                ; Go to subroutine 2
                        ;JSR           SUB3                ; Print Velocity Profile
                        END
;************************** FUNCTIONS/SUBROUTINES **************************
;Subroutine 1
;Desc: call-by-value using registers D, X, and Y
;Params: Y=TARGET_SPEED, D=TARGET_TIME, X = 5
SUB1                    LDD           TARGET_TIME         ;Load location of total time into register D
                        STY           T_TOTAL             ;Store the total time into memory
                        LDX           #$0005              ;Load the divisor to find 20% of the total time
                        IDIV                              ;Divide D by X and store in register X
                        STX           T_A                 ;Store register X in memory
                        LDY           T_A                 ;Load the acceleration/deceleration time into register y
                        LDD           #$0003              ;Load 3 into register D
                        EMUL                              ;Multiply the 20% value in Y by 3 to get the 60% constant velocity time
                        STD           T_C                 ;Store that number into memory
                        RTS

;Subroutine 2
;Desc: call-by-reference using the address of the parameter
;Params:
;Calculate 10 velocity values for each of the acceleration, constant, and deceleration intervals
SUB2                    LDX          #$000A               ;Store 10 into register x for the number of time intervals
RT_MOTOR                LDD          V_CONSTANT_LOC       ;Load the constant velocity number into register D
                        IDIV                              ;Divide D by x and store the result in X
                        STX          INCREM_NUM           ;store the result into memory
                        LDD          #0                   ;Make D zero
                        STD          RT_MOTOR_VEL_LOC     ;Store D into memory
                        LDY          #RT_MOTOR_VEL_LOC    ;Load the address of the right motor velocity profile into register Y

                        ;Add $0064 to each memory location until reaching $03E8
ACCEL                   ADDD         INCREM_NUM           ;Add the velocity increment value to D and store it in D
                        STD          $2,+Y                ;Increment the memory location and store register D into memory
                        CPD          V_CONSTANT_LOC       ;Compare D to the final velocity
                        BMI          ACCEL                ;If D is less, repeat the process
                        TFR          D,X                  ;Move contents of register D into X
                        LDAA         #$08                 ;Load accumulator A with a count of 8

CONST                   STX          $2,+Y                ;Store the constant velocity into 9 more memory locations
                        CMPA         #$00
                        BEQ          DECEL
                        DECA
                        BRA          CONST

DECEL                   TFR          X,D                  ;Transfer the final velocity back into D
DEC_LOOP                SUBD         INCREM_NUM           ;Subtract the increment value from D
                        STD          $2,+Y                ;Store the values in subsequent memory locations
                        CPD          #0                   ;
                        BNE          DEC_LOOP             ;

LFT_MOTOR               LDY          #LFT_MOTOR_VEL_LOC   ;
                        LDX          #RT_MOTOR_VEL_LOC    ;
                        LDAA         #$1E                 ;
LFT_MOTOR_LOOP          MOVW         $2,X+,$2,Y+          ;Copy the velocity profile of the right motor into the left motor
                        DECA                              ;
                        BNE          LFT_MOTOR_LOOP       ;
                        RTS                               ;

;Subroutine 3 that displays the velocity profile to the terminal
;Printf the first few lines
SUB3                    LDD           #PRINT_LN_3         ; Print velocity profile header
                        LDX           PRINTF              ;
                        JSR           0,X                 ;
;Loop through and print the velocity profiles
AGAIN                   LDX           #RT_MOTOR_VEL_LOC   ;
                        LDD           2,X+                ;
                        PSHD                              ;
                        LDY           $00                 ;
                        PSHY                              ;
                        LDD           #PRINT_VEL_LNS      ;
                        LDX           PRINTF              ;
                        JSR           0,X                 ;
                        INY                               ;
                        CPY           #$29                ;
                        BNE           AGAIN               ;
;Print out the last few lines
                        RTS                               ;
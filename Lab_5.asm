	ORIG	4000
REG_BASE	EQU		$0000
PORT_J		EQU		$0028
DDR_J		EQU		$0029
J_INPUT		EQU		$00
NUM_OVERFL	EQU		$1E
TFLG2		EQU		$8F
TSCR		EQU		%86
TOF			EQU		$80
TIM_EN		EQU		$80

;Clear TOF
			LDAA	#TOF
			STAA	TFLG2
;Enable Timer
			BSET	TSCR,TIM_EN
;Initialize counter and wait NUM_OVERFL			
			LDAA	#J_INPUT
			STAA	DDR_J
			LDX		#REG_BASE	;Load register base with 0
			
			

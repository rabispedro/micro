; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0  BCF STATUS, RP0
#define BANK1  BSF STATUS, RP0

CBLOCK 0x20
	DELAY_1
	DELAY_2
ENDC

; entradas
#define LIGA PORTA,1
#define DESLIGA PORTA, 2
	
; saídas
#define LED PORTA, 0

; constantes
V_DELAY_1 equ .250
V_DELAY_2 equ .250
 V_DELAY_3 equ .4

; void setup()
RES_VECT CODE 0x0000								; processor reset vector
    BANK1
    BCF TRISA, 0 										; Define pino de saída

    BANK0

MAIN
    BTFSC LIGA
    GOTO MAIN
    
PISCA_EM_OPERACAO
    BSF LED ; apaga led
    CALL DELAY
    BCF LED ; acende led
    CALL DELAY

    BTFSC DESLIGA
    GOTO PISCA_EM_OPERACAO
    
    GOTO MAIN

DELAY
    MOVLW V_DELAY_1
    MOVWF DELAY_1						; delay2 = 250

INICIALIZA_DELAY_2
    MOVLW V_DELAY_2
    MOVWF DELAY_2							; delay2 = 250
    
DECREMENTA_DELAY_2
    NOP
    DECFSZ DELAY_2, F	; if(--delay2)
    GOTO DECREMENTA_DELAY_2
    
    DECFSZ DELAY_1, F	; if(--delay1)
    GOTO INICIALIZA_DELAY_2
    
    RETURN
    
    END
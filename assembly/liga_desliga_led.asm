; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

 #define BANK0  BCF STATUS, RP0
 #define BANK1  BSF STATUS, RP0
 
 CBLOCK 0x20
    FILTRO ; [0x20] int filtro
    FLAGS  ; [0x21] int flags
ENDC

#define ACAO	FLAGS, 0
#define LAMP	PORTA, 0
#define BOTAO	PORTA, 1
    
 ; SETUP
RES_VECT  CODE    0x0000            ; processor reset vector
    BANK1
    BCF TRISA, 0
    
    BANK0
    BCF LAMP
    MOVLW .100
    MOVWF FILTRO
    
    BCF ACAO

LE_BOTAO
    BTFSC BOTAO
    GOTO BOTAO_NAO_PRESSIONADO
    
    BTFSC ACAO
    GOTO LE_BOTAO
    
    DECFSZ FILTRO, F
    GOTO LE_BOTAO
    
    BSF ACAO
    BTFSS LAMP
    GOTO ACENDE_LAMPADA
    
    BCF LAMP
    GOTO LE_BOTAO
    
ACENDE_LAMPADA
    BSF LAMP
    GOTO LE_BOTAO
    
BOTAO_NAO_PRESSIONADO
    MOVLW .100
    MOVWF FILTRO
    BCF ACAO
    GOTO LE_BOTAO

    END

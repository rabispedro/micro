; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

 ; SETUP
RES_VECT  CODE    0x0000            ; processor reset vector
    BSF STATUS, RP0                        ; Ativa o BIT RP0  na posição STATUS
    BCF TRISA, 0                              ; Desativa o BIT 0 na posição TRISA
    BCF STATUS, RP0                       ; Desativa o BIT RP0 na posição STATUS
    BCF PORTA, 0                            ; Desativa o BIT 0 na posição PORTA
  
LOOP_MAIN
    BTFSS PORTA, 1
    GOTO BOTAO_PRESSIONADO
    BCF PORTA, 0
    GOTO LOOP_MAIN
  
BOTAO_PRESSIONADO
    BSF PORTA,0
    GOTO LOOP_MAIN

    END
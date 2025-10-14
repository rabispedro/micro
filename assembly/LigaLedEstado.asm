; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

 #define BANK0 BCF STATUS, RP0
 
 
 ; SETUP
RES_VECT  CODE    0x0000            ; processor reset vector
    BSF STATUS, RP0                        ; seleciona banco de memoria RAM 1
    BCF TRISA, 0                              ; configura o bit 0 do PORTA como sa�da
    BCF STATUS, RP0                       ; seleciona o banco de memoria RAM 0
    BCF PORTA, 0                            ; apaga a lampada
    
    
INICIALIZA_CONTADOR
    MOVLW .100                            ; w = 100
    MOVWF 0x20                           ; [0x20] CONTADOR = 100
 
PONTO_1
    BTFSC PORTA, 1                        ; testa se o bot�o est� pressionado
    GOTO INICIALIZA_CONTADOR  ; se n�o estiver pressionado pula para o PONTO_1
    
    DECFSZ 0X20, F                        ; [0x20] CONTADOR-- e testa se chegou a 0
    GOTO PONTO_1                        ; se n�o zerou, volta para o teste do bot�o
    
    BTFSS PORTA, 0                        ; testa se a lampada est� acesa
    GOTO ACENDE_LAMPADA
    BCF PORTA, 0                           ; apaga a lampada
    
PONTO_2
    BTFSC PORTA, 1                         ; testa se  o bot�o est� pressionado
    GOTO INICIALIZA_CONTADOR   ; bot�o solto, voltar � execu��o normal
    GOTO PONTO_2                         ; continua testando o bot�o
 
 ACENDE_LAMPADA
    BSF PORTA, 0
    GOTO PONTO_2
    
    END

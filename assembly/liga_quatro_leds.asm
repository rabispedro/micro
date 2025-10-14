; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

; void setup()
RES_VECT  CODE    0x0000                              ; processor reset vector
	 ; seleciona o BANK 1
	BSF  STATUS,  RP0
	BCF  STATUS,  RP1
	
	BSF TRISA, 1                                   ; configura o bit 1 do PORTA como entrada (RA1)
	BSF TRISA, 2                                   ; configura o bit 2 do PORTA como entrada (RA2)
	BSF TRISA, 3                                   ; configura o bit 3 do PORTA como entrada (RA3)
	BSF TRISA, 4                                   ; configura o bit 4 do PORTA como entrada (RA4)
	
	BCF TRISB, 0                                   ; configura o bit 0 do PORTB como saída (RB0)
	BCF TRISB, 1                                   ; configura o bit 1 do PORTB como saída (RB1)
	BCF TRISB, 2                                   ; configura o bit 2 do PORTB como saída (RB2)
	BCF TRISB, 3                                   ; configura o bit 3 do PORTB como saída (RB3)
	
	; seleciona o BANK 0
	BCF STATUS, RP0
	BCF STATUS, RP1
	
	BCF PORTB, 0                                  ; apaga o bit 0 da lâmpada (RB0)
	BCF PORTB, 1                                  ; apaga o bit 1 da lâmpada (RB1)
	BCF PORTB, 2                                  ; apaga o bit 2 da lâmpada (RB2)
	BCF PORTB, 3                                  ; apaga o bit 3 da lâmpada (RB3)
	
LOOP_1
	BTFSC PORTA, 1                             ; testa se RA1 está acionado
	GOTO LOOP_1                                ; RA1 não está acionado, retorna para o teste de RA1
	
	; RA1 foi acionado
	MOVLW 0X1                                   ; máscara 0001 (ou seja, primeiro LED)
	XORWF  PORTB, F                           ; RB0 = !RB0 e segue para LOOP_2

LOOP_2
	BTFSC PORTA, 2                             ; testa se RA2 está acionado
	GOTO LOOP_2                                ; RA2 não está acionado, retorna para o teste de RA2
	
	; RA2 foi acionado
	MOVLW 0x2                                   ; máscara 0010 (ou seja, segundo LED)
	XORWF PORTB, F                            ; RB1 = !RB1 e segue para LOOP_3

LOOP_3
	BTFSC PORTA, 3                             ; testa se RA3 está acionado
	GOTO LOOP_3                                ; RA3 não está acionado, retorna para o teste de RA3
	
	; RA3 foi acionado
	MOVLW 0X4                                   ; máscara 0100 (ou seja, terceiro LED)
	XORWF PORTB, F                            ; RB2 = !RB2 e segue para LOOP_4

LOOP_4
	BTFSC PORTA, 4                             ; testa se RA4 está acionado
	GOTO LOOP_4                                ; RA4 não está acionado, retorna para o teste de RA4
	
	; RA4 foi acionado
	MOVLW 0X8                                   ; máscara 1000 (ou seja, quarto LED)
	XORWF PORTB, F                            ; RB3 = !RB3 e volta para LOOP_1

	GOTO LOOP_1

    END

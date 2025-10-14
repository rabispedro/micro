; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0  BCF STATUS, RP0
#define BANK1  BSF STATUS, RP0

CBLOCK 0x20
	FILTRO_PROGRESSIVO
	FILTRO_REGRESSIVO
	FLAGS
	UNIDADE
ENDC

CBLOCK 0X30											; inicio do vetor de dados para o display: codigos[10]
	CODIGO_0
	CODIGO_1
	CODIGO_2
	CODIGO_3
	CODIGO_4
	CODIGO_5
	CODIGO_6
	CODIGO_7
	CODIGO_8
	CODIGO_9
ENDC

; variáveis
#define ACAO_PROGRESSIVA FLAGS, 0
#define ACAO_REGRESSIVA FLAGS, 1

; entradas
#define B_ZERAR PORTA, 1
#define B_CONTAR_PROGRESSIVO PORTA, 2
#define B_CONTAR_REGRESSIVO PORTA, 3

; saídas
#define DISPLAY PORTB

; constantes
V_FILTRO equ .100

; void setup()
RES_VECT CODE 0x0000								; processor reset vector
    BANK1
    CLRF TRISB										; todos os pinos são saídas

    BANK0
    ; inicializando o vetor
    MOVLW 0xFE
    MOVWF CODIGO_0
    MOVLW 0x38
    MOVWF CODIGO_1
    MOVLW 0xDD
    MOVWF CODIGO_2
    MOVLW 0x7D
    MOVWF CODIGO_3
    MOVLW 0x3B
    MOVWF CODIGO_4
    MOVLW 0x77
    MOVWF CODIGO_5
    MOVLW 0xF7
    MOVWF CODIGO_6
    MOVLW 0x3C
    MOVWF CODIGO_7
    MOVLW 0xFF
    MOVWF CODIGO_8
    MOVLW 0x7F
    MOVWF CODIGO_9

    CLRF UNIDADE									; unidade = 0
    BCF ACAO_PROGRESSIVA							; acao_progressiva = false
    BCF ACAO_REGRESSIVA								; acao_regressiva = false

    MOVLW V_FILTRO									; w = 100
    MOVWF FILTRO_PROGRESSIVO						; filtro_progressivo = 100
    MOVLW V_FILTRO
    MOVWF FILTRO_REGRESSIVO							; filtro_regressivo = 100

    CALL ATUALIZA_DISPLAY							; chama a subrotina 'ATUALIZA_DISPLAY'

MAIN
    BTFSS B_ZERAR									; if(b_zerar)
    GOTO B_ZERAR_PRESSIONADO

    BTFSS B_CONTAR_PROGRESSIVO						; if(b_contar_progressivo)
    GOTO B_PROGRESSIVO_PRESSIONADO

    BTFSS B_CONTAR_REGRESSIVO						; if(b_regressivo)
    GOTO B_REGRESSIVO_PRESSIONADO

    ; nenhum botão pressionado, resetar botões
    MOVLW V_FILTRO									; w = 100
    MOVWF FILTRO_PROGRESSIVO						; filtro_progressivo = 100
    MOVLW V_FILTRO									; w = 100
    MOVWF FILTRO_REGRESSIVO							; filtro_regressivo = 100
    BSF ACAO_PROGRESSIVA							; acao_progressiva = true
    BSF ACAO_REGRESSIVA								; acao_regressiva = true

    GOTO MAIN

B_ZERAR_PRESSIONADO
    CLRF UNIDADE									; unidade = 0
    CALL ATUALIZA_DISPLAY

    GOTO MAIN

B_PROGRESSIVO_PRESSIONADO
    BTFSS ACAO_PROGRESSIVA							; if (acao_progressivo)
    GOTO MAIN

    DECFSZ FILTRO_PROGRESSIVO, F					; if(--filtro_progressivo)
    GOTO MAIN

    BCF ACAO_PROGRESSIVA							; acao_progressiva = false
    INCF UNIDADE, F			    					; unidade++

    MOVLW .10			    						; w = 10
    SUBWF UNIDADE, W		    					; w = w - unidade

    BTFSC STATUS, C			    					; if (C == 0), ou seja, if (unidade == 10)
    CLRF UNIDADE			    					; unidade = 0

    CALL ATUALIZA_DISPLAY

	GOTO MAIN

B_REGRESSIVO_PRESSIONADO
	BTFSS ACAO_REGRESSIVA							; if (acao_regressiva)
	GOTO MAIN

	DECFSZ FILTRO_REGRESSIVO, F						; if(--filtro_regressivo)
	GOTO MAIN

	BCF ACAO_REGRESSIVA								; acao_regressiva = false
	DECF UNIDADE, F								    ; unidade--

	MOVLW .1										; w = 1
	ADDWF UNIDADE, W								; w = w - unidade

	BTFSC STATUS, C									; if (C == 0), ou seja, if (unidade == -1)
	CALL REINICIA_CONTADOR_REGRESSIVO

	CALL ATUALIZA_DISPLAY

	GOTO MAIN

REINICIA_CONTADOR_REGRESSIVO
	MOVLW .9										; w = 9
	MOVWF UNIDADE									; unidade = 9

	RETURN

ATUALIZA_DISPLAY
	MOVLW 0x30							; w = *vetor
	MOVWF FSR							; ponteiro de memória indireta (FSR) = *vetor

	MOVF UNIDADE, W						; w = unidade
	ADDWF FSR, F						; fsr = vetor[unidade]

	MOVF INDF, W						; w = vetor[unidade]
	MOVWF DISPLAY						; display = vetor[unidade]

	RETURN

	END
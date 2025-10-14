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
	DELAY_3
	FLAGS
	UNIDADE
ENDC

; inicio do vetor de dados para o display: codigos[10]
CBLOCK 0X30
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
#define ESTADO_PROGRESSIVO FLAGS, 1
#define ESTADO_REGRESSIVO FLAGS, 2
#define ESTADO_PARADO FLAGS, 3

; entradas
#define B_ZERAR PORTA, 1
#define B_CONTAR_PROGRESSIVO PORTA, 2
#define B_CONTAR_REGRESSIVO PORTA, 3
#define B_PARAR PORTA, 4

; saídas
#define DISPLAY PORTB

; constantes
V_DELAY_1 equ .4
V_DELAY_2 equ .250
V_DELAY_3 equ .250

; void setup()
; processor reset vector
RES_VECT    CODE    0x0000
	BANK1
	; todos os pinos são saídas
	CLRF TRISB

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

	; unidade = 0
	CLRF UNIDADE
	; estado_progressivo = false
	BCF ESTADO_PROGRESSIVO
	; estado_regressivo = false
	BCF ESTADO_REGRESSIVO
	; estado_parado = true
	BSF ESTADO_PARADO

	; chama a subrotina 'ATUALIZA_DISPLAY'
	CALL ATUALIZA_DISPLAY

MAIN
    ; Verificação de botões
    ; if(b_parar)
    BTFSS B_PARAR
    CALL B_PARAR_PRESSIONADO

    ; if(b_zerar)
    BTFSS B_ZERAR
    CALL B_ZERAR_PRESSIONADO

    ; if(b_contar_progressivo)
    BTFSS B_CONTAR_PROGRESSIVO
    CALL B_PROGRESSIVO_PRESSIONADO

	; if(b_regressivo)
    BTFSS B_CONTAR_REGRESSIVO
    CALL B_REGRESSIVO_PRESSIONADO

    ; Verificação de estados
    ; if(estado_parado)
    BTFSC ESTADO_PARADO
    GOTO MAIN

    ; if (estado_progressivo)
    BTFSC ESTADO_PROGRESSIVO
    GOTO CONTAGEM_PROGRESSIVA

    ; if (estado_regressivo)
    BTFSC ESTADO_REGRESSIVO
    GOTO CONTAGEM_REGRESSIVA

    GOTO MAIN

B_PARAR_PRESSIONADO
    BCF ESTADO_PROGRESSIVO
    BCF ESTADO_REGRESSIVO
    BSF ESTADO_PARADO

    RETURN

B_ZERAR_PRESSIONADO
    ; if (estado_parado)
    BTFSS ESTADO_PARADO
    RETURN

    ; unidade = 0
    CLRF UNIDADE
    BCF ESTADO_PROGRESSIVO
    BCF ESTADO_REGRESSIVO
    BSF ESTADO_PARADO

    CALL ATUALIZA_DISPLAY

    RETURN

B_PROGRESSIVO_PRESSIONADO
    ; if (estado_parado)
    BTFSS ESTADO_PARADO
    RETURN

    BSF ESTADO_PROGRESSIVO
    BCF ESTADO_REGRESSIVO
    BCF ESTADO_PARADO

    RETURN

B_REGRESSIVO_PRESSIONADO
    ; if (estado_parado)
    BTFSS ESTADO_PARADO
    RETURN

    BCF ESTADO_PROGRESSIVO
    BSF ESTADO_REGRESSIVO
    BCF ESTADO_PARADO

    RETURN

CONTAGEM_PROGRESSIVA
	; unidade++
    INCF UNIDADE, F

	; w = 10
    MOVLW .10
	; w = w - unidade
    SUBWF UNIDADE, W

	; if (C == 0), ou seja, if (unidade == 10), então unidade = 0
    BTFSC STATUS, C
    CLRF UNIDADE

    CALL DELAY
    CALL ATUALIZA_DISPLAY

    GOTO MAIN

CONTAGEM_REGRESSIVA
	; unidade--
    DECF UNIDADE, F

	; w = 1
    MOVLW .1
	; w = w - unidade
    ADDWF UNIDADE, W

	; if (C == 0), ou seja, if (unidade == -1), então unidade = 9
    BTFSC STATUS, C
    CALL REINICIA_CONTADOR_REGRESSIVO

    CALL DELAY
    CALL ATUALIZA_DISPLAY

    GOTO MAIN

REINICIA_CONTADOR_REGRESSIVO
    ; w = 9
	MOVLW .9
	; unidade = 9
    MOVWF UNIDADE

    RETURN

ATUALIZA_DISPLAY
    ; w = *vetor
	MOVLW 0x30
	; ponteiro de memória indireta (FSR) = *vetor
    MOVWF FSR

	; w = unidade
    MOVF UNIDADE, W
	; fsr = vetor[unidade]
    ADDWF FSR, F

	; w = vetor[unidade]
    MOVF INDF, W
	; display = vetor[unidade]
    MOVWF DISPLAY

    RETURN

DELAY
	; delay1 = 4
    MOVLW V_DELAY_1
    MOVWF DELAY_1

INICIALIZA_DELAY_2
	; delay2 = 250
    MOVLW V_DELAY_2
    MOVWF DELAY_2

INICIALIZA_DELAY_3
    ; delay3 = 250
	MOVLW V_DELAY_3
    MOVWF DELAY_3

DECREMENTA_DELAY
    NOP

	; if(--delay3), então DECREMENTA_DELAY
    DECFSZ DELAY_3, F
    GOTO DECREMENTA_DELAY

    ; NOP
	; if(--delay2), então DECREMENTA_DELAY
    DECFSZ DELAY_2, F
    GOTO INICIALIZA_DELAY_3

	; if(--delay1), então INICIALIZA_DELAY_2
    DECFSZ DELAY_1, F
    GOTO INICIALIZA_DELAY_2

    RETURN

	END
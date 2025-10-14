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
    F_INCREMENTAR
    F_DECREMENTAR
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

; inicio do vetor de dados para o display: delays[10]
CBLOCK 0X40
    TIMER_0
    TIMER_1
    TIMER_2
    TIMER_3
    TIMER_4
    TIMER_5
    TIMER_6
    TIMER_7
    TIMER_8
    TIMER_9
ENDC	
    
; variáveis
#define E_PARADO FLAGS, 0
#define A_INCREMENTAR FLAGS, 1
#define A_DECREMENTAR FLAGS, 2

; entradas
#define B_LIGA PORTA, 1
#define B_DESLIGA PORTA, 2
#define B_INCREMENTAR PORTA, 3
#define B_DECREMENTAR PORTA, 4

; saídas
#define DISPLAY PORTB
#define LED PORTA, 0

; constantes
V_FILTRO  equ .100
V_DELAY_2 equ .50
V_DELAY_3 equ .250

; void setup()
; processor reset vector
RES_VECT    CODE    0x0000
    BANK1
    ; todos os pinos são saídas
    CLRF TRISB
    BCF TRISA, 0
    
    BSF TRISA, 1
    BSF TRISA, 2
    BSF TRISA, 3
    BSF TRISA, 4

    BANK0
    ; inicializando o vetor codigos[10]
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

    ; inicializando o vetor delays[10]
    MOVLW .20
    MOVWF TIMER_0
    MOVLW .16
    MOVWF TIMER_1
    MOVLW .12
    MOVWF TIMER_2
    MOVLW .10
    MOVWF TIMER_3
    MOVLW .8
    MOVWF TIMER_4
    MOVLW .6
    MOVWF TIMER_5
    MOVLW .5
    MOVWF TIMER_6
    MOVLW .4
    MOVWF TIMER_7
    MOVLW .3
    MOVWF TIMER_8
    MOVLW .2
    MOVWF TIMER_9

    ; unidade = 0
    CLRF UNIDADE
    
    ; acao_incrementar = false
    BCF A_INCREMENTAR
    
    ; acao_decrementar = false
    BCF A_DECREMENTAR
    
    ; estado_parado = true
    BSF E_PARADO

    ; chama a subrotina 'ATUALIZA_DISPLAY'
    CALL ATUALIZA_DISPLAY

MAIN
    ; if(b_zerar)
    BTFSS B_LIGA
    GOTO B_LIGA_PRESSIONADO
    
    ; if(b_contar_progressivo)
    BTFSS B_INCREMENTAR
    GOTO B_INCREMENTAR_PRESSIONADO

    ; if(b_regressivo)
    BTFSS B_DECREMENTAR
    GOTO B_DECREMENTAR_PRESSIONADO
    
    ; filtor_incrementar = filtro_decrementar = 100
    MOVLW V_FILTRO
    MOVWF F_INCREMENTAR
    MOVWF F_DECREMENTAR
    
    ; acao_incrementar = true
    BSF A_INCREMENTAR
    
    ; acao_decrementar = true
    BSF A_DECREMENTAR
    
    ; if(estado_parado)
    BTFSC E_PARADO
    GOTO MAIN

    ; Verificação de botões
    ; if(b_parar)
    BTFSS B_DESLIGA
    GOTO B_DESLIGA_PRESSIONADO
    
    CALL DELAY
    CALL ATUALIZA_DISPLAY
    
    ; led = !led
    MOVLW 0X1 ; máscara 0001 (ou seja, LED)
    XORWF PORTA, F

    GOTO MAIN
    
B_DESLIGA_PRESSIONADO
    ; estado_parado = true
    BSF E_PARADO
    
    ; led = false
    BCF LED
    
    GOTO MAIN
    
B_LIGA_PRESSIONADO
    ; estado_parado
    BCF E_PARADO
    
    ; led = true
    BSF LED
    
    GOTO MAIN

B_INCREMENTAR_PRESSIONADO
    ; if (estado_parado)
    BTFSS E_PARADO
    GOTO MAIN
    
    ; if(acao_incrementar)
    BTFSS A_INCREMENTAR
    GOTO MAIN
    
    ; if(--filtro_incrementar)
    DECFSZ F_INCREMENTAR, F
    GOTO MAIN
    
    ; acao_incrementar = false
    BCF A_INCREMENTAR
    
    ; unidade++
    INCF UNIDADE, F

    ; w = 10
    MOVLW .10
    
    ; w = w - unidade
    SUBWF UNIDADE, W

    ; if (C == 0), ou seja, if (unidade == 10), então unidade = 0
    BTFSC STATUS, C
    CLRF UNIDADE

    GOTO MAIN

B_DECREMENTAR_PRESSIONADO
    ; if (estado_parado)
    BTFSS E_PARADO
    GOTO MAIN
    
    ; if(acao_decrementar)
    BTFSS A_DECREMENTAR
    GOTO MAIN
    
    ; if(--filtro_decrementar)
    DECFSZ F_DECREMENTAR, F
    GOTO MAIN
    
    ; acao_decrementar = true
    BCF A_DECREMENTAR
    
    ; unidade--
    DECF UNIDADE, F

    ; w = 1
    MOVLW .1
    
    ; w = w - unidade
    ADDWF UNIDADE, W

    ; if (C == 0), ou seja, if (unidade == -1), então unidade = 9
    BTFSC STATUS, C
    CALL REINICIA_CONTADOR_REGRESSIVO

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
    ; w = *delays
    MOVLW 0x40
    
    ; ponteido de memória indireta (FSR) = *delays
    MOVWF FSR
    
    ; w = unidade
    MOVF UNIDADE, W
    
    ; fsr = delays[unidade]
    ADDWF FSR, F
    
    ; w = delays[unidade]
    MOVF INDF, W
    
    MOVWF DELAY_1

INICIALIZA_DELAY_2
    ; delay2 = 50
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

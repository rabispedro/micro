; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define ZERO 0xFE
#define UM 0x38
#define DOIS 0xDD
#define TRES 0x7D
#define QUATRO 0x3B
#define CINCO 0x77
#define SEIS 0xF7
#define SETE 0x3C
#define OITO 0xFF
#define NOVE 0x7F

 #define BANK0  BCF STATUS, RP0
 #define BANK1  BSF STATUS, RP0
 
 CBLOCK 0x20
    FILTRO
    FLAGS
    UNIDADE
ENDC

CBLOCK 0X30	    ; inicio do vetor de dados para o display: CODIGOS[10]
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
#define ACAO FLAGS, 0
    
; entradas
#define B_CONTAR PORTA, 1
#define B_ZERAR PORTA, 2
    
; saídas
#define DISPLAY PORTB

; constantes
V_FILTRO equ .100

; void setup()
RES_VECT  CODE    0x0000	     ; processor reset vector
    BANK1
    CLRF TRISB		     ; todos os pinos são saídas
    
    BANK0
    ; inicializando o vetor
    MOVLW ZERO
    MOVWF CODIGO_0
    MOVLW UM
    MOVWF CODIGO_1
    MOVLW DOIS
    MOVWF CODIGO_2
    MOVLW TRES
    MOVWF CODIGO_3
    MOVLW QUATRO
    MOVWF CODIGO_4
    MOVLW CINCO
    MOVWF CODIGO_5
    MOVLW SEIS
    MOVWF CODIGO_6
    MOVLW SETE
    MOVWF CODIGO_7
    MOVLW OITO
    MOVWF CODIGO_8
    MOVLW NOVE
    MOVWF CODIGO_9
  
    CLRF UNIDADE		    ; unidade = 0
    BCF ACAO		    ; acao = false
    MOVLW V_FILTRO		    ; w = 100
    MOVWF FILTRO		    ; filtro = w

    CALL ATUALIZA_DISPLAY	    ; chama a subrotina 'ATUALIZA_DISPLAY'

MAIN
    BTFSS B_ZERAR			     ; if(b_zerar)
    GOTO B_ZERAR_PRESSIONADO
    
    BTFSC B_CONTAR			     ; if(!b_contar) 
    GOTO B_CONTAR_NAO_PRESSIONADO
    
    BTFSC ACAO			    ; if (!acao)
    GOTO MAIN
    
    DECFSZ FILTRO, F			     ; if(--filtro)
    GOTO MAIN
    
    BSF ACAO			    ; acao = true
    INCF UNIDADE, F			    ; unidade++
    
    MOVLW .10			    ; w = 10
    SUBWF UNIDADE, W		    ; w = w - unidade
    
    BTFSC STATUS, C			    ; if (C == 0) , ou seja, if (10 < unidade)
    CLRF UNIDADE			    ; unidade = 0
    
    CALL ATUALIZA_DISPLAY
    
    GOTO MAIN

    
B_ZERAR_PRESSIONADO
    CLRF UNIDADE			; unidade = 0
    CALL ATUALIZA_DISPLAY
    
    GOTO MAIN

B_CONTAR_NAO_PRESSIONADO
    MOVLW V_FILTRO			; w = 100
    MOVWF FILTRO			; filtro = w
    BCF ACAO			; acao = false
    
    GOTO MAIN
    
ATUALIZA_DISPLAY
    MOVLW 0x30			 ; w = *vetor
    MOVWF FSR			 ; ponteiro de memória indireta (FSR) = *vetor
    MOVF UNIDADE, W			 ; w = unidade
    ADDWF FSR, F			 ; fsr = vetor[unidade]
    MOVF INDF, W			 ; w = vetor[unidade]
    MOVWF DISPLAY			 ; display = vetor[unidade
    
    RETURN
    
    END
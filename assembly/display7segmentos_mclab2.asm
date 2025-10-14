; PIC16F877A Configuration Bit Settings

; Assembly source line config statements

#include "p16f877a.inc"

; CONFIG
; __config 0xFF71
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

#define BANK0  BCF STATUS, RP0
#define BANK1  BSF STATUS, RP0

CBLOCK 0x20
    TEMPO_1S
    UNIDADE
    DEZENA
    CENTENA
    MILHAR
    FLAGS
    W_TEMP
    S_TEMP
ENDC

; entradas
#define INICIAR PORTB,0
#define PARAR PORTB, 1
#define ZERAR PORTB, 2

; sa�das
#define DISPLAYS PORTD
#define D_UNIDADE PORTB, 4
#define D_DEZENA PORTB, 5
#define D_CENTEZA PORTB, 6
#define D_MILHAR PORTB, 7
    
; constantes
V_TMR0 equ .131
V_TEMPO_1S equ .125

; vari�veis
 #define FIM_1S FLAGS, 0
 #define FIM_8MS FLAGS, 1
 #define CONTANDO FLAGS, 2
 #define INCREMENTO FLAGS, 3
 
; void setup()
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

ISR_VECT       CODE    0x0004           ; interrupt vector location
       ; salvou STATUS e W em vari�veis para n�o perder o valor dentro da interrup��o
       MOVWF W_TEMP ; 
       MOVF STATUS, W	; 
       MOVWF S_TEMP ; 

       BTFSS INTCON, T0IF   ; if(!T0IF), ou seja, testa se a interrup��o n�o foi por TMR0
       GOTO SAI_INTERRUPCAO
       
       ; resetando o contador de 1 segundo
       BCF INTCON, T0IF	; limpar o bit de status do TMR0
       
       ; deu o tempo de 8ms
       BSF FIM_8MS
       
       MOVLW V_TMR0	; w = 131
       ADDWF TMR0, F	; TMR0 += 131

       DECFSZ TEMPO_1S, F ; if(--tempo_1s)
       GOTO SAI_INTERRUPCAO
       
       ; contador zerou, deu o tempo de 250ms
       BSF FIM_1S
       
       ; resetar o contador
       MOVLW V_TEMPO_1S
       MOVWF TEMPO_1S
       
SAI_INTERRUPCAO
       MOVF S_TEMP, W ; restaurar valor de STATUS para antes da interrup��o
       MOVWF STATUS
       MOVF W_TEMP, W ; restaurar valor de W para antes da interrup��o

    RETFIE

CODIGO
    ADDWF PCL, F
    
    ; carregando na mem�ria
    RETLW 0x3F
    RETLW 0x06
    RETLW 0x5B
    RETLW 0x4F
    RETLW 0x66
    RETLW 0x6D
    RETLW 0x7D
    RETLW 0x07
    RETLW 0x7F
    RETLW 0x6F

START
    BANK1
    CLRF TRISD	; configura todo o PORTD como sa�da
    MOVLW 0xF	; mascara '00001111' para acionar o TRISB com 4 portas como entrada e 4 portas como sa�da
    MOVWF TRISB

    ; Configurando o TMR0: PC <1:4>
    MOVLW B'11010101'	; palavra de configura��o do TMR0
    ; bit 7: RBPU - resistor PULLUP  PORTB
    ; bit 6: INTDEG - define a borda da int RB0/INT
    ; bit 5: T0CS - fonte do clock TMR0, definido como fonte interna
    ; bit 4: T0SE - borda do clock externo
    ; bit 3: PSA - quem usa o prescaler (PS), definido para uso do TMR0
    ; bit 2..0: PS<2:0> - sele�ao da escala do prescaler (PS), definido para 64
    
    ; carrega a palavra de configura��o do TMR0
    MOVWF OPTION_REG
    
    BANK0
    CLRF UNIDADE	; unidade = 0
    CLRF DEZENA	; dezena = 0
    CLRF CENTENA	; centeza = 0
    CLRF MILHAR	; milhar = 0
    
    MOVLW V_TEMPO_1S
    MOVWF TEMPO_1S ; tempo_1s = 125
    
    CLRF FLAGS	; fim_1s = fim_8ms = contando = false
    
    CLRF PORTB	; apagar todo o  display de 7 segmentos
    
    BSF CONTANDO
    BSF INCREMENTO
    
    ; Ajuste do contador para contar de 255 para 131
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE ; habilita atender interrup��o por TMR0
    BSF INTCON, GIE ; habilita atender interrup��es

    GOTO MAIN

MAIN
    BTFSC FIM_8MS ; if(fim_8s)
    CALL TROCA_DISPLAY
    
    BTFSC CONTANDO ; if(contando)
    GOTO QUAL_CONTANDO
    
    BTFSS INICIAR ; if(!iniciar)
    GOTO INCREMENTAR_PRESSIONADO
;    
    BTFSS PARAR
    GOTO DECREMENTAR_PRESSIONADO
    
    BTFSC ZERAR	; if(zerar)
    GOTO MAIN
    
    CLRF UNIDADE
    CLRF DEZENA
    
    GOTO MAIN

INCREMENTAR_PRESSIONADO
    BSF INCREMENTO
    BSF CONTANDO
    
    GOTO MAIN

DECREMENTAR_PRESSIONADO
    BCF INCREMENTO
    BSF CONTANDO
    
    GOTO MAIN
    
QUAL_CONTANDO
    BTFSS INCREMENTO
    GOTO CONTANDO_REGRESSIVO
    
    GOTO CONTANDO_PROGRESSIVO
    
    
CONTANDO_PROGRESSIVO
    BTFSS PARAR	; if(!parar)
    GOTO PARAR_PRESSIONADO
    
    BTFSS FIM_1S	; if(!fim_1s)
    GOTO MAIN
    
    INCF UNIDADE, F	; unidade++
    
    BCF FIM_1S
    
    MOVLW .10
    SUBWF UNIDADE, W ; w = unidade - 10
    
    BTFSS STATUS, C	; if(unidade < 10)
    GOTO MAIN
    
    CLRF UNIDADE
    INCF DEZENA, F	; dezena++
    
    MOVLW .10
    SUBWF DEZENA, W
    
    BTFSC STATUS, C	; if(dezena > 10)
    CLRF DEZENA
    
    GOTO MAIN

CONTANDO_REGRESSIVO
    BTFSS PARAR	; if(!parar)
    GOTO PARAR_PRESSIONADO
    
    BTFSS FIM_1S	; if(!fim_1s)
    GOTO MAIN
    
    BCF FIM_1S
    
    DECF UNIDADE, F	; unidade--
    
    MOVLW .1
    ADDWF UNIDADE, W ; w = unidade - 1
    
    BTFSC STATUS, C	; if(unidade < 10)
    GOTO DECREMENTAR_UNIDADE
    
    GOTO MAIN

DECREMENTAR_UNIDADE
    MOVLW .9
    MOVWF UNIDADE
    
    DECF DEZENA, F	; dezena--
    
    MOVLW .1
    ADDWF DEZENA, W
    
    BTFSC STATUS, C	; if(dezena > 10)
    CALL DECREMENTAR_DEZENA
    
    GOTO MAIN

DECREMENTAR_DEZENA
    MOVLW .9
    MOVWF DEZENA
    RETURN
    
INICIAR_PRESSIONADO
    MOVLW V_TEMPO_1S
    MOVWF TEMPO_1S ; contador = 125
    BSF CONTANDO ; contando = true
    
    GOTO MAIN

PARAR_PRESSIONADO
    BCF CONTANDO	; contando = false
    
    GOTO MAIN

TROCA_DISPLAY
    BCF FIM_8MS	; fim_8ms = false
    
    BTFSS D_UNIDADE ; if(d_unidade)
    GOTO TESTA_DEZENA
    
    BCF D_UNIDADE
    
    MOVF DEZENA, W
    CALL CODIGO
    
    MOVWF DISPLAYS
    
    BSF D_DEZENA
    
    RETURN

TESTA_DEZENA
    BCF D_DEZENA
    
    MOVF UNIDADE, W
    CALL CODIGO
    
    MOVWF DISPLAYS
    
    BSF D_UNIDADE
    
    RETURN
    
    END
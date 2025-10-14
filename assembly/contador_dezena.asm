; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0  BCF STATUS, RP0
#define BANK1  BSF STATUS, RP0

CBLOCK 0x20
    TEMPO_1S
    UNIDADE
    DEZENA
    FLAGS
    W_TEMP
    S_TEMP
ENDC

; entradas
#define ZERAR PORTA,1
#define INICIAR PORTA, 2
#define PARAR PORTA, 3
#define QUAL_DISPLAY PORTB, 4

; saídas
#define DISPLAYS PORTB

; constantes
V_TMR0 equ .131
V_TEMPO_1S equ .125

; variáveis
 #define FIM_1S FLAGS, 0
 #define FIM_8MS FLAGS, 1
 #define CONTANDO FLAGS, 2
 
; void setup()
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

ISR_VECT       CODE    0x0004           ; interrupt vector location
       ; salvou STATUS e W em variáveis para não perder o valor dentro da interrupção
       MOVWF W_TEMP ; 
       MOVF STATUS, W	; 
       MOVWF S_TEMP ; 

       BTFSS INTCON, T0IF   ; if(!T0IF), ou seja, testa se a interrupção não foi por TMR0
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
       MOVF S_TEMP, W ; restaurar valor de STATUS para antes da interrupção
       MOVWF STATUS
       MOVF W_TEMP, W ; restaurar valor de W para antes da interrupção

    RETFIE

CODIGO
    ADDWF PCL, F
    
    ; carregando na memória
    RETLW 0xFE
    RETLW 0x38
    RETLW 0xDD
    RETLW 0x7D
    RETLW 0x3B
    RETLW 0x77
    RETLW 0xF7
    RETLW 0x3C
    RETLW 0xFF
    RETLW 0x7F
    
;    RETLW B'11111110'
;    RETLW B'00111000'
;    RETLW B'11011101'
;    RETLW B'01111101'
;    RETLW B'00111011'
;    RETLW B'01110111'
;    RETLW B'11110111'
;    RETLW B'00111100'
;    RETLW B'11111111'
;    RETLW B'01111111'

START
    BANK1
    CLRF TRISB	; configura todo o PORTB como saída

    ; Configurando o TMR0: PC <1:4>
    MOVLW B'11010101'	; palavra de configuração do TMR0
    ; bit 7: RBPU - resistor PULLUP  PORTB
    ; bit 6: INTDEG - define a borda da int RB0/INT
    ; bit 5: T0CS - fonte do clock TMR0, definido como fonte interna
    ; bit 4: T0SE - borda do clock externo
    ; bit 3: PSA - quem usa o prescaler (PS), definido para uso do TMR0
    ; bit 2..0: PS<2:0> - seleçao da escala do prescaler (PS), definido para 64
    
    ; carrega a palavra de configuração do TMR0
    MOVWF OPTION_REG
    
    BANK0
    CLRF UNIDADE	; unidade = 0
    CLRF DEZENA	; dezena = 0
    
    MOVLW V_TEMPO_1S
    MOVWF TEMPO_1S ; tempo_1s = 125
    
    CLRF FLAGS	; fim_1s = fim_8ms = contando = false
    
    ; Ajuste do contador para contar de 255 para 131
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE ; habilita atender interrupção por TMR0
    BSF INTCON, GIE ; habilita atender interrupções

    GOTO MAIN

MAIN
    BTFSC FIM_8MS ; if(fim_8s)
    CALL TROCA_DISPLAY
    
    BTFSC CONTANDO ; if(contando)
    GOTO ESTA_CONTANDO
    
    BTFSS INICIAR ; if(!iniciar)
    GOTO INICIAR_PRESSIONADO
    
    BTFSC ZERAR	; if(zerar)
    GOTO MAIN
    
    CLRF UNIDADE
    CLRF DEZENA
    
    GOTO MAIN

ESTA_CONTANDO
    BTFSS PARAR	; if(!parar)
    GOTO PARAR_PRESSIONADO
    
    BTFSS FIM_1S	; if(!fim_1s)
    GOTO MAIN
    
;    BCF FIM_1
    
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
    
    BTFSS QUAL_DISPLAY ; if(qual_display)
    GOTO DEZENA_ACESA
    
    MOVF DEZENA, W
    CALL CODIGO
    
    ANDLW B'11101111'	; máscara XXX0-XXXX
    MOVWF DISPLAYS
    
    RETURN

DEZENA_ACESA
    MOVF UNIDADE, W
    CALL CODIGO
    
    MOVWF DISPLAYS
    
    RETURN
    
    END
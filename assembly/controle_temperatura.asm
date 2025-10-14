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
    M_H
    M_L
    S_H
    S_L
    R_H
    R_L
    VALOR_ADC_H
    VALOR_ADC_L
    W_TEMP
    S_TEMP
ENDC

; entradas
#define B_ACIONA_SENSOR PORTB, 0
#define B_ACIONA_POTENCIOMETRO PORTB, 1
#define B_INICIAR PORTB, 2
#define B_PARAR PORTB, 3

; saídas
#define D_UNIDADE PORTB, 4
#define D_DEZENA PORTB, 5
#define D_CENTENA PORTB, 6
#define D_MILHAR PORTB, 7
#define FAN PORTC, 1
#define HEATHER PORTC, 2
#define DISPLAYS PORTD

; constantes
V_TMR0 equ .131
V_TEMPO_1S equ .10

; variáveis
 #define FIM_1S FLAGS, 0
 #define FIM_8MS FLAGS, 1
 #define NEGATIVO FLAGS, 2
 
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
    CLRF TRISD	; configura todo o PORTD como saída
    
    MOVLW 0xF
    MOVWF TRISB
    
    BCF FAN
    BCF HEATHER
    
    ; Configurando ADCCONS1
    MOVLW B'10000100'
    ; bit 7: ADFM - justificado à direita
    ; bit 6: ADCS2 - configuração do clock do conversor (clock interno)
    ; bit 5..4: bits não usados
    ; bit 3..0: PCFG<3:0> - define as portas a serem usadas
    
    ; carrega a palavra de configuração no ADCON1
    MOVWF ADCON1

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
    
    ; Configurando ADCCONS0
    MOVLW B'11001001'
    ; bit 7..6: ADCS2 - configuração do clock do conversor (clock interno)
    ; bit 5..3: CHS<2:0> - selecionao o canal a ser lido
    ; bit 2: GO/DONE - inicia a conversão e informa o fim
    ; bit 1: bit não usado
    ; bit 0: ADON - liga conversor AD
    
    ; carrega a palavra de configuração no ADCON0
    MOVWF ADCON0
    
    CLRF UNIDADE	; unidade = 0
    CLRF DEZENA	; dezena = 0
    CLRF CENTENA	; centeza = 0
    CLRF MILHAR	; milhar = 0
    
    BCF FAN
    BSF HEATHER
    
    MOVLW V_TEMPO_1S
    MOVWF TEMPO_1S ; tempo_1s = 125
    
    CLRF FLAGS	; fim_1s = fim_8ms = negativo = false
    
    CLRF PORTB	; apagar todo o  display de 7 segmentos
    
    ; Ajuste do contador para contar de 255 para 131
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE ; habilita atender interrupção por TMR0
    BSF INTCON, GIE ; habilita atender interrupções

    GOTO MAIN

MAIN
    BTFSC FIM_8MS ; if(fim_8s)
    CALL TROCA_DISPLAY
    
    BTFSS FIM_1S    ; if(fim_1s) 
    GOTO MAIN
    
    BCF FIM_1S
    
    BSF ADCON0, GO ; ativa a conversão
    
    BTFSC ADCON0, GO ; if(!go), ou seja, testa se a conversão acabou
    GOTO $-1	; se não acabou, testa novamente
    
    MOVF ADRESH, W  ; w = adresh
    MOVWF VALOR_ADC_H ; valor_adc = adresh
    
    BANK1
    MOVF ADRESL, W
    
    BANK0
    MOVWF VALOR_ADC_L
    CLRF DEZENA
    CLRF CENTENA
    CLRF MILHAR
    
TESTAR_MILHAR
    MOVLW 0x03
    MOVWF S_H
    
    MOVLW 0xE8
    MOVWF S_L
    
    MOVF VALOR_ADC_H, W
    MOVWF M_H
    
    MOVF VALOR_ADC_L, W
    MOVWF M_L
    
    CALL SUBTRACAO_16BITS
    
    BTFSC NEGATIVO
    GOTO TESTAR_CENTENA
    
    MOVF R_H, W
    MOVWF VALOR_ADC_H
    
    MOVF R_L, W
    MOVWF VALOR_ADC_L
    
    INCF MILHAR, F
    
    GOTO TESTAR_MILHAR

TESTAR_CENTENA
    MOVLW 0x00
    MOVWF S_H
    
    MOVLW 0x64
    MOVWF S_L
    
    MOVF VALOR_ADC_H, W
    MOVWF M_H
    
    MOVF VALOR_ADC_L, W
    MOVWF M_L
    
    CALL SUBTRACAO_16BITS
    
    BTFSC NEGATIVO
    GOTO TESTAR_DEZENA
    
    MOVF R_H, W
    MOVWF VALOR_ADC_H
    
    MOVF R_L, W
    MOVWF VALOR_ADC_L
    
    INCF CENTENA, F
    
    GOTO TESTAR_CENTENA
    
TESTAR_DEZENA
    MOVLW .10	; w = 10
    
    SUBWF VALOR_ADC_L, W	; w = valor_adc - 10
    
    BTFSS STATUS, C ; if (valor_adc - 10 > 0)
    GOTO TESTAR_UNIDADE
    
    MOVWF VALOR_ADC_L	; valor_adc = (valor_adc - 10)
    INCF DEZENA, F		; dezena++
    
    GOTO TESTAR_DEZENA

TESTAR_UNIDADE
    MOVF VALOR_ADC_L, W	; w = valor_adc
    
    MOVWF UNIDADE		; unidade = w
    
    GOTO MAIN
    
SUBTRACAO_16BITS
    BCF NEGATIVO
    
    MOVF S_L, W
    SUBWF M_L, W
    MOVWF R_L
   
    BTFSS STATUS, C
    BSF NEGATIVO
    
    MOVF S_H, W
    SUBWF M_H, W
    MOVWF R_H
   
    BTFSS STATUS, C
    GOTO EH_NEGATIVO
    
    BTFSS NEGATIVO
    RETURN
    
    MOVLW .1
    SUBWF R_H, F
    
    BTFSS STATUS, C
    GOTO EH_NEGATIVO
    
    BCF NEGATIVO
    RETURN
    
EH_NEGATIVO
    BSF NEGATIVO
    RETURN
    
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
    
TESTA_MILHAR
    BCF D_MILHAR
    
    MOVF UNIDADE, W
    CALL CODIGO
    
    MOVWF DISPLAYS
    
    BSF D_UNIDADE
    
    RETURN
    
TESTA_CENTENA
    BTFSS D_CENTENA
    GOTO TESTA_MILHAR
    
    BCF D_CENTENA
    
    MOVF MILHAR, W
    CALL CODIGO
    
    MOVWF DISPLAYS
    
    BSF D_MILHAR
    
    RETURN
    
TESTA_DEZENA
    BTFSS D_DEZENA
    GOTO TESTA_CENTENA
    
    BCF D_DEZENA
    
    MOVF CENTENA, W
    CALL CODIGO
    
    MOVWF DISPLAYS
    
    BSF D_CENTENA
    
    RETURN
    
    END

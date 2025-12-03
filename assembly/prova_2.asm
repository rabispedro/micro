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
    F_MUDA_DISPLAY
    F_HISTERESE
    F_PROCESSO
    VALOR_DIFERENCA
    VALOR_SET_POINT
    VALOR_HISTERESE
    VALOR_TEMPERATURA
    VALOR_SET_POINT_NEGATIVO
    VALOR_SET_POINT_POSITIVO
    VALOR_ADC
    FLAGS
    FLAGS_ACAO
    W_TEMP
    S_TEMP
ENDC

; entradas
#define B_PROCESSO PORTB, 0
#define B_MUDA_DISPLAY PORTB, 1
#define B_INCREMENTA_HISTERESE PORTB, 2
#define B_DECREMENTA_HISTERESE PORTB, 3
    
; saídas
#define DISPLAYS PORTD
#define D_UNIDADE PORTB, 4
#define D_DEZENA PORTB, 5
#define D_CENTENA PORTB, 6
#define D_MILHAR PORTB, 7
#define HEATER PORTC, 2
#define FAN PORTC, 1 

; constantes
V_TMR0 equ .131
V_TEMPO_1S equ .10
V_LIMITE_SUPERIOR_SET_POINT equ .185
V_LIMITE_INFERIOR_SET_POINT equ .85
V_LIMITE_SUPERIOR_HISTERESE equ .10
V_LIMITE_INFERIOR_HISTERESE equ .1
V_FILTRO equ .100

; variáveis
 #define FIM_1S FLAGS, 0
 #define FIM_8MS FLAGS, 1
 #define E_HISTERESE FLAGS, 2
 #define E_SET_POINT FLAGS, 3
 #define E_PROCESSO FLAGS, 4
 #define E_TEMPERATURA FLAGS, 5
 
 #define A_MUDA_DISPLAY FLAGS_ACAO, 0
 #define A_HISTERESE FLAGS_ACAO, 1
 #define A_PROCESSO FLAGS_ACAO, 2
 
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
    BCF HEATER
    
    ; Configurando ADCCONS1
    MOVLW B'00000100'
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
    
    CLRF VALOR_DIFERENCA		; valor_diferenca = 0
    CLRF VALOR_HISTERESE		; valor_histerese = 0
    CLRF VALOR_TEMPERATURA		; valor_temperatura = 0
    CLRF VALOR_SET_POINT		; valor_set_point = 0
    CLRF VALOR_SET_POINT_NEGATIVO	; valor_set_point_negativo = 0
    CLRF VALOR_SET_POINT_POSITIVO	; valor_set_point_positivo = 0
    
    MOVLW .5
    MOVWF VALOR_HISTERESE   ; valor_histerese = 5

    MOVLW V_TEMPO_1S
    MOVWF TEMPO_1S ; tempo_1s = 125
    
    CLRF FLAGS	; fim_1s = fim_8ms = estado_potenciometro = false
    CLRF FLAGS_ACAO
    BCF FAN
    BCF HEATER
    
    ; estado_inicial => potenciometro ligado
    MOVLW .1
    MOVWF MILHAR
    BSF E_SET_POINT
    BCF E_TEMPERATURA
    BCF E_HISTERESE
    
    MOVLW V_FILTRO
    MOVWF F_MUDA_DISPLAY
    MOVWF F_HISTERESE
    MOVWF F_PROCESSO
    
    BSF A_MUDA_DISPLAY
    BSF A_HISTERESE
    BSF A_PROCESSO
    
    CLRF PORTB	; apagar todo o  display de 7 segmentos
    
    ; Ajuste do contador para contar de 255 para 131
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE ; habilita atender interrupção por TMR0
    BSF INTCON, GIE ; habilita atender interrupções

    GOTO MAIN

MAIN
    ; Processa botões de entrada
    BTFSS B_PROCESSO
    GOTO B_PROCESSO_PRESSIONADO
    
    BTFSS B_MUDA_DISPLAY
    GOTO B_MUDA_DISPLAY_PRESSIONADO
    
    BTFSS B_INCREMENTA_HISTERESE
    GOTO B_INCREMENTA_HISTERESE_PRESSIONADO
    
    BTFSS B_DECREMENTA_HISTERESE
    GOTO B_DECREMENTA_HISTERESE_PRESSIONADO
    
    BTFSC FIM_8MS ; if(fim_8s)
    CALL TROCA_DISPLAY
    
    BTFSS FIM_1S    ; if(fim_1s) 
    GOTO MAIN
    
    BCF FIM_1S
    
    MOVLW V_FILTRO
    MOVWF F_MUDA_DISPLAY
    MOVWF F_HISTERESE
    MOVWF F_PROCESSO
    
    BSF A_MUDA_DISPLAY
    BSF A_HISTERESE
    BSF A_PROCESSO
    
    ; Escolhe entre sensor e potenciometro
    CALL ACIONA_SENSOR
    
    BTFSC E_SET_POINT
    CALL ACIONA_POTENCIOMETRO
    
    BSF ADCON0, GO ; ativa a conversão
    
    BTFSC ADCON0, GO ; if(!go), ou seja, testa se a conversão acabou
    GOTO $-1	; se não acabou, testa novamente
    
    MOVF ADRESL, W  ; w = adresl
    MOVWF VALOR_ADC ; valor_adc = adres_low
    
    BTFSC E_TEMPERATURA
    MOVWF VALOR_TEMPERATURA
    
    BTFSC E_SET_POINT
    MOVWF VALOR_SET_POINT	; valor_potenciometro = adres_low
    
    BTFSC E_SET_POINT
    CALL AJUSTE_SET_POINT
    
    BTFSC E_HISTERESE
    CALL AJUSTE_HISTERESE
    
    BTFSC E_PROCESSO
    CALL TESTA_FAN
    
    CLRF DEZENA
    CLRF CENTENA
    
    GOTO TESTAR_CENTENA

AJUSTA_SET_POINT_COM_HISTERESE
     ; Ajuste set_point_negativo
    MOVF VALOR_SET_POINT, W ; w = valor_set_point
    MOVWF VALOR_SET_POINT_NEGATIVO  ;	valor_set_point_negativo = valor_set_point
    MOVF VALOR_HISTERESE, W ; w = valor_histerese
    
    SUBWF VALOR_SET_POINT_NEGATIVO, F	; valor_set_point_negativo = valor_set_point - valor_histerese
    
    ; Ajuste set_point_positivo
    MOVF VALOR_SET_POINT, W ; w = valor_set_point
    MOVWF VALOR_SET_POINT_POSITIVO  ; valor_set_point_positivo = valor_set_point
    MOVF VALOR_HISTERESE, W ; w = valor_histerese
    
    ADDWF VALOR_SET_POINT_POSITIVO, F	; valor_set_point_positivo = valor_set_point + valor_histerese
    
    RETURN
    
AJUSTE_SET_POINT
     ; Controle de Limites 
     ; valor_potenciometro = minimo entre valor_potenciometro e 185
    MOVLW V_LIMITE_SUPERIOR_SET_POINT ; w = 185
    MOVWF VALOR_DIFERENCA   ; valor_diferenca = 185
    MOVF VALOR_SET_POINT, W	; w = valor_potenciometro
    
    SUBWF VALOR_DIFERENCA, W	; valor_diferenca - valor_potenciometro
    
    BTFSS STATUS, C ; if(185 - valor_potenciometro)
    GOTO AJUSTA_LIMITE_SUPERIOR

    ; valor_potenciometro = maximo entre valor_potenciometro e 85
    MOVF VALOR_SET_POINT, W	; w = valor_potenciometro
    MOVWF VALOR_DIFERENCA		; valor_diferenca = valor_potenciometro
    MOVLW V_LIMITE_INFERIOR_SET_POINT		; w = 85
    
    SUBWF VALOR_DIFERENCA, W
    
    BTFSS STATUS, C ; if (valor_potenciometro - 85)
    GOTO AJUSTA_LIMITE_INFERIOR
    
    CALL AJUSTA_SET_POINT_COM_HISTERESE
    
    ; valor dentro do limite
    RETURN

AJUSTA_LIMITE_SUPERIOR
    MOVLW V_LIMITE_SUPERIOR_SET_POINT
    MOVWF VALOR_SET_POINT
    
    CALL AJUSTA_SET_POINT_COM_HISTERESE
    
    RETURN

AJUSTA_LIMITE_INFERIOR
    MOVLW V_LIMITE_INFERIOR_SET_POINT
    MOVWF VALOR_SET_POINT
    
    CALL AJUSTA_SET_POINT_COM_HISTERESE
    
    RETURN

AJUSTE_HISTERESE
    MOVF VALOR_HISTERESE, W
    MOVWF VALOR_ADC
    
    RETURN
    
TESTA_FAN 
    ; valor_set_point_negativo < valor_adc < valor_set_point_positivo
    
    ; testa se temperatura atual está abaixo
    MOVF VALOR_SET_POINT_NEGATIVO, W
    MOVWF VALOR_DIFERENCA   ; valor_diferenca = valor_adc
    
    MOVF VALOR_TEMPERATURA, W	; w = valor_set_point_negativo
    SUBWF VALOR_DIFERENCA, W	; w = valor_adc - valor_set_point_negativo
    
    BTFSC STATUS, C ; if (valor_set_point_negativo - valor_adc < 0)
    GOTO SOBE_TEMPERATURA
    
    ; testa se temperatura atual está acima
    MOVF VALOR_TEMPERATURA, W
    MOVWF VALOR_DIFERENCA
    
    MOVF VALOR_SET_POINT_POSITIVO, W	; w = valor_set_point
    SUBWF VALOR_DIFERENCA, W	; w = valor_set_point_positivo - valor_adc
    
    BTFSC STATUS, C ; if (valor_set_point_negativo - valor_adc)
    GOTO DESCE_TEMPERATURA
    
    RETURN
    
SOBE_TEMPERATURA
    ; valor_adc < valor_set_point_negativo
    BSF HEATER
    BCF FAN
    
    RETURN
    
DESCE_TEMPERATURA
    ; valor_set_point_positivo < valor_adc
    BCF HEATER
    BSF FAN
    
    RETURN

B_PROCESSO_PRESSIONADO
    BTFSS A_PROCESSO
    GOTO MAIN
    
    DECFSZ F_PROCESSO, F
    GOTO MAIN
    
    BCF A_PROCESSO
    
    ; estado_processo = !estado_processo
    BTFSC E_PROCESSO
    GOTO DESLIGA_PROCESSO
    
    BSF E_PROCESSO
    
    GOTO MAIN

DESLIGA_PROCESSO
    BCF E_PROCESSO
    
    GOTO MAIN

B_MUDA_DISPLAY_PRESSIONADO
    BTFSS A_MUDA_DISPLAY
    GOTO MAIN
    
    DECFSZ F_MUDA_DISPLAY, F
    GOTO MAIN
    
    BCF A_MUDA_DISPLAY
    
    BTFSC E_HISTERESE
    GOTO ACIONA_VALOR_SET_POINT
    
    ; if(e_set_point)
    ; estado_display => !estado_set_point, estado_temperatura, !estado_histerese
    BTFSC E_SET_POINT
    GOTO ACIONA_VALOR_TEMPERATURA

    ; if (e_temperatura)
    ; estado_display => !estado_set_point, !estado_temperatura, estado_histerese
    BTFSC E_TEMPERATURA
    GOTO ACIONA_VALOR_HISTERESE
    
    GOTO MAIN

ACIONA_VALOR_SET_POINT
    ; set_point => !estado_set_point && !estado_temperatura && estado_histerese
    
    BSF E_SET_POINT
    BCF E_TEMPERATURA
    BCF E_HISTERESE
    
    MOVLW .1
    MOVWF MILHAR
    
    GOTO MAIN
    
ACIONA_VALOR_TEMPERATURA
    ; estado_temperatura => estado_set_point && !estado_temperatura && !estado_histerese
    
    BCF E_SET_POINT
    BSF E_TEMPERATURA
    BCF E_HISTERESE
    
    MOVLW .2
    MOVWF MILHAR
    
    GOTO MAIN

ACIONA_VALOR_HISTERESE
     ; estado_histerese => !estado_set_point && estado_temperatura && !estado_histerese
    
    BCF E_SET_POINT
    BCF E_TEMPERATURA
    BSF E_HISTERESE
    
    MOVLW .3
    MOVWF MILHAR
    
    GOTO MAIN
    
B_INCREMENTA_HISTERESE_PRESSIONADO
    BTFSS E_HISTERESE
    GOTO MAIN
    
    BTFSC E_PROCESSO
    GOTO MAIN
    
    BTFSS A_HISTERESE
    GOTO MAIN
    
    DECFSZ F_HISTERESE, F
    GOTO MAIN
    
    BCF A_HISTERESE
    
    INCF VALOR_HISTERESE, F ; valor_histerese++
    
    MOVLW V_LIMITE_SUPERIOR_HISTERESE
    SUBWF VALOR_HISTERESE, W
    
    BTFSC STATUS, C ; if (valor_histerese - 10)
    GOTO AJUSTA_LIMITE_SUPERIOR_HISTERESE
    
    GOTO MAIN

AJUSTA_LIMITE_SUPERIOR_HISTERESE
    MOVLW V_LIMITE_SUPERIOR_HISTERESE
    MOVWF VALOR_HISTERESE   ; valor_histerese = 10
    
    GOTO MAIN
    
B_DECREMENTA_HISTERESE_PRESSIONADO
    BTFSS E_HISTERESE
    GOTO MAIN
    
    BTFSC E_PROCESSO
    GOTO MAIN
    
    BTFSS A_HISTERESE
    GOTO MAIN
    
    DECFSZ F_HISTERESE, F
    GOTO MAIN
    
    BCF A_HISTERESE
    
    DECF VALOR_HISTERESE, F ; valor_histerese--
    
    BTFSC STATUS, Z ; if (valor_histerese == 0)
    GOTO AJUSTA_LIMITE_INFERIOR_HISTERESE
    
    GOTO MAIN

AJUSTA_LIMITE_INFERIOR_HISTERESE
    MOVLW V_LIMITE_INFERIOR_HISTERESE
    MOVWF VALOR_HISTERESE   ; valor_histerese = 1
    
    GOTO MAIN
    
ACIONA_SENSOR
    BCF ADCON0, GO
    
    MOVLW B'11000001'
    MOVWF ADCON0
    
    RETURN
    
ACIONA_POTENCIOMETRO
    BCF ADCON0, GO
    
    MOVLW B'11001001'
    MOVWF ADCON0
    
    RETURN
    
TESTAR_CENTENA
    MOVLW .100	; w = 100
    
    SUBWF VALOR_ADC, W	; w = valor_adc - 100
    
    BTFSS STATUS, C ; if (valor_adc - 100 > 0)
    GOTO TESTAR_DEZENA
    
    MOVWF VALOR_ADC	; valor_adc = (valor_adc - 100)
    INCF CENTENA, F		; centena++
    
    GOTO TESTAR_CENTENA
    
TESTAR_DEZENA
    MOVLW .10	; w = 10
    
    SUBWF VALOR_ADC, W	; w = valor_adc - 10
    
    BTFSS STATUS, C ; if (valor_adc - 10 > 0)
    GOTO TESTAR_UNIDADE
    
    MOVWF VALOR_ADC	; valor_adc = (valor_adc - 10)
    INCF DEZENA, F		; dezena++
    
    GOTO TESTAR_DEZENA

TESTAR_UNIDADE
    MOVF VALOR_ADC, W	; w = valor_adc
    
    MOVWF UNIDADE		; unidade = w
    
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
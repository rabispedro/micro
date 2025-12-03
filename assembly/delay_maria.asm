; PIC16F877A Configuration Bit Settings
#include "p16f877a.inc"
; CONFIG
; __config 0xFF71
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

#define BANK0 BCF STATUS,RP0
#define BANK1 BSF STATUS,RP0

 CBLOCK 0x20
    TEMPO_1S
    UNIDADE
    DEZENA
    CENTENA
    MILHAR
    FLAGS
    VALOR_ADC
    W_TEMP
    S_TEMP
    FILTRO_P
    V_FILTRO
 ENDC
 
;variáveis boolenas
#define FIM_1S		FLAGS,0
#define FIM_8MS		FLAGS,1
#define ACAO_LIGA_P	FLAGS,2
 
;entradas
#define LEITOR_P	PORTB,0 ;RB0: seleciona a leitura da entrada analógica AN1 (potenciômetro);
#define LEITOR_S	PORTB,1 ;RB1: seleciona a leitura da entrada analógica AN0 (sensor de temperatura);
#define LIGA_HEATER	PORTB,2 ;RB2: liga a resistência de aquecimento (HEATER);
#define DESLIGA_HEATER  PORTB,3 ;RB3: desliga a resistência de aquecimento (HEATER)

;saídas
#define D_UNIDADE	PORTB,4  ;RB4: aciona o cátodo comum do display da UNIDADE;
#define D_DEZENA	PORTB,5  ;RB5: aciona o cátodo comum do display da DEZENA;
#define D_CENTENA	PORTB,6  ;RB6: aciona o cátodo comum do display da CENTENA;
#define D_MILHAR	PORTB,7  ;RB7: aciona o cátodo comum do display da MILHAR;
#define DISPLAYS	PORTD    ;RD7....RD0: acionamento dos displays de 7 segmentos(a,b,c,d,e,f,g e ponto decimal);

;#define POTENCIOMETRO   PORTA,0
;#define SENSOR          PORTA,1
#define HEATER          PORTC,2

 ;constantes
V_TMR0      equ .131
V_TEMPO_1S  equ .10 
v_FILTRO    equ .100
;=============================== programa ======================================
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

ISR_VECT  CODE    0x0004	    ; interrupt vector location
    MOVWF   W_TEMP		    ;salvar W e STATUS
    MOVF    STATUS,W		    ;nas
    MOVWF   S_TEMP		    ;variáveis temporárias
    BTFSS   INTCON,T0IF		    ;testa se a interrupção foi por TMR0
    GOTO    SAI_INTERRUPCAO	    ;se não, vaza
    BCF	    INTCON,T0IF		    ;T0IF = 0
    BSF	    FIM_8MS		    ;FIM_8MS = 1
    MOVLW   V_TMR0		    ;W = V_TMR0
    ADDWF   TMR0,F		    ;TMR0 = TMR0 + V_TMR0
    DECFSZ  TEMPO_1S,F		    ;TEMPO_1S-- e testa se zerou
    GOTO    SAI_INTERRUPCAO	    ;se não zerou, vaza
    BSF	    FIM_1S		    ;FIM_1S = 1
    MOVLW   V_TEMPO_1S		    ;W = V_TEMPO_1S
    MOVWF   TEMPO_1S		    ;TEMPO_1S = V_TEMPO_1S
SAI_INTERRUPCAO    
    MOVF    S_TEMP,W		    ;restaurar W e STATUS
    MOVWF   STATUS		    ;a partir das 
    MOVF    W_TEMP,W		    ;variáveis temporárias 
    RETFIE

CODIGO
    ADDWF   PCL,F
    RETLW   B'00111111'		    ;código do número 0
    RETLW   B'00000110'		    ;código do número 1
    RETLW   B'01011011'		    ;código do número 2
    RETLW   B'01001111'		    ;código do número 3
    RETLW   B'01100110'		    ;código do número 4
    RETLW   B'01101101'		    ;código do número 5
    RETLW   B'01111101'		    ;código do número 6
    RETLW   B'00000111'		    ;código do número 7
    RETLW   B'01111111'		    ;código do número 8
    RETLW   B'01101111'		    ;código do número 9
    
START
    BANK1			    ;seleciona banco de memória RAM 1
    CLRF    TRISC
    MOVLW   B'00000111'             ; RA0, RA1, RA2 - como entrada, RA3?RA5 como saída
    MOVWF   TRISA

    CLRF    TRISD		    ;configura todo o PORTD como saída
    MOVLW   B'00001111'		    ;configura os 4MSB do PORTB com saída
    MOVWF   TRISB		    ;e os 4LSB com entrada
    MOVLW   B'11010101'		    ;palavra de configuração do TIMER0
				    ;bit 7 - RBPU - resistor PULLUP PORTB => 1
				    ;bit 6 - INTDEG - define a borda da int. RB0/INT => 1
				    ;bit 5 - T0CS - fonte de clock TMR0: interna = 0
				    ;bit 4 - T0SE - borda do clock externa; default = 1
				    ;bit 3 - PSA - quem usa o prescaler
				    ;bit 2..0 - PS - taxa do Prescaler 1:4 => 001
    MOVWF   OPTION_REG		    ;carrega a palavra de configuração do TMR0
    MOVLW   B'00000100'		    ;palavra de configuração do ADCON1
				    ;bit 7 - ADFM - justificado à esquerda => 0
				    ;bit 6 - ADCS2 - configuração do clock do ADC => 0
				    ;bit 5..4 - não usado
				    ;bit 3..0 - PCFG3:PCFG0 - define as portas a serem usada 
    MOVWF   ADCON1		    ;carrega a palavra de configuração no ADCON1
    BANK0			    ;seleciona banco de memória RAM 0
    MOVLW   B'11001001'		    ;palavra de configuração do ADCON0
				    ;bit 7..6 - ADCS1:ADCS0 - configuração do clock do ADC
				    ;bit 5..3 - CHS2:CHS0- seleciona o canal a ser lido
				    ;bit 2 - GO/DONE inicia a conversão e informa o fim
				    ;bit 1 - não usado
				    ;bit 0 - ADON   - liga conversor AD
    MOVWF   ADCON0		    ;carrega a palavra de configuração no ADCON0
   
    
    
    ;BCF     POTENCIOMETRO
    CLRF    UNIDADE		    ;UNIDADE = 0
    CLRF    DEZENA		    ;DEZENA = 0
    CLRF    CENTENA		    ;CENTENA = 0
    MOVLW   V_FILTRO		    ;W = V_FILTRO
    MOVWF   FILTRO_P		    ;FILTRO = V_FILTRO
    BCF	    ACAO_LIGA_P		    ; ACAO_LIGA = 0
    MOVLW   V_TEMPO_1S		    ;W = V_TEMPO_1S
    MOVWF   TEMPO_1S		    ;TEMPO_1S = V_TEMPO_1S
    CLRF    FLAGS		    ;FLAGS = 0, ou seja, zera todas as variáveis booleanas
    CLRF    PORTB		    ;zera as saída do PORTB
    MOVLW   V_TMR0		    ;W = V_TMR0
    MOVWF   TMR0		    ;TMR0 = V_TMR0
    BSF	    INTCON,T0IE		    ;habilita atender interrupção por TMR0
    BSF	    INTCON,GIE		    ;habilita atender interrupções
   
    
LACO_PRINCIPAL
    BTFSC   FIM_8MS		    ;testa se passou 8ms da interrupção por TMR0
    CALL    TROCA_DISPLAY	    ;se passou, chama a sub-rotina TROCA_DISPLAY
    BTFSS   FIM_1S		    ;testa se passou 1s 
    GOTO    LACO_PRINCIPAL	    ;se não passiu 1s, pule para LACO_PRINCIPAL
    
    BTFSS   LEITOR_P
    CALL    SELECIONA_AN1
   
    BTFSS   LEITOR_S
    CALL    SELECIONA_AN0
     
    BTFSS   DESLIGA_HEATER
    CALL    DESLIGA
    
    BTFSS   LIGA_HEATER
    CALL    LIGA
    
    CALL    CONVERTER
    
    GOTO    LACO_PRINCIPAL

SELECIONA_AN0
    MOVLW   B'11000001'     ; CHS2:CHS0 = 000 ? AN0, ADON = 1
    MOVWF   ADCON0
;    CALL    CONVERTER
    RETURN 
    
SELECIONA_AN1
    MOVLW   B'11001001'     ; CHS2:CHS0 = 001 ? AN1, ADON = 1
    MOVWF   ADCON0
;    CALL    CONVERTER
    RETURN
    
CONVERTER
     BCF     FIM_1S		    ;FIM_1S = 0
     BSF     ADCON0,GO		    ;ativa a conversão
     BTFSC   ADCON0,GO		    ;testa se a conversão acabou
     GOTO    $-1	            ;se não acabou, testa de novo
     MOVF    ADRESH,W		    ;W = ADRESH
     MOVWF   VALOR_ADC		    ;VALOR_ADC = ADRESH
     CLRF    DEZENA		    ;DEZENA = 0
     CLRF    CENTENA		    ;CENTENA = 0
     GOTO    TESTAR_CENTENA                                                                                                                                        
     
LIGA
     BSF     HEATER
     RETURN

DESLIGA
     BCF     HEATER
     RETURN
     
TESTAR_CENTENA
    MOVLW   .100		    ;W = 100
    SUBWF   VALOR_ADC,W		    ;W = VALOR_ADC - 100
    BTFSS   STATUS,C		    ;testa se o resultado é positivo
    GOTO    TESTAR_DEZENA	    ;se não for positivo, pule para TESTAR_DEZENA
    MOVWF   VALOR_ADC		    ;VALOR_ADC = VALOR_ADC - 100
    INCF    CENTENA,F		    ;CENTENA++
    GOTO    TESTAR_CENTENA	    ; pule para TESTAR_CENTENA 
    
TESTAR_DEZENA
    MOVLW   .10			    ;W = 10
    SUBWF   VALOR_ADC,W		    ;W = VALOR_ADC - 10
    BTFSS   STATUS,C		    ;testa se o resultado é positivo
    GOTO    TESTAR_UNIDADE	    ;se não for positivo, pule para TESTAR_UNIDADE
    MOVWF   VALOR_ADC		    ;VALOR_ADC = VALOR_ADC - 10
    INCF    DEZENA,F		    ;DEZENA++
    GOTO    TESTAR_DEZENA	    ; pule para TESTAR_DEZENA   
TESTAR_UNIDADE 
    MOVF    VALOR_ADC,W		    ;W = VALOR_ADC
    MOVWF   UNIDADE		    ;UNIDADE = VALOR_ADC
    GOTO    LACO_PRINCIPAL	    ;pule para LACO_PRINCIPAl
    
TROCA_DISPLAY
    BCF	    FIM_8MS		    ;FIM_8MS = 0
    BTFSS   D_UNIDADE		    ;testa se o display da UNIDADE estáa aceso
    GOTO    TESTA_DEZENA	    ;se não estiver, pule para TESTA_DEZENA
    BCF	    D_UNIDADE		    ;desativa o display da UNIDADE
    MOVF    DEZENA,W		    ;W = DEZENA
    CALL    CODIGO		    ;chama a sub-rotina de busca do código do display
    MOVWF   DISPLAYS		    ;PORTB = W
    BSF	    D_DEZENA		    ;ativa o display da DEZENA
    RETURN
TESTA_DEZENA
    BTFSS   D_DEZENA		    ;testa se o display da DEZENA está aceso
    GOTO    TESTA_CENTENA	    ;se não estiver, pule para TESTA_CENTENA    
    BCF	    D_DEZENA		    ;desativa o display da DEZENA
    MOVF    CENTENA,W		    ;W = CENTENA
    CALL    CODIGO		    ;chama a sub-rotina de busca do código do display
    MOVWF   DISPLAYS		    ;PORTB = W
    BSF	    D_CENTENA		    ;ativa o display da CENTENA
    RETURN  
TESTA_CENTENA  
    BCF	    D_CENTENA		    ;desativa o display da CENTENA
    MOVF    UNIDADE,W		    ;W = UNIDADE
    CALL    CODIGO		    ;chama a sub-rotina de busca do código do display
    MOVWF   DISPLAYS		    ;PORTB = W
    BSF	    D_UNIDADE		    ;ativa o display da UNIDADE
    RETURN   
    
    END
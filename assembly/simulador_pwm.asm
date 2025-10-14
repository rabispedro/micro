#include "p16f628a.inc"

; CONFIG
; __config 0xFF78
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF
 
#define BANK0	    BCF	STATUS,RP0
#define BANK1	    BSF	STATUS,RP0
 
    CBLOCK 0x20
	FILTRO_INCREMENTO
	FILTRO_DECREMENTO
	CONTADOR
	LARGURA
	UNIDADE
	DEZENA
	TEMPO_1MS
	FLAGS
	W_TEMP
	S_TEMP
    ENDC
    
; vari�veis
#define FIM_1MS		    FLAGS,0
#define ACAO_INCREMENTO	    FLAGS,1
#define ACAO_DECREMENTO	    FLAGS,2
#define ACAO_LIGA	    FLAGS,3

; entradas
#define LIGAR	     PORTA,1
#define DESLIGAR     PORTA,2
#define	INCREMENTA   PORTA,3
#define DECREMENTA   PORTA,4
#define QUAL_DISPLAY PORTB,4
    
; sa�das
#define LAMPADA	    PORTA,0
#define DISPLAYS    PORTB
    
; constantes
V_TMR0	    EQU	    .131	    ; (125u = 1u * NP * Ps) => NP = 125 / Ps (para Ps = 1, NP = 125) => TMR0 = (256-125) = 131 
V_FILTRO    EQU	    .100
	  

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
	    
ISR_VECT  CODE    0x0004            ; interrupt vector location
    MOVWF   W_TEMP		    ; salvar W e STATUS
    MOVF    STATUS,W		    ; nas vari�veis tempor�rias
    MOVWF   S_TEMP		    ; nas vari�veis tempor�rias
    BTFSS   INTCON,T0IF		    ; testa se a interrup��o foi por TMR0
    GOTO    SAI_INTERRUPCAO	    ; se n�o foi, vai para SAI_INTERRUPCAO
    BCF	    INTCON,T0IF		    ; se foi, T0IF = 0 (limpa o bit/flag que indicou que houve interrup��o por TMR0)
    MOVLW   V_TMR0		    ; W = V_TMR0
    ADDWF   TMR0,F		    ; TMR0 = TMR0 + W
    INCF    CONTADOR,F		    ; incrementa o valor do CONTADOR
    MOVLW   .16			    ; W = 16
    SUBWF   CONTADOR,W		    ; W = CONTADOR - 16
    BTFSC   STATUS,C		    ; testa se o resultado � positivo
    CLRF    CONTADOR		    ; se positivo, CONTADOR = 0
    
    INCF    TEMPO_1MS,F		    ; incrementa o valor de TEMPO_1MS a cada interrup��o (125us)
    MOVLW   .8			    ; W = 8
    SUBWF   TEMPO_1MS,W		    ; W = TEMPO_1MS - 8
    BTFSS   STATUS,C		    ; testa se o valor � negativo
    GOTO    VER_PWM		    ; se negativo, vai para VER_PWM
    
    CLRF    TEMPO_1MS		    ; se atingiu 1ms, volta TEMPO_1MS = 0
    BSF	    FIM_1MS		    ; indica que chegou a 1ms (FIM_1MS = 1)
    
    
VER_PWM
    BTFSS   ACAO_LIGA		    ; testa se a LAMPADA est� desligada (ACAO_LIGA = 0)
    GOTO    ZERA_PWM		    ; se ACAO_LIGA = 0, vai para ZERA_PWM para desligar a LAMPADA de fato
    MOVF    CONTADOR,W		    ; W = CONTADOR
    SUBWF   LARGURA,W		    ; W = LARGURA - CONTADOR
    BTFSS   STATUS,C		    ; testa se o resultado � negativo
    GOTO    ZERA_PWM		    ; se negativo, vai para ZERA_PWM
    MOVF    LARGURA,W		    ; se positivo, W = LARGURA
    BTFSC   STATUS,Z		    ; testa se (LARGURA - W = 0), ou seja, caso (W = LARGURA - CONTADOR) seja W = 0, tem que desligar
    GOTO    ZERA_PWM		    ; se for igual a 0, vai para ZERA_PWM
    BSF	    LAMPADA		    ; se positivo, ativa a sa�da (LAMPADA)
    GOTO    SAI_INTERRUPCAO	    ; vai para SAI_INTERRUPCAO
  
ZERA_PWM
    BCF	    LAMPADA		    ; desativa a sa�da (LAMPADA)
    GOTO    SAI_INTERRUPCAO
    
SAI_INTERRUPCAO
    MOVF    S_TEMP,W		    ;
    MOVWF   STATUS		    ;
    MOVF    W_TEMP,W		    ;
    RETFIE
    
CODIGO
    ADDWF   PCL,F		    ;
    RETLW B'11111110'		    ; c�digo bin�rio do n�mero 0
    RETLW B'00111000'		    ; c�digo bin�rio do n�mero 1
    RETLW B'11011101'		    ; c�digo bin�rio do n�mero 2
    RETLW B'01111101'		    ; c�digo bin�rio do n�mero 3
    RETLW B'00111011'		    ; c�digo bin�rio do n�mero 4
    RETLW B'01110111'		    ; c�digo bin�rio do n�mero 5
    RETLW B'11110111'		    ; c�digo bin�rio do n�mero 6
    RETLW B'00111100'		    ; c�digo bin�rio do n�mero 7
    RETLW B'11111111'		    ; c�digo bin�rio do n�mero 8
    RETLW B'01111111'		    ; c�digo bin�rio do n�mero 9
    
MAIN_PROG CODE                      ; let linker place main program
START
    BANK1			    ; seleciona o banco de mem�ria RAM 1
    BCF	    TRISA,0		    ; configura o PORTA,0 (LAMPADA) como sa�da
    CLRF    TRISB		    ; configura todo o PORTB como sa�da
    MOVLW   B'11011000'		    ; palavra de configura��o do TIMER0
    
				    ; COMENT�RIOS DE CONFIGURA��O DO TIMER0
				    ; bit 7 - RBPU - resisitor PULLUP PORTB -> 1
				    ; bit 6 - INTDEG - define a borda (subida ou descida do clock) da int. RB0/INT -> 1
				    ; bit 5 - T0CS - fonte de clock TIMER0: Interna -> 0
				    ; bit 4 - T0SE - borda (subida ou descida do clock) do clock externo
				    ; bit 3 - PSA - quem usa o Prescaler: WDT -> 1 (N�O SER� USADO)
				    ; bit 2..0 - PS - taxa do Prescaler: 1:1 -> 000 (N�O SER� USADO)
				    
    MOVWF   OPTION_REG		    ; carrega a palavra de configura��o do TIMER0 
    BANK0			    ; seleciona o banco de mem�ria RAM 0
    
    ; inicializando as vari�veis
    BCF	    LAMPADA		    ; desliga LAMPADA
    
    CLRF    CONTADOR		    ; CONTADOR = 0
    MOVLW   .0			    ; W = 7
    MOVWF   LARGURA		    ; LARGURA = W
    
    CLRF    UNIDADE		    ; UNIDADE = 0
    CLRF    DEZENA		    ; DEZENA = 0
    
    MOVLW   V_FILTRO		    ; W = V_FILTRO
    MOVWF   FILTRO_INCREMENTO	    ; FILTRO_INCREMENTO = W
    MOVWF   FILTRO_DECREMENTO	    ; FILTRO_DECREMENTO = W
    BCF	    ACAO_INCREMENTO	    ; ACAO_INCREMENTO = 0
    BCF	    ACAO_DECREMENTO	    ; ACAO_DECREMENTO = 0
    BCF	    ACAO_LIGA		    ; ACAO_LIGA = 0
    
    CLRF    FLAGS		    ; FLAGS = 0 (zera todas as vari�veis booleanas)
    MOVLW   V_TMR0		    ; W = V_TMR0
    MOVF    TMR0		    ; TMR0 = W
    
    BSF	    INTCON,T0IE		    ; habilita atender interrup��o por TRM0 (espec�fico)
    BSF	    INTCON,GIE		    ; habilita atender as interrup��es (geral)


LACO_PRINCIPAL
    BTFSC   FIM_1MS		    ; testa se j� passou 1ms
    CALL    TROCA_DISPLAY	    ; se passou, chama a sub-rotina TROCA_DISPLAY
    
    BTFSS   LIGAR		    ; testa se o bot�o LIGAR foi pressionado
    BSF	    ACAO_LIGA		    ; se sim, define ACAO_LIGA = 1
    
    BTFSS   DESLIGAR		    ; testa se o bot�o DESLIGAR foi pressionado
    BCF	    ACAO_LIGA		    ; se sim, define ACAO_DESLIGA = 0
    
    BTFSS   INCREMENTA		    ; testa se o bot�o INCREMENTA foi pressionado
    GOTO    INCREMENTA_PRESSIONADO  ; se sim, vai para a sub-rotina INCREMENTA_PRESSIONADO
    
    BTFSS   DECREMENTA		    ; testa se o bot�o DECREMENTA foi pressionado
    GOTO    DECREMENTA_PRESSIONADO  ; se sim, vai para a sub-rotina DECREMENTA_PRESSIONADO
    
    GOTO    B_NAO_PRESSIONADO
    
    
INCREMENTA_PRESSIONADO
    BTFSC   ACAO_INCREMENTO	    ; testa se ACAO_INCREMENTO = 1 (bot�o j� pressionado)
    GOTO    LACO_PRINCIPAL	    ; se sim, volta para o LACO_PRINCIPAL
    
    DECFSZ  FILTRO_INCREMENTO,F	    ; decrementa do FILTRO_INCREMENTO para apertar o bot�o novamente
    GOTO    LACO_PRINCIPAL	    ; se n�o zerou, retorna e permite apertar novamente
    
    BSF	    ACAO_INCREMENTO	    ; foi pressionado e acabou o tempo de espera, ACAO_INCREMENTO = 1
    
    INCF    LARGURA,F		    ; incrementa a largura da onda (LARGURA++)
    INCF    UNIDADE,F		    ; incrementa a unidade (UNIDADE++)
    
    ; testa se DEZENA j� � 1
    MOVLW   .1			    ; W = 1
    SUBWF   DEZENA,W		    ; W = DEZENA - 1
    BTFSC   STATUS,C		    ; testa se o resultado � positivo
    GOTO    FIM_DO_CICLO	    ; se for positivo (DEZENA = 1), vai para FIM_DO_CICLO
    ; se n�o, testa se UNIDADE passou pra 10
    MOVLW   .10			    ; W = 10
    SUBWF   UNIDADE,W		    ; W = UNIDADE - 10
    BTFSS   STATUS,C		    ; testa se o resultado � negativo
    GOTO    LACO_PRINCIPAL	    ; se for negativo, volta para LACO_PRINCIPAL
    CLRF    UNIDADE		    ; se n�o for, UNIDADE = 0
    INCF    DEZENA,F		    ; incrementa 1 na DEZENA (DEZENA++)
    
    GOTO    LACO_PRINCIPAL
    
    
DECREMENTA_PRESSIONADO
    BTFSC   ACAO_DECREMENTO	    ; testa se ACAO_DECREMENTO = 1 (bot�o j� pressionado)
    GOTO    LACO_PRINCIPAL	    ; se sim, volta para o LACO_PRINCIPAL
    
    DECFSZ  FILTRO_DECREMENTO,F	    ; decrementa do FILTRO_DECREMENTO para apertar o bot�o novamente
    GOTO    LACO_PRINCIPAL	    ; se n�o zerou, retorna e permite apertar novamente
    
    BSF	    ACAO_DECREMENTO	    ; foi pressionado e acabou o tempo de espera, ACAO_DECREMENTO = 1
    
    DECF    LARGURA		    ; decrementa a largura da onda (LARGURA--)
    DECF    UNIDADE,F		    ; decrementa a unidade (UNIDADE--)
    
    ; testa se passou pra -1
    MOVLW   .1			    ; W = 1
    ADDWF   UNIDADE,W		    ; W = UNIDADE + W
    BTFSS   STATUS,C		    ; testa se o resultado � zero
    GOTO    LACO_PRINCIPAL	    ; se n�o for zero, volta para LACO_PRINCIPAL
    MOVLW   .9			    ; se for, volta para 9
    MOVWF   UNIDADE		    ; UNIDADE = 9
    
    DECF    DEZENA,F		    ; decrementa 1 na DEZENA (DEZENA--)
    MOVLW   .1			    ; W = 1
    ADDWF   DEZENA,W		    ; W = DEZENA + W
    BTFSS   STATUS,C		    ; testa se o resultado � zero
    GOTO    LACO_PRINCIPAL	    ; se n�o for zero, volta para LACO_PRINCIPAL
    ; se for, reseta pra 16
    MOVLW   .1			    ; W = 1
    MOVWF   DEZENA		    ; DEZENA = 1
    MOVLW   .6			    ; W = 6
    MOVWF   UNIDADE		    ; UNIDADE = 6
    MOVLW   .16			    ; W = 16
    MOVWF   LARGURA		    ; reseta a LARGURA para m�xima (LARGURA = 16)
    GOTO    LACO_PRINCIPAL
    
    
FIM_DO_CICLO			    ; verifica se chegou no fim do ciclo (0 a 16)
    ; testa se UNIDADE = 6
    MOVLW   .7			    ; W = 7
    SUBWF   UNIDADE,W		    ; W = UNIDADE - 7
    BTFSS   STATUS,C		    ; testa se o resultado � negativo
    GOTO    LACO_PRINCIPAL	    ; se for negativo, volta para LACO_PRINCIPAL
    CLRF    UNIDADE		    ; UNIDADE = 0
    CLRF    DEZENA		    ; DEZENA = 0
    MOVLW   .0			    ; W = 0
    MOVWF   LARGURA		    ; reseta a LARGURA para m�nima (LARGURA = 0)
    
    GOTO    LACO_PRINCIPAL
    
    
B_NAO_PRESSIONADO		    ; reseta as vari�veis e contador FILTRO
    MOVLW	V_FILTRO	    ; W = V_FILTRO
    MOVWF	FILTRO_INCREMENTO   ; FILTRO_INCREMENTO = V_FILTRO
    MOVWF	FILTRO_DECREMENTO   ; FILTRO_DECREMENTO = V_FILTRO
    BCF		ACAO_INCREMENTO	    ; ACAO_INCREMENTO = 0
    BCF		ACAO_DECREMENTO	    ; ACAO_DECREMENTO = 0
    GOTO	LACO_PRINCIPAL
    
TROCA_DISPLAY
    BCF	    FIM_1MS		    ; FIM_1MS = 0
    BTFSS   QUAL_DISPLAY	    ; testa qual o display est� aceso (RB4)
    GOTO    DEZENA_ACESA	    ; se 0 (a dezena est� acesa), tem que colocar a unidade, ent�o vai para DEZENA_ACESA
    MOVF    DEZENA,W		    ; W = DEZENA
    CALL    CODIGO		    ; chama a sub-rotina de busca do c�digo do display
    ANDLW   B'11101111'		    ; W = W & B'11101111' (porta AND)
    MOVWF   DISPLAYS		    ; DISPLAYS = W
    
    RETURN
    
DEZENA_ACESA
    MOVF    UNIDADE,W		    ; W = UNIDADE
    CALL    CODIGO		    ; chama a sub-rotina de busca do c�digo do display
    MOVWF   DISPLAYS		    ; DISPLAYS = W
    
    RETURN

    END
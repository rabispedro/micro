; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0  BCF STATUS, RP0
#define BANK1  BSF STATUS, RP0

CBLOCK 0x20
    CONTADOR
    LARGURA
    UNIDADE
    DEZENA
    F_INCREMENTO
    F_DECREMENTO
    TEMPO_1MS
    TEMPO_2MS
    FLAGS
    W_TEMP
    S_TEMP
ENDC
    
CBLOCK 0x30
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

; entradas
#define B_LIGAR PORTA, 1
#define B_DESLIGAR PORTA, 2
#define B_INCREMENTO PORTA, 3
#define B_DECREMENTO PORTA, 4

; saídas
#define LED PORTA, 0
#define DISPLAYS PORTB
#define QUAL_DISPLAY PORTB, 4

; constantes
V_FILTRO equ .100
V_TMR0 equ .131
V_CONTADOR equ .100

; variáveis
 #define TEMPO FLAGS, 0
 #define A_INCREMENTO FLAGS, 1
 #define A_DECREMENTO FLAGS, 2
 #define E_LIGADO FLAGS, 3
 #define FIM_1MS FLAGS, 4
 #define E_PAUSADO FLAGS, 5
 #define FIM_2MS FLAGS, 6
 
; void setup()
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

ISR_VECT       CODE    0x0004           ; interrupt vector location
       MOVWF W_TEMP ; 
       MOVF STATUS, W	; 
       MOVWF S_TEMP ; 

       BTFSS INTCON, T0IF   ; if(!T0IF), ou seja, testa se a interrupção não foi por TMR0
       GOTO SAI_INTERRUPCAO
       
       ; resetando o contador
       BCF INTCON, T0IF	; limpar o bit de status do TMR0
       MOVLW V_TMR0		; w = 131
       ADDWF TMR0, F		; TMR0 += 131
       
       INCF CONTADOR, F	    ; contador++
       MOVLW .16		    ; w = 16
       SUBWF CONTADOR, W	    ; contador -= 16
       
       BTFSC STATUS, C		    ; if (contador == 0)
       CALL ZERA_CONTADOR
       
       MOVF CONTADOR, W	; w = contador
       SUBWF LARGURA, W	; w = largura - contador
       
       BTFSC STATUS, C		; 
       GOTO SAI_INTERRUPCAO
       
       BTFSS E_PAUSADO
       GOTO SAI_INTERRUPCAO
       
       ; lógica para acionar/desacionar o led
       
       ; led = !led
       
       
       ;BSF E_LIGADO		; estado_ligado = true
       GOTO SAI_INTERRUPCAO

ZERA_CONTADOR
       CLRF CONTADOR		    ; limpa contador
       BSF TEMPO		    ; tempo = true
       
       RETURN
       
SAI_INTERRUPCAO
       MOVF S_TEMP, W ; 
       MOVWF STATUS ;
       MOVF W_TEMP, W
       
    RETFIE

MAIN_PROG CODE                      ; let linker place main program

 CODIGO
    ADDWF PCL, F
    
    ; carregando os dígitos do display na memória
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
 
START
    BANK1
    CLRF TRISB	; Define os painel led como saída
    BCF TRISA, 0 	; Define pino de saída
    
    BSF TRISA, 1	; Define os pinos de entrada do botão de ligar
    BSF TRISA, 2	; Define os pinos de entrada do botão de desligar
    BSF TRISA, 3	; Define os pinos de entrada do botão de incrementar
    BSF TRISA, 4	; Define os pinos de entrada do botão de decrementar

    ; Configurando o TMR0: PC <1:4>
    MOVLW B'11010000'	; palavra de configuração do TMR0
    ; bit 7: RBPU - resistor PULLUP  PORTB
    ; bit 6: INTDEG - define a borda da int RB0/INT
    ; bit 5: T0CS - fonte do clock TMR0, definido como fonte interna
    ; bit 4: T0SE - borda do clock externo
    ; bit 3: PSA - quem usa o prescaler (PS), definido para uso do TMR0
    ; bit 2..0: PS<2:0> - seleçao da escala do prescaler (PS), definido para 2
    
    ; carrega a palavra de configuração do TMR0
    MOVWF OPTION_REG
    
    BANK0
    BCF LED			; Apaga o LED
    
    BSF E_LIGADO		; estado_ligado = true
    BCF E_PAUSADO		; estado_pausado = false
    BCF A_INCREMENTO	; acao_incremento = false
    BCF A_DECREMENTO	; acao_decremento = false
    
    CLRF CONTADOR		; contador = 0
    
    CLRF UNIDADE
    CLRF DEZENA
    
    MOVLW .2		; w = 8
    MOVWF LARGURA		; largura = 8
    
    MOVLW V_FILTRO		; w = 100
    MOVWF F_INCREMENTO	; filtro_incremento = 100
    MOVWF F_DECREMENTO	; filtro_decremento = 100
    
    ; Ajuste do contador para contar de 255 para 131
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE		; habilita atender interrupção por TMR0
    BSF INTCON, GIE		; habilita atender interrupções

    GOTO MAIN

MAIN
;    BTFSS B_LIGAR
;    GOTO B_LIGAR_PRESSIONADO
;    
;    BTFSS B_DESLIGAR
;    GOTO B_DESLIGAR_PRESSIONADO
;    
;    BTFSS B_INCREMENTO
;    GOTO B_INCREMENTO_PRESSIONADO
;    
;    BTFSS B_DECREMENTO
;    GOTO B_DECREMENTO_PRESSIONADO
;    
;    BCF FIM_1MS
;    
;    BCF A_INCREMENTO
;    BCF A_DECREMENTO
;    
;    MOVLW V_FILTRO
;    MOVWF F_INCREMENTO
;    MOVWF F_DECREMENTO
;         
;    MOVWF LARGURA		 
    
    CALL B_INCREMENTO_PRESSIONADO 
   
    
    GOTO MAIN

    
B_LIGAR_PRESSIONADO
    BSF E_LIGADO    ; estado_ligado = true
    
    GOTO MAIN
    
B_DESLIGAR_PRESSIONADO
    BCF E_LIGADO    ; estado_ligado = false
    BCF LED
    
    GOTO MAIN
    
B_INCREMENTO_PRESSIONADO
;    BTFSS A_INCREMENTO
;    GOTO MAIN
;    
;    DECFSZ F_INCREMENTO
;    GOTO MAIN
    
    ADDWF LARGURA, F	; largura++
    ADDWF UNIDADE, F
    
    MOVLW .16		; w = 16
    SUBWF LARGURA, W	; w = 16 - largura
    
    BTFSC STATUS, C
    CALL AJUSTE_INCREMENTO_DEZESSEIS
    
    MOVLW .10		; w = 10
    SUBWF LARGURA, W	; w = 10 - largura
    
    BTFSC STATUS, C
    CALL AJUSTE_INCREMENTO_DEZ
    
    CALL TROCA_DISPLAY
    
    GOTO MAIN
    
B_DECREMENTO_PRESSIONADO
;    BTFSS A_DECREMENTO
;    GOTO MAIN
;    
;    DECFSZ F_DECREMENTO
;    GOTO MAIN
    
    
    
    GOTO MAIN
    
AJUSTE_INCREMENTO_DEZESSEIS
    MOVLW .0
    MOVWF LARGURA
    MOVWF UNIDADE
    MOVWF DEZENA
    
    RETURN
    
AJUSTE_INCREMENTO_DEZ
    MOVLW .0
    MOVWF UNIDADE
    
    MOVLW .1
    MOVWF DEZENA
    
    RETURN
    



DECREMENTAR_UNIDADE
    MOVLW .9
    MOVWF UNIDADE
    
    DECF DEZENA, F	; dezena--
    
    MOVLW .1
    ADDWF DEZENA, W
    
    BTFSC STATUS, C	; if(dezena > 10)
    CALL DECREMENTAR_DEZENA
    
    RETURN

DECREMENTAR_DEZENA
    MOVLW .9
    MOVWF DEZENA
    RETURN
    
TROCA_DISPLAY
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

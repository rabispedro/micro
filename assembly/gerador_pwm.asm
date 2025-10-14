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
    ONDAS
    UNIDADE
    DEZENA
    FILTRO_INCREMENTO
    FILTRO_DECREMENTO
    TEMPO_1MS
    FLAGS
    W_TEMP
    S_TEMP
ENDC

; entradas
#define BOTAO_LIGAR PORTA,1
#define BOTAO_DESLIGAR PORTA,2
#define BOTAO_INCREMENTAR PORTA,3
#define BOTAO_DECREMENTAR PORTA,4
#define QUAL_DISPLAY PORTB, 4
    
; saídas
#define LED PORTA, 0
#define DISPLAYS PORTB

; constantes
V_TMR0 equ .131
V_CONTADOR equ .100
 V_FILTRO equ .100

; variáveis
 #define TEMPO FLAGS, 0
 #define FIM_1MS FLAGS, 1
 #define PISCANDO FLAGS, 2
 #define ACAO_INCREMENTO FLAGS, 3
 #define ACAO_DECREMENTO FLAGS, 4
 
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
       MOVLW V_TMR0	; w = 125
       ADDWF TMR0, F	; TMR0 += 125
       
       INCF CONTADOR, F	    ; contador++
       MOVLW .16		    ; w = 16
       SUBWF CONTADOR, W	    ; contador -= 16
       
       BTFSC STATUS, C		    ; if (contador == 0)
       CALL ZERA_CONTADOR
       
       MOVF CONTADOR, W	; w = contador
       SUBWF LARGURA, W	; w = largura - contador
       
       BTFSS STATUS, C		; 
       GOTO ZERA_PWM
       
       BSF PISCANDO		; Liga a lampada
       GOTO SAI_INTERRUPCAO

ZERA_CONTADOR
       CLRF CONTADOR		    ; limpa contador
       BSF TEMPO		    ; tempo = true
       
       RETURN

ZERA_PWM
      BCF PISCANDO		; Desliga a lampada
       
SAI_INTERRUPCAO
       MOVF S_TEMP, W ; 
       MOVWF STATUS ;
       MOVF W_TEMP, W
       
    RETFIE

MAIN_PROG CODE                      ; let linker place main program

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
 
START
    BANK1
    BCF TRISA, 0 	; Define pino de saída
    CLRF TRISB	; Define displays como saida

    ; Configurando o TMR0: PC <1:1>, colocando o PS para o Watch Dog
    MOVLW B'11011000'	; palavra de configuração do TMR0
    ; bit 7: RBPU - resistor PULLUP  PORTB
    ; bit 6: INTDEG - define a borda da int RB0/INT
    ; bit 5: T0CS - fonte do clock TMR0, definido como fonte interna
    ; bit 4: T0SE - borda do clock externo
    ; bit 3: PSA - quem usa o prescaler (PS), definido para uso do TMR0
    ; bit 2..0: PS<2:0> - seleçao da escala do prescaler (PS), definido para 2
    
    ; carrega a palavra de configuração do TMR0
    MOVWF OPTION_REG
    
    BANK0
    BCF LED ; Apaga o LED
    
    BCF PISCANDO		; piscando = false
    CLRF ONDAS		; ondas = 0
    CLRF CONTADOR		; contador = 0
    
    MOVLW .7		; w = 7
    MOVWF LARGURA		; largura = 7
    
    MOVLW V_FILTRO
    MOVWF FILTRO_INCREMENTO
    MOVWF FILTRO_DECREMENTO
    
    BCF ACAO_INCREMENTO
    BCF ACAO_DECREMENTO
    
    ; Ajuste do contador para contar de 255 para 131
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE ; habilita atender interrupção por TMR0
    BSF INTCON, GIE ; habilita atender interrupções 

    GOTO MAIN

MAIN
    BTFSC FIM_1MS ; if(fim_1s)
    CALL TROCA_DISPLAY
    
    ; Verifica botão
    BTFSS BOTAO_INCREMENTAR
    CALL INCREMENTO_PRESSIONADO
    
    BTFSS BOTAO_DECREMENTAR
    CALL DECREMENTO_PRESSIONADO
    
    
    BTFSC CONTANDO ; if(contando)
    GOTO ESTA_CONTANDO
    
    BTFSS INICIAR ; if(!iniciar)
    GOTO INICIAR_PRESSIONADO
    
    BTFSC ZERAR	; if(zerar)
    GOTO MAIN
    
    CLRF UNIDADE
    CLRF DEZENA
    
    GOTO MAIN
    
    
    GOTO MAIN
    
    
    
INCREMENTO_PRESSIONADO
    BTFSS ACAO_INCREMENTO
    RETURN
    
    DECFSZ FILTRO_INCREMENTO, F
    RETURN
    
    BCF ACAO_INCREMENTO
    INCF LARGURA ; largura++
    
    MOVLW .16
    SUBWF LARGURA, W
    
    BTFSC STATUS, C ; if (largura == 16) largura = 0;
    CLRF LARGURA
    
    CALL ATUALIZA_DISPLAY
    
    RETURN

DECREMENTO_PRESSIONADO
    BTFSS ACAO_DECREMENTO
    RETURN
    
    DECFSZ FILTRO_DECREMENTO, F
    RETURN
    
    BCF ACAO_DECREMENTO
    DECF LARGURA, F ; largura--;
    
    MOVLW .1
    ADDWF LARGURA, W
    
    BTFSC STATUS, C ; if (largura == -1) largura = 15;
    CALL REINICIA_LARGURA
    
    CALL ATUALIZA_DISPLAY
    
    RETURN
    
REINICIA_LARGURA
    MOVLW .15
    MOVWF LARGURA
    
    RETURN

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

REINICIA_DISPLAY
    CLRF UNIDADE
    CLRF DEZENA
    
    RETURN
    
    END

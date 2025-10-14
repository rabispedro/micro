; Aluno: Pedro Henrique Rabis Diniz
; RA: 14254711611-1
    
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
    F_PARAR
    F_INCREMENTAR
    F_DECREMENTAR
    FLAGS
    W_TEMP
    S_TEMP
ENDC

; entradas
#define B_PARAR PORTA,1
#define B_ZERAR PORTA, 2
#define B_INCREMENTAR PORTA, 3
#define B_DECREMENTAR PORTA, 4
#define QUAL_DISPLAY PORTB, 4

; saídas
#define DISPLAYS PORTB
#define LAMPADA PORTA, 0

; constantes
V_TMR0 equ .131
V_TEMPO_1S equ .125
V_FILTRO equ .100
 
; variáveis
#define FIM_1S FLAGS, 0
#define FIM_8MS FLAGS, 1
#define E_CONTANDO FLAGS, 2
#define A_PARAR FLAGS, 3
#define A_INCREMENTAR FLAGS, 4
#define A_DECREMENTAR FLAGS, 5
#define E_99 FLAGS, 6
#define E_00 FLAGS, 7

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

START
    BANK1
    CLRF TRISB    ; configura todo o PORTB como saída
    BCF LAMPADA   ; configura PORTA, 0 como saída

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
    BCF LAMPADA    ; lampada = false
    
    CLRF UNIDADE   ; unidade = 0
    CLRF DEZENA    ; dezena = 0
    
    ; tempo_1s = 125
    MOVLW V_TEMPO_1S
    MOVWF TEMPO_1S
    
    ; fim_1s = fim_8ms = estado_contando = false
    CLRF FLAGS
    
    ; acao_parar = acao_incrementar = acao_decrementar = estado_00 = true
    BSF A_PARAR
    BSF A_INCREMENTAR
    BSF A_DECREMENTAR
    BSF E_00
    
    ; filtro_incrementar = filtro_decrementar = 100
    MOVLW V_FILTRO
    MOVWF F_PARAR
    MOVWF F_INCREMENTAR
    MOVWF F_DECREMENTAR
    
    ; Ajuste do contador para contar de 255 para 131
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE ; habilita atender interrupção por TMR0
    BSF INTCON, GIE ; habilita atender interrupções

    GOTO MAIN

MAIN
    BTFSC FIM_8MS ; if(fim_8s)
    CALL TROCA_DISPLAY
    
    BTFSC FIM_1S
    CALL TEMPORIZANDO
    
    BTFSS B_PARAR ; if(!botao_parar)
    GOTO PARAR_PRESSIONADO
    
    BTFSS B_INCREMENTAR ; if(!botao_incrementar)
    GOTO INCREMENTAR_PRESSIONADO
    
    BTFSS B_DECREMENTAR ; if(!botao_decrementar)
    GOTO DECREMENTAR_PRESSIONADO
    
    BTFSS B_ZERAR	; if(!botao_zerar)
    GOTO ZERAR_PRESSIONADO
    
    BSF A_PARAR
    BSF A_INCREMENTAR
    BSF A_DECREMENTAR
    
    MOVLW V_FILTRO
    MOVWF F_PARAR
    MOVWF F_INCREMENTAR
    MOVWF F_DECREMENTAR
    
    GOTO MAIN

PARAR_PRESSIONADO
    BTFSS A_PARAR
    GOTO MAIN
    
    DECFSZ F_PARAR, F
    GOTO MAIN
    
    BCF A_PARAR
    
    MOVLW B'00000100' ; máscara para o bit 2 de FLAGS (estado_contando)
    XORWF FLAGS, F    ; alterna o valor de estado_contando
    
    ; if (!estado_contando)
    BTFSS E_CONTANDO
    GOTO MAIN
    
    ; if (estado_contando)
    MOVLW V_TEMPO_1S
    MOVWF TEMPO_1S ; contador = 125
    
    GOTO MAIN

INCREMENTAR_PRESSIONADO
    BTFSC E_CONTANDO
    GOTO MAIN
    
    BTFSC E_99
    GOTO MAIN
    
    BTFSS A_INCREMENTAR
    GOTO MAIN
    
    DECFSZ F_INCREMENTAR, F
    GOTO MAIN
    
    BCF A_INCREMENTAR
    BCF E_00    ; estado_00 = false
    
    INCF UNIDADE, F
    
    MOVLW .10
    
    SUBWF UNIDADE, W
    
    BTFSC STATUS, C
    CALL INCREMENTAR_UNIDADE
    
    GOTO MAIN

INCREMENTAR_UNIDADE
    CLRF UNIDADE
    
    INCF DEZENA, F  ; dezena++
    
    MOVLW .10
    SUBWF DEZENA, W
    
    BTFSC STATUS, C
    CALL INCREMENTAR_DEZENA
    
    
    RETURN

INCREMENTAR_DEZENA
    MOVLW .9
    MOVWF UNIDADE
    MOVWF DEZENA
    
    BSF E_99
    
    RETURN

DECREMENTAR_PRESSIONADO
    BTFSC E_CONTANDO
    GOTO MAIN
    
    BTFSC E_00
    GOTO MAIN
    
    BTFSS A_DECREMENTAR
    GOTO MAIN
    
    DECFSZ F_DECREMENTAR, F
    GOTO MAIN
    
    BCF A_DECREMENTAR
    BCF E_99    ; estado_99 = false
    
    DECF UNIDADE, F
    
    MOVLW .1
    
    ADDWF UNIDADE, W  ; if (unidade == 0)
    
    BTFSC STATUS, C
    CALL DECREMENTAR_UNIDADE
    
    GOTO MAIN

DECREMENTAR_UNIDADE
    MOVLW .9
    MOVWF UNIDADE
    
    DECF DEZENA, F	; dezena--
    
    MOVLW .1
    ADDWF DEZENA, W
    
    BTFSC STATUS, C	;
    CALL DECREMENTAR_DEZENA
    
    RETURN

DECREMENTAR_DEZENA
    MOVLW .0
    MOVWF UNIDADE
    MOVWF DEZENA
    
    BSF E_00
    
    RETURN

ZERAR_PRESSIONADO
    BTFSC E_CONTANDO
    GOTO MAIN
    
    ; zerando o temporizador
    BCF LAMPADA      ; lampada = false
    CLRF UNIDADE     ; unidade = 0
    CLRF DEZENA      ; dezena = 0
    
    GOTO MAIN

TEMPORIZANDO
    BCF FIM_1S
    
    BTFSS E_CONTANDO
    RETURN
    
    BTFSC E_00
    BSF LAMPADA
    
    BTFSC E_00
    BCF E_CONTANDO
    
    BTFSC E_00
    RETURN
    
    DECF UNIDADE, F
    
    MOVLW .1
    
    ADDWF UNIDADE, W
    
    BTFSC STATUS, C
    CALL DECREMENTAR_UNIDADE
    
    ;BSF E_00
    
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

    END
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
    FLAGS
    W_TEMP
    S_TEMP
ENDC

; entradas
#define LIGA PORTA,1
#define DESLIGA PORTA, 2
    
; saídas
#define LED PORTA, 0

; constantes
V_TMR0 equ .6
V_CONTADOR equ .250

; variáveis
 #define FIM_TEMPO FLAGS, 0
 #define PISCANDO FLAGS, 1
 
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
       MOVLW V_TMR0	; w = 6
       ADDWF TMR0	; TMR0 += 6
       
       DECFSZ CONTADOR, F ; if(--contador)
       GOTO SAI_INTERRUPCAO
       
       ; contador zerou, deu o tempo de 250ms
       BSF FIM_TEMPO
       
       ; resetar o contador
       MOVLW V_CONTADOR
       MOVWF CONTADOR
       
SAI_INTERRUPCAO
       MOVF S_TEMP, W ; 
       MOVWF STATUS ;
       MOVF W_TEMP, W
       
    RETFIE

MAIN_PROG CODE                      ; let linker place main program

START
    BANK1
    BCF TRISA, 0 	; Define pino de saída

    ; Configurando o TMR0: PC <1:4>
    MOVLW B'11010001'	; palavra de configuração do TMR0
    ; bit 7: RBPU - resistor PULLUP  PORTB
    ; bit 6: INTDEG - define a borda da int RB0/INT
    ; bit 5: T0CS - fonte do clock TMR0, definido como fonte interna
    ; bit 4: T0SE - borda do clock externo
    ; bit 3: PSA - quem usa o prescaler (PS), definido para uso do TMR0
    ; bit 2..0: PS<2:0> - seleçao da escala do prescaler (PS), definido para 4
    
    ; carrega a palavra de configuração do TMR0
    MOVWF OPTION_REG
    
    BANK0
    BCF LED ; Apaga o LED
    
    BCF PISCANDO ; piscando = false
    
    MOVLW V_CONTADOR; w = 250
    MOVWF CONTADOR ; contador = 250
    BCF FIM_TEMPO ; fim_tempo = false
    
    ; Ajuste do contador para contar de 255 para 250
    MOVLW V_TMR0
    MOVWF TMR0
    
    BSF INTCON, T0IE ; habilita atender interrupção por TMR0
    BSF INTCON, GIE ; habilita atender interrupções 

    GOTO MAIN

MAIN
    BTFSS PISCANDO ; if(!piscando)
    GOTO NAO_ATIVO
    
    BTFSS DESLIGA ; if(desliga)
    GOTO DESLIGA_PRESSIONADO
    
    BTFSS FIM_TEMPO ; if(!fim_tempo)
    GOTO MAIN
    
    BCF FIM_TEMPO ; passou 250ms
    
    MOVLW 0X1 ; aciona o bit 1
    XORWF PORTA, F    ; troca o estado atual da lâmpada
    
    GOTO MAIN
    
DESLIGA_PRESSIONADO
    BCF LED ; desliga LED
    BCF PISCANDO ; piscando = false
    
NAO_ATIVO
    BTFSC LIGA ; if (!liga)
    GOTO MAIN
    
    BSF PISCANDO
    BSF LED
    
    MOVLW V_CONTADOR; w = 250
    MOVWF CONTADOR ; contador = 250
    BCF FIM_TEMPO ; fim_tempo = false
    
    GOTO MAIN

    END
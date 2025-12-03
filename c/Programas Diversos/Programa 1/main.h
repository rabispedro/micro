#include <16F877A.h>
#device ADC = 10

#FUSES PUT		 // Power Up Timer
#FUSES BROWNOUT	 // Reset when brownout detected
#FUSES NOLVP	 // No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O
#FUSES NOCPD	 // No EE protection
#FUSES NOWRT	 // Program memory not write protected
#FUSES NOPROTECT // Code not protected from reading

#use delay(crystal = 8MHz)
#use FIXED_IO(B_outputs = PIN_B7, PIN_B6, PIN_B5, PIN_B4)
#use FIXED_IO(D_outputs = PIN_D7, PIN_D6, PIN_D5, PIN_D4, PIN_D3, PIN_D2, PIN_D1, PIN_D0)
#define B_CONTAR PIN_B0
#define B_PARAR PIN_B1
#define B_ZERAR PIN_B2

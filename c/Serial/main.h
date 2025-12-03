#include <16F877A.h>
#device ADC=10

#FUSES PUT                   	//Power Up Timer
#FUSES BROWNOUT              	//Reset when brownout detected
#FUSES NOLVP                 	//No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O
#FUSES NOCPD                 	//No EE protection
#FUSES NOWRT                 	//Program memory not write protected
#FUSES NOPROTECT             	//Code not protected from reading

#use delay(crystal=4MHz)
#use fixed_io(c_outputs=PIN_C6)
#use rs232(baud=9600, xmit=PIN_C6,rcv=PIN_C7)
#define B_0	PIN_B0
#define B_1	PIN_B1
#define B_2	PIN_B2
#define B_3	PIN_B3



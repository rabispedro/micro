#include <16F628A.h>
#device ADC=16

#FUSES PUT                   	//Power Up Timer
#FUSES MCLR                  	//Master Clear pin enabled
#FUSES NOBROWNOUT            	//No brownout reset
#FUSES NOLVP                 	//No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O
#FUSES NOCPD                 	//No EE protection
#FUSES NOPROTECT             	//Code not protected from reading

#use delay(internal=4MHz)
#use FIXED_IO( B_outputs=PIN_B3,PIN_B2,PIN_B1,PIN_B0 )
#define B_LED_0	PIN_A1
#define B_LED_1	PIN_A2
#define B_LED_2	PIN_A3
#define B_LED_3	PIN_A4
#define LED_0	PIN_B0
#define LED_1	PIN_B1
#define LED_2	PIN_B2
#define LED_3	PIN_B3



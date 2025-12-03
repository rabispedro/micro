#include <16F877A.h>
#device ADC = 10

#FUSES PUT		 // Power Up Timer
#FUSES BROWNOUT	 // Reset when brownout detected
#FUSES NOLVP	 // No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O
#FUSES NOCPD	 // No EE protection
#FUSES NOWRT	 // Program memory not write protected
#FUSES NOPROTECT // Code not protected from reading

#use delay(crystal = 8MHz)
#use rs232(baud = 9600, parity = N, xmit = PIN_C6, rcv = PIN_C7, bits = 8, stream = PORT1)
#use FIXED_IO(C_outputs = PIN_C2, PIN_C1)
#define S_1 PIN_B0
#define S_2 PIN_B1
#define S_3 PIN_B2
#define S_4 PIN_B3
#define FAN PIN_C1
#define HEATER PIN_C2

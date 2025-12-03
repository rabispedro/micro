#include <main.h>

int1 fim_2ms = 0, fim_500ms = 0, fim_5s = 0, qualLeitura = 1;
int8 qualDisplay = 0, milhar = 0, centena = 0, dezena = 0, unidade = 0, contador_2ms = 2, contador_250ms = 250, contador_500ms = 2;
int16 contador_5s = 1000, valor = 0;

BYTE CONST codigo[10] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};

void atualiza_display(void);

#INT_TIMER0
void TIMER0_isr(void)
{
	set_timer0(get_timer0());

	if (--contador_2ms)
	{
		fim_2ms = 1;
		contador_2ms = 2;
	}

	if (--contador_250ms) {
		contador_250ms = 250;
		contador_500ms--;
	}

	if (contador_500ms == 0)
	{
		fim_500ms = 1;
		contador_500ms = 2;
		contador_5s--;
	}

	if(contador_5s == 0) {
		fim_5s = 1;
		contador_5s = 1000;
	}
}

void main()
{
	setup_adc_ports(AN0_AN1_AN3);
	setup_adc(ADC_CLOCK_INTERNAL);
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_4 | RTCC_8_BIT); // 1.0 ms overflow

	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	while (TRUE)
	{
		if (fim_2ms)
		{
			fim_2ms = 0;
			atualiza_display();
		}

		if (fim_500ms)
		{
			fim_500ms = 0;
			set_adc_channel(qualLeitura);
			valor = read_adc();

			// valor = 983
			// milhar = valor / 1000 => 983 / 1000 =                                0
			// centena = (valor % 1000) / 100 => (983 % 1000) / 100 => 983 / 100 => 9
			// dezena = (((valor % 1000) % 100) / 10) => (83 / 10) =>               8
			// unidade = (valor % 10) => (983 % 10) =>                              3
			
			milhar = (valor / 1000);
			centena = ((valor % 1000) / 100);
			dezena = (((valor % 1000) % 100) / 10);
			unidade = (valor % 10);
		}
		
		if (fim_5s) {
			fim_5s = 0;
			qualLeitura = !qualLeitura;
		}
	}
}

void atualiza_display(void)
{
	switch (qualDisplay)
	{
	case 0:
		output_b(0b10000000);
		output_d(codigo[milhar]);
		break;
	case 1:
		output_b(0b01000000);
		output_d(codigo[centena]);
		break;
	case 2:
		output_b(0b00100000);
		output_d(codigo[dezena]);
		break;
	default:
		output_b(0b00010000);
		output_d(codigo[unidade]);
		break;
	}

	qualDisplay++;
	if (qualDisplay == 4)
	{
		qualDisplay = 0;
	}
}
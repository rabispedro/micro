#include <main.h>
#include <lcd_8bits.c>

int1 fim_100ms, processando, aquecendo, resfriando;
int8 contador_100ms = 100, filtro_botao = 100;
int16 potenciometro, temperatura, histeresis = 20;
float temperatura_desejada, temperatura_atual;

#INT_TIMER0
void TIMER0_isr(void)
{
	set_timer0(get_timer0() + 6);

	if (--contador_100ms)
	{
		fim_100ms = 1;
		contador_100ms = 100;
	}
}

// Fórmula 1024 para 50.0: sensor * 0.048828125 + (25.0)
// Fórmula 50.0 para 1024: temperatura * 20,48 + (25.0)
// Fórmula 50.0 para 1024: temperatura * 20,48 + (25.0)

void main()
{
	setup_adc_ports(AN0_AN1_AN3);
	setup_adc(ADC_CLOCK_INTERNAL);
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_8 | RTCC_8_BIT); // 1.0 ms overflow

	lcd_init();

	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	while (TRUE)
	{
		if (fim_100ms)
		{
			fim_100ms = 0;

			set_adc_channel(1);
			potenciometro = read_adc();
			temperatura_desejada = potenciometro * 0.048828125 + 25.0;
			lcd_gotoxy(1, 1);
			printf(lcd_write_dat, "Hist: %04Lu %4.2f", potenciometro, temperatura_desejada);

			delay_us(40);

			set_adc_channel(0);
			temperatura = read_adc();
			temperatura_atual = temperatura * 0.048828125 + 25.0;
			lcd_gotoxy(1, 2);
			printf(lcd_write_dat, "%1.2f: %04Lu %4.2f", (histeresis * 0.048828125), temperatura, temperatura_atual);
		}

		if (processando)
		{
			if (potenciometro > (temperatura + histeresis))
			{
				output_high(HEATER);
				aquecendo = 1;
			}
			else if (potenciometro < (temperatura - histeresis))
			{
				output_low(HEATER);
				aquecendo = 0;
			}

			if (potenciometro <= temperatura - histeresis)
			{
				output_high(FAN);
				resfriando = 1;
			}
			else if (potenciometro == temperatura)
			{
				output_low(FAN);
				resfriando = 0;
			}

			if (!input(S_1))
			{
				while (--filtro_botao);
				filtro_botao = 100;
				processando = 0;

				output_low(HEATER);
				output_low(FAN);
				aquecendo = 0;
				resfriando = 0;
			}
		}
		else
		{
			if (!input(S_1))
			{
				while (--filtro_botao);
				filtro_botao = 100;
				processando = 1;
			}
		}

		if (!input(S_2))
		{
			while (--filtro_botao);
			filtro_botao = 100;

			histeresis += 2;
			if (histeresis >= 204)
			{
				histeresis = 202;
			}
		}

		if (!input(S_3))
		{
			while (--filtro_botao);
			filtro_botao = 100;

			histeresis -= 2;
			if (histeresis <= 0)
			{
				histeresis = 2;
			}
		}
	}
}

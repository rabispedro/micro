#include <modulo_1.h>
#include <lcd_8bits.c>

int1 fim_100ms, fim_250ms, fim_rx;

int8 contador_100ms = 100, contador_250ms = 250;

int1 fim_leitura, processando, aquecendo, resfriando;

int16 potenciometro, temperatura, histeresis = 20;
float temperatura_desejada, temperatura_atual;

int16 histeresis_anterior;

int8 filtro_botao = 100;

int1 valor_resistencia, valor_processo;
int8 indice_rx = 0;
char estado_rx, dado_rx, valor_pot[4], valor_temp[4], valor_hist[4];

#INT_TIMER0
void TIMER0_isr(void)
{
	set_timer0(get_timer0() + 6);

	if (--contador_100ms == 0)
	{
		fim_100ms = 1;
		contador_100ms = 100;
	}
	if (--contador_250ms == 0)
	{
		fim_250ms = 1;
		contador_250ms = 250;
	}
}

#INT_RDA
void RDA_isr(void)
{
	dado_rx = getc();

	if (dado_rx == 'P' || dado_rx == 'H' || dado_rx == 'S' || dado_rx == 'R' || dado_rx == 'T')
	{
		estado_rx = dado_rx;
	}
	else if (dado_rx == '.')
	{
		fim_rx = 1;
		indice_rx = 0;
	}

	if (!fim_rx)
	{
		switch (estado_rx)
		{
		case 'P':
			valor_pot[indice_rx++] = dado_rx;
			break;
		case 'H':
			valor_hist[indice_rx++] = dado_rx;
			break;
		case 'S':
			valor_processo = (dado_rx == '1');
			break;
		case 'R':
			valor_resistencia = (dado_rx == '1');
			break;
		case 'T':
			valor_temp[indice_rx++] = dado_rx;
			break;
		}
	}
}

void main()
{
	setup_adc_ports(AN0_AN1_AN3);
	setup_adc(ADC_CLOCK_INTERNAL);
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_8 | RTCC_8_BIT); // 1.0 ms overflow

	lcd_init();

	enable_interrupts(INT_TIMER0);
	enable_interrupts(INT_RDA);
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

			// delay_us(40);

			// set_adc_channel(0);
			// temperatura = read_adc();
			temperatura_atual = temperatura * 0.048828125 + 25.0;
			lcd_gotoxy(1, 2);
			printf(lcd_write_dat, "%1.2f: %04Lu %4.2f", (histeresis * 0.048828125), temperatura, temperatura_atual);
		}

		if (fim_250ms)
		{
			fim_250ms = 0;

			printf("P%04Lu.", potenciometro);
		}

      if (fim_rx)
      {
         fim_rx = 0;

         switch (estado_rx)
         {
         case 'H':
            histeresis = (int16)(valor_hist[0] - '0') * 1000 +
               (int16)(valor_hist[1] - '0') * 100 +
               (int16)(valor_hist[2] - '0') * 10 +
               (int16)(valor_hist[3] - '0');
            break;
         case 'S':
            processando = valor_processo;
            break;
         case 'R':
            aquecendo = valor_resistencia;
            break;
         case 'T':
            temperatura = (int16)(valor_temp[0] - '0') * 1000 +
               (int16)(valor_temp[1] - '0') * 100 +
               (int16)(valor_temp[2] - '0') * 10 +
               (int16)(valor_temp[3] - '0');
            break;
         }
      }

		if (processando)
		{
			if (potenciometro > (temperatura + histeresis))
			{
				output_high(HEATER);
				aquecendo = 1;
				printf("R%c.", (aquecendo ? '1' : '0'));
			}
			else if (potenciometro < (temperatura - histeresis))
			{
				output_low(HEATER);
				aquecendo = 0;
				printf("R%c.", (aquecendo ? '1' : '0'));
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

				printf("S%c.", (processando ? '1' : '0'));
				printf("R%c.", (aquecendo ? '1' : '0'));
			}
		}
		else
		{
			if (!input(S_1))
			{
				while (--filtro_botao);
				filtro_botao = 100;
				processando = 1;

				printf("S%c.", (processando ? '1' : '0'));
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

			printf("H%04Lu.", histeresis);
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
			printf("H%04Lu.", histeresis);
		}
	}
}

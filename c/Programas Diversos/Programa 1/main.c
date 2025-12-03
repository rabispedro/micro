#include <main.h>

int1 fim_1ms = 0, fim_100ms = 0, contando = 0;
int8 qual_digito = 0, unidade = 0, dezena = 0, centena = 0, filtro_contar = 100, filtro_parar = 100, filtro_zerar = 100, contador_100ms = 100, contador_500ms = 0;

BYTE CONST codigo[10] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};

void atualiza_display(void);

#INT_TIMER0
void TIMER0_isr(void)
{
	// set_timer0(get_timer0() + 131);
	set_timer0(get_timer0());
	fim_1ms = 1;
	if (--contador_100ms)
	{
		fim_100ms = 1;
		contador_100ms = 100;
		contador_500ms++;
	}
}

void main()
{
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_8 | RTCC_8_BIT); // 1.0 ms overflow

	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	while (TRUE)
	{
		if (fim_1ms)
		{
			fim_1ms = 0;

			atualiza_display();
		}

		if (contando)
		{
			if (fim_100ms)
			{
				fim_100ms = 0;

				if (contador_500ms == 200)
				{
					contador_500ms = 0;
					unidade++;

					if (unidade == 10) {
						dezena++;
						
						if (dezena == 10) {
							centena++;

							if (centena == 10) {
								centena = 0;
							}
							
							dezena = 0;
						}

						unidade = 0;
				}
				}

			}

			if (!input(B_PARAR))
			{
				while (--filtro_parar);
				filtro_parar = 100;

				contando = 0;
			}
		}
		else
		{
			if (!input(B_ZERAR))
			{
				while (--filtro_zerar);
				filtro_zerar = 100;

				unidade = 0;
				dezena = 0;
				centena = 0;
			}

			if (!input(B_CONTAR))
			{
				while (--filtro_contar);
				filtro_contar = 100;

				contando = 1;
			}
		}
	}
}

void atualiza_display(void)
{
	if (qual_digito == 0)
	{
		output_b(0b10000000);
		output_d(0x3F);
	} else if (qual_digito == 1)
	{
		output_b(0b01000000);
		output_d(codigo[centena]);
	} else if (qual_digito == 2)
	{
		output_b(0b00100000);
		output_d(codigo[dezena] | 0b10000000);
	} else
	{
		output_b(0b00010000);
		output_d(codigo[unidade]);
	}

	qual_digito++;
	if (qual_digito == 4) {
		qual_digito = 0;
	}
}

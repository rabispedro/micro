/*
* Prova de Programação 1 - C (19/11/2025)
* Nome: Pedro Henrique Rabis Diniz
* RA: 14254711611-1
*/

#include <main.h>

int1 fim_1ms = 0, fim_100ms = 0, fim_500ms = 0, fim_1s = 0;
int8 contador_100ms = 100, contador_500ms = 50, contador_1s = 2;

int1 acao_processo = 1, acao_zerar = 1, acao_incremento = 1, acao_decremento = 1;
int16 filtro_processo = 1000, filtro_zerar = 1000, filtro_incremento = 1000, filtro_decremento = 1000;

int8 estado_atual, qual_digito = 0, unidade = 0, dezena = 0, centena = 0, milhar = 0;

BYTE CONST codigo[10] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};

void atualiza_display(void);
void incrementa_digitos(void);
void decrementa_digitos(void);

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
		contador_500ms--;
	}
	if (contador_500ms == 0)
	{
		fim_500ms = 1;
		contador_500ms = 50;
		contador_1s--;
	}
	if (contador_1s == 0)
	{
		fim_1s = 1;
		contador_1s = 2;
	}
}

void main()
{
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_8 | RTCC_8_BIT); // 1.0 ms overflow

	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	// ESTADOS:
	// CONFIGURANDO = 0
	// PAUSADO = 1
	// CONTANDO = 2
	// ACIONADO = 3

	output_low(BUZZER);

	while (TRUE)
	{
		if (fim_1ms)
		{
			fim_1ms = 0;
			atualiza_display();
		}

		acao_processo = 1, acao_zerar = 1, acao_incremento = 1, acao_decremento = 1;
		switch (estado_atual)
		{
		case 0: // CONFIGURANDO
			if (!input(B_PROCESSO) && acao_processo)
			{
				while (--filtro_processo);
				filtro_processo = 1000;
				acao_processo = 0;

				if (unidade + dezena + centena + milhar > 0)
				estado_atual = 2;
			}
			if (!input(B_INCREMENTO) && acao_incremento)
			{
				while (--filtro_incremento);
				filtro_incremento = 1000;
				acao_incremento = 0;

				if (unidade + dezena + centena + milhar < 36)
				{
					if(fim_500ms)
					{
						fim_500ms = 0;
						incrementa_digitos();
					}
				}
			}
			if (!input(B_DECREMENTO) && acao_decremento)
			{
				while (--filtro_decremento);
				filtro_decremento = 1000;
				acao_decremento = 0;

				if (unidade + dezena + centena + milhar > 0)
				{
					if(fim_500ms)
					{
						fim_500ms = 0;
						decrementa_digitos();
					}
				}
			}
			break;
		case 1: // PAUSADO
			if (!input(B_PROCESSO) && acao_processo)
			{
				while (--filtro_processo);
				filtro_processo = 1000;
				acao_processo = 0;

				estado_atual = 2;
			}

			if (!input(B_ZERAR) && acao_zerar)
			{
				while (--filtro_zerar);
				filtro_zerar = 1000;
				acao_zerar = 0;

				unidade = dezena = centena = milhar = 0;
				estado_atual = 0;
			}
			break;
		case 2: // CONTANDO
			if (fim_1s)
			{
				fim_1s = 0;
				if (unidade + dezena + centena + milhar > 0)
					decrementa_digitos();
				else
					estado_atual = 3;
			}

			if (!input(B_PROCESSO) && acao_processo)
			{
				while (--filtro_processo);
				filtro_processo = 1000;
				acao_processo = 0;

				estado_atual = 1;
			}
			break;
		default: // ACIONADO
			output_high(BUZZER);

			if (!input(B_ZERAR) && acao_processo)
			{
				while (--filtro_zerar);
				filtro_zerar = 1000;
				acao_processo = 0;

				output_low(BUZZER);
				estado_atual = 0;
			}
			break;
		}
	}
}

void atualiza_display(void)
{
	switch (qual_digito)
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
		output_d(codigo[dezena] | 0b10000000);
		break;
	default:
		output_b(0b00010000);
		output_d(codigo[unidade]);
		break;
	}

	if (++qual_digito == 4)
		qual_digito = 0;
}

void incrementa_digitos(void)
{
	if (++unidade == 10)
	{
		if (++dezena == 10)
		{
			if (++centena == 10)
			{
				if (++milhar == 10)
				{
					milhar = 0;
				}

				centena = 0;
			}

			dezena = 0;
		}

		unidade = 0;
	}
}

void decrementa_digitos()
{
	if (--unidade == 255)
	{
		if (--dezena == 255)
		{
			if (--centena == 255)
			{
				if (--milhar == 255)
				{
					milhar = 9;
				}

				centena = 9;
			}

			dezena = 9;
		}

		unidade = 9;
	}
}

#include <main.h>
#include <lcd_8bits.c>

int1 fim_100ms = 0;
int16 contador_100ms = 100;

int1 modo = 1, fan_estado, heater_estado;
int16 heater_pwm, heater_ajuste, fan_pwm, fan_ajuste;
int16 heater_porcentagem, heater_ajuste_porcentagem, fan_porcentagem, fan_ajuste_porcentagem;

int16 filtro_s1 = 250, filtro_s2 = 250, filtro_s3 = 250, filtro_s4 = 250;

#INT_TIMER0
void TIMER0_isr(void)
{
	set_timer0(get_timer0() + 6);

	if (--contador_100ms == 0)
	{
		fim_100ms = 1;
		contador_100ms = 100;
	}
}

void main()
{
	setup_adc_ports(AN0_AN1_AN3);
	setup_adc(ADC_CLOCK_INTERNAL);
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_4 | RTCC_8_BIT); // 1.0 ms overflow
	setup_timer_2(T2_DIV_BY_1, 199, 1);						// 200 us overflow, 200 us interrupt

	setup_ccp1(CCP_PWM);
	setup_ccp2(CCP_PWM);
	set_pwm1_duty((int16)0);
	set_pwm2_duty((int16)0);

	lcd_init();

	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	while (TRUE)
	{
		if (fim_100ms)
		{
			fim_100ms = 0;

			set_adc_channel(0);
			heater_pwm = read_adc();

			heater_porcentagem = heater_pwm * 0.09765625;
			heater_ajuste_porcentagem = heater_ajuste * 0.09765625;

			lcd_gotoxy(1, 1);
			// printf(lcd_write_dat, "H: %Ld %Ld %Ld", heater_pwm, heater_porcentagem, heater_ajuste_porcentagem);
			if (heater_estado)
				printf(lcd_write_dat, "H: %02Ld%% %02Ld%% ON  %c", heater_porcentagem, heater_ajuste_porcentagem, (modo ? 'x' : ' '));
			else
				printf(lcd_write_dat, "H: %02Lu%% %02Lu%% OFF %c", heater_porcentagem, heater_ajuste_porcentagem, (modo ? 'x' : ' '));
			
			if (heater_estado)
				set_pwm1_duty(heater_ajuste_porcentagem * 8);
			else
				set_pwm1_duty(0);

			set_adc_channel(2);
			fan_pwm = read_adc();
			fan_porcentagem = fan_pwm * 0.09765625;
			fan_ajuste_porcentagem = fan_ajuste * 0.09765625;
			
			lcd_gotoxy(1, 2);
			if (fan_estado)
				printf(lcd_write_dat, "F: %02Lu%% %02Lu%% ON  %c", fan_porcentagem, fan_ajuste_porcentagem, (!modo ? 'x' : ' '));
			else
				printf(lcd_write_dat, "F: %02Lu%% %02Lu%% OFF %c", fan_porcentagem, fan_ajuste_porcentagem, (!modo ? 'x' : ' '));

			if (fan_estado)
				set_pwm2_duty(fan_ajuste_porcentagem * 8);
			else
				set_pwm2_duty(0);
		}

		if (!input(B_S1))
		{
			while (!input(B_S1));

			// while (filtro_s1--);
			filtro_s1 = 250;

			heater_estado = !heater_estado;
		}
		filtro_s1 = 250;

		if (!input(B_S2))
		{
			while (!input(B_S2));

			// while (filtro_s2--);
			filtro_s2 = 250;

			fan_estado = !fan_estado;
		}
		filtro_s2 = 250;

		if (!input(B_S3))
		{
			while (!input(B_S3));

			// while (filtro_s3--);
			filtro_s3 = 250;

			modo = !modo;
		}
		filtro_s3 = 250;

		if (!input(B_S4))
		{
			while (!input(B_S4));

			// while (filtro_s4--);
			filtro_s4 = 250;

			set_adc_channel(1);
			int16 ajuste = read_adc();
			if (modo)
				heater_ajuste = ajuste;
			else
				fan_ajuste = ajuste;
		}
		filtro_s4 = 250;
	}
}

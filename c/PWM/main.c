#include <main.h>
#include <lcd_8bits.c>

int1 fim_100ms;
int8 contador_100ms = 100;
int16 pot, largura;
float pwm_percentual;

#INT_TIMER0
void TIMER0_isr(void)
{
	set_timer0(get_timer0() + 6);

	if (--contador_100ms)
	{
		contador_100ms = 100;
		fim_100ms = 1;
	}
}

void main()
{
	setup_adc_ports(AN0_AN1_AN3);
	setup_adc(ADC_CLOCK_INTERNAL);
	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_4 | RTCC_8_BIT); // 1.024 ms overflow
	setup_timer_2(T2_DIV_BY_4, 249, 1);						// 1.000 ms overflow, 1.0 ms interrupt

	set_adc_channel(1);

	lcd_init();
	printf(lcd_write_dat, "POT:0000");
	lcd_gotoxy(1, 2);
	printf(lcd_write_dat, "CT:0000 000.000%%");

	setup_ccp1(CCP_PWM);
	set_pwm1_duty((int16)0);

	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	while (TRUE)
	{
		if (fim_100ms)
		{
			fim_100ms = 0;
			pot = read_adc();
			lcd_gotoxy(5, 1);
			printf(lcd_write_dat, "%04Lu", pot);

			largura = pot * 0.9765396;
			lcd_gotoxy(4, 2);
			printf(lcd_write_dat, "%04Lu", largura);
			set_pwm1_duty(largura);

			pwm_percentual = largura * 0.1001001;
			lcd_gotoxy(9, 2);
			printf(lcd_write_dat, "%3.4f%%", pwm_percentual);
		}
	}
}

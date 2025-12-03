#include <main.h>

int1 fim131_ms;
int8 contador131_ms = 100;

#INT_TIMER0
void TIMER0_isr(void)
{
	set_timer0(get_timer0());
	if (!contador131_ms) {
		fim131_ms = 1;
		contador131_ms = 100;
	}

}
#define LCD_RS_PIN PIN_C1
#define LCD_RW_PIN PIN_C2

#include <lcd.c>

void main()
{
	char k;

	setup_timer_0(RTCC_INTERNAL | RTCC_DIV_256 | RTCC_8_BIT); // 13.1 ms overflow

	enable_interrupts(INT_TIMER0);
	enable_interrupts(GLOBAL);

	lcd_init();

	lcd_putc("\fReady...\n");

	while (TRUE)
	{

		// Example using external LCD
		// k = kbd_getc();
		// if (k != 0)
		// 	if (k == '*')
		// 		lcd_putc('\f');
		// 	else
		// 		lcd_putc(k);

		// TODO: User Code

		// TODO: User Code
	}
}

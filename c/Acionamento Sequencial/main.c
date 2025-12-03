#include <main.h>

int8 filtro0 = 100, filtro1 = 100, filtro2 = 100, filtro3 = 100;

void main()
{
	output_low(LED_0);
	output_low(LED_1);
	output_low(LED_2);
	output_low(LED_3);
	while (TRUE)
	{
		while (TRUE)
		{
			if (!input(B_LED_0))
			{
				while (--filtro0);
				filtro0 = 100;
				output_toggle(LED_0);
				break;
			}
		}

		while (TRUE)
		{
			if (!input(B_LED_1))
			{
				while (--filtro1);
				filtro1 = 100;
				output_toggle(LED_1);
				break;
			}
		}

		while (TRUE)
		{
			if (!input(B_LED_2))
			{
				while (--filtro2);
				filtro2 = 100;
				output_toggle(LED_2);
				break;
			}
		}

		while (TRUE)
		{

			if (!input(B_LED_3))
			{
				while (--filtro3);
				filtro3 = 100;
				output_toggle(LED_3);
				break;
			}
		}
	}
}

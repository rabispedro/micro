#include <liga_desliga_led.h>

void main()
{
  output_low(LAMPADA);
	while(TRUE)
	{
    if(input(B_LIGA) == 0)
    {
      output_high(LAMPADA);
    }
    if(input(B_DESLIGA) == 0)
    {
      output_low(LAMPADA);
    }
	}
}

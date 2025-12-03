#include <main.h>

void main()
{
  output_low(LAMPADA);

	while(TRUE)
	{
    if (input(BOTAO) == 0)
    {
      output_toggle(LAMPADA);
    }
	}
}

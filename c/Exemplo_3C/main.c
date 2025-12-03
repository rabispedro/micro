#include <main.h>

int8 filtro = 100;

void main()
{
  output_low(LAMPADA);
  while (TRUE)
  {
    if (!input(B_TROCA_LAMPADA))
    {
      while (filtro > 0)
      {
        filtro--;
      }

      output_toggle(LAMPADA);
      filtro = 100;
    }
  }
}

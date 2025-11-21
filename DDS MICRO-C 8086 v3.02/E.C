#include <stdio.h>

#define DIGITS_TO_FIND 200

char buf[ 128 ];

int main()
{

  int limit;
  int x, n;
  int a[ DIGITS_TO_FIND ];
  limit = DIGITS_TO_FIND;
  x = 0;

  for (n = limit - 1; n > 0; --n) {
      a[n] = 1;
  }

  a[1] = 2, a[0] = 0;
  while (limit > 9) {
      n = limit--;
      while (--n) {
          a[n] = x % n;

          x = 10 * a[n-1] + x/n;
      }
      printf("%d", x);
  }

  printf( "\ndone\n" );
  return 0;
}

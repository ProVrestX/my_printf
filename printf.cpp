#include <stdio.h>
#include <stdlib.h>

extern "C" int printf_asm(const char*, ...);

int main() {
    const char *format = "%d\n%b\n%c\n%s\n%%\n%x\n%c\n%o\n%o\n";
    long long   par1 = 123456;
    int         par2 = 5;
    const char  par3 = 'c';
    const char *par4 = "STRING";
    long long   par5 = 0xA1B2C3DE;
    const char  par6 = 'f';
    int         par7 = -1234;
    int         par8 = 0;

    // int len = printf_asm("Hello, %s%c %d %d %d %x %x\n", "World", '!', 1,2,3,31,52);
    // int len = printf_asm("Hello, %s%c %d\n", "World", '!', 1);
    int len = printf_asm("%d\n%b\n%c\n%s\n%%\n%x\n%c\n%o\n%o\n"
                      "%d %s %x %d %% %c %b %r\n", par1, par2, par3,
                      par4, par5, par6, par7, par8,
                      -1, "love", 3802, 100, 33, 30);
    printf("Len: %d\n", len);
    return 0;
}
all: make

asm: printf_asm.asm
	nasm -f elf64 -l printf_asm.lst printf_asm.asm
	ld -s -o printf_asm printf_asm.o

c: printf.cpp
	g++ printf.c -o printf.si

make: printf.cpp printf_asm.asm
	nasm -f elf64 -l printf_asm.lst printf_asm.asm
	g++ -no-pie printf.cpp printf_asm.o -o printf
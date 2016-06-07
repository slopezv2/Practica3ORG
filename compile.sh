echo "Compiling files..."
nasm -f elf32 prog.asm
echo "Linking asm..."
ld -m elf_i386 prog.o -o prog
echo "Clearing proyect..."
rm *.sh~
rm *.asm~
rm *.o
rm *.txt
rm *ppm~

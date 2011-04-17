COMPILE = avr-gcc -Wall -Werror -W -Os -I. -mmcu=atmega8515
OBJECTS = main.o

# symbolic targets:
all:	main.hex main.raw.bin

.c.o:
	$(COMPILE) -c $< -o $@

.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@

.c.s:
	$(COMPILE) -S $< -o $@

clean:
	rm -f main.hex main.lst main.obj main.cof main.list main.map main.eep.hex main.bin main.raw.bin *.o 

# file targets:
main.bin:	$(OBJECTS)
	$(COMPILE) -o main.bin $(OBJECTS)

main.hex:	main.bin
	rm -f main.hex main.eep.hex
	avr-objcopy -j .text -j .data -O ihex main.bin main.hex
	../checksize main.bin

main.raw.bin:	main.bin
	avr-objcopy -j .text -j .data -O binary main.bin main.raw.bin

disasm:	main.bin
	avr-objdump -d main.bin

cpp:
	$(COMPILE) -E main.c

PWD	= $(shell pwd)

flash:	all
	avrdude -c usbasp -p atmega8515 -U flash:w:main.hex

reset:
	avrdude -c usbasp -p atmega8515

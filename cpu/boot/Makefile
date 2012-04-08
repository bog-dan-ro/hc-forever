CC	= sdcc
LD	= sdcc
CFLAGS	= -mz80 --std-c99 --Werror --opt-code-size
LDFLAGS	= -mz80 --out-fmt-ihx

MAKEBIN	= makebin
ROMSIZE	= 16384

OBJS	= font.gen.o

all:	cboot.bin

clean:
	rm -f *.o *.ihx *.map *.lst *.lnk *.sym *.bin

font.gen.c: ../clairsys.bin
	./bin2c.py font_data < $< > $@

%.bin: %.ihx
	$(MAKEBIN) -s $(ROMSIZE) < $< > $@

%.ihx: %.o $(OBJS)
	$(LD) $(LDFLAGS) $^

%.o: %.c
	$(CC) $(CFLAGS) -c $<

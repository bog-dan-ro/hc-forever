ASMS	= $(wildcard *.asm)
TAPS	= $(ASMS:.asm=.tap)

all:	$(TAPS)

clean:
	rm -f $TAPS

%.tap:	%.asm
	pasmo --alocal --tapbas $< $@
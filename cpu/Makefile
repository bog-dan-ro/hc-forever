ASMS	= $(patsubst %.inc.asm,,$(wildcard *.asm))
TAPS	= $(ASMS:.asm=.tap)
BINS	= $(ASMS:.asm=.bin)

all:	$(TAPS) $(BINS)

clean:
	rm -f $TAPS $BINS


.PHONY: version.gen.txt
version.gen.txt:
	echo -n "$$(git rev-parse HEAD | cut -b-8) / $$(date +"%Y-%m-%d")" > $@

boot.*: version.gen.txt

%.tap:	%.asm
	pasmo -E ORIGIN=0x6000 --alocal --tapbas $< $@

%.tzx:	%.asm
	pasmo -E ORIGIN=0x6000 --alocal --tzxbas $< $@

%.bin:	%.asm
	pasmo -E ORIGIN=0 --alocal --bin $< $@

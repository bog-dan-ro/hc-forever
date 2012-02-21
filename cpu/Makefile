ASMS	= $(wildcard *.asm)
TAPS	= $(ASMS:.asm=.tap)

all:	$(TAPS)

clean:
	rm -f $TAPS


.PHONY: version.gen.txt
version.gen.txt:
	echo -n "$$(git rev-parse HEAD | cut -b-8) / $$(date +"%Y-%m-%d")" > $@

boot.tap: version.gen.txt

%.tap:	%.asm
	pasmo --alocal --tapbas $< $@
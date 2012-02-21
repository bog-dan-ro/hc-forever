org 0xa000

screen		equ	0x4000
pixels_len	equ	6144
attributes	equ	0x5800
attributes_len	equ	768

; variables
cursor		equ	0x5b00
stack		equ	0x5c00

main proc

	di
	ld	hl, stack
	ld	sp, stack

; clear screen
	ld	hl, screen
	ld	(cursor), hl
	ld	de, screen + 1
	ld	bc, pixels_len
	xor	a
	ld	(hl), a
	ldir
; set attributes (black on white)
	ld	bc, 512
	ld	a, 0x78
	ld	(hl), a
	ldir

; paint an RGB strip in the lower third
	ld	b, 64
	xor	a
_rgbfill:
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	add	a, 0x08
	and	0x7f
	djnz	_rgbfill

; write a banner
	ld	de, banner
	call	puts

; and, cut.
	ld	a, 4
	out	(0xfe), a
	di
	halt


include print_func.inc.asm

banner:
	db "HC-Forever (rev B)", 10
	db "Copyright ", 127, " 2005-2012 Alex Badea <vamposdecampos@gmail.com>"
	db 10, 10
	db "Bootloader "
	incbin "version.gen.txt"
	db 0

endp
end main

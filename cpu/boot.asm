org 0x6000

screen		equ	0x4000
pixels_len	equ	6144
attributes	equ	0x5800
attributes_len	equ	768

; variables
cursor		equ	0x5b00
key		equ	0x5b02
stack		equ	0x5c00

main proc

	di
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

; read key
menu:
	ld	bc, 0xf7fe	; keys 1..5
	in	a, (c)
	cpl
	and	0x1f
	ld	(key), a
	or	a
	jr	z, menu
_wait_release:
	in	a, (c)
	and	0x1f
	cp	0x1f
	jr	nz, _wait_release

	ld	a, (key)	; can be 1, 2, 4, 8, 16
	cp	1
	jr	z, boot_maskrom
	cp	2
	jr	z, boot_spiflash
	jr	menu

boot_maskrom:
	ld	de, str_maskrom
	call	puts
	; TODO
	ld	a, 3
	out	(0xfe), a
	halt

boot_spiflash:
	ld	de, str_spiflash
	call	puts
	; TODO
	ld	a, 4
	out	(0xfe), a
	halt


include print_func.inc.asm

banner:
	db "HC-Forever (rev B)", 10
	db "Copyright ", 127, " 2005-2012 Alex Badea <vamposdecampos@gmail.com>"
	db 10, 10
	db "Bootloader "
	incbin "version.gen.txt"
	db 10
	db "Boot:  1=mask ROM  2=SPI flash", 10
	db 0

str_maskrom:	db "mask ROM... ", 0
str_spiflash:	db "SPI flash... ", 0

endp
end main

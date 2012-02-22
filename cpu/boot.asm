org ORIGIN

screen		equ	0x4000
pixels_len	equ	6144
attributes	equ	0x5800
attributes_len	equ	768

; variables
cursor		equ	0x5b00
key		equ	0x5b02
stack		equ	0x5c00

; mmu stuff
ram_pages	equ	0x8000
page_port	equ	0x42fd

; page port bits
PAGEDST_BANK0	equ	0x00
PAGEDST_BANK1	equ	0x40
PAGEDST_BANK2	equ	0x80
PAGEDST_BANK3	equ	0xc0
PAGE_READONLY	equ	0x20
PAGESRC_FPGA	equ	0x10
PAGESRC_XRAM	equ	0
PAGESRC_BITS	equ	0x0f

; SPI
SPI_READ	equ	0x03
PORT_SPI_SELECT	equ	0x1f
PORT_SPI_DATA	equ	0x3f
flash_page	equ	0x3f			; bits 16..23 of the address

assert_cs macro
	ld	a, 3				; on-board SPI flash chip (m25p32)
	out	(PORT_SPI_SELECT), a
endm

release_cs macro
	xor	a
	out	(PORT_SPI_SELECT), a
endm

main proc

	di
	ld	sp, stack

	release_cs

; set up paging
	ld	a, 1
	out	(0xfe), a
	call	page_in_xram

; check if we've already copied the mask rom
; (this happens after a warm reset, i.e. every time except
; first power-up)
	ld	a, (copy_done_flag)
	cp	1
	jr	z, _copy_done

; copy "mask rom" to a safe area (part of it is in the video memory)
	ld	a, 2
	out	(0xfe), a
	ld	hl, mask_rom
	ld	de, ram_pages
	ld	bc, mask_rom_end - mask_rom
	ldir
	; duplicate for the IF1 slot (avoid crashes)
	ld	hl, mask_rom
	ld	bc, mask_rom_end - mask_rom
	ldir

	ld	a, 1
	ld	(copy_done_flag), a
_copy_done:

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

; beep
	ld	bc, 200
	ld	l, 0x07
_beep:
	ld	a, l
	out	(0xfe), a
	xor	0x10
	ld	l, a
	push	bc
	ld	b, 100
_delay:
	djnz	_delay
	pop	bc
	dec	bc
	ld	a, b
	or	c
	jr	nz, _beep


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
	cp	16
	jr	z, boot_maskrom
	cp	1
	ld	h, 0x00
	jr	z, boot_spiflash
	cp	2
	ld	h, 0x40
	jr	z, boot_spiflash
	cp	4
	ld	h, 0x80
	jr	z, boot_spiflash
	cp	8
	ld	h, 0xc0
	jr	z, boot_spiflash
	jr	menu

boot_maskrom:
	ld	de, str_maskrom
	call	puts
	ld	a, 3
	out	(0xfe), a
	; ROM image was already copied at ram_pages
	jr	boot

boot_spiflash:
	ld	de, str_spiflash
	call	puts
	ld	a, 4
	out	(0xfe), a

	assert_cs
	ld	a, SPI_READ
	out	(PORT_SPI_DATA), a
	ld	a, flash_page
	out	(PORT_SPI_DATA), a
	ld	a, h			; bank
	out	(PORT_SPI_DATA), a
	xor	a
	out	(PORT_SPI_DATA), a
	ld	bc, 0x4000
	ld	de, ram_pages
_read_loop:
	out	(PORT_SPI_DATA), a
	in	a, (PORT_SPI_DATA)
	ld	(de), a
	inc	de
	dec	bc
	ld	a, b
	or	c
	jr	nz, _read_loop
	release_cs

	ld	de, str_done
	call	puts
	jr	boot


; page lower 32K of external SRAM at 0x8000
page_in_xram:
	ld	bc, page_port
	ld	a, PAGEDST_BANK2 | PAGESRC_XRAM | 0
	out	(c), a
	ld	a, PAGEDST_BANK3 | PAGESRC_XRAM | 1
	out	(c), a
	ret

; copy the trampoline routine somewhere in bank 1, and jump to it
boot:
	ld	hl, boot_trampoline
	ld	de, stack
	ld	bc, boot_trampoline_end - boot_trampoline
	ldir
	jp	stack

; configure paging for runtime, and jump to ROM
boot_trampoline:
	ld	a, 6
	out	(0xfe), a
	ld	bc, page_port
	ld	a, PAGEDST_BANK0 | PAGE_READONLY | PAGESRC_XRAM | 0
	out	(c), a
	;ld	a, PAGEDST_BANK1 | PAGESRC_FPGA | 1
	;out	(c), a
	ld	a, PAGEDST_BANK2 | PAGESRC_XRAM | 2
	out	(c), a
	ld	a, PAGEDST_BANK3 | PAGESRC_XRAM | 3
	out	(c), a
	jp	0
boot_trampoline_end:

include print_func.inc.asm

banner:
	db "HC-Forever (rev B)", 10
	db "Copyright ", 127, " 2005-2012 Alex Badea <vamposdecampos@gmail.com>"
	db 10, 10
	db "Bootloader "
	incbin "version.gen.txt"
	db "Choose image:", 10
	db "  1..4 - SPI flash", 10
	db "  5    - mask ROM", 10
	db 0

str_maskrom:	db "mask ROM... ", 0
str_spiflash:	db "SPI flash... ", 0
str_done:	db "done", 0

copy_done_flag:	db 0

mask_rom:
	incbin "48.rom"
mask_rom_end:

endp
end main

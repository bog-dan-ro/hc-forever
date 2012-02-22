org 32000

PORT_SPI_SELECT	equ	0x1f
PORT_SPI_DATA	equ	0x3f

WREN		equ	0x06
WRDI		equ	0x04
RDID		equ	0x9f
RDSR		equ	0x05
PAGE_PROGRAM	equ	0x02
SECTOR_ERASE	equ	0xd8
READ		equ	0x03

; bits 16..23 of the address
flash_page	equ	0x3f

; Spectrum ROM routines
po_msg		equ	0x0c0a


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
	xor	a
	ld	de, banner - 1
	call	po_msg

	release_cs

; RDID

	xor	a
	ld	de, str_rdid - 1
	call	po_msg

	assert_cs

	ld	a, RDID
	out	(PORT_SPI_DATA), a

	ld	b, 4
_rdid_loop:
	out	(PORT_SPI_DATA), a
	in	a, (PORT_SPI_DATA)
	call	po_hex
	djnz	_rdid_loop

	release_cs

; flash read

	assert_cs
	ld	a, READ
	out	(PORT_SPI_DATA), a
	ld	a, flash_page
	out	(PORT_SPI_DATA), a
	xor	a
	out	(PORT_SPI_DATA), a
	out	(PORT_SPI_DATA), a
	ld	b, 0
_read_loop:
	out	(PORT_SPI_DATA), a
	in	a, (PORT_SPI_DATA)
	call	po_hex
	djnz	_read_loop
	release_cs

	ei
	ret




po_hex:
	push	af
	rrca
	rrca
	rrca
	rrca
	call	po_nibble
	pop	af
	call	po_nibble
	ret

po_nibble:
	push	hl
	push	de
	and	0x0f
	ld	h, 0
	ld	l, a
	ld	de, hex_chars
	add	hl, de
	ld	a, (hl)
	rst	0x10
	pop	de
	pop	hl
	ret



banner:		db	"spiread", 13 + 128
str_rdid:	db	"rdid:", ' ' + 128
str_ptr:	db	"data:", ' ' + 128
hex_chars:	db	"0123456789abcdef"


endp
end main

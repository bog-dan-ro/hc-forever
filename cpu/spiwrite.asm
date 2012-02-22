org 33000

PORT_SPI_SELECT	equ	0x1f
PORT_SPI_DATA	equ	0x3f

WREN		equ	0x06
WRDI		equ	0x04
RDID		equ	0x9f
RDSR		equ	0x05
PAGE_PROGRAM	equ	0x02
SECTOR_ERASE	equ	0xd8

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
	ld	de, 0
	ld	(flash_ptr), de

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

; flash write

	;call	spi_wren
	;call	spi_erase
	;call	spi_wait
	call	spi_wait
	call	spi_wren
	call	spi_wait
	call	spi_program
	call	spi_wait

	xor	a
	ld	de, str_ptr - 1
	call	po_msg
	ld	hl, (flash_ptr)
	ld	a, h
	call	po_hex
	ld	a, l
	call	po_hex

	ei
	ret

spi_wren:
	ld	a, 'w'
	rst	0x10
	assert_cs
	ld	a, WREN
	out	(PORT_SPI_DATA), a
	release_cs
	ret


spi_erase:
	ld	a, 'E'
	rst	0x10
	assert_cs
	ld	a, SECTOR_ERASE
	out	(PORT_SPI_DATA), a
	ld	a, flash_page
	out	(PORT_SPI_DATA), a
	ld	de, (flash_ptr)
	ld	a, d
	out	(PORT_SPI_DATA), a
	ld	a, e
	out	(PORT_SPI_DATA), a
	release_cs
	ret

spi_program:
	ld	a, 'P'
	rst	0x10
	assert_cs
	ld	a, PAGE_PROGRAM
	out	(PORT_SPI_DATA), a
	ld	a, flash_page
	out	(PORT_SPI_DATA), a
	ld	de, (flash_ptr)
	ld	a, d
	out	(PORT_SPI_DATA), a
	ld	a, e
	out	(PORT_SPI_DATA), a

	ld	hl, data_buf
	add	hl, de

	ld	b, 10
_loop:
	ld	a, (hl)
	out	(PORT_SPI_DATA), a
	inc	hl
	inc	de
	djnz	_loop
	ld	(flash_ptr), de

	release_cs
	ret

spi_wait:
	assert_cs
	ld	a, RDSR
	out	(PORT_SPI_DATA), a
_wait_loop:
	ld	a, '.'
	rst	0x10
	out	(PORT_SPI_DATA), a
	in	a, (PORT_SPI_DATA)
	push	af
	call	po_hex
	pop	af
	and	1
	jr	nz, _wait_loop
	ld	a, '!'
	rst	0x10
	release_cs
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



banner:		db	"spiwrite", 13 + 128
str_rdid:	db	"rdid:", ' ' + 128
str_ptr:	db	"ptr:", ' ' + 128
hex_chars:	db	"0123456789abcdef"

flash_ptr	dw	0
data_len	dw	data_buf_end - data_buf
data_buf:
		incbin "hello0.bin"
data_buf_end:
		db	"xxxabcdefghijklmnopqrstuvwxyz"

endp
end main

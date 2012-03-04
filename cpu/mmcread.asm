org 32000

PORT_SPI_SELECT	equ	0x1f
PORT_SPI_DATA	equ	0x3f

MMC_RESET			equ	0x40
MMC_SEND_OPERATING_STATE	equ	0x41
MMC_SET_BLOCKLEN		equ	0x50
MMC_READ_SINGLE_BLOCK		equ	0x51

; Spectrum ROM routines
po_msg		equ	0x0c0a
; Spectrum Basic system variables
SCR_CT		equ	23962

WREN		equ	0x06
WRDI		equ	0x04
RDID		equ	0x9f
RDSR		equ	0x05
PAGE_PROGRAM	equ	0x02
SECTOR_ERASE	equ	0xd8

spi_assert_cs macro
	ld	a, 3				; on-board SPI flash chip (m25p32)
	out	(PORT_SPI_SELECT), a
endm

mmc_assert_cs macro
	ld	a, 1				; VS0 (SD card)
	out	(PORT_SPI_SELECT), a
endm

release_cs macro
	xor	a
	out	(PORT_SPI_SELECT), a
endm


main proc

	ld	a, 0xfe
	call	0x1601		; chan-open channel 'S'

	xor	a
	ld	de, banner - 1
	call	po_msg

	release_cs
	call	dwell

; init
	ld	a, 0xff
	ld	b, 10			; 80 clocks
_init_loop:
	out	(PORT_SPI_DATA), a
	djnz	_init_loop
	nop

	ld	a, 'I'
	rst	0x10

; enter SPI mode
	mmc_assert_cs
	ld	a, MMC_RESET
	out	(PORT_SPI_DATA), a
	xor	a
	out	(PORT_SPI_DATA), a
	out	(PORT_SPI_DATA), a
	out	(PORT_SPI_DATA), a
	out	(PORT_SPI_DATA), a
	ld	a, 0x95			; checksum
	out	(PORT_SPI_DATA), a
	ld	b, 8
	call	mmc_wait_response
	release_cs

	ld	a, (readbuf)
	cp	1
	jp	nz, fail

; set operating state
	ld	b, 50			; retry count
set_operstate:
	push	bc
	call	dwell
	ld	a, 13
	rst	0x10
	ld	a, 'S'
	rst	0x10

	ld	a, 0xff
	out	(PORT_SPI_DATA), a
	nop

	mmc_assert_cs
	ld	a, MMC_SEND_OPERATING_STATE
	ld	hl, 0
	ld	de, 0
	call	mmc_command
	ld	b, 8
	call	mmc_wait_response
	release_cs

	pop	bc
	ld	a, (readbuf)
	cp	0
	jr	z, oper_done
	djnz	set_operstate
	jp	fail

oper_done:
	ld	a, 13
	rst	0x10
	ld	a, 'B'
	rst	0x10

	mmc_assert_cs
	ld	a, MMC_SET_BLOCKLEN
	ld	hl, 0
	ld	de, 0x0100
	call	mmc_command
	ld	b, 8
	call	mmc_wait_response
	release_cs

; erase sectors
	ld	de, 0
	ld	(block_off), de
do_erase:
	call	spi_wren
	call	spi_erase
	call	spi_wait

	ld	de, (block_off)
	inc	d			; 64 KB (512 kbits)
	ld	(block_off), de
	ld	a, d
	cp	5
	jr	nz, do_erase

	ld	a, 13
	rst	0x10

	ld	de, 0
	ld	(block_off), de

;read & flash
do_flash:
	ld	hl, (block_off)
	ld	a, h
	call	po_hex
	ld	a, l
	call	po_hex

	ld	a, 0xff
	ld	(SCR_CT), a

	ld	a, 13
	rst	0x10
	ld	a, 'R'
	rst	0x10

	mmc_assert_cs
	ld	a, MMC_READ_SINGLE_BLOCK
	ld	de, (block_off)
	ld	h, 0		; HL:DE == byte offset
	ld	l, d
	ld	d, e
	ld	e, 0
	call	mmc_command
	ld	b, 1
	call	mmc_wait_response
	ld	a, (readbuf)
	cp	0
	jr	nz, read_fail
	ld	a, 'r'
	rst	0x10
	ld	b, 1
	call	mmc_wait_response
	ld	a, (readbuf)
	cp	0xfe
	jr	nz, read_fail
	ld	bc, 0x0100
	call	mmc_read_data
	release_cs

	jr	skip_print	; XXX

	ld	a, 13
	rst	0x10

; print
	ld	bc, 0x0100
	ld	hl, readbuf
_print_loop:
	ld	a, (hl)
	call	po_hex
	inc	hl
	dec	bc
	ld	a, b
	or	c
	jr	nz, _print_loop

skip_print:
	call	spi_wren
	call	spi_wait
	call	spi_program
	call	spi_wait
	ld	a, 13
	rst	0x10

	ld	de, (block_off)
	inc	de
	ld	(block_off), de
	ld	a, d
	cp	5
	jr	nz, do_flash
; done
	ei
	ret

read_fail:
	release_cs

fail:
	ld	a, 'F'
	rst	0x10
	ld	a, 'A'
	rst	0x10
	ld	a, 'I'
	rst	0x10
	ld	a, 'L'
	rst	0x10
	ei
	ret

; wait a while
dwell:
	push	bc
	ld	b, 4
_dwell_loop:
	in	a, (PORT_SPI_DATA)
	djnz	_dwell_loop
	pop	bc
	ret

; A=command; H, L, D, E=args
mmc_command:
	out	(PORT_SPI_DATA), a
	nop
	ld	a, h
	out	(PORT_SPI_DATA), a
	nop
	nop
	ld	a, l
	out	(PORT_SPI_DATA), a
	nop
	nop
	ld	a, d
	out	(PORT_SPI_DATA), a
	nop
	nop
	ld	a, e
	out	(PORT_SPI_DATA), a
	nop
	nop
	ld	a, 0xff			; fake checksum
	out	(PORT_SPI_DATA), a
	nop
	nop
	ret

mmc_wait_response:
	push	bc
	ld	b, 0
_waitloop:
	call	dwell
	ld	a, 0xff
	out	(PORT_SPI_DATA), a
	in	a, (PORT_SPI_DATA)
	cp	0xff
	jr	nz, _waitdone
	djnz	_waitloop
_waitdone:
	pop	bc

	ld	hl, readbuf
_rdloop:
	ld	(hl), a
	inc	hl
	call	po_hex
	call	dwell
	ld	a, b
	cp	1
	ret	z
	ld	a, 0xff
	out	(PORT_SPI_DATA), a
	in	a, (PORT_SPI_DATA)
	djnz	_rdloop
	ret

mmc_read_data:
	ld	hl, readbuf
_rdloop:
	ld	a, 0xff
	out	(PORT_SPI_DATA), a
	in	a, (PORT_SPI_DATA)
	ld	(hl), a
	inc	hl
	dec	bc
	ld	a, b
	or	c
	jr	nz, _rdloop
	ret

;;;;;;
; SPI stuff

spi_wren:
	ld	a, 'w'
	rst	0x10
	spi_assert_cs
	ld	a, WREN
	out	(PORT_SPI_DATA), a
	release_cs
	ret


spi_erase:
	ld	a, 'E'
	rst	0x10
	spi_assert_cs
	ld	a, SECTOR_ERASE
	out	(PORT_SPI_DATA), a
	ld	de, (block_off)
	ld	a, d
	out	(PORT_SPI_DATA), a
	ld	a, e
	out	(PORT_SPI_DATA), a
	xor	a
	out	(PORT_SPI_DATA), a
	release_cs
	ret

spi_program:
	ld	a, 'P'
	rst	0x10
	spi_assert_cs
	ld	a, PAGE_PROGRAM
	out	(PORT_SPI_DATA), a
	ld	de, (block_off)
	ld	a, d
	out	(PORT_SPI_DATA), a
	ld	a, e
	out	(PORT_SPI_DATA), a
	xor	a
	out	(PORT_SPI_DATA), a

	ld	hl, readbuf
	ld	b, 0
_loop:
	ld	a, (hl)
	out	(PORT_SPI_DATA), a
	inc	hl
	inc	de
	djnz	_loop

	release_cs
	ret

spi_wait:
	spi_assert_cs
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


;;;;;;

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



banner:		db	"mmcread", 13 + 128
str_cid:	db	"cid:", ' ' + 128
str_ptr:	db	"data:", ' ' + 128
hex_chars:	db	"0123456789abcdef"

block_off:	dw	0		; bits 24..8 of the address

readbuf:
; 512 bytes

endp
end main

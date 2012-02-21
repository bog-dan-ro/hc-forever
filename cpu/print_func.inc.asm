puts:
	; if (!*de) return;
	ld	a, (de)
	or	a
	ret	z
	; putchar(*de++)
	inc	de
	call	putchar
	jr	puts

putchar:
	exx
	cp	10
	jr	z, _newline

	; hl = a * 4
	ld	l, a
	ld	h, 0
	add	hl, hl
	add	hl, hl
	add	hl, hl
	; hl += &font - 256   (font data starts with '@')
	ld	de, font - 256
	add	hl, de
	; read cursor location, and advance the cursor
	ld	de, (cursor)
	inc	de
	ld	(cursor), de
	dec	de
	ld	b, 8
_putchar_byte:
	; copy one horizontal byte for the character
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	d
	djnz	_putchar_byte
	jr	_done

_newline:
	ld	hl, (cursor)
	ld	a, l
	and	0xe0
	add	a, 0x20
	ld	l, a
	jr	nc, _nc
	ld	a, h
	add	a, 8
	ld	h, a
_nc:
	ld	(cursor), hl

_done:
	exx
	ret

font:
	incbin "clairsys.bin"
font_end:


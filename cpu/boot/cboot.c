#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define PIXELS_ADDR	0x4000
#define PIXELS_SIZE	6144
#define ATTRIB_ADDR	(PIXELS_ADDR + PIXELS_SIZE)
#define ATTRIB_SIZE	768

struct screen {
	uint8_t row;		/* 0-based */
	uint8_t col;		/* 0-based */
	uint8_t attr;
};

enum color {
	COLOR_BLACK	= 0,
	COLOR_BLUE,
	COLOR_RED,
	COLOR_MAGENTA,
	COLOR_GREEN,
	COLOR_CYAN,
	COLOR_YELLOW,
	COLOR_WHITE,
	COLORF_BRIGHT	= 8,
};

static struct screen screen;
static volatile __sfr __at 0xfe port_fe;
static volatile __at PIXELS_ADDR uint8_t screen_data[PIXELS_SIZE];
static volatile __at ATTRIB_ADDR uint8_t screen_attr[ATTRIB_SIZE];

extern unsigned char font_data[];

static inline void screen_set_attr(unsigned fgcol, unsigned bgcol,
	unsigned bright, unsigned flash)
{
	screen.attr = (fgcol & 0x7) | ((bgcol & 0x0f) << 3);
	/* not yet used due to optimizer error */
	(void) bright;
	(void) flash;
}

static void screen_clear(void)
{
	memset(ATTRIB_ADDR, screen.attr, ATTRIB_SIZE);
	screen.row = 0;
	screen.col = 0;
}

static void screen_print_char(char c)
{
	unsigned char *glyph;
	unsigned char *dp;
	unsigned char k;

	glyph = &font_data[8 * (c - 32)];
	dp = &screen_data[2048 * (screen.row / 8) + (screen.row % 8) * 32 + screen.col];
	for (k = 0; k < 8; k++) {
		*dp = *glyph;
		dp += 0x100;
		glyph++;
	}
	screen_attr[screen.row * 32 + screen.col] = screen.attr;
}

static void screen_scroll(void)
{
	/* TODO */
}

static void screen_advance(void)
{
	if (++screen.col >= 32) {
		screen.col = 0;
		if (++screen.row >= 24) {
			screen_scroll();
			screen.row--;
		}
	}
}

void putchar(char c)
{
	switch (c) {
	case '\n':
		screen.col = 31;
		break;
	default:
		screen_print_char(c);
		break;
	}
	screen_advance();
}

/* display a banner with all colors in the lower display third */
static void rgb_banner()
{
	unsigned char k;
	unsigned char *dp;
	unsigned char attr = 0;

	dp = &screen_attr[32 * 8 * 2];
	dp = screen_attr;
	for (k = 0; k < 64; k++) {
		*dp++ = attr;
		*dp++ = attr;
		*dp++ = attr;
		*dp++ = attr;
		attr = (attr + 8) & 0x7f;
	}
}

int main(void)
{
	screen_set_attr(COLOR_BLACK, COLOR_WHITE, 0, 0);
	screen_clear();
	rgb_banner();

	screen.row = 9;
	printf("HC-Forever (rev B)\n"
		"Copyright \x7f 2005-2012 Alex Badea <vamposdecampos@gmail.com>\n\n");

	while (1) {
		port_fe = 0;
		port_fe = 0xff;
	}
}

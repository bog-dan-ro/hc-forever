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

extern unsigned char font_data[];

static inline void screen_set_attr(unsigned fgcol, unsigned bgcol,
	unsigned bright, unsigned flash)
{
	screen.attr = (fgcol & 0x7) | ((bgcol & 0x07) << 3);
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
	int k;

	glyph = &font_data[8 * (c - 32)];
	dp = &screen_data[2048 * (screen.row / 8) + (screen.row % 8) * 32 + screen.col];
	for (k = 0; k < 8; k++) {
		*dp = *glyph;
		dp += 0x100;
		glyph++;
	}
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

static void screen_putc(char c)
{
	screen_print_char(c);
	screen_advance();
}

static void screen_puts(const char *s)
{
	while (*s)
		screen_putc(*s++);
}

int main(void)
{
	screen_set_attr(COLOR_BLACK, COLOR_WHITE, 0, 0);
	screen_clear();
	screen_puts("Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
		"Vestibulum sit amet nibh in lectus pellentesque pellentesque id quis urna. "
		"Quisque ipsum mi, vehicula vel euismod a, varius et purus. "
		"Sed lobortis, nibh ac feugiat consequat, mi libero egestas nibh, et malesuada orci arcu et lorem. "
		"Nunc non gravida augue. Morbi a pellentesque nulla. "
		"Praesent quis est leo, sed convallis justo. "
		"Suspendisse sed justo eu orci bibendum pharetra. "
		"Aliquam elementum massa quis justo malesuada sit amet pellentesque lectus vestibulum. "
		"Maecenas eu ligula in ligula consequat dapibus eget id orci. "
		"Nam dignissim sollicitudin volutpat. "
		"Vivamus felis ante, molestie eget consequat nec, hendrerit non augue. "
		"Pellentesque imperdiet tincidunt elit. ");
	screen_puts("There are more things in Heaven and Earth, Horatio, than are dreamt of in your philosophy.");

	while (1) {
		port_fe = 0;
		port_fe = 0xff;
	}
}

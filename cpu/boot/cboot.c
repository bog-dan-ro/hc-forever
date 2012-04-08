#include <stdint.h>
#include <string.h>

#define PIXELS_ADDR	0x4000
#define PIXELS_SIZE	6144
#define ATTRIB_ADDR	(PIXELS_ADDR + PIXELS_SIZE)
#define ATTRIB_SIZE	768

struct screen {
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
}

int main(void)
{
	screen_set_attr(COLOR_BLACK, COLOR_WHITE, 0, 0);
	screen_clear();

	while (1) {
		port_fe = 0;
		port_fe = 0xff;
	}
}

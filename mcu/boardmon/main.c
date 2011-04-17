#define F_CPU	14000000

#include <stdio.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/sleep.h>
#include <avr/pgmspace.h>
#include <util/delay.h>

#define BAUD_RATE 57600

#define nop() do { __asm__ __volatile__ ("nop"); } while (0)
/* #define nop() _delay_ms(1) */

/******************************************************************************/
/* UART */

static int uart_putchar(char c, FILE *fp)
{
	if (c == '\n')
		uart_putchar('\r', fp);
	loop_until_bit_is_set(UCSRA, UDRE);
	UDR = c;
	return 0;
}

static int uart_getchar(FILE *fp)
{
	char res;

	(void) fp;

	loop_until_bit_is_set(UCSRA, RXC);
	res = UDR;
	uart_putchar(res, fp);	/* echo */
	return res;
}

FILE uart_fp = FDEV_SETUP_STREAM(uart_putchar, uart_getchar, _FDEV_SETUP_RW);

static void uart_init(void)
{
	UBRRH = 0;
	UBRRL = F_CPU / (BAUD_RATE * 16L) - 1;
	UCSRB = _BV(TXEN) | _BV(RXEN);
	UCSRC = _BV(URSEL) | _BV(UCSZ1) | _BV(UCSZ0);

	stdin = stdout = &uart_fp;
}

/******************************************************************************/

/*

pins:
PE2 - !BUSRQ
PE0 - !BUSACK
PE1 - ADDR_LE
PD4 - !RESET (CPU)

PD7 - !RD
PD6 - !WR

PA7..0 - CPU_A15..8
PC7..0 - D7..0

PD5 - temporary LED0

*/

#define BUSRQ_n		E, 2
#define BUSACK_n	E, 0
#define ADDR_LE		E, 1
#define RD_n		D, 7
#define WR_n		D, 6
#define RESET_n		D, 4
#define LED0		D, 5
#define CLKOUT		B, 0

#define ADDR_PORT	PORTA
#define ADDR_DDR	DDRA
#define ADDR_PIN	PINA
#define DATA_PORT	PORTC
#define DATA_DDR	DDRC
#define DATA_PIN	PINC

#define bit_set(r, b, v)	\
	do { \
		if (v) (r) |= _BV(b); \
		else (r) &= ~_BV(b); \
	} while (0)
#define bit_get(r, b)	(!!((r) & _BV(b)))

#define _output(port, b, v)	bit_set(PORT ## port, b, v)
#define _ddr(port, b, v)	bit_set(DDR ## port, b, v)
#define _input(port, b)		bit_get(PIN ## port, b)

#define output(signal, v)	_output(signal, v)
#define ddr(signal, v)		_ddr(signal, v)		/* v==1 -> output */
#define input(signal)		_input(signal)

#define pullup(signal)		do { _ddr(signal, 0); _output(signal, 1); } while (0)
#define pulldown(signal)	do { _output(signal, 0); _ddr(signal, 1); } while (0)

/******************************************************************************/
/* Clock generator */

static void clockgen_init(void)
{
	/* set Timer0 to generate a 7MHz clock output on OC0 */
	TCCR0 = _BV(WGM01) | _BV(COM00) | _BV(CS00);
	OCR0 = 0;
	ddr(CLKOUT, 1);
}

/******************************************************************************/
/* Bootstrap */

/* enter bootstrap mode: assert BUSRQ, wait for BUSACK,
 * set addr & data pin directions
 */
static void bootstrap_enable(void)
{
	printf_P(PSTR("\nRESET... "));
	output(RESET_n, 1);	/* otherwise it won't BUSACK */

	printf_P(PSTR("BUSRQ... "));

	output(ADDR_LE, 0);
	pulldown(BUSRQ_n);

	while (input(BUSACK_n))
		nop();
	printf_P(PSTR("BUSACK\n"));

	ADDR_DDR = 0xff;	/* all outputs */
	DATA_DDR = 0xff;	/* all outputs */

	/* set RD/WR as outputs, high (deasserted) */
	output(RD_n, 1);
	output(WR_n, 1);
	ddr(RD_n, 1);
	ddr(WR_n, 1);
}

static void bootstrap_disable(void)
{
	ADDR_DDR = 0;		/* all inputs */
	ADDR_PORT = 0xff;	/* enable pullups */
	DATA_DDR = 0;		/* all inputs */
	DATA_PORT = 0xff;	/* enable pullups */

	pullup(RD_n);
	pullup(WR_n);
	output(ADDR_LE, 1);	/* work around hang (FIXME) */

	printf_P(PSTR("-BUSRQ... "));
	pullup(BUSRQ_n);	/* deassert */

	while (!input(BUSACK_n))
		nop();
	printf_P(PSTR("-BUSACK\n"));
}

/******************************************************************************/

static uint32_t lfsr = 0xdeadbeefUL;

static uint32_t rand32(void)
{
	/* taps: 32 31 29 1; characteristic polynomial: x^32 + x^31 + x^29 + x + 1 */
	lfsr = (lfsr >> 1) ^ (-(lfsr & 1u) & 0xd0000001u); 

	return lfsr;
}

/******************************************************************************/
/* Memory access */

static void mem_write(unsigned short addr, unsigned char value)
{
	ADDR_PORT = addr >> 8;
	DATA_PORT = addr & 0xff;
	output(ADDR_LE, 1);
	output(ADDR_LE, 0);

	DATA_PORT = value;
	output(WR_n, 0);
	nop();
	nop();
	nop();
	nop();
	output(WR_n, 1);
}

static unsigned char mem_read(unsigned short addr)
{
	unsigned char res;
	unsigned char k;

	ADDR_PORT = addr >> 8;
	DATA_PORT = addr & 0xff;
	output(ADDR_LE, 1);
	output(ADDR_LE, 0);

	/* inputs, no pull-ups */
	DATA_DDR = 0;
	DATA_PORT = 0;
	output(RD_n, 0);
	for (k = 0; k < 16; k++)
		nop();
	res = DATA_PIN;
	output(RD_n, 1);

	DATA_DDR = 0xff; /* outputs */

	return res;
}

static void fill_video_mem(char mode, char value)
{
	unsigned short k, lo, hi;

	lo = 0;
	hi = 6912;

	if (mode <= 6)
		hi = 6144;
	if (mode >= 7)
		lo = 6144;

	for (k = lo; k < hi; k++) {
		char v = value;

		switch (mode) {
		case 0:
			v = 0;
			break;
		case 1:
			v = 0xff;
			break;
		case 2:
			v = (k & 0xff);
			break;
		case 3:
			v = ~(k & 0xff);
			break;
		case 4:
			v = 0x55;
			break;
		case 5:
			v = 0xaa;
			break;
		case 6:
		case 7:
			v = rand32() & 0xff;
			break;
		case 8:
			v = 0x07;
			break;
		case 9:
			v = 0x70;
			break;
		}
		mem_write(0x4000 + k, v);
	}
}

static void test_mem(unsigned short low, unsigned short high)
{
	unsigned short addr;
	unsigned char v;
	unsigned char cnt = 0;

	printf_P(PSTR("test memory: 0x%04x .. 0x%04x\n"), low, high);
	printf_P(PSTR("- seq fill\n"));
	v = 0x42;
	addr = low;
	do {
		v = (v << 1) ^ (addr >> 8);
		v = (v << 1) ^ ~(addr & 0xff);
		mem_write(addr, v);
		addr++;
	} while (addr != high);

	printf_P(PSTR("- seq test\n"));
	v = 0x42;
	addr = low;
	do {
		unsigned char ch = mem_read(addr);

		v = (v << 1) ^ (addr >> 8);
		v = (v << 1) ^ ~(addr & 0xff);
		if (ch != v) {
			printf_P(PSTR("error at 0x%x: expected 0x%x read 0x%x\n"), addr, v & 0xff, ch & 0xff);
			if (++cnt > 20) {
				printf_P(PSTR("too many errors\n"));
				return;
			}
		}
		addr++;
	} while (addr != high);
}

static void dump_mem(void)
{
	char row, k;
	int addr;
	
	printf_P(PSTR("addr (hex): "));
	scanf("%x", &addr);
	
	for (row = 0; row < 10; row++) {
		printf_P(PSTR("\n0x%04x:"), addr);
		for (k = 0; k < 16; k++) {
			printf_P(PSTR(" %02x"), mem_read(addr));
			addr++;
		}
	}
}

static void memtest_menu(void)
{
	uint8_t blk;

	while (1) {
		int ch;
		
		printf_P(PSTR("\nmemtest> "));
		ch = getchar();
		if (ch == 'q')
			break;

		bootstrap_enable();
		switch (ch) {
		case '0' ... '9':
			printf_P(PSTR("\nmemory fill #%c"), ch);
			fill_video_mem(ch - '0', 0);
			break;
		case 't':
			for (blk = 0; blk < 8; blk++) {
				_delay_ms(100);
				test_mem(blk * 8192, blk * 8192 + 8191);
			}
			break;
		case 'v':
			test_mem(16384, 32767);
			break;
		case 'd':
			dump_mem();
			break;
		}
		bootstrap_disable();
	}
}

/******************************************************************************/

int main(void)
{
	DDRA = 0;
	DDRB = 0;
	DDRC = 0;
	DDRD = 0;
	DDRE = 0;

	PORTA = 0xff;
	PORTB = 0xff;
	PORTC = 0xff;
	PORTD = 0xff;
	PORTE = 0xff;

	ddr(LED0, 1);
	ddr(ADDR_LE, 1);
	pullup(BUSRQ_n);
	pulldown(RESET_n); /* XXX */

	/* this is helpful when using the bootloader */
	_delay_ms(100);

	uart_init();
	printf_P(PSTR("\n\nHC-forever (C) 2006-2011 by Vampire-\n"
		__DATE__ " " __TIME__ "\n\n"));

	output(LED0, 1);
	clockgen_init();

	printf_P(PSTR("booted\n"));
	while (1) {
		int ch;
		
		printf_P(PSTR("\nmon> "));
		ch = getchar();

		switch (ch) {
		case 'B':
			bootstrap_enable();
			printf_P(PSTR("\nbootstrap active."));
			break;
		case 'b':
			bootstrap_disable();
			printf_P(PSTR("\nbootstrap off."));
			break;

		case 'P':
			printf_P(PSTR("\nasserting BUSRQ; BUSACK = %d"), input(BUSACK_n));
			pulldown(BUSRQ_n);
			break;
		case 'p':
			printf_P(PSTR("\nreleasing BUSRQ; BUSACK = %d"), input(BUSACK_n));
			pullup(BUSRQ_n);
			break;

		case 'w':
			printf_P(PSTR("\nreleasing nWR"));
			pullup(WR_n);
			break;
		case 'W':
			printf_P(PSTR("\nasserting nWR"));
			pulldown(WR_n);
			break;

		case 'm':
			memtest_menu();
			break;

		default:
			/* TODO: print help */
			break;
		}
		
		output(LED0, !input(LED0));
	}
	
	return 0;
}

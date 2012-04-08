static volatile __sfr __at 0xfe port_fe;

int main(void)
{
	while (1) {
		port_fe = 0;
		port_fe = 0xff;
	}
}

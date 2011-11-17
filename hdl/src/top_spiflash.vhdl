-- Top-level module for a GODIL_XC3S500E from OHO-Elektronik
-- Signal names are the ones used by OHO in their reference design

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_spiflash is
port (
	m49, sw1, sw2, sout, rts, c13, d13, tdin:	in  std_logic;
	cts, vs2, sin, cso:				out std_logic;
	tvs1, tvs0, tm1, thsw, tcclk, tmosi:		out std_logic;
	pin:						in std_logic_vector(48 downto 1)
);
end top_spiflash;


architecture beh of top_spiflash is

signal jtag_din		: std_logic_vector(2 downto 0) := (others => '0');
signal spi_cs		: std_logic	:= '1';
signal spi_mosi		: std_logic	:= '0';
signal spi_clk		: std_logic	:= '0';

begin

	jtag_din(2) <= tdin;
	cso	<= spi_cs;
	tcclk	<= spi_clk;
	tmosi	<= spi_mosi;

	bscan: entity work.BscanUser
		generic map (
			DR_LEN		=> jtag_din'length
		)
		port map (
			Clock			=> m49,
			DataIn			=> jtag_din,
			DataOut(2)		=> spi_mosi,
			DataOut(1)		=> spi_clk,
			DataOut(0)		=> spi_cs
		);

	tm1 <= '0';
	thsw <= '0';
	tvs0 <= '0';
	tvs1 <= '0';

	vs2 <= spi_clk;
	cts <= spi_mosi;
	sin <= tdin;

end beh;


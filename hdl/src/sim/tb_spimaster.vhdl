library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spimaster is
end tb_spimaster;

architecture behavioral of tb_spimaster is

constant CLOCK_PERIOD : time := 142 ns;

signal	Clock		: std_logic := '0';             -- tb clock

signal	spi_rst		: std_logic := '0';
signal	spi_wr		: std_logic := '0';
signal	spi_ctrl	: std_logic := '0';
signal	spi_din		: std_logic_vector(7 downto 0);

begin

	spi_master: entity work.SpiMaster
		port map (
			Clock		=> Clock,
			Reset		=> spi_rst,
			WriteEnable	=> spi_wr,
			ControlSelect	=> spi_ctrl,
			DataIn		=> spi_din,
			SpiMiso		=> '1'
		);

	clock_gen: process
	begin
		Clock <= '0';
		wait for CLOCK_PERIOD / 2;
		Clock <= '1';
		wait for CLOCK_PERIOD / 2;
	end process;

	stimulus: process
	begin
		wait for CLOCK_PERIOD;
		spi_rst <= '1';
		wait for CLOCK_PERIOD;
		spi_rst <= '0';

		wait for CLOCK_PERIOD * 3;
		spi_ctrl <= '1';
		spi_din <= x"01";
		wait for CLOCK_PERIOD;
		spi_wr <= '1';
		wait for CLOCK_PERIOD * 2.5;
		spi_wr <= '0';
		wait for CLOCK_PERIOD * 5.5;
		spi_ctrl <= '0';
		wait for CLOCK_PERIOD;
		spi_din <= x"aa";
		spi_wr <= '1';
		wait for CLOCK_PERIOD * 2.5;
		spi_wr <= '0';
		wait for CLOCK_PERIOD * 1000;
	end process;

end behavioral;

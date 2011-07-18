library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pixels is
end tb_pixels;

architecture behavioral of tb_pixels is

component top_pixels is
port (
	Clock7		: in  std_logic := '0';
	VideoAddress	: inout std_logic_vector(13 downto 0);
	VideoData	: in  std_logic_vector(7 downto 0);
	vram_nOE	: out std_logic;
	vram_nWE	: out std_logic;
	LED		: out std_logic;
	DAC		: out std_logic_vector(1 downto 0)
);
end component;

constant CLOCK_PERIOD : time := 142 ns;

signal Clock		: std_logic := '0';             -- tb clock
signal Counter		: std_logic_vector(8 downto 0) := (8 => '1', others => '0');

begin

	top: top_pixels
		port map (
			Clock7		=> Clock,
			VideoAddress	=> open,
			VideoData	=> Counter(7 downto 0)
		);

	clock_gen: process
	begin
		Clock <= '0';
		wait for CLOCK_PERIOD / 2;
		Clock <= '1';
		wait for CLOCK_PERIOD / 2;
	end process;

	process (Clock)
	begin
		if rising_edge(Clock) then
			Counter <= std_logic_vector(unsigned(Counter) + 1);
		end if;
	end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_syncgen is
end tb_syncgen;

architecture behavioral of tb_syncgen is

constant CLOCK_PERIOD : time := 142 ns;

signal	Clock		: std_logic := '0';             -- tb clock

begin

	sync_gen: entity work.SyncGen
		port map (
			Clock7		=> Clock,
			Border		=> open,
			Blank		=> open,
			Sync		=> open
		);

	clock_gen: process
	begin
		Clock <= '0';
		wait for CLOCK_PERIOD / 2;
		Clock <= '1';
		wait for CLOCK_PERIOD / 2;
	end process;

end behavioral;

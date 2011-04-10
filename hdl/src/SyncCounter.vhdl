library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SyncCounter is
generic (
	BITS		: integer := 9					-- number of counter bits
);
port(
	Clock		: in  std_logic;				-- input clock (count on falling edge)
	SyncReset	: in  std_logic;				-- synchronous reset input
	Counter		: out std_logic_vector(BITS - 1 downto 0)	-- counter output bits
);
end SyncCounter;


architecture behavioral of SyncCounter is

signal IntCounter : unsigned(BITS-1 downto 0) := (others => '0');

begin

process(Clock)
begin
	if (falling_edge(Clock)) then
		if SyncReset = '1' then
			IntCounter <= (others => '0');
		else
			IntCounter <= IntCounter + 1;
		end if;
	end if;
end process;

process (IntCounter)
begin
	Counter <= std_logic_vector(IntCounter);
end process;

end behavioral;

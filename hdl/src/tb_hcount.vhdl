library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_hcount is
end tb_hcount;

architecture behavioral of tb_hcount is


component VideoCounter is
generic (
	BITS		: integer;						-- number of counter bits
	TOTAL_LEN	: integer;
	ACTIVE_LEN	: integer;
	BORDER_LEN	: integer;
	BLANK_LEN	: integer;
	PORCH_LEN	: integer;
	SYNC_LEN	: integer
);
port(
	Clock		: in  std_logic;				-- input clock (count on rising edge)
	Enable		: in  std_logic;				-- enable input
	Counter		: out std_logic_vector(BITS - 1 downto 0);	-- counter output bits
	Border		: out std_logic;
	Blank		: out std_logic;
	Sync		: out std_logic;
	Carry		: out std_logic
);
end component;


constant CLOCK_PERIOD : time := 142 ns;

signal	Clock		: std_logic := '0';             -- tb clock
signal	Counter		: std_logic_vector(8 downto 0) := (others => '0');

begin

	hcnt: VideoCounter
		generic map (
			BITS		=> 9,
			TOTAL_LEN	=> 448,
			ACTIVE_LEN	=> 256,
			BORDER_LEN	=> 48,
			BLANK_LEN	=> 96,
			PORCH_LEN	=> 16,
			SYNC_LEN	=> 24
		)
		port map (
			Clock		=> Clock,
			Enable		=> '1',
			Counter		=> Counter,
			Border		=> open,
			Blank		=> open,
			Sync		=> open,
			Carry		=> open
		);

	clock_gen : process
	begin
		Clock <= '0';
		wait for CLOCK_PERIOD / 2;
		Clock <= '1';
		wait for CLOCK_PERIOD / 2;
	end process clock_gen;

end behavioral;

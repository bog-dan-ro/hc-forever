library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Timing constants layout:
--  0
--  |    pixel data    | border | blank | sync | blank | border |
--  |<-- ACTIVE_LEN -->|
--                     |<BORDER>|
--                              |<----- BLANK_LEN ---->|
--                              |<PORCH>|<SYNC>|
--  |<----------------------- TOTAL_LEN ----------------------->|


entity VideoCounter is
generic (
	BITS		: integer := 9;					-- number of counter bits
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
end VideoCounter;


architecture behavioral of VideoCounter is

component SyncCounter is
generic (
	BITS		: integer := 9					-- number of counter bits
);
port(
	Clock		: in  std_logic;				-- input clock (count on rising edge)
	Enable		: in  std_logic;				-- enable input
	SyncReset	: in  std_logic;				-- synchronous reset input
	Counter		: out std_logic_vector(BITS - 1 downto 0)	-- counter output bits
);
end component;

signal	CounterReset	: std_logic;
signal	IntCounter	: std_logic_vector(BITS - 1 downto 0) := (others => '0');

constant BLANK_START	: integer := ACTIVE_LEN + BORDER_LEN;
constant BLANK_END	: integer := BLANK_START + BLANK_LEN - 1;
constant SYNC_START	: integer := BLANK_START + PORCH_LEN;
constant SYNC_END	: integer := SYNC_START + SYNC_LEN - 1;

begin

cnt: SyncCounter
	generic map (
		BITS		=> BITS
	)
	port map (
		Clock		=> Clock,
		Enable		=> Enable,
		SyncReset	=> CounterReset,
		Counter		=> IntCounter
	);

CounterReset	<= '1' when (unsigned(IntCounter) = TOTAL_LEN - 1) else '0';
Border		<= '1' when (unsigned(IntCounter) >= ACTIVE_LEN) else '0';
Blank		<= '1' when (unsigned(IntCounter) >= BLANK_START
			and  unsigned(IntCounter) <= BLANK_END) else '0';
Sync		<= '1' when (unsigned(IntCounter) >= SYNC_START
			and  unsigned(IntCounter) <= SYNC_END) else '0';

Carry		<= CounterReset;
Counter		<= IntCounter;

end behavioral;

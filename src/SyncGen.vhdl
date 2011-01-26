library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SyncGen is
port(
	Clock7		: in  std_logic;				-- master clock (7 MHz)
	Border		: out std_logic;
	Blank		: out std_logic;
	Sync		: out std_logic
);
end SyncGen;


architecture behavioral of SyncGen is

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
	Clock		: in  std_logic;				-- input clock (count on falling edge)
	Counter		: out std_logic_vector(BITS - 1 downto 0);	-- counter output bits
	Border		: out std_logic;
	Blank		: out std_logic;
	Sync		: out std_logic;
	Carry		: out std_logic
);
end component;

signal	HCount		: std_logic_vector(8 downto 0) := (others => '0');
signal	VCount		: std_logic_vector(8 downto 0) := (others => '0');
signal	HBorder		: std_logic;
signal	HBlank		: std_logic;
signal	HSync		: std_logic;
signal	HCarry		: std_logic;
signal	VBorder		: std_logic;
signal	VBlank		: std_logic;
signal	VSync		: std_logic;

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
			Clock		=> Clock7,
			Counter		=> HCount,
			Border		=> HBorder,
			Blank		=> HBlank,
			Sync		=> HSync,
			Carry		=> HCarry
		);

	vcnt: VideoCounter
		generic map (
			BITS		=> 9,
			TOTAL_LEN	=> 312,
			ACTIVE_LEN	=> 192,
			BORDER_LEN	=> 56,
			BLANK_LEN	=> 8,
			PORCH_LEN	=> 0,
			SYNC_LEN	=> 4
		)
		port map (
			Clock		=> HCarry,
			Counter		=> VCount,
			Border		=> VBorder,
			Blank		=> VBlank,
			Sync		=> VSync,
			Carry		=> open
		);

	Border <= HBorder or VBorder;
	Blank <= HBlank or VBlank;
	Sync <= HSync or VSync;

end behavioral;

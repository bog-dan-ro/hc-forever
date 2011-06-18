library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SyncGen is
port(
	Clock7		: in  std_logic;				-- master clock (7 MHz)
	HCount		: out std_logic_vector(8 downto 0);
	VCount		: out std_logic_vector(8 downto 0);
	Border		: out std_logic;
	Blank		: out std_logic;
	Sync		: out std_logic;
	Interrupt	: out std_logic;
	VCarry		: out std_logic
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

signal	HBorder		: std_logic;
signal	HBlank		: std_logic;
signal	HSync		: std_logic;
signal	HCarry		: std_logic;
signal	VBorder		: std_logic;
signal	VBlank		: std_logic;
signal	VSync		: std_logic;
signal	HCountInt	: std_logic_vector(8 downto 0);
signal	VCountInt	: std_logic_vector(8 downto 0);

begin

	hcnt: VideoCounter
		generic map (
			BITS		=> 9,
			TOTAL_LEN	=> 448,
			ACTIVE_LEN	=> 256,
			-- 48 for somewhat better centering, 64 for compatibile timing
			BORDER_LEN	=> 64,
			BLANK_LEN	=> 96,
			PORCH_LEN	=> 16,
			SYNC_LEN	=> 32
		)
		port map (
			Clock		=> Clock7,
			Counter		=> HCountInt,
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
			Counter		=> VCountInt,
			Border		=> VBorder,
			Blank		=> VBlank,
			Sync		=> VSync,
			Carry		=> VCarry
		);

	Border <= HBorder or VBorder;
	Blank <= HBlank or VBlank;
	Sync <= HSync or VSync;
	HCount <= HCountInt;
	VCount <= VCountInt;
	Interrupt <= '1' when VSync = '1'
		and VCountInt(2 downto 0) = "000"
		and HCountInt(8 downto 6) = "000"
		else '0';

end behavioral;

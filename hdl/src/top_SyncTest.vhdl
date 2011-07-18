library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top_SyncTest is
port (
	Clock7		: in  std_logic;
	HCount		: out std_logic_vector(8 downto 0);
	VCount		: out std_logic_vector(8 downto 0);
	Border		: out std_logic;
	Blank		: out std_logic;
	Sync		: out std_logic;
	Flash		: out std_logic;
	DAC		: out std_logic_vector(1 downto 0)
);
end top_SyncTest;


architecture behavioral of top_SyncTest is

component SyncGen is
port(
	Clock7		: in  std_logic;				-- master clock (7 MHz)
	HCount		: out std_logic_vector(8 downto 0);
	VCount		: out std_logic_vector(8 downto 0);
	Border		: out std_logic;
	Blank		: out std_logic;
	Sync		: out std_logic;
	Carry		: out std_logic
);
end component;

signal Carry: std_logic := '0';
signal BorderInt: std_logic := '0';
signal BlankInt: std_logic := '0';
signal SyncInt: std_logic := '0';
signal FlashCount: unsigned(4 downto 0) := (others => '0');
signal HCountInt: std_logic_vector(8 downto 0);
signal VCountInt: std_logic_vector(8 downto 0);

begin

sgen: SyncGen
	port map (
		Clock7		=> Clock7,
		HCount		=> HCountInt,
		VCount		=> VCountInt,
		Border		=> BorderInt,
		Blank		=> BlankInt,
		Sync		=> SyncInt,
		Carry		=> Carry
	);

process (Clock7)
begin
	if rising_edge(Clock7) and Carry = '1' then
		FlashCount <= FlashCount + 1;
	end if;
end process;

Flash <= FlashCount(4);
Border <= BorderInt;
Blank <= BlankInt;
Sync <= SyncInt;
HCount <= HCountInt;
VCount <= VCountInt;


DAC <=	"00" when SyncInt = '1' else
	"01" when BlankInt = '1' else
	"10" when BorderInt = '1' else
	"01" when (HCountInt(0) xor VCountInt(0)) = '0' else
	"10" when (HCountInt(3) xor VCountInt(3)) = '0' else
	"11";

end architecture;

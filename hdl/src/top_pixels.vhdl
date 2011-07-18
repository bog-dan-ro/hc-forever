library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_pixels is
port (
	Clock7		: in  std_logic := '0';
	VideoAddress	: inout std_logic_vector(13 downto 0);
	VideoData	: in  std_logic_vector(7 downto 0);
	vram_nOE	: out std_logic;
	vram_nWE	: out std_logic;
--	Red		: out std_logic;
--	Green		: out std_logic;
--	Blue		: out std_logic;
--	Highlight	: out std_logic;
	LED		: out std_logic;
	DAC		: out std_logic_vector(1 downto 0)
);
end top_pixels;

architecture behavioral of top_pixels is

signal Carry		: std_logic := '0';
signal BlankInt		: std_logic := '0';
signal SyncInt		: std_logic := '0';
signal FlashCount	: unsigned(4 downto 0) := (others => '0');
signal RedInt		: std_logic := '0';
signal GreenInt		: std_logic := '0';
signal BlueInt		: std_logic := '0';

signal VideoAddressInt	: std_logic_vector(13 downto 0);
signal VideoAddressEn	: std_logic := '0';

begin

	vidgen: entity work.VideoGen
		port map (
			Clock7		=> Clock7,
			VideoAddress	=> VideoAddressInt,
			VideoData	=> VideoData,
			VideoDataEn	=> VideoAddressEn,
			VideoBusReq	=> open,
			FrameInterrupt	=> open,
			FrameCarry	=> Carry,
			Red		=> RedInt,
			Green		=> GreenInt,
			Blue		=> BlueInt,
			Highlight	=> open,
			Blank		=> BlankInt,
			Sync		=> SyncInt,
			BorderRed	=> '0',
			BorderGreen	=> '1',
			BorderBlue	=> '1',
			FlashClock	=> FlashCount(4)
		);

	VideoAddress <=
		VideoAddressInt when VideoAddressEn = '1'
		else (others => 'Z');
	vram_nOE <= not VideoAddressEn;
	vram_nWE <= '1';

	process (Clock7)
	begin
		if rising_edge(Clock7) and Carry = '1' then
			FlashCount <= FlashCount + 1;
		end if;
	end process;

	LED	<= FlashCount(4);
--	Red	<= RedInt;
--	Green	<= GreenInt;
--	Blue	<= BlueInt;

	DAC <=	"00" when SyncInt = '1' else
		"01" when BlankInt = '1' else
		"11" when (RedInt = '1' and GreenInt = '1' and BlueInt = '1') else
		"10" when (RedInt = '1' or GreenInt = '1' or BlueInt = '1') else
		"01";

end architecture;

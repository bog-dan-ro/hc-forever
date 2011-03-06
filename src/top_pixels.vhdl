library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_pixels is
port (
	Clock7		: in  std_logic := '0';
--	VideoAddress	: inout std_logic_vector(13 downto 0);
--	Red		: out std_logic;
--	Green		: out std_logic;
--	Blue		: out std_logic;
--	Highlight	: out std_logic;
	Flash		: out std_logic;
	DAC		: out std_logic_vector(1 downto 0)
);
end top_pixels;

architecture behavioral of top_pixels is

signal DataBus		: std_logic_vector(7 downto 0) := x"3c";

signal Pixel		: std_logic := '0';
signal PixelBufLoad	: std_logic := '0';
signal PixelOutLoad	: std_logic := '0';
signal AttrBufLoad	: std_logic := '0';
signal AttrOutLoad	: std_logic := '0';
signal HCounter		: std_logic_vector(8 downto 0) := (others => '0');
signal VCounter		: std_logic_vector(8 downto 0) := (others => '0');
signal DataEnable	: std_logic := '0';

signal VCarry		: std_logic := '0';
signal BorderInt	: std_logic := '0';
signal BlankInt		: std_logic := '0';
signal SyncInt		: std_logic := '0';
signal FlashCount	: unsigned(4 downto 0) := (others => '0');
signal RedInt		: std_logic := '0';
signal GreenInt		: std_logic := '0';
signal BlueInt		: std_logic := '0';

signal VideoAddress	: std_logic_vector(13 downto 0);

begin

	sgen: entity work.SyncGen
		port map (
			Clock7		=> Clock7,
			HCount		=> HCounter,
			VCount		=> VCounter,
			Border		=> BorderInt,
			Blank		=> BlankInt,
			Sync		=> SyncInt,
			VCarry		=> VCarry
		);


	pixel_reg: entity work.PixelReg
		port map (
			Clock		=> Clock7,
			DataBus		=> DataBus,
			BufferLoad	=> PixelBufLoad,
			OutputLoad	=> PixelOutLoad,
			PixelOut	=> Pixel
		);

	attr_reg: entity work.AttributeReg
		port map (
			Clock		=> Clock7,
			DataBus		=> DataBus,
			BufferLoad	=> AttrBufLoad,
			OutputLoad	=> AttrOutLoad,
			DataEnable	=> DataEnable,
			Pixel		=> Pixel,
			BorderRed	=> '0',
			BorderGreen	=> '1',
			BorderBlue	=> '1',
			Red		=> RedInt,
			Green		=> GreenInt,
			Blue		=> BlueInt,
			Highlight	=> open,
			Flash		=> open
		);

	vdata: entity work.VideoData
		port map (
			Clock		=> Clock7,
			HCounter	=> HCounter,
			VCounter	=> VCounter,
			Border		=> BorderInt,
			PixelBufLoad	=> PixelBufLoad,
			PixelOutLoad	=> PixelOutLoad,
			AttrBufLoad	=> AttrBufLoad,
			AttrOutLoad	=> AttrOutLoad,
			DataEnable	=> DataEnable,
			Address		=> VideoAddress,
			AddressEnable	=> open
		);

	DataBus <=
		x"07" when (VideoAddress(12) = '1' and VideoAddress(9) = '0') else
		x"ff" when (VCounter = "000000000") else
		x"55" when (VCounter = "000000001") else
		x"aa" when (VCounter = "000000010") else
		"10" & HCounter(8 downto 3);
--	VideoAddress <=
--		VideoAddressInt when VideoAddressEn = '1'
--		else (others => 'Z');


	process (VCarry)
	begin
		if (falling_edge(VCarry)) then
			FlashCount <= FlashCount + 1;
		end if;
	end process;

	Flash	<= FlashCount(4);
--	Red	<= RedInt;
--	Green	<= GreenInt;
--	Blue	<= BlueInt;

	DAC <=	"00" when SyncInt = '1' else
		"01" when BlankInt = '1' else
		"11" when (RedInt = '1' and GreenInt = '1' and BlueInt = '1') else
		"10" when (RedInt = '1' or GreenInt = '1' or BlueInt = '1') else
		"01";

end architecture;

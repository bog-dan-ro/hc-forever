library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_vidgen is
port (
	Clock7		: in  std_logic := '0';
	VideoAddress	: inout std_logic_vector(13 downto 0);
	VideoData	: in  std_logic_vector(7 downto 0);
	vram_nOE	: out std_logic;
	vram_nWE	: out std_logic;
	cpu_a14		: in  std_logic;
	cpu_a15		: in  std_logic;
	cpu_nRD		: in  std_logic;
	cpu_nWR		: in  std_logic;
	nBootstrap	: in  std_logic;
	BootAddressLatch: in  std_logic;
--	Red		: out std_logic;
--	Green		: out std_logic;
--	Blue		: out std_logic;
--	Highlight	: out std_logic;
	LED		: out std_logic;
	DAC		: out std_logic_vector(1 downto 0)
);
end top_vidgen;

architecture behavioral of top_vidgen is

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

signal VideoAddressInt	: std_logic_vector(13 downto 0);
signal VideoAddressReq	: std_logic := '0';
signal VideoAddressEn	: std_logic := '0';
signal VideoRamOutEn	: std_logic := '0';
signal VideoRamWriteEn	: std_logic := '0';

signal Bootstrap	: std_logic;
signal BootAddress	: std_logic_vector(7 downto 0);

signal CpuReadEn	: std_logic;
signal CpuWriteEn	: std_logic;

begin

	CpuReadEn <= not cpu_nRD;
	CpuWriteEn <= not cpu_nWR;

	-- bootstrap

	Bootstrap <= not nBootstrap;
	process (BootAddressLatch)
	begin
		if rising_edge(BootAddressLatch) then
			BootAddress <= VideoData;
		end if;
	end process;

	-- video

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
			DataBus		=> VideoData,
			BufferLoad	=> PixelBufLoad,
			OutputLoad	=> PixelOutLoad,
			PixelOut	=> Pixel
		);

	attr_reg: entity work.AttributeReg
		port map (
			Clock		=> Clock7,
			DataBus		=> VideoData,
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
			Address		=> VideoAddressInt,
			AddressEnable	=> VideoAddressReq
		);

	VideoAddressEn <=
		'0' when Bootstrap = '1' else
		VideoAddressReq;

	-- TODO: chip select
	VideoRamOutEn <=
		CpuReadEn when Bootstrap = '1' else
		'1';
	VideoRamWriteEn <=
		CpuWriteEn when Bootstrap = '1' else
		'0';

	VideoAddress <=
		(
			7 => BootAddress(7),
			6 => BootAddress(6),
			5 => BootAddress(5),
			4 => BootAddress(4),
			3 => BootAddress(3),
			2 => BootAddress(2),
			1 => BootAddress(1),
			0 => BootAddress(0),
			others => 'Z'
		) when Bootstrap = '1' else
		VideoAddressInt;

	vram_nOE <= not VideoRamOutEn;
	vram_nWE <= not VideoRamWriteEn;

	process (VCarry)
	begin
		if falling_edge(VCarry) then
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

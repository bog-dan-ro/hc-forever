library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VideoGen is
port (
	Clock7		: in  std_logic := '0';				-- 7MHz input pixel clock
	Clock3p5	: out std_logic;				-- 3.5MHz output clock
	VideoAddress	: out std_logic_vector(13 downto 0);		-- video address output
	VideoData	: in  std_logic_vector(7 downto 0);		-- video data input
	VideoDataEn	: out std_logic;				-- video data output enable
	VideoBusReq	: out std_logic;				-- exclusive bus request
	FrameInterrupt	: out std_logic;				-- interrupt output at end of frame
	FrameCarry	: out std_logic;				-- carry out, 1 clock at end of frame
	Red		: out std_logic;
	Green		: out std_logic;
	Blue		: out std_logic;
	Highlight	: out std_logic;
	Blank		: out std_logic;
	Sync		: out std_logic;
	BorderRed	: in  std_logic;
	BorderGreen	: in  std_logic;
	BorderBlue	: in  std_logic;
	FlashClock	: in  std_logic
);
end VideoGen;

architecture behavioral of VideoGen is

signal Pixel		: std_logic := '0';
signal PixelBufLoad	: std_logic := '0';
signal PixelOutLoad	: std_logic := '0';
signal AttrBufLoad	: std_logic := '0';
signal AttrOutLoad	: std_logic := '0';
signal HCounter		: std_logic_vector(8 downto 0) := (others => '0');
signal VCounter		: std_logic_vector(8 downto 0) := (others => '0');
signal DataEnable	: std_logic := '0';

signal Border		: std_logic := '0';


begin

	sgen: entity work.SyncGen
		port map (
			Clock7		=> Clock7,
			HCount		=> HCounter,
			VCount		=> VCounter,
			Border		=> Border,
			Blank		=> Blank,
			Sync		=> Sync,
			Carry		=> FrameCarry
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
			BorderRed	=> BorderRed,
			BorderGreen	=> BorderGreen,
			BorderBlue	=> BorderBlue,
			Red		=> Red,
			Green		=> Green,
			Blue		=> Blue,
			Highlight	=> Highlight,
			FlashClock	=> FlashClock
		);

	vdata: entity work.VideoData
		port map (
			Clock		=> Clock7,
			HCounter	=> HCounter,
			VCounter	=> VCounter,
			Border		=> Border,
			PixelBufLoad	=> PixelBufLoad,
			PixelOutLoad	=> PixelOutLoad,
			AttrBufLoad	=> AttrBufLoad,
			AttrOutLoad	=> AttrOutLoad,
			DataEnable	=> DataEnable,
			Address		=> VideoAddress,
			AddressEnable	=> VideoDataEn
		);

	Clock3p5	<= HCounter(0);
	VideoBusReq	<= HCounter(2) or HCounter(3);

end architecture;

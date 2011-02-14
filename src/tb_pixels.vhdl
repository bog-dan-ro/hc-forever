library ieee;
use ieee.std_logic_1164.all;

entity tb_pixels is
end tb_pixels;

architecture behavioral of tb_pixels is

constant CLOCK_PERIOD : time := 142 ns;

signal Clock		: std_logic := '0';             -- tb clock
signal DataBus		: std_logic_vector(7 downto 0) := x"3c";

signal Pixel		: std_logic := '0';
signal PixelBufLoad	: std_logic := '0';
signal PixelOutLoad	: std_logic := '0';
signal AttrBufLoad	: std_logic := '0';
signal AttrOutLoad	: std_logic := '0';
signal HCounter		: std_logic_vector(8 downto 0) := (8 => '1', others => '0');
signal Border		: std_logic := '0';
signal DataEnable	: std_logic := '0';

begin

	hcnt: entity work.VideoCounter
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
			Counter		=> HCounter,
			Border		=> Border,
			Blank		=> open,
			Sync		=> open,
			Carry		=> open
		);

	pixel_reg: entity work.PixelReg
		port map (
			Clock		=> Clock,
			DataBus		=> DataBus,
			BufferLoad	=> PixelBufLoad,
			OutputLoad	=> PixelOutLoad,
			PixelOut	=> Pixel
		);

	attr_reg: entity work.AttributeReg
		port map (
			Clock		=> Clock,
			DataBus		=> DataBus,
			BufferLoad	=> AttrBufLoad,
			OutputLoad	=> AttrOutLoad,
			DataEnable	=> DataEnable,
			Pixel		=> Pixel,
			BorderRed	=> '0',
			BorderGreen	=> '1',
			BorderBlue	=> '1'
		);

	vdata: entity work.VideoData
		port map (
			Clock		=> Clock,
			HCounter	=> HCounter,
			Border		=> Border,
			PixelBufLoad	=> PixelBufLoad,
			PixelOutLoad	=> PixelOutLoad,
			AttrBufLoad	=> AttrBufLoad,
			AttrOutLoad	=> AttrOutLoad,
			DataEnable	=> DataEnable
		);

	DataBus <= HCounter(DataBus'range);

	clock_gen: process
	begin
		Clock <= '0';
		wait for CLOCK_PERIOD / 2;
		Clock <= '1';
		wait for CLOCK_PERIOD / 2;
	end process;

end architecture;

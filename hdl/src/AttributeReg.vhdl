library ieee;
use ieee.std_logic_1164.all;


entity AttributeReg is
port (
	Clock		: in  std_logic;			-- pixel clock
	DataBus		: in  std_logic_vector(7 downto 0);	-- memory data bus
	BufferLoad	: in  std_logic;			-- latch data into buffer
	OutputLoad	: in  std_logic;			-- latch data into output buffer
	Pixel		: in  std_logic;			-- current pixel
	DataEnable	: in  std_logic;			-- '0' for border
	BorderRed	: in  std_logic;
	BorderGreen	: in  std_logic;
	BorderBlue	: in  std_logic;
	Red		: out std_logic;
	Green		: out std_logic;
	Blue		: out std_logic;
	Highlight	: out std_logic;
	Flash		: out std_logic
);
end AttributeReg;


architecture behavioral of AttributeReg is

signal AttrBuffer	: std_logic_vector(7 downto 0) := (others => '0');
signal OutputBuffer	: std_logic_vector(7 downto 0) := (others => '0');

signal PrevBufLoad	: std_logic := '0';

begin

process (Clock)
begin
	if rising_edge(Clock) then
		-- TODO: this simulates a real edge-triggered FF, but is probably not needed
		if BufferLoad = '1' and PrevBufLoad = '0' then
			AttrBuffer <= DataBus;
		end if;
		PrevBufLoad <= BufferLoad;

		if OutputLoad = '1' then
			OutputBuffer <= AttrBuffer;
			if DataEnable = '0' then
				OutputBuffer(3) <= BorderBlue;
				OutputBuffer(4) <= BorderRed;
				OutputBuffer(5) <= BorderGreen;
				OutputBuffer(6) <= '0';
				OutputBuffer(7) <= '0';
			end if;
		end if;
	end if;
end process;

Blue	<= OutputBuffer(0) when Pixel = '1' else OutputBuffer(3);
Red	<= OutputBuffer(1) when Pixel = '1' else OutputBuffer(4);
Green	<= OutputBuffer(2) when Pixel = '1' else OutputBuffer(5);
Highlight	<= OutputBuffer(6);
Flash		<= OutputBuffer(7);

end architecture;


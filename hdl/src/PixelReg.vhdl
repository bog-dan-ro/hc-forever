library ieee;
use ieee.std_logic_1164.all;


entity PixelReg is
port (
	Clock		: in  std_logic;			-- pixel clock
	DataBus		: in  std_logic_vector(7 downto 0);	-- memory data bus
	BufferLoad	: in  std_logic;			-- latch data into buffer
	OutputLoad	: in  std_logic;			-- latch data into shift register
	PixelOut	: out std_logic
);
end PixelReg;


architecture behavioral of PixelReg is

signal PixelBuffer	: std_logic_vector(7 downto 0) := (others => '0');
signal ShiftReg		: std_logic_vector(7 downto 0) := (others => '0');

signal PrevBufLoad	: std_logic := '0';

begin

process (Clock)
begin
	if rising_edge(Clock) then
		-- TODO: this simulates a real edge-triggered FF, but is probably not needed
		if BufferLoad = '1' and PrevBufLoad = '0' then
			PixelBuffer <= DataBus;
		end if;
		PrevBufLoad <= BufferLoad;

		if OutputLoad = '1' then
			ShiftReg <= PixelBuffer;
		else
			ShiftReg(7 downto 1) <= ShiftReg(6 downto 0);
			ShiftReg(0) <= '0';
		end if;
	end if;
end process;

PixelOut <= ShiftReg(7);

end architecture;


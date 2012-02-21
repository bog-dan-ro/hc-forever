library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity SpiMaster is
port(
	Clock		: in  std_logic;				-- input clock
	Reset		: in  std_logic;				-- async reset
	WriteEnable	: in  std_logic;				-- write command
	ControlSelect	: in  std_logic;				-- 1 to select control port (0 for data)
	ChipSelect	: out std_logic_vector(2 downto 0);		-- CS lines (active high)
	DataIn		: in  std_logic_vector(7 downto 0);
	DataOut		: out std_logic_vector(7 downto 0);
	SpiMiso		: in  std_logic;				-- SPI MISO line
	SpiMosi		: out std_logic;				-- SPI MOSI line
	SpiClock	: out std_logic					-- SPI clock output
);
end SpiMaster;


architecture behavioral of SpiMaster is

signal BitCounter: unsigned(2 downto 0) := (others => '0');
signal Running: std_logic := '0';
signal ChipSelReg: std_logic_vector(ChipSelect'range) := (others => '0');
signal ShiftReg: std_logic_vector(DataIn'range);
signal ChipSelControl: std_logic_vector(1 downto 0);
signal SpiClockReg: std_logic := '1';
signal SpiMosiReg: std_logic;

begin

-- map control register bits
ChipSelControl <= DataIn(1 downto 0);
-- outputs
DataOut <= ShiftReg;
SpiMosi <= SpiMosiReg;
SpiClock <= SpiClockReg;
ChipSelect <= ChipSelReg;

process(Clock, Reset)
begin

	if rising_edge(Clock) then
		if WriteEnable = '1' then
			if ControlSelect = '1' then
				case ChipSelControl is
				when "01" => ChipSelReg <= "001";
				when "10" => ChipSelReg <= "010";
				when "11" => ChipSelReg <= "100";
				when others => ChipSelReg <= "000";
				end case;
			else
				Running <= '1';
				BitCounter <= (others => '0');
				SpiClockReg <= '1';
				SpiMosiReg <= '1';
				ShiftReg <= DataIn;
			end if;
		elsif Running = '1' then
			SpiClockReg <= not SpiClockReg;
			if SpiClockReg = '1' then
				-- falling edge
				SpiMosiReg <= ShiftReg(7);
				ShiftReg <= ShiftReg(6 downto 0) & SpiMiso;
			else
				-- rising edge
				BitCounter <= BitCounter + 1;
				if BitCounter = 7 then
					Running <= '0';
				end if;
			end if;
		end if;
	end if;

	if Reset = '1' then
		Running <= '0';
		BitCounter <= (others => '0');
		ChipSelReg <= (others => '0');
		SpiClockReg <= '1';
	end if;
end process;

end behavioral;

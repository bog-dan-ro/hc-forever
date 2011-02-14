library ieee;
use ieee.std_logic_1164.all;

entity VideoData is
port (
	Clock		: in  std_logic;
	HCounter	: in  std_logic_vector(8 downto 0);
	Border		: in  std_logic;
	PixelBufLoad	: out std_logic;
	PixelOutLoad	: out std_logic;
	AttrBufLoad	: out std_logic;
	AttrOutLoad	: out std_logic;
	DataEnable	: out std_logic
);
end VideoData;

architecture behavioral of VideoData is

signal DataEnableInt	: std_logic := '0';
signal VideoFetch	: std_logic := '0';
signal OutputLoad	: std_logic := '0';

begin

process (HCounter)
begin
	if rising_edge(HCounter(3)) then
		DataEnableInt <= not Border;
	end if;
end process;

VideoFetch <= DataEnableInt and HCounter(3) and HCounter(0) and Clock;
PixelBufLoad <= VideoFetch and not HCounter(1);
AttrBufLoad  <= VideoFetch and HCounter(1);

OutputLoad <= HCounter(2) and not HCounter(1) and not HCounter(0) and Clock;
AttrOutLoad <= OutputLoad;
PixelOutLoad <= OutputLoad and DataEnableInt;

DataEnable <= DataEnableInt;

end architecture;

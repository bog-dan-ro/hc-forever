library ieee;
use ieee.std_logic_1164.all;

entity VideoData is
port (
	Clock		: in  std_logic;
	HCounter	: in  std_logic_vector(8 downto 0);
	VCounter	: in  std_logic_vector(8 downto 0);
	Border		: in  std_logic;
	PixelBufLoad	: out std_logic;
	PixelOutLoad	: out std_logic;
	AttrBufLoad	: out std_logic;
	AttrOutLoad	: out std_logic;
	DataEnable	: out std_logic;
	Address		: out std_logic_vector(13 downto 0)
);
end VideoData;

architecture behavioral of VideoData is

signal DataEnableInt	: std_logic := '0';
signal VideoFetch	: std_logic := '0';
signal OutputLoad	: std_logic := '0';

signal PixelAddrEn	: std_logic := '0';
signal AttrAddrEn	: std_logic := '0';

signal PixelAddress	: std_logic_vector(13 downto 0);
signal AttrAddress	: std_logic_vector(13 downto 0);

signal DelayedHC3	: std_logic;

begin

process (HCounter(3))
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

PixelAddrEn <= DataEnableInt and HCounter(3) and not HCounter(1);
AttrAddrEn <= DataEnableInt and HCounter(3) and HCounter(1);

-- equivalent to delaying HCounter(3) by 4 clock cycles
DelayedHC3 <= not (HCounter(3) xor HCounter(2));

AttrAddress <= "0110"
	& VCounter(7 downto 3)
	& HCounter(7 downto 4)
	& DelayedHC3;
PixelAddress <= "0"
	& VCounter(7 downto 6)
	& VCounter(2 downto 0)
	& VCounter(5 downto 3)
	& HCounter(7 downto 4)
	& DelayedHC3;

Address <=
	PixelAddress when PixelAddrEn = '1' else
	AttrAddress when AttrAddrEn = '1' else
	(others => 'Z');

end architecture;

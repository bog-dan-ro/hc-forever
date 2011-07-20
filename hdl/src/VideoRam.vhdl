-- 32 Kbyte Block RAM, one R/W port, one read-only port

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity VideoRam is
generic (
	ADDR_BITS		: integer := 15;
	DATA_BITS		: integer := 8
);
port (
	Clock			: in  std_logic;
	Enable			: in  std_logic;
	WriteEnable		: in  std_logic;
	Address			: in  std_logic_vector(ADDR_BITS-1 downto 0);
	DataIn			: in  std_logic_vector(DATA_BITS-1 downto 0);
	DataOut			: out std_logic_vector(DATA_BITS-1 downto 0);

	DualEnable		: in  std_logic;
	DualAddress		: in  std_logic_vector(ADDR_BITS-1 downto 0);
	DualDataOut		: out std_logic_vector(DATA_BITS-1 downto 0)
);
end VideoRam;

architecture behavioral of VideoRam is

type ram_type is array (0 to 2**ADDR_BITS - 1) of std_logic_vector (DataOut'range);
signal RAM: ram_type := (
	others => x"07"
);

signal ReadAddress: std_logic_vector(Address'range);
signal DualReadAddress: std_logic_vector(DualAddress'range);

attribute syn_ramstyle: string;
attribute syn_ramstyle of RAM: signal is "block_ram";

begin

	process (Clock)
	begin
		if rising_edge(Clock) then
			if Enable = '1' and WriteEnable = '1' then
				RAM(conv_integer(Address)) <= DataIn;
			end if;

			if Enable = '1' then
				ReadAddress <= Address;
			end if;
			if DualEnable = '1' then
				DualReadAddress <= DualAddress;
			end if;
		end if;
	end process;

	DataOut <= RAM(conv_integer(ReadAddress));
	DualDataOut <= RAM(conv_integer(DualReadAddress));

end behavioral;

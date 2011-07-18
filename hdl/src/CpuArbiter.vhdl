library ieee;
use ieee.std_logic_1164.all;


entity CpuArbiter is
port (
	Clock		: in  std_logic;			-- input half clock (3.5 MHz)
	CpuAddress	: in  std_logic_vector(15 downto 14);
	CpuMemReq	: in  std_logic;			-- /MREQ
	IoPortReq	: in  std_logic;			-- I/O port 0xfe access
	VidGenReq	: in  std_logic;
	CpuClock	: out std_logic
);
end CpuArbiter;


architecture behavioral of CpuArbiter is

signal CpuHold		: std_logic := '0';
signal CpuClockInt	: std_logic := '0';
signal MreqT23		: std_logic := '0';

begin

	CpuHold		<=
		'0' when (MreqT23 = '1') else
		IoPortReq or (CpuMemReq and not CpuAddress(15) and CpuAddress(14));

	CpuClockInt	<=
		'1' when (CpuHold = '1' and VidGenReq = '1') else
		Clock;

	CpuClock	<= CpuClockInt;

	process (CpuClockInt)
	begin
		if rising_edge(CpuClockInt) then
			MreqT23 <= CpuMemReq or IoPortReq;
		end if;
	end process;

end architecture;


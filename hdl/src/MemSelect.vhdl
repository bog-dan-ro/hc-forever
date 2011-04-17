library ieee;
use ieee.std_logic_1164.all;


entity MemSelect is
port (
	CpuAddress	: in  std_logic_vector(15 downto 14);	-- Address bus bits
	CpuMemReq	: in  std_logic;			-- /MREQ
	CpuIoReq	: in  std_logic;			-- /IORQ
	CpuReadEn	: in  std_logic;			-- /RD
	CpuWriteEn	: in  std_logic;			-- /WR
	Bootstrap	: in  std_logic;			-- /BUSACK
	VideoAddressReq	: in  std_logic;			-- vidgen RAM request
	RamSelect	: out std_logic_vector(0 to 1);		-- main RAM /CS (for each chip)
	RamPage		: out std_logic;			-- main RAM A14
	VideoRamOutEn	: out std_logic;			-- video RAM /OE
	VideoRamWriteEn	: out std_logic				-- video RAM /WE
);
end MemSelect;


architecture behavioral of MemSelect is

signal MemReq		: std_logic;
signal CpuVideoSel	: std_logic;
signal CpuRomSel	: std_logic;
signal CpuRamSel	: std_logic;
signal VideoAddressEn	: std_logic;

begin

	MemReq <= CpuMemReq or Bootstrap;

	CpuVideoSel	<= MemReq and not CpuAddress(15) and CpuAddress(14);
	CpuRomSel	<= MemReq and not CpuAddress(15) and not CpuAddress(14);
	CpuRamSel	<= MemReq and CpuAddress(15);

	VideoAddressEn <=
		'0' when Bootstrap = '1' else
		VideoAddressReq;

	VideoRamOutEn <=
		'1' when VideoAddressEn = '1' else
		CpuReadEn when CpuVideoSel = '1' else
		'0';
	VideoRamWriteEn <=
		'0' when VideoAddressEn = '1' else
		CpuWriteEn when CpuVideoSel = '1'
		else '0';

	RamSelect(0)	<= CpuRomSel;
	RamSelect(1)	<= CpuRamSel;
	RamPage		<= CpuAddress(14);

end architecture;

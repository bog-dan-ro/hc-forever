library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_vidgen is
port (
	Clock7		: in  std_logic := '0';
	VideoAddress	: inout std_logic_vector(13 downto 0);
	VideoData	: in  std_logic_vector(7 downto 0);
	vram_nOE	: out std_logic;
	vram_nWE	: out std_logic;
	cpu_clk		: out std_logic;
	cpu_nINT	: out std_logic;
	cpu_a14		: in  std_logic;
	cpu_a15		: in  std_logic;
	cpu_a0		: in  std_logic;
	cpu_nRD		: in  std_logic;
	cpu_nWR		: in  std_logic;
	cpu_nMREQ	: in  std_logic;
	cpu_nIORQ	: in  std_logic;
	ram_nCS0	: out std_logic;
	ram_nCS1	: out std_logic;
	ram_a14		: out std_logic;
	nBootstrap	: in  std_logic;
	BootAddressLatch: in  std_logic;
--	Red		: out std_logic;
--	Green		: out std_logic;
--	Blue		: out std_logic;
--	Highlight	: out std_logic;
	InFE		: out std_logic;
	OutFE		: out std_logic;
	LED		: out std_logic;
	DAC		: out std_logic_vector(1 downto 0)
);
end top_vidgen;

architecture behavioral of top_vidgen is

signal Clock3p5		: std_logic := '0';
signal Carry		: std_logic := '0';
signal BlankInt		: std_logic := '0';
signal SyncInt		: std_logic := '0';
signal FlashCount	: unsigned(4 downto 0) := (others => '0');
signal RedInt		: std_logic := '0';
signal GreenInt		: std_logic := '0';
signal BlueInt		: std_logic := '0';

signal VideoAddressInt	: std_logic_vector(13 downto 0);
signal VideoAddressReq	: std_logic := '0';
signal VideoAddressEn	: std_logic := '0';
signal VideoRamOutEn	: std_logic := '0';
signal VideoRamWriteEn	: std_logic := '0';
signal VidGenReq	: std_logic := '0';

signal Bootstrap	: std_logic;
signal BootAddress	: std_logic_vector(7 downto 0);

signal CpuMemReq	: std_logic;
signal CpuIoReq		: std_logic;
signal CpuReadEn	: std_logic;
signal CpuWriteEn	: std_logic;
signal CpuVideoSel	: std_logic;
signal CpuRomSel	: std_logic;
signal CpuRamSel	: std_logic;
signal CpuFeReq		: std_logic;
signal CpuInterrupt	: std_logic;

begin

	-- CPU interface
	CpuReadEn <= not cpu_nRD;
	CpuWriteEn <= not cpu_nWR;
	CpuMemReq <= Bootstrap or (not cpu_nMREQ);
	CpuIoReq <= not cpu_nIORQ;
	cpu_nINT <= not CpuInterrupt;

	CpuVideoSel	<= CpuMemReq and not cpu_a15 and cpu_a14;
	CpuRomSel	<= CpuMemReq and not cpu_a15 and not cpu_a14;
	CpuRamSel	<= CpuMemReq and cpu_a15;

	CpuFeReq	<= CpuIoReq and not cpu_a0;
	InFE		<= CpuIoReq and not cpu_a0 and CpuReadEn;
	OutFE		<= CpuIoReq and not cpu_a0 and CpuWriteEn;

	arb: entity work.CpuArbiter
		port map (
			Clock		=> Clock3p5,
			CpuAddress(15)	=> cpu_a15,
			CpuAddress(14)	=> cpu_a14,
			CpuMemReq	=> CpuMemReq,
			IoPortReq	=> CpuFeReq,
			VidGenReq	=> VidGenReq,
			CpuClock	=> cpu_clk
		);

	-- bootstrap

	Bootstrap <= not nBootstrap;
	process (BootAddressLatch)
	begin
		if rising_edge(BootAddressLatch) then
			BootAddress <= VideoData;
		end if;
	end process;

	-- video

	vidgen: entity work.VideoGen
		port map (
			Clock7		=> Clock7,
			Clock3p5	=> Clock3p5,
			VideoAddress	=> VideoAddressInt,
			VideoData	=> VideoData,
			VideoDataEn	=> VideoAddressReq,
			VideoBusReq	=> VidGenReq,
			FrameInterrupt	=> CpuInterrupt,
			FrameCarry	=> Carry,
			Red		=> RedInt,
			Green		=> GreenInt,
			Blue		=> BlueInt,
			Highlight	=> open,
			Blank		=> BlankInt,
			Sync		=> SyncInt,
			BorderRed	=> '0',
			BorderGreen	=> '1',
			BorderBlue	=> '1',
			FlashClock	=> FlashCount(4)
		);

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

	VideoAddress <=
		VideoAddressInt when VideoAddressEn = '1' else
		(
			7 => BootAddress(7),
			6 => BootAddress(6),
			5 => BootAddress(5),
			4 => BootAddress(4),
			3 => BootAddress(3),
			2 => BootAddress(2),
			1 => BootAddress(1),
			0 => BootAddress(0),
			others => 'Z'
		) when Bootstrap = '1' else
		(others => 'Z');

	vram_nOE <= not VideoRamOutEn;
	vram_nWE <= not VideoRamWriteEn;

	-- main RAM

	ram_nCS0 <= not CpuRomSel;
	ram_nCS1 <= not CpuRamSel;
	ram_a14 <= cpu_a14;

	-- flash

	process (Clock7)
	begin
		if rising_edge(Clock7) and Carry = '1' then
			FlashCount <= FlashCount + 1;
		end if;
	end process;

	LED	<= FlashCount(4);
--	Red	<= RedInt;
--	Green	<= GreenInt;
--	Blue	<= BlueInt;

	-- composite video (sort of, luma only)

	DAC <=	"00" when SyncInt = '1' else
		"01" when BlankInt = '1' else
		"11" when (RedInt = '1' and GreenInt = '1' and BlueInt = '1') else
		"10" when (RedInt = '1' or GreenInt = '1' or BlueInt = '1') else
		"01";

end architecture;

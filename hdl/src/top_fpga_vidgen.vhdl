-- Top-level module for a GODIL_XC3S500E from OHO-Elektronik
-- Signal names are the ones used by OHO in their reference design

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_fpga_vidgen is
port (
	m49, sw1, sw2, sout, rts, c13, d13:		in  std_logic;
	cts, cso, vs2, sin:				out std_logic;
	tvs1, tvs0, tmosi, tdin, tcclk, tm1, thsw:	out std_logic;
	pin:						out std_logic_vector(48 downto 1)
);
end top_fpga_vidgen;


architecture beh of top_fpga_vidgen is

signal Clock7		: std_logic;
signal Clock3p5		: std_logic;
signal CpuClock		: std_logic;

signal Carry		: std_logic := '0';
signal Blank		: std_logic := '0';
signal Highlight	: std_logic := '0';
signal Sync		: std_logic := '0';
signal Red		: std_logic := '0';
signal Green		: std_logic := '0';
signal Blue		: std_logic := '0';
signal FlashCount	: unsigned(4 downto 0) := (others => '0');

signal VideoAddress	: std_logic_vector(13 downto 0);
signal VideoDataEn	: std_logic := '0';
signal VideoData	: std_logic_vector(7 downto 0);

signal vram_addr	: std_logic_vector(15 downto 0);
signal mem_addr		: std_logic_vector(15 downto 0);
signal mem_din		: std_logic_vector(7 downto 0);
signal mem_dout		: std_logic_vector(7 downto 0);
signal mem_sel		: std_logic;
signal mem_wr		: std_logic;

signal jtag_din		: std_logic_vector(31 downto 0);
signal jtag_dout	: std_logic_vector(jtag_din'range);
signal jtag_we		: std_logic;

signal cpu_mreq_n	: std_logic;
signal cpu_iorq_n	: std_logic;
signal cpu_rd_n		: std_logic;
signal cpu_wr_n		: std_logic;
signal cpu_int_n	: std_logic;
signal cpu_wait_n	: std_logic;
signal cpu_addr		: std_logic_vector(15 downto 0);
signal cpu_din		: std_logic_vector(7 downto 0);
signal cpu_dout		: std_logic_vector(7 downto 0);

signal cpu_mreq		: std_logic;
signal cpu_iorq		: std_logic;
signal cpu_rd		: std_logic;
signal cpu_wr		: std_logic;
signal cpu_int		: std_logic;
signal cpu_wait		: std_logic;

begin

	clocking: entity work.GodilClocking
		port map (
			BoardClock	=> m49,
			Clock7		=> Clock7,
			Clock3p5	=> Clock3p5,
			CpuClock	=> CpuClock
		);

	vidgen: entity work.VideoGen
		port map (
			Clock7		=> Clock7,
			Clock3p5	=> Clock3p5,
			VideoAddress	=> VideoAddress,
			VideoData	=> VideoData,
			VideoDataEn	=> VideoDataEn,
			VideoBusReq	=> cpu_wait,
			FrameInterrupt	=> cpu_int,
			FrameCarry	=> Carry,
			Red		=> Red,
			Green		=> Green,
			Blue		=> Blue,
			Highlight	=> Highlight,
			Blank		=> Blank,
			Sync		=> Sync,
			BorderRed	=> '1',
			BorderGreen	=> '1',
			BorderBlue	=> '1',
			FlashClock	=> FlashCount(4)
		);

	vram: entity work.VideoRam
		port map (
			Clock		=> Clock7,
			Enable		=> mem_sel,
			Address		=> mem_addr(14 downto 0),
			DataOut		=> mem_dout,
			WriteEnable	=> mem_wr,
			DataIn		=> mem_din,
			DualEnable	=> VideoDataEn,
			DualAddress	=> vram_addr(14 downto 0),
			DualDataOut	=> VideoData
		);

	bscan: entity work.BscanUser
		generic map (
			DR_LEN		=> jtag_din'length
		)
		port map (
			DataIn		=> jtag_din,
			DataOut		=> jtag_dout
		);

	z80: entity work.T80s port map (
		RESET_n => sw2,			-- sw2 is active low
		CLK_n => CpuClock,
		WAIT_n => '1', --cpu_wait_n,
		INT_n => cpu_int_n,
		NMI_n => '1',
		BUSRQ_n => '1',
		M1_n => open,
		MREQ_n => cpu_mreq_n,
		IORQ_n => cpu_iorq_n,
		RD_n => cpu_rd_n,
		WR_n => cpu_wr_n,
		RFSH_n => open,
		HALT_n => cts,
		BUSAK_n => open,
		A => cpu_addr,
		DI => cpu_din,
		DO => cpu_dout
	);

	cpu_rd <= not cpu_rd_n;
	cpu_wr <= not cpu_wr_n;
	cpu_mreq <= not cpu_mreq_n;
	cpu_iorq <= not cpu_iorq_n;
	cpu_int_n <= not cpu_int;
	cpu_wait_n <= not cpu_wait;

	-- video ram & jtag

	jtag_we <= jtag_dout(31);

	mem_sel <= cpu_mreq or jtag_we;
	mem_wr <= (cpu_mreq and cpu_wr) or jtag_we;
	mem_addr <= jtag_dout(23 downto 8) when jtag_we = '1' else cpu_addr;
	mem_din <= jtag_dout(7 downto 0) when jtag_we = '1' else cpu_dout;
	cpu_din <= mem_dout; -- XXX select

	vram_addr <= "01" & VideoAddress;

	process (Clock7)
	begin
		if rising_edge(Clock7) then
			jtag_din <= (24 => sw1, 25 => sw2, others => '0');
			if VideoDataEn = '1' and VideoAddress = jtag_dout(21 downto 8) then
				-- sniff video ram
				jtag_din(7 downto 0) <= VideoData;
				jtag_din(21 downto 8) <= VideoAddress;
				jtag_din(31) <= '1';
			end if;
		end if;
	end process;

	-- flash
	process (Clock7)
	begin
		if rising_edge(Clock7) and Carry = '1' then
			FlashCount <= FlashCount + 1;
		end if;
	end process;

	-- 5-bit passive DAC
	pin(6 downto 2) <=
		"00000" when Sync = '1' else
		"10000" when Blank = '1' else
		"1" & Highlight & Green & Red & Blue;

	pin(1) <= '0';
	pin(48 downto 7) <= (others => '0');

	tm1 <= '0';
	thsw <= '0';
	tcclk <= '0';
	tdin <= '0';
	tmosi <= '0';
	tvs0 <= '0';
	tvs1 <= '0';

	vs2 <= FlashCount(4);
	cso <= '1';
	sin <= sout xor sw1 xor sw2 xor rts xor c13 xor d13;

end beh;
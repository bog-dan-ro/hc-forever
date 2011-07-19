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

signal vram_ce_n	: std_logic;
signal vram_we_n	: std_logic;
signal vram_addr	: std_logic_vector(13 downto 0);
signal vram_din		: std_logic_vector(7 downto 0);
signal vram_we		: std_logic;

signal jtag_din		: std_logic_vector(31 downto 0);
signal jtag_dout	: std_logic_vector(jtag_din'range);

begin

	clocking: entity work.GodilClocking
		port map (
			BoardClock	=> m49,
			Clock7		=> Clock7
		);

	vidgen: entity work.VideoGen
		port map (
			Clock7		=> Clock7,
			VideoAddress	=> VideoAddress,
			VideoData	=> VideoData,
			VideoDataEn	=> VideoDataEn,
			VideoBusReq	=> open,
			FrameInterrupt	=> open,
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

	vram: entity work.SSRAM
		generic map (
			AddrWidth	=> 14,
			DataWidth	=> 8
		)
		port map (
			Clk		=> Clock7,
			CE_n		=> vram_ce_n,
			WE_n		=> vram_we_n,
			A		=> vram_addr,
			DIn		=> vram_din,
			DOut		=> VideoData
		);

	bscan: entity work.BscanUser
		generic map (
			DR_LEN		=> jtag_din'length
		)
		port map (
			DataIn		=> jtag_din,
			DataOut		=> jtag_dout
		);

	-- video ram & jtag
	vram_addr <=
		jtag_dout(21 downto 8) when vram_we = '1' else
		VideoAddress when VideoDataEn = '1' else
		(others => '-');
	vram_ce_n <= not (VideoDataEn or vram_we);
	vram_we_n <= not vram_we;
	vram_din <= jtag_dout(7 downto 0);
	vram_we <= jtag_dout(31);

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
	cts <= not sw1;
	sin <= sout xor sw1 xor sw2 xor rts xor c13 xor d13;

end beh;

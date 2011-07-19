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
signal BlankInt		: std_logic := '0';
signal SyncInt		: std_logic := '0';
signal FlashCount	: unsigned(4 downto 0) := (others => '0');
signal RedInt		: std_logic := '0';
signal GreenInt		: std_logic := '0';
signal BlueInt		: std_logic := '0';

signal VideoAddressInt	: std_logic_vector(13 downto 0);
signal VideoAddressEn	: std_logic := '0';
signal VideoData	: std_logic_vector(7 downto 0);

begin

	clocking: entity work.GodilClocking
		port map (
			BoardClock	=> m49,
			Clock7		=> Clock7
		);

	vidgen: entity work.VideoGen
		port map (
			Clock7		=> Clock7,
			VideoAddress	=> VideoAddressInt,
			VideoData	=> VideoData,
			VideoDataEn	=> VideoAddressEn,
			VideoBusReq	=> open,
			FrameInterrupt	=> open,
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

	process (Clock7)
	begin
		if rising_edge(Clock7) and Carry = '1' then
			FlashCount <= FlashCount + 1;
		end if;
	end process;

end beh;

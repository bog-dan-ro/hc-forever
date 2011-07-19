library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.Vcomponents.ALL;

entity GodilClocking is
port (
	BoardClock		: in  std_logic;	-- input board clock (49.152 MHz)
	Clock7			: out std_logic		-- DCM clock output (7-ish MHz)
);
end GodilClocking;

architecture rtl of GodilClocking is

signal CLKDV_BUF	: std_logic;
signal CLKFB_IN		: std_logic;
signal CLKIN_IBUFG	: std_logic;
signal CLK0_BUF		: std_logic;
signal GND_BIT		: std_logic;

begin
	GND_BIT <= '0';
--	CLKIN_IBUFG_OUT <= CLKIN_IBUFG;
--	CLK0_OUT <= CLKFB_IN;

	CLKDV_BUFG_INST: BUFG
		port map (
			I	=> CLKDV_BUF,
			O	=> Clock7
		);

	CLKIN_IBUFG_INST: IBUFG
		port map (
			I	=> BoardClock,
			O	=> CLKIN_IBUFG
		);

	CLK0_BUFG_INST: BUFG
		port map (
			I	=> CLK0_BUF,
			O	=> CLKFB_IN
		);

	DCM_SP_INST: DCM_SP
		generic map (
			CLK_FEEDBACK		=> "1X",
			CLKDV_DIVIDE		=> 7.0,
			CLKFX_DIVIDE		=> 1,
			CLKFX_MULTIPLY		=> 4,
			CLKIN_DIVIDE_BY_2	=> FALSE,
			CLKIN_PERIOD		=> 20.345,
			CLKOUT_PHASE_SHIFT	=> "NONE",
			DESKEW_ADJUST		=> "SYSTEM_SYNCHRONOUS",
			DFS_FREQUENCY_MODE	=> "LOW",
			DLL_FREQUENCY_MODE	=> "LOW",
			DUTY_CYCLE_CORRECTION	=> TRUE,
			FACTORY_JF		=> x"C080",
			PHASE_SHIFT		=> 0,
			STARTUP_WAIT		=> FALSE
		)
		port map (
			CLKFB		=> CLKFB_IN,
			CLKIN		=> CLKIN_IBUFG,
			DSSEN		=> GND_BIT,
			PSCLK		=> GND_BIT,
			PSEN		=> GND_BIT,
			PSINCDEC	=> GND_BIT,
			RST		=> GND_BIT,
			CLKDV		=> CLKDV_BUF,
			CLKFX		=> open,
			CLKFX180	=> open,
			CLK0		=> CLK0_BUF,
			CLK2X		=> open,
			CLK2X180	=> open,
			CLK90		=> open,
			CLK180		=> open,
			CLK270		=> open,
			LOCKED		=> open,
			PSDONE		=> open,
			STATUS		=> open
		);

end rtl;

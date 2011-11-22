-- Top-level module for a GODIL_XC3S500E from OHO-Elektronik
-- Signal names are the ones used by OHO in their reference design

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.ALL;

entity top_spiraw is
port (
	m49, sw1, sw2, sout, rts, c13, d13, tdin:	in  std_logic;
	cts, vs2, sin, cso:				out std_logic;
	tvs1, tvs0, tm1, thsw, tcclk, tmosi:		out std_logic;
	pin:						in std_logic_vector(48 downto 1)
);
end top_spiraw;


architecture beh of top_spiraw is

signal jtag_capture		: std_logic;
signal jtag_drck1		: std_logic;
signal jtag_drck2		: std_logic;
signal jtag_reset		: std_logic;
signal jtag_sel1		: std_logic;
signal jtag_sel2		: std_logic;
signal jtag_shift		: std_logic;
signal jtag_tdi			: std_logic;
signal jtag_update		: std_logic;
signal jtag_tdo1		: std_logic;
signal jtag_tdo2		: std_logic;

signal data_buf			: std_logic_vector(1 downto 0);

signal spi_cs		: std_logic	:= '1';
signal spi_mosi		: std_logic	:= '0';
signal spi_clk		: std_logic	:= '0';

type state_type is (LOAD, EXEC);
signal state	: state_type := LOAD;


begin

	bscan: BSCAN_SPARTAN3
	port map (
		CAPTURE		=> jtag_capture,
		DRCK1		=> jtag_drck1,
		DRCK2		=> jtag_drck2,
		RESET		=> jtag_reset,
		SEL1		=> jtag_sel1,
		SEL2		=> jtag_sel2,
		SHIFT		=> jtag_shift,
		TDI		=> jtag_tdi,
		UPDATE		=> jtag_update,
		TDO1		=> jtag_tdo1,
		TDO2		=> jtag_tdo2
	);

	process (jtag_reset, jtag_drck1)
	begin
		if jtag_reset = '1' then
			spi_cs <= '1';
			spi_clk <= '0';
			spi_mosi <= '0';
			state <= LOAD;
		elsif rising_edge(jtag_drck1) then
			if jtag_shift = '0' then
				data_buf <= "00";
				state <= LOAD;
			else
				data_buf <= data_buf(0) & jtag_tdi;
				if state = LOAD then
					state <= EXEC;
					spi_clk <= '0';
				else
					state <= LOAD;
					spi_clk <= '1';
					case data_buf is
					when "01" =>
						spi_cs <= '1';
					when "10" =>
						spi_cs <= '0';
					when "00" =>
						spi_mosi <= '0';
					when "11" =>
						spi_mosi <= '1';
					when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;

	jtag_tdo1 <= tdin;

--	process (jtag_reset, jtag_update)
--	begin
--		if jtag_reset = '1' then
--			DataOutBuf <= (others => '0');
--		elsif rising_edge(jtag_update) then
--			if jtag_sel1 = '1' then
--				DataOutBuf <= jtag_dr;
--			end if;
--		end if;
--	end process;

	cso	<= spi_cs;
	tcclk	<= spi_clk;
	tmosi	<= spi_mosi;

	tm1 <= '0';
	thsw <= '0';
	tvs0 <= '0';
	tvs1 <= '0';

	vs2 <= spi_clk;
	cts <= spi_mosi;
	sin <= tdin;

end beh;


-- Top-level module for a GODIL_XC3S500E from OHO-Elektronik
-- Signal names are the ones used by OHO in their reference design

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_spiflash is
generic (
	BUFFER_BITS	: integer := 16 * 8
);
port (
	m49, sw1, sw2, sout, rts, c13, d13, tdin:	in  std_logic;
	cts, vs2, sin, cso:				out std_logic;
	tvs1, tvs0, tm1, thsw, tcclk, tmosi:		out std_logic;
	pin:						in std_logic_vector(48 downto 1)
);
end top_spiflash;


architecture beh of top_spiflash is

signal jtag_din		: std_logic_vector(BUFFER_BITS + 24 - 1 downto 0) := (others => '0');
signal jtag_dout	: std_logic_vector(jtag_din'range);
signal spi_cs		: std_logic	:= '1';
signal spi_mosi		: std_logic	:= '0';
signal spi_clk		: std_logic	:= '0';

type state_type is (IDLE, CLK_LO, CLK_HI, DONE);
signal spi_state	: state_type := IDLE;

signal spi_start	: std_logic	:= '0';
signal spi_start_prev	: std_logic	:= '0';
signal spi_start_buf	: std_logic	:= '0';
signal spi_count	: std_logic_vector(18 downto 0);
signal spi_buf		: std_logic_vector(BUFFER_BITS - 1 downto 0);

signal jtag_cmd_start	: std_logic;
signal jtag_cmd_reset	: std_logic;
signal jtag_reg_dlen	: std_logic_vector(15 downto 0);
signal jtag_reg_buf	: std_logic_vector(spi_buf'range);

begin
	jtag_cmd_reset	<= jtag_dout(0);
	jtag_cmd_start	<= jtag_dout(1);
	jtag_reg_dlen	<= jtag_dout(23 downto 8);
	jtag_reg_buf	<= jtag_dout(BUFFER_BITS+24-1 downto 24);

	jtag_din(BUFFER_BITS+24-1 downto 24) <= spi_buf;
	jtag_din(0) <= spi_cs;
	jtag_din(4) <= '1' when spi_state = IDLE else '0';
	jtag_din(5) <= '1' when spi_state = CLK_LO else '0';
	jtag_din(6) <= '1' when spi_state = CLK_HI else '0';
	jtag_din(7) <= '1' when spi_state = DONE else '0';
	jtag_din(15 downto 8) <= (others => '1');
	jtag_din(23 downto 16) <= jtag_dout(7 downto 0);


	spi_fsm: process(m49)
	begin
		if rising_edge(m49) then
			case spi_state is
			when IDLE =>
				if jtag_cmd_start = '1' then
					spi_state <= CLK_HI;
					spi_buf <= jtag_reg_buf;
					spi_count(18 downto 3) <= jtag_reg_dlen;
					spi_count(2 downto 0) <= (others => '0');
					spi_cs <= '0';
					spi_clk <= '0';
				end if;
			when CLK_LO =>
				spi_clk <= '1';
				spi_state <= CLK_HI;
			when CLK_HI =>
				spi_clk <= '0';
				spi_mosi <= spi_buf(BUFFER_BITS - 1);
				spi_buf(BUFFER_BITS-1 downto 1) <= spi_buf(BUFFER_BITS-2 downto 0);
				spi_buf(0) <= tdin;
				spi_count <= std_logic_vector(unsigned(spi_count) - 1);
				if unsigned(spi_count) = 0 then
					spi_state <= DONE;
				else
					spi_state <= CLK_LO;
				end if;
			when DONE =>
				spi_cs <= '1';
			end case;

			if jtag_cmd_reset = '1' then
				spi_state <= IDLE;
				spi_cs <= '1';
				spi_clk <= '1';
				spi_mosi <= '1';
			end if;
		end if;
	end process;

	cso	<= spi_cs;
	tcclk	<= spi_clk;
	tmosi	<= spi_mosi;

	bscan: entity work.BscanUser
		generic map (
			DR_LEN		=> jtag_din'length
		)
		port map (
			Clock			=> m49,
			DataIn			=> jtag_din,
			DataOut			=> jtag_dout
		);

	tm1 <= '0';
	thsw <= '0';
	tvs0 <= '0';
	tvs1 <= '0';

	vs2 <= spi_clk;
	cts <= spi_mosi;
	sin <= tdin;

end beh;


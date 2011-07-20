library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.Vcomponents.ALL;

entity BscanUser is
generic (
	DR_LEN			: integer := 8		-- data register length (bits)
);
port (
	Clock			: in  std_logic;
	DataIn			: in  std_logic_vector(DR_LEN-1 downto 0);
	DataOut			: out std_logic_vector(DR_LEN-1 downto 0)
);
end BscanUser;

architecture beh of BscanUser is

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
signal jtag_dr			: std_logic_vector(DR_LEN-1 downto 0);
signal DataOutBuf		: std_logic_vector(jtag_dr'range);

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
			jtag_dr <= (others => '0');
		elsif rising_edge(jtag_drck1) then
			if jtag_shift = '0' then
				jtag_dr <= DataIn;
			else
				jtag_dr(jtag_dr'high) <= jtag_tdi;
				for k in 0 to jtag_dr'high - 1 loop
					jtag_dr(k) <= jtag_dr(k + 1);
				end loop;
			end if;
		end if;
	end process;

	jtag_tdo1 <= jtag_dr(0);

	process (jtag_reset, jtag_update)
	begin
		if jtag_reset = '1' then
			DataOutBuf <= (others => '0');
		elsif rising_edge(jtag_update) then
			if jtag_sel1 = '1' then
				DataOutBuf <= jtag_dr;
			end if;
		end if;
	end process;

	process (Clock)
	begin
		if rising_edge(Clock) then
			DataOut <= DataOutBuf;
		end if;
	end process;

end beh;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_arbiter is
end tb_arbiter;

architecture behavioral of tb_arbiter is


constant CLOCK_PERIOD : time := 142 ns;

signal	Clock		: std_logic := '0';             -- tb clock
signal	Counter		: std_logic_vector(8 downto 0) := (others => '0');

signal	CpuClock	: std_logic;

signal	mreq		: std_logic := '-';
signal	fereq		: std_logic := '0';
signal	vidreq		: std_logic := '0';

signal	nMREQ		: std_logic := '1';
signal	nRFSH		: std_logic := '1';
signal	nRD		: std_logic := '1';
signal	nWR		: std_logic := '1';
signal	nM1		: std_logic := '1';
signal	ADDR		: std_logic_vector(15 downto 0) := x"0000";

begin
	hcnt: entity work.VideoCounter
		generic map (
			BITS		=> 9,
			TOTAL_LEN	=> 448,
			ACTIVE_LEN	=> 256,
			BORDER_LEN	=> 48,
			BLANK_LEN	=> 96,
			PORCH_LEN	=> 16,
			SYNC_LEN	=> 24
		)
		port map (
			Clock		=> Clock,
			Enable		=> '1',
			Counter		=> Counter,
			Border		=> open,
			Blank		=> open,
			Sync		=> open,
			Carry		=> open
		);

	arb: entity work.CpuArbiter
		port map (
			Clock		=> Counter(0),
			CpuAddress(15)	=> ADDR(15),
			CpuAddress(14)	=> ADDR(14),
			CpuMemReq	=> mreq,
			IoPortReq	=> fereq,
			VidGenReq	=> vidreq,
			CpuClock	=> CpuClock
		);

	vidreq	<= Counter(2) or Counter(3);
	mreq	<= not nMREQ;
	-- fereq	<= (not nIORQ) and (not ADDR(0));
	fereq	<= '0';

	stim: process
	begin
		------ CPU fetch
		-- t1
		nM1 <= '0';
		ADDR <= x"4242";
		wait for CLOCK_PERIOD / 2;
		nMREQ <= '0';
		nRD <= '0';
		wait for CLOCK_PERIOD / 2;
		-- t2
		wait for CLOCK_PERIOD;
		-- t3
		ADDR <= x"aaaa";
		nMREQ <= '1';
		nRD <= '1';
		nM1 <= '1';
		nRFSH <= '0';
		wait for CLOCK_PERIOD / 2;
		nMREQ <= '0';
		wait for CLOCK_PERIOD / 2;
		-- t4
		wait for CLOCK_PERIOD / 2;
		nMREQ <= '1';
		wait for CLOCK_PERIOD / 2;
		-- next t1
		nRFSH <= '1';
		ADDR <= (others => 'X');

	end process stim;

	clock_gen: process
	begin
		Clock <= '0';
		wait for CLOCK_PERIOD / 2;
		Clock <= '1';
		wait for CLOCK_PERIOD / 2;
	end process clock_gen;

end behavioral;

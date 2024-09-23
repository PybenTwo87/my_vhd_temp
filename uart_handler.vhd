LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uart_handler IS
PORT (
	clk             : IN  STD_LOGIC;
	reset_n         : IN  STD_LOGIC;
	tx_start        : IN  STD_LOGIC;
	tx_data_32      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
	tx              : OUT STD_LOGIC;
	rx              : IN  STD_LOGIC;
	rx_data_32      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	rx_done         : OUT STD_LOGIC;
	tx_done         : OUT STD_LOGIC;
	tx_busy         : OUT STD_LOGIC;
	rx_busy         : OUT STD_LOGIC
);
END uart_handler;

ARCHITECTURE Behavioral OF uart_handler IS

COMPONENT uart
	GENERIC(
		clk_freq  :  INTEGER    := 50_000_000;
		baud_rate :  INTEGER    := 9_600;
		os_rate   :  INTEGER    := 16;
		d_width   :  INTEGER    := 8;
		parity    :  INTEGER    := 0;
		parity_eo :  STD_LOGIC  := '0');
	PORT(
		clk      :  IN   STD_LOGIC;
		reset_n  :  IN   STD_LOGIC;
		tx_ena   :  IN   STD_LOGIC;
		tx_data  :  IN   STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
		rx       :  IN   STD_LOGIC;
		rx_busy  :  OUT  STD_LOGIC;
		rx_done  :  OUT  STD_LOGIC;
		rx_error :  OUT  STD_LOGIC;
		rx_data  :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
		tx_busy  :  OUT  STD_LOGIC;
		tx_done  :  OUT  STD_LOGIC;
		tx       :  OUT  STD_LOGIC
	);
END COMPONENT;

TYPE statetypeTX IS (ready, s0, s1, done_dly); --needed states
SIGNAL stateTX : statetypeTX := ready;

TYPE statetypeRX IS (ready, s0, s1, done_dly); --needed states
SIGNAL stateRX : statetypeRX := ready;

SIGNAL byte_count_tx : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0'); 
SIGNAL tx_data_out   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
SIGNAL tx_done_dly_cntr : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
SIGNAL tx_start_reg_00, tx_start_reg_01  : STD_LOGIC := '0';
SIGNAL tx_ena 	 	 : STD_LOGIC := '0';
SIGNAL tx_busy_in 	 : STD_LOGIC := '0';
SIGNAL tx_done_in    : STD_LOGIC := '0';

SIGNAL byte_count_rx : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
SIGNAL rx_data_in	 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
SIGNAL rx_data32_reg : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
SIGNAL rx_done_dly_cntr : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
SIGNAL rx_done_in : STD_LOGIC := '0';
SIGNAL rx_busy_in 	 : STD_LOGIC := '0';

SIGNAL rst : STD_LOGIC;

BEGIN

-- UART TX HANDLER
uart_tx_handler : PROCESS(clk, rst)
BEGIN
	IF(rst = '1')THEN
		byte_count_tx <= (OTHERS => '0');
		tx_data_out <= (OTHERS => '0');
		tx_done_dly_cntr <= (OTHERS => '0');
		tx_ena <= '0';
		tx_done <= '0';
		stateTX <= ready;
	ELSE
		IF(clk'EVENT AND clk = '1')THEN
			CASE stateTX IS
				WHEN ready =>
					tx_done <= '0';
					byte_count_tx <= (OTHERS => '0');
					tx_done_dly_cntr <= (OTHERS => '0');
					tx_data_out <= tx_data_32(31 DOWNTO 24);
					IF(tx_start_reg_01 = '1')THEN
						byte_count_tx <= byte_count_tx + '1';
						tx_ena <= '1';
						stateTX <= s0;
					ELSE
						tx_ena <= '0';
						stateTX <= ready;
					END IF;
				WHEN s0 =>
					tx_ena <= '0';
					IF(tx_done_in = '1')THEN
						IF(byte_count_tx = 1)THEN
							byte_count_tx <= byte_count_tx + '1';
							tx_data_out <= tx_data_32(23 DOWNTO 16);
							stateTX <= s1;
						ELSIF(byte_count_tx = 2)THEN
							byte_count_tx <= byte_count_tx + '1';
							tx_data_out <= tx_data_32(15 DOWNTO 8);
							stateTX <= s1;
						ELSIF(byte_count_tx = 3)THEN
							byte_count_tx <= byte_count_tx + '1';
							tx_data_out <= tx_data_32(7 DOWNTO 0);
							stateTX <= s1;
						ELSE
							tx_done <= '1';
							stateTX <= done_dly;
						END IF;
					ELSE
						stateTX <= s0;
					END IF;
				WHEN s1 =>
					tx_ena <= '1';
					stateTX <= s0;
				WHEN done_dly =>
					tx_done_dly_cntr <= tx_done_dly_cntr + '1';
					IF(tx_done_dly_cntr >= 16)THEN
						tx_done <= '0';
						stateTX <= ready;
					ELSE
						stateTX <= done_dly;
					END IF;
			END CASE;					
		END IF;
	END IF;
END PROCESS;

tx_busy <= tx_busy_in;

-- UART RX HANDLER
uart_rx_handler : PROCESS(clk, rst)
BEGIN
	IF(rst = '1')THEN
		stateRX <= ready;
		byte_count_rx <= (OTHERS => '0');
		rx_data32_reg <= (OTHERS => '0');
		rx_done_dly_cntr <= (OTHERS => '0');
		rx_done <= '0';
	ELSE
		IF(clk'EVENT AND clk = '1')THEN
			CASE stateRX IS
				WHEN ready =>
					byte_count_rx <= (OTHERS => '0');
					rx_done_dly_cntr <= (OTHERS => '0');
					rx_done <= '0';
					IF(rx_done_in = '1')THEN
						byte_count_rx <= byte_count_rx + '1';
						rx_data32_reg(31 DOWNTO 24) <= rx_data_in;
						stateRX <= s0;
					ELSE
						stateRX <= ready;
					END IF;
				WHEN s0 =>
					IF(byte_count_rx = 1)THEN
						IF(rx_done_in = '1')THEN
							byte_count_rx <= byte_count_rx + '1';
							rx_data32_reg(23 DOWNTO 16) <= rx_data_in;
							stateRX <= s0;	
						ELSE
							stateRX <= s0;	
						END IF;
					ELSIF(byte_count_rx = 2)THEN
						IF(rx_done_in = '1')THEN
							byte_count_rx <= byte_count_rx + '1';
							rx_data32_reg(15 DOWNTO 8) <= rx_data_in;
							stateRX <= s0;	
						ELSE
							stateRX <= s0;	
						END IF;
					ELSIF(byte_count_rx = 3)THEN
						IF(rx_done_in = '1')THEN
							byte_count_rx <= byte_count_rx + '1';
							rx_data32_reg(7 DOWNTO 0) <= rx_data_in;
							rx_done <= '1';
							stateRX <= done_dly;	
						ELSE
							stateRX <= s0;	
						END IF;
					END IF;					
				WHEN s1 =>
					stateRX <= s0;
				WHEN done_dly =>
					rx_done_dly_cntr <= rx_done_dly_cntr + '1';
					IF(rx_done_dly_cntr >= 16)THEN
						rx_done <= '0';
						stateRX <= ready;
					ELSE
						stateRX <= done_dly;
					END IF;
			END CASE;
		END IF;
	END IF;
END PROCESS;

PROCESS(rst, clk)
BEGIN
	IF(reset_n = '0')THEN
		tx_start_reg_00 <= '0';
		tx_start_reg_01 <= '0';
	ELSE
		IF(clk'EVENT AND clk = '1')THEN
			tx_start_reg_00 <= tx_start;
			tx_start_reg_01 <= tx_start_reg_00 AND NOT(tx_start);
		END IF;
	END IF;
END PROCESS;

rx_data_32 <= rx_data32_reg;
rx_busy <= rx_busy_in;

rst <= NOT(reset_n);

-- UART Instantiation
uart_handlr_inst: uart 
GENERIC MAP( 
	clk_freq  => 100_000_000,  -- Example clock frequency 
	baud_rate => 9_600,       -- Example baud rate
	os_rate   => 16,          -- Example oversampling rate
	d_width   => 8,           -- Example data width
	parity    => 0,           -- No parity
	parity_eo => '0'          -- Even parity
)
PORT MAP(
	clk       => clk,
	reset_n   => reset_n,
	tx_ena    => tx_ena,
	tx_data   => tx_data_out,
	rx        => rx,
	rx_busy   => rx_busy_in,
	rx_done   => rx_done_in,
	rx_error  => OPEN,
	rx_data   => rx_data_in,
	tx_busy   => tx_busy_in,
	tx_done   => tx_done_in,
	tx        => tx 
);
END Behavioral;

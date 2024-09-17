------------------------------------------------------------------------
------------------------------------------------------------------------
-- R. BERUMEN 20240914
-- Modulo processing for 8-digit seven-segment display on Nexys A7.
--
-- Instatiation Template
--
--COMPONENT ss_mod_calc IS
--	PORT(
--		clk 		: IN  STD_LOGIC;
--		en			: IN  STD_LOGIC;
--		reset		: IN  STD_LOGIC;
--		input_reg	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
--		digit_0_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
--		digit_1_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
--		digit_2_reg : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
--		digit_3_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
--		digit_4_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
--		digit_5_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
--		digit_6_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
--		digit_7_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0')	
--	);
--END COMPONENT;
--
--my_ss_mod_calc : ss_mod_calc
--	PORT MAP(
--		clk 		=> clk, 		
--		en			=> en,			
--		reset		=> reset,		
--		input_reg	=> input_reg,	
--		digit_0_reg	=> digit_0_reg,	
--		digit_1_reg	=> digit_1_reg,
--		digit_2_reg => digit_2_reg, 
--		digit_3_reg	=> digit_3_reg,	
--		digit_4_reg	=> digit_4_reg,	
--		digit_5_reg	=> digit_5_reg,	
--		digit_6_reg	=> digit_6_reg,	
--		digit_7_reg	=> digit_7_reg	
--	);
--	
------------------------------------------------------------------------
------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ss_mod_calc IS
	PORT(
		clk 		: IN  STD_LOGIC;
		en			: IN  STD_LOGIC;
		reset		: IN  STD_LOGIC;
		input_reg	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		digit_0_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
		digit_1_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
		digit_2_reg : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
		digit_3_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
		digit_4_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
		digit_5_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
		digit_6_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');	
		digit_7_reg	: OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0')	
	);
END ss_mod_calc;

ARCHITECTURE behavior OF ss_mod_calc IS

SIGNAL digit_reg_temp : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

TYPE statetype IS(ready, s0, s1, s2, s3, s4, s5); --needed states
SIGNAL state : statetype; 
SIGNAL digit_cntr : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";

BEGIN

-- Modulo State Machine
ss_mod_calc_proc : PROCESS(clk, reset)

VARIABLE n_reg_a : UNSIGNED(15 DOWNTO 0);
VARIABLE n_reg_b : UNSIGNED(15 DOWNTO 0);

BEGIN
	IF(reset = '1')THEN
		state <= ready;
		digit_reg_temp 	<= (OTHERS => '0');
		digit_cntr		<= (OTHERS => '0');
		n_reg_a 		:= (OTHERS => '0');
		n_reg_b 		:= (OTHERS => '0');
	ELSIF(clk'EVENT AND clk = '1')THEN
		CASE state IS
			WHEN ready =>
				digit_reg_temp <= (OTHERS => '0');			
				IF(en = '1')THEN
					n_reg_a := UNSIGNED(input_reg);
					state <= s0;
				ELSE
					state <= ready;
				END IF;
			WHEN s0 =>
				n_reg_b := n_reg_a MOD 10;
				state <= s4;
			WHEN s1 =>
				n_reg_a := n_reg_a - n_reg_b;
				state <= s2;
			WHEN s2 =>
				n_reg_a := n_reg_a / 10;
				state <= s3;
			WHEN s3 =>
				n_reg_b := n_reg_a MOD 10;
				state <= s4;
			WHEN s4 =>
				digit_reg_temp <= STD_LOGIC_VECTOR(n_reg_b);
				state <= s5;
			WHEN s5 =>
				IF(digit_cntr = 0)THEN
					digit_cntr <= digit_cntr + '1';
					digit_0_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= s1;
				ELSIF(digit_cntr = 1)THEN
					digit_cntr <= digit_cntr + '1';				
					digit_1_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= s1;
				ELSIF(digit_cntr = 2)THEN
					digit_cntr <= digit_cntr + '1';
					digit_2_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= s1;
				ELSIF(digit_cntr = 3)THEN
					digit_cntr <= digit_cntr + '1';
					digit_3_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= s1;
				ELSIF(digit_cntr = 4)THEN
					digit_cntr <= digit_cntr + '1';
					digit_4_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= s1;
				ELSIF(digit_cntr = 5)THEN
					digit_cntr <= digit_cntr + '1';				
					digit_5_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= s1;
				ELSIF(digit_cntr = 6)THEN
					digit_cntr <= digit_cntr + '1';				
					digit_6_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= s1;
				ELSIF(digit_cntr = 7)THEN
					digit_cntr <= (OTHERS => '0');				
					digit_7_reg <= digit_reg_temp(3 DOWNTO 0);
					state <= ready;
				END IF;
		END CASE;
	END IF;
END PROCESS;

END behavior;
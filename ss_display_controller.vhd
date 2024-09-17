LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ss_display_controller IS
	PORT(
		clk 		: IN STD_LOGIC;
		en			: IN STD_LOGIC;
		reset	    : IN STD_LOGIC;
		input_reg	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		DP			: OUT STD_LOGIC;
		CG  		: OUT STD_LOGIC;
		CF  		: OUT STD_LOGIC;
		CE  		: OUT STD_LOGIC;
		CD  		: OUT STD_LOGIC;
		CC  		: OUT STD_LOGIC;
		CB  		: OUT STD_LOGIC;
		CA  		: OUT STD_LOGIC;
		anode_out	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000"
	);
END ss_display_controller;

ARCHITECTURE behav OF ss_display_controller IS

COMPONENT ss_mod_calc IS
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
END COMPONENT;

COMPONENT anode_en_gen IS
	PORT(
		clk 	: IN  STD_LOGIC;
		reset	: IN  STD_LOGIC;
		AN		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111110"	
	);
END COMPONENT;

COMPONENT pos_edge_det                    
	PORT(                                   
		clk		: IN  STD_LOGIC;            
		reset	: IN  STD_LOGIC;            
		din		: IN  STD_LOGIC;            
		qout	: OUT STD_LOGIC := '0'      
	);                                      
END COMPONENT;  

CONSTANT num_0_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "11000000"; --p g f e d c b a 
CONSTANT num_1_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111001"; --p g f e d c b a 
CONSTANT num_2_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "10100100"; --p g f e d c b a 
CONSTANT num_3_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "10110000"; --p g f e d c b a 
CONSTANT num_4_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "10011001"; --p g f e d c b a 
CONSTANT num_5_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "10010010"; --p g f e d c b a 
CONSTANT num_6_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "10000010"; --p g f e d c b a 
CONSTANT num_7_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111000"; --p g f e d c b a 
CONSTANT num_8_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "10000000"; --p g f e d c b a 
CONSTANT num_9_mask 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "10010000"; --p g f e d c b a 

SIGNAL digit_7_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_6_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_5_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_4_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_3_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_2_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_1_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_0_reg_01	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
SIGNAL digit_out_reg	: STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');

SIGNAL anode_out_reg_00	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111110";
SIGNAL anode_out_reg 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111110";
SIGNAL delay_cntr00 	: STD_LOGIC_VECTOR(18 DOWNTO 0) := (OTHERS => '0');

SIGNAL en00 			: STD_LOGIC := '0';

SIGNAL bcd_out_reg		: STD_LOGIC_VECTOR(7 DOWNTO 0) := num_0_mask;

BEGIN

-- anode enable generator
an_en_gen : PROCESS(clk, reset)
BEGIN
	IF(reset = '1')THEN
		anode_out_reg_00 <= "11111110";
		delay_cntr00 <= (OTHERS => '0');
	ELSE
		IF(clk'EVENT AND clk = '1')THEN	
			delay_cntr00 <= delay_cntr00 + '1';
			IF(delay_cntr00 >= 200000)THEN -- 2ms @ 100 MHz
				anode_out_reg_00 <= anode_out_reg_00(6 DOWNTO 1) & anode_out_reg_00(0) & anode_out_reg_00(7);
				delay_cntr00 <= (OTHERS => '0');
			ELSE 	
				delay_cntr00 <= delay_cntr00 + '1';
			END IF;
		END IF;
	END IF;
END PROCESS;

-- Binary output registers
dff_digit : PROCESS(clk, reset)
BEGIN
	IF(reset = '1')THEN
		digit_out_reg <= (OTHERS => '0');
		anode_out_reg <= "11111110";
	ELSE
		IF(clk'EVENT AND clk = '1')THEN
			IF(anode_out_reg_00 =  "01111111")THEN
				digit_out_reg <= digit_7_reg_01;
			ELSIF(anode_out_reg_00 = "10111111")THEN
				digit_out_reg <= digit_6_reg_01;
			ELSIF(anode_out_reg_00 = "11011111")THEN
				digit_out_reg <= digit_5_reg_01;
			ELSIF(anode_out_reg_00 = "11101111")THEN
				digit_out_reg <= digit_4_reg_01;
			ELSIF(anode_out_reg_00 = "11110111")THEN
				digit_out_reg <= digit_3_reg_01;
			ELSIF(anode_out_reg_00 = "11111011")THEN
				digit_out_reg <= digit_2_reg_01;
			ELSIF(anode_out_reg_00 = "11111101")THEN
				digit_out_reg <= digit_1_reg_01;
			ELSIF(anode_out_reg_00 = "11111110")THEN
				digit_out_reg <= digit_0_reg_01;
			END IF;
			anode_out_reg <= anode_out_reg_00;			
		END IF;
	END IF;
END PROCESS;

anode_out <= anode_out_reg;

-- Decimal output registers
bcd_proc : PROCESS(clk, reset)
BEGIN
	IF(reset = '1')THEN
		bcd_out_reg <= num_0_mask;
	ELSE
		IF(clk'EVENT AND clk = '1')THEN
			IF(digit_out_reg = 0)THEN
				bcd_out_reg <= num_0_mask;
			ELSIF(digit_out_reg = 1)THEN
				bcd_out_reg <= num_1_mask;
			ELSIF(digit_out_reg = 2)THEN
				bcd_out_reg <= num_2_mask;
			ELSIF(digit_out_reg = 3)THEN
				bcd_out_reg <= num_3_mask;
			ELSIF(digit_out_reg = 4)THEN
				bcd_out_reg <= num_4_mask;
			ELSIF(digit_out_reg = 5)THEN
				bcd_out_reg <= num_5_mask;
			ELSIF(digit_out_reg = 6)THEN
				bcd_out_reg <= num_6_mask;
			ELSIF(digit_out_reg = 7)THEN
				bcd_out_reg <= num_7_mask;
			ELSIF(digit_out_reg = 8)THEN
				bcd_out_reg <= num_8_mask;
			ELSIF(digit_out_reg = 9)THEN
				bcd_out_reg <= num_9_mask;
			ELSE
				bcd_out_reg <= num_0_mask;
			END IF;
		END IF;
	END IF;
END PROCESS;

--p g f e d c b a 
DP <= bcd_out_reg(7);
CG <= bcd_out_reg(6);
CF <= bcd_out_reg(5);
CE <= bcd_out_reg(4);
CD <= bcd_out_reg(3);
CC <= bcd_out_reg(2);
CB <= bcd_out_reg(1);
CA <= bcd_out_reg(0);

my_ss_mod_calc : ss_mod_calc
PORT MAP(
	clk 		=> clk, 		
	en			=> en00,			
	reset		=> reset,		
	input_reg	=> input_reg,	
	digit_0_reg	=> digit_0_reg_01,
	digit_1_reg	=> digit_1_reg_01,
	digit_2_reg => digit_2_reg_01,
	digit_3_reg	=> digit_3_reg_01,
	digit_4_reg	=> digit_4_reg_01,
	digit_5_reg	=> digit_5_reg_01,
	digit_6_reg	=> digit_6_reg_01,
	digit_7_reg	=> digit_7_reg_01
);

my_pos_edge_det : pos_edge_det            
PORT MAP(                                 
	clk		=> clk,                         
	reset	=> reset,                       
	din		=> en,                         
	qout	=> en00                         
);   

END behav;
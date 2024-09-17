--------------------------------------------
--------------------------------------------
--R. BERUMEN 20240914                      
--Instatiation template                    
--COMPONENT pos_edge_det                    
--	PORT(                                   
--		clk		: IN  STD_LOGIC;            
--		reset	: IN  STD_LOGIC;            
--		din		: IN  STD_LOGIC;            
--		qout	: OUT STD_LOGIC := '0'      
--	);                                      
--END COMPONENT;                            
--                                          
--my_pos_edge_det : pos_edge_det            
--PORT MAP(                                 
--	clk		=> clk,                         
--	reset	=> reset,                       
--	din		=> din,                         
--	qout	=> qout                         
--);                                        
--------------------------------------------
--------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pos_edge_det IS
	PORT(
		clk		: IN  STD_LOGIC;
		reset	: IN  STD_LOGIC;
		din		: IN  STD_LOGIC;
		qout	: OUT STD_LOGIC := '0'
	);
END pos_edge_det;

ARCHITECTURE behavior OF pos_edge_det IS

SIGNAL dff0, dff1 : STD_LOGIC := '0';

BEGIN

pos_edge : PROCESS(clk, reset)
BEGIN
	IF(reset = '1')THEN
		dff0 <= '0';
		dff1 <= '0';
	ELSE
		IF(clk'EVENT AND clk = '1')THEN
			dff0 <= din;
			dff1 <= dff0;
			qout <= din AND NOT(dff1);
		END IF;
	END IF;
END PROCESS;

END behavior;
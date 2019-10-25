library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fb_fsm_tb is
end entity;

architecture test of fb_fsm_tb is
	
	constant MAX_CYCLES : integer:= 4;
	constant NUM_DATA_CHANNELS : integer := 4;
	constant Mclk_period : time := 10ns;
	signal Mclk : std_logic := '0';
	signal rst : std_logic := '1';
	signal ch1_data_in : std_logic_vector(79 downto 0) := (others=>'0');
	signal ch2_data_in : std_logic_vector(79 downto 0) := (others=>'0');
	signal ch3_data_in : std_logic_vector(79 downto 0) := (others=>'0');
	signal ch4_data_in : std_logic_vector(79 downto 0) := (others=>'0');
	signal data_valid_in : std_logic := '0';
	signal out_data 	: std_logic_vector(MAX_CYCLES*NUM_DATA_CHANNELS -1 downto 0);
	signal data_valid_out : std_logic;
	signal data_valid_in_check : std_logic;
	signal index_check : integer;
	
	component fb_fsm
	generic(
		constant MAX_CYCLES : integer := 4
	);
	port(
		--IN/OUT
		data_out 			: out std_logic_vector((MAX_CYCLES*NUM_DATA_CHANNELS - 1) downto 0);
		ch1_in  			: in  std_logic_vector(79 downto 0);
		ch2_in  			: in  std_logic_vector(79 downto 0);
		ch3_in  			: in  std_logic_vector(79 downto 0);
		ch4_in  			: in  std_logic_vector(79 downto 0);
		data_valid_out    	: out std_logic;
		clk      			: in  std_logic;
		rst      			: in  std_logic;
		data_valid_in		: in  std_logic;

		
		--FOR TESTING PURPOSES
		data_valid_in_check				: out std_logic;
		index_check 		: out integer
	);
	end component;

begin
	
	fb_fsm1 : fb_fsm 
	GENERIC MAP ( MAX_CYCLES => MAX_CYCLES )
	PORT MAP(
		data_out 		=> out_data,
		ch1_in 			=> ch1_data_in,
		ch2_in  		=> ch2_data_in,
		ch3_in  		=> ch3_data_in,
		ch4_in  		=> ch4_data_in,
		data_valid_out  => data_valid_out,
		clk      		=> Mclk,
		rst      		=> rst,
		data_valid_in	=> data_valid_in,

		--FOR TESTING PURPOSES
		data_valid_in_check		=> data_valid_in_check,
		index_check 	=> index_check
	);
	
	Mclk_process : process
	begin
		Mclk <= '0';
		wait for Mclk_period/2;
		Mclk <= '1';
		wait for Mclk_period/2;
	end process;
	
	stimulus : process
	begin
		wait for 100 ns;
		
		wait until Mclk = '1';
		
		-- TEST CASE 1:
		rst <= '0';
		data_valid_in <= '0';
		ch1_data_in <= (others=> '0');
		ch2_data_in <= (others=> '0');
		ch3_data_in <= (others=> '0');
		ch4_data_in <= (others=> '0');
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_120A";
		ch2_data_in <= x"0000_0000_0000_0000_30D4";
		ch3_data_in <= x"0000_0000_0000_0000_28AA";
		ch4_data_in <= x"0000_0000_0000_0000_1211";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_1234";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_1234";
		ch4_data_in <= x"0000_0000_0000_0000_1234";		
        wait for 10 ns;
        
		-- TEST CASE 2:
		rst <= '1';
		data_valid_in <= '0';
		ch1_data_in <= (others=> '0');
		ch2_data_in <= (others=> '0');
		ch3_data_in <= (others=> '0');
		ch4_data_in <= (others=> '0');
		wait for 10 ns;
		rst <= '0';
		data_valid_in <= '1';
		ch1_data_in <= (others=> '0');
		ch2_data_in <= (others=> '0');
		ch3_data_in <= (others=> '0');
		ch4_data_in <= (others=> '0');
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_120A";
		ch2_data_in <= x"0000_0000_0000_0000_30D4";
		ch3_data_in <= x"0000_0000_0000_0000_28AA";
		ch4_data_in <= x"0000_0000_0000_0000_1211";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_1234";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_1234";
		ch4_data_in <= x"0000_0000_0000_0000_1234";	
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_120A";
		ch2_data_in <= x"0000_0000_0000_0000_30D4";
		ch3_data_in <= x"0000_0000_0000_0000_28AA";
		ch4_data_in <= x"0000_0000_0000_0000_1211";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_1234";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_1234";
		ch4_data_in <= x"0000_0000_0000_0000_1234";	
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_120A";
		ch2_data_in <= x"0000_0000_0000_0000_30D4";
		ch3_data_in <= x"0000_0000_0000_0000_28AA";
		ch4_data_in <= x"0000_0000_0000_0000_1211";
		wait for 10 ns;
		
		-- TEST CASE 3:
		rst <= '1';
		data_valid_in <= '0';
		ch1_data_in <= (others=>'0');
		ch2_data_in <= (others=>'0');
		ch3_data_in <= (others=>'0');
		ch4_data_in <= (others=>'0');
		wait for 10 ns;
		rst <= '0';
		data_valid_in <= '1';
		ch1_data_in <= (others=> '0');
		ch2_data_in <= (others=> '0');
		ch3_data_in <= (others=> '0');
		ch4_data_in <= (others=> '0');
		wait for 10 ns;
		ch1_data_in <= x"0000_0000_0000_0000_120A";
		ch2_data_in <= x"0000_0000_0000_0000_30D4";
		ch3_data_in <= x"0000_0000_0000_0000_28AA";
		ch4_data_in <= x"0000_0000_0000_0000_1211";
		wait for 10 ns;
		data_valid_in <= '0';
		ch1_data_in <= x"0000_0000_0000_0000_1234";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		data_valid_in <= '1';
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		data_valid_in <= '0';
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_1234";
		ch4_data_in <= x"0000_0000_0000_0000_1234";	
		wait for 10 ns;
		data_valid_in <= '0';
		ch1_data_in <= x"0000_0000_0000_0000_120A";
		ch2_data_in <= x"0000_0000_0000_0000_30D4";
		ch3_data_in <= x"0000_0000_0000_0000_28AA";
		ch4_data_in <= x"0000_0000_0000_0000_1211";
		wait for 10 ns;
		data_valid_in <= '1';
		ch1_data_in <= x"0000_0000_0000_0000_1234";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		data_valid_in <= '1';
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_0032";
		ch4_data_in <= x"0000_0000_0000_0000_0121";
		wait for 10 ns;
		data_valid_in <= '1';
		ch1_data_in <= x"0000_0000_0000_0000_0032";
		ch2_data_in <= x"0000_0000_0000_0000_3214";
		ch3_data_in <= x"0000_0000_0000_0000_1234";
		ch4_data_in <= x"0000_0000_0000_0000_1234";	
		wait for 10 ns;
		data_valid_in <= '0';
		ch1_data_in <= x"0000_0000_0000_0000_120A";
		ch2_data_in <= x"0000_0000_0000_0000_30D4";
		ch3_data_in <= x"0000_0000_0000_0000_28AA";
		ch4_data_in <= x"0000_0000_0000_0000_1211";
		wait for 10 ns;
		
		wait;
		
	end process;
	
end;

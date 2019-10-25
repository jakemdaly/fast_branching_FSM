library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fb_fsm is

	generic(
		MAX_CYCLES : integer := 4;
		NUM_DATA_CHANNELS : integer := 4
	);
	port(
		--IN/OUT
		data_out 			: out std_logic_vector((MAX_CYCLES*4 - 1) downto 0);
		ch1_in  			: in  std_logic_vector(79 downto 0);
		ch2_in  			: in  std_logic_vector(79 downto 0);
		ch3_in  			: in  std_logic_vector(79 downto 0);
		ch4_in  			: in  std_logic_vector(79 downto 0);
		data_valid_out    	: out std_logic;
		clk      			: in  std_logic;
		rst      			: in  std_logic;
		data_valid_in		: in  std_logic;

		
		--FOR TESTING PURPOSES
		data_valid_in_check				: out std_logic
		--index_check 		: out integer;
		
	);
end entity fb_fsm;                         -- entity dut

architecture RTL of fb_fsm is
	signal index  	: integer := 0; --index to store incoming NUM_DATA_CHANNELS samples at
	signal data 	: std_logic_vector((MAX_CYCLES*NUM_DATA_CHANNELS - 1) downto 0) := (others => '0'); --internal storage variable for incoming channel data
--	signal ready 	: std_logic := '0'; -- signal to indicate it's ok to start storing data
	type fsm_states is (reset_fsm, store_data, dump);
begin

	fsm : process(clk) is
		variable state : fsm_states;
		variable data_variable : std_logic_vector((MAX_CYCLES*NUM_DATA_CHANNELS - 1) downto 0) := data;
	begin
		
		if rst = '1' then
			state  := reset_fsm;
			data_variable := (others => '0');
--			ready 			<= '0';
			index  			<= 0;
			data 			<= (others => '0');
			data_valid_out  <= '0';
			data_out 		<= (others => '0');
			
			-- TESTER VARIABLES
			data_valid_in_check 	<= data_valid_in;
			--index_check 	<= 0;
			
		elsif rising_edge(clk) then

			case state is
				
				when reset_fsm =>
					if data_valid_in = '1' then
						state := store_data;
					end if;
					--ready no change
					index  			<= 0;
					data 			<= (others => '0');
					data_valid_out 	<= '0';
					data_out 		<= (others => '0');
					
					-- TESTER VARIABLES
					--index_check 	<= 0;
					data_valid_in_check 	<= data_valid_in;
					
				when store_data =>
	
					if data_valid_in = '1' then
							
						if (index = MAX_CYCLES*NUM_DATA_CHANNELS - NUM_DATA_CHANNELS) then
							state := dump;
							data_valid_out <= '1';
						else
							state := store_data;
						end if;
						
						--ch1. note it only checks first sample!
						if (ch1_in(15 downto 0) > b"0010000000000000") then
							data_variable(index downto index) := "1";
						elsif(ch1_in(15 downto 0) < b"0010000000000000") then
							data_variable(index downto index) := "0";
						end if;
						
						--ch2. note it only checks first sample
						if (ch2_in(15 downto 0) > b"0010000000000000") then
							data_variable(index+1 downto index+1) := "1";
						elsif(ch2_in(15 downto 0) < b"0010000000000000") then
							data_variable(index+1 downto index+1) := "0";
						end if;

						--ch3. note it only checks first sample
						if (ch3_in(15 downto 0) > b"0010000000000000") then
							data_variable(index+2 downto index+2) := "1";
						elsif(ch3_in(15 downto 0) < b"0010000000000000") then
							data_variable(index+2 downto index+2) := "0";
						end if;
						
						--ch4. note it only checks first sample
						if (ch4_in(15 downto 0) > b"0010000000000000") then
							data_variable(index+3 downto index+3) := "1";
						elsif(ch4_in(15 downto 0) < b"0010000000000000") then
							data_variable(index+3 downto index+3) := "0";
						end if;						 
						
						index <= index + NUM_DATA_CHANNELS;
						data <= data_variable;
						data_out <= data_variable;
						
						-- TESTER VARIABLES
						--index_check <= index + NUM_DATA_CHANNELS;
							
					elsif (data_valid_in /= '1') then
						state := store_data;
						
						--ready no change
						index  			<= index;
						data 			<= data_variable;
						data_valid_out 	<= '0';
						data_out 		<= data_variable;
						
						-- TESTER VARIABLES
						--index_check 	<= index;
						data_valid_in_check 	<= data_valid_in;
							
					end if; 
					
				when dump =>
					
					-- double check that index is max_cycles*4
					if index = MAX_CYCLES*4 then
						
						state := dump;
						
						index 			<= index;
						data_out 		<= data_variable;
						data_valid_out 	<= '1';
						
						-- TESTER VARIABLES
						--index_check 	<= index;
						data_valid_in_check 	<= data_valid_in;
						
					end if;

						
			end case;
		end if;
	end process fsm;

end architecture RTL;

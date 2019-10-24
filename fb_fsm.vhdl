library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fb_fsm is

	generic(
		constant MAX_CYCLES : integer := 4;
		constant NUM_DATA_CHANNELS : integer := 4
	);
	port(
		--IN/OUT
		data_out 			: out unsigned((MAX_CYCLES*4 - 1) downto 0);
		ch1_in  			: in  unsigned(79 downto 0);
		ch2_in  			: in  unsigned(79 downto 0);
		ch3_in  			: in  unsigned(79 downto 0);
		ch4_in  			: in  unsigned(79 downto 0);
		data_valid_out    	: out std_logic;
		clk      			: in  std_logic;
		rst      			: in  std_logic;
		data_valid_in		: in  std_logic;

		
		--FOR TESTING PURPOSES
		data_valid_in_check				: out std_logic;
		index_check 		: out integer;
		data_check 			: out unsigned((MAX_CYCLES*NUM_DATA_CHANNELS - 1) downto 0)
		
	);
end entity fb_fsm;                         -- entity dut

architecture RTL of fb_fsm is
	signal index  	: integer := 0; --index to store incoming NUM_DATA_CHANNELS samples at
	signal data 	: unsigned((MAX_CYCLES*NUM_DATA_CHANNELS - 1) downto 0) := (others => '0'); --internal storage variable for incoming channel data
--	signal ready 	: std_logic := '0'; -- signal to indicate it's ok to start storing data
	type fsm_states is (reset_fsm, store_data, dump);
begin

	fsm : process(clk) is
		variable state : fsm_states;
		variable data_variable : unsigned((MAX_CYCLES*NUM_DATA_CHANNELS - 1) downto 0) := data;
	begin
		
		if rst = '1' then
			state  := reset_fsm;
--			ready 			<= '0';
			index  			<= 0;
			data 			<= (others => '0');
			data_valid_out  <= '0';
			data_out 		<= (others => '0');
			
			-- TESTER VARIABLES
			data_valid_in_check 	<= data_valid_in;
			index_check 	<= 0;
			data_check 		<= (others => '0');
			
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
					index_check 	<= 0;
					data_valid_in_check 	<= data_valid_in;
					data_check 		<= (others => '0');
					
				when store_data =>
	
					if data_valid_in = '1' then
							
						if (index = MAX_CYCLES*NUM_DATA_CHANNELS - NUM_DATA_CHANNELS) then
							state := dump;
							data_valid_out <= '1';
						else
							state := store_data;
						end if;
						
						--ch1
						if (ch1_in > '0010000000000000') then
							data_variable(index downto index) := '1';
						elsif(ch1_in < '0010000000000000') then
							data_variable(index downto index) := '0';
						end if;
						
						--ch2
						if (ch2_in > '0010000000000000') then
							data_variable(index+1 downto index+1) := '1';
						elsif(ch2_in < '0010000000000000') then
							data_variable(index+1 downto index+1) := '0';
						end if;

						--ch3
						if (ch3_in > '0010000000000000') then
							data_variable(index+2 downto index+2) := '1';
						elsif(ch3_in < '0010000000000000') then
							data_variable(index+2 downto index+2) := '0';
						end if;
						
						--ch4
						if (ch4_in > '0010000000000000') then
							data_variable(index+3 downto index+3) := '1';
						elsif(ch4_in < '0010000000000000') then
							data_variable(index+3 downto index+3) := '0';
						end if;						 
						
						index <= index + NUM_DATA_CHANNELS;
						data <= data_variable;
						
						-- TESTER VARIABLES
						index_check <= index + NUM_DATA_CHANNELS;
							
					elsif (data_valid_in /= '1') then
						state := store_data;
						
						--ready no change
						index  			<= index;
						data 			<= data;
						data_valid_out 	<= '0';
						data_out 		<= data;
						
						-- TESTER VARIABLES
						index_check 	<= index;
						ready_check 	<= ready;
						data_check 		<= data;
							
					end if; 
					
				when dump =>
					
					-- double check that index is max_cycles*4
					if index = MAX_CYCLES*4 then
						
						state := dump;
						
						index 			<= index;
						data_out 		<= data;
						data_valid_out 	<= '1';
						
						-- TESTER VARIABLES
						index_check 	<= index;
						data_valid_in_check 	<= data_valid_in;
						data_check 		<= data;
						
					end if;

						
			end case;
		end if;
	end process fsm;

end architecture RTL;

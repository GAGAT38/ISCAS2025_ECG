LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity Spi_Master_HS_V2 is
	GENERIC(
		d_width : INTEGER := 8 --data bus width
	 ); 
	 PORT(
	en      : IN     STD_LOGIC;
    clock   : IN     STD_LOGIC;                             --system clock
    reset   : IN     STD_LOGIC;                             --synchronous reset
    enable  : IN     STD_LOGIC;                             --initiate transaction
    tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data to transmit
    miso    : IN     STD_LOGIC;   
    sclk    : inout  STD_LOGIC;                             --spi clock
    mosi    : OUT    STD_LOGIC;                             --master out, slave in
    busy    : OUT    STD_LOGIC;                             --busy / data ready signal
    rx_data : inout    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)); --data received
	 
end Spi_Master_HS_V2;

architecture Behavioral of Spi_Master_HS_V2 is

	--type state_type is (idle, sending); 
	--signal state 		 						: state_type := idle;
	
	signal en_sclk: std_logic;
	signal enable_buffer: std_logic;
	signal tx_data_shifted: std_logic_vector(7 downto 0);
	signal sclk_counter: unsigned(2 downto 0);
	
begin

	--sclk <= clock when en_sclk = '1' else '0';
	sclk <= clock and en_sclk;
	
	busy <= '1' when enable /= enable_buffer or en_sclk = '1' else '0';
	
	--mosi <= tx_data(7) when enable /= enable_buffer else tx_data_shifted(7);
	mosi <= tx_data_shifted(7) when en_sclk = '1' else '0';

	clk_process_sclk_pos: process(sclk, reset) 
	begin
		if reset = '1' then
			sclk_counter <= "111";
		elsif sclk'event and sclk = '1' and en = '1' then
			sclk_counter <= sclk_counter + 1;
		end if;
	end process;
	
	clk_process_sclk_neg: process(sclk, reset) 
	begin
		if reset = '1' then
			rx_data <= (others => '0');
		elsif sclk'event and sclk = '0' and en = '1' then
			rx_data <= rx_data(6 downto 0) & miso;
			--rx_data <= rx_data(6 downto 0) & '1';
		end if;
	end process;
	
	clk_process_neg: process(clock, reset) 
	begin
		if reset = '1' then
			en_sclk <= '0';
			enable_buffer <= '0';
		elsif clock'event and clock = '0' and en = '1' then
		
			if enable /= enable_buffer then
				en_sclk <= '1';
				tx_data_shifted <= tx_data;
			elsif sclk_counter = "111" and en_sclk = '1' then 
				en_sclk <= '0';
			elsif en_sclk = '1' then
				tx_data_shifted(7 downto 1) <= tx_data_shifted(6 downto 0);
			end if;
			
			enable_buffer <= enable;
			
		end if;
	end process;
	
	
end Behavioral;

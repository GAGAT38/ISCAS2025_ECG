----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Gabriel Gagnon-Turcotte
-- 
-- Create Date:    08:28:37 03/18/2023 
-- Design Name: 
-- Module Name:    SAR_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SAR_Multiplexer_Logic is
	port(
		clk 																			: in std_logic;
		spi_clk																			: in std_logic;
		rst 																			: in std_logic;
		en  																			: in std_logic;
		ready  																			: out std_logic;
	
		trig_adc_sequence																: in std_logic;
		
		--SPI interface
		mcu_mosi 																		: out std_logic;
		mcu_miso 																		: in std_logic;
		mcu_sl_sel 																		: inout std_logic; 
		mcu_sclk 																		: inout std_logic;
		--End SPI interface
		
		--SAR ADC interface
		SAR_start																		: out std_logic;	
		SAR_converted_value 															: in std_logic_vector(9 downto 0);
		SAR_conversion_done 															: in std_logic;
		--End SAR ADC interface
		
		AnalogMux_Sel 																	: out std_logic_vector(2 downto 0)		
		
	);
end SAR_Multiplexer_Logic;

architecture Behavioral of SAR_Multiplexer_Logic is

	COMPONENT SPI_Master_HS_V2
	GENERIC(
		d_width : INTEGER := 8 --data bus width
	 ); 
	port(	
			en      : IN     STD_LOGIC;
			clock   : IN     STD_LOGIC;                             --system clock
			reset   : IN     STD_LOGIC;                             --synchronous reset
			enable  : IN     STD_LOGIC;                             --initiate transaction
			tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data to transmit
			miso    : IN     STD_LOGIC;                             --master in, slave out
			sclk    : inout  STD_LOGIC;                             --spi clock
			mosi    : OUT    STD_LOGIC;                             --master out, slave in
			busy    : OUT    STD_LOGIC;                             --busy / data ready signal
			rx_data : inout    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)  --data received
		);
	end COMPONENT;
	
	
	type statetype is (idle, delay_SAR_start, wait_SAR_conversion_done_off, wait_for_SAR, transfer_byte_1, transfer_byte_2);
	signal currentstate: statetype;
	
	
	signal mux_countrer: unsigned(2 downto 0);
	signal SAR_converted_value_buffer: std_logic_vector(7 downto 0);
	
	signal mcu_init_spi_tr: std_logic;                            
	signal mcu_spi_data_out: std_logic_vector(7 downto 0);   
	signal mcu_spi_busy: std_logic;   
	signal mcu_spi_data_in: std_logic_vector(7 downto 0); 


begin

	 Spi_Master_HS_inst: SPI_Master_HS_V2
	 port map(	
			en      => en,
			clock   => spi_clk,
			reset   => rst,
			enable  => mcu_init_spi_tr,                            
			tx_data => mcu_spi_data_out,
			miso    => mcu_miso,
			sclk    => mcu_sclk,
			mosi    => mcu_mosi,
			busy    => mcu_spi_busy,
			rx_data => mcu_spi_data_in
	 );

	AnalogMux_Sel <= std_logic_vector(mux_countrer);

	process(rst, clk)
	begin
		if rst = '1' then
			mcu_sl_sel <= '1';
			mcu_init_spi_tr <= '0';
			SAR_start <= '0';
			mux_countrer <= (others => '0');
			SAR_converted_value_buffer <= (others => '0');
			ready <= '0';
			currentstate <= idle;
		elsif clk'event and clk = '1' and en = '1' then
			case currentstate is
			
				when idle =>
					
					mcu_sl_sel <= '1';
					SAR_start <= '0';
					mux_countrer <= (others => '0');
										
					if trig_adc_sequence = '1' then
						currentstate <= delay_SAR_start;
						ready <= '0';
					else
						ready <= '1';
					end if;
					
				when delay_SAR_start =>
					SAR_start <= '1';
					mcu_sl_sel <= '0';
					currentstate <= wait_SAR_conversion_done_off;
					
				when wait_SAR_conversion_done_off =>
					SAR_start <= '0';
					if SAR_conversion_done = '0' then
						currentstate <= wait_for_SAR;
					end if;
					
				when wait_for_SAR =>
					if SAR_conversion_done = '1' then
						SAR_converted_value_buffer(1 downto 0) <= SAR_converted_value(9 downto 8);
						mcu_spi_data_out <= SAR_converted_value(7 downto 0);
						mcu_init_spi_tr <= not(mcu_init_spi_tr);
						currentstate <= transfer_byte_1;
					end if;
					
					
				when transfer_byte_1 =>
					if mcu_spi_busy = '0' then
						mcu_spi_data_out <= SAR_converted_value_buffer;
						mcu_init_spi_tr <= not(mcu_init_spi_tr);
						currentstate <= transfer_byte_2;
					end if;
					
				when transfer_byte_2 =>
					if mcu_spi_busy = '0' then
						if mux_countrer = 7 then
							if trig_adc_sequence = '0' then
								currentstate <= idle;
							end if;
						else
							mux_countrer <= mux_countrer + 1;
							currentstate <= delay_SAR_start;
						end if;
					end if;
				
				when others =>
					currentstate <= idle;
				
			end case;
		end if;
	end process;

end Behavioral;


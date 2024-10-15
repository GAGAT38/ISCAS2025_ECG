----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Gabriel Gagnon-Turcotte
-- 
-- Create Date:    08:28:37 03/18/2022 
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

entity SAR_controller is
	port(
		clk : in std_logic;
		rst : in std_logic;
		en  : in std_logic;
		
		comp_value : in std_logic;
		comp_value_i : in std_logic;
		start: in std_logic;
		
		Bx : out std_logic_vector(8 downto 0);
		Bxref : out std_logic_vector(8 downto 0);
		B  : out std_logic;
		Bref  : out std_logic;
		SH	 : out std_logic;
		pol: out std_logic;
		poli: out std_logic;
		
		converted_value : out std_logic_vector(9 downto 0);
		conversion_done : out std_logic
	);
end SAR_controller;

architecture Behavioral of SAR_controller is

type statetype is (idle, sample_and_hold, pol_determination, conversion);
signal currentstate: statetype;
signal counter: unsigned(3 downto 0);
signal polarity: std_logic;
signal converted_value_buffer : std_logic_vector(9 downto 0);

begin

	converted_value <= converted_value_buffer;

	process(rst, clk)
	begin
		if rst = '1' then
			SH <= '0';
			B <= '0';
			Bx <= (others => '1');
			Bxref  <= (others => '0');
			Bref <= '0';
			pol <= '0';
			poli <= '0';
			converted_value_buffer  <= (others => '0');
			conversion_done <= '0';
			currentstate <= idle;
		elsif clk'event and clk = '1' and en = '1' then
			case currentstate is
			
				when idle =>
					Bx <= (others => '1');
					B <= '1';
					Bxref  <= (others => '0');
					Bref <= '0';
					SH <= '1';
					pol <= '0';
					poli <= '0';
					counter <= "1000";
					if start = '1' then
						conversion_done <= '0';
						converted_value_buffer  <= (others => '0');
						currentstate <= sample_and_hold;
					end if;
				
				when sample_and_hold =>
					SH <= '0';
					Bx <= (others => '0');
					B <= '0';
					Bxref  <= (others => '1');
					Bref <= '1';
					currentstate <= pol_determination;
					
				when pol_determination =>
					if comp_value = '1' then
						pol <= '1';
						poli <= '0';
						polarity <= '1';
						converted_value_buffer(9) <= '1';
					else
						pol <= '0';
						poli <= '1';
						polarity <= '0';
						converted_value_buffer(9) <= '0';
					end if;
					Bx(to_integer(counter)) <= '1';
					Bxref(to_integer(counter)) <= '0';
					currentstate <= conversion;
					
					
				when conversion =>
					if (comp_value = '1' and polarity = '1') or (comp_value_i = '1' and polarity = '0') then
						if polarity = '1' then
							converted_value_buffer(to_integer(counter)) <= '1';
						end if;
					else
						if polarity = '0' then
							converted_value_buffer(to_integer(counter)) <= '1';
						end if;
						Bxref(to_integer(counter)) <= '1';
						Bx(to_integer(counter)) <= '0';
					end if;
					
					if counter = 0 then
						conversion_done <= '1';
						currentstate <= idle;
					else
						counter <= counter - 1;
						Bx(to_integer(counter - 1)) <= '1';
						Bxref(to_integer(counter - 1)) <= '0';
					end if;
				
			end case;
		end if;
	end process;

end Behavioral;


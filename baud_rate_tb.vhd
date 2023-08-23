library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_rate_tb is
end entity;

architecture tb of baud_rate_tb is

	component baud_rate_generator is
        generic(
            MAX_COUNT : positive := 5208 -- number of times 9600 goes into 50 MHz
        );
        port(
            clk_i       : in std_logic; -- 50Mhz clock
            rst_i       : in std_logic;
            baud_clk_o  : out std_logic
        );
	end component;
	
	signal rst : std_logic;
	signal baud_clk: std_logic;
	signal clk : std_logic := '0'; 
	
begin	
	
    DUT : baud_rate_generator
        port map(
            clk_i       => clk,
            rst_i       => rst,
            baud_clk_o  => baud_clk
        );

    process begin
    
        rst <= '1';
        
        wait for 10 ns;
        
        rst <= '0';
        
        while true loop
            clk <= not clk;
            wait for 20 ns;
        end loop;
    
    end process;
end architecture;
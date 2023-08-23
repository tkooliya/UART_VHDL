library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_rate_generator is
    generic(
        MAX_CLK_COUNT : positive := 5208 -- number of times 9600 goes into 50 MHz
    );
    port(
        clk_i       : in std_logic; -- 50Mhz clock
        rst_i       : in std_logic;
        baud_clk_o  : out std_logic
    );
end entity;

architecture behaviour of baud_rate_generator is

    signal counter_r : unsigned(14 downto 0);

begin
    process(clk_i, rst_i) begin
        if(rst_i = '1') then
            counter_r <= to_unsigned(0, 15);
            baud_clk_o  <= '0';
            
        elsif(rising_edge(clk_i)) then
            
            counter_r <= counter_r + 1;

            if(counter_r = (MAX_CLK_COUNT - 1) / 2) then
                counter_r <= to_unsigned(0, counter_r'length);
                baud_clk_o <= NOT(baud_clk_o);
            end if;
				
        end if;
    end process;
end behaviour;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
    port(
        sig_in          : in std_logic;
        clk             : in std_logic;
        debounced_sig   : out std_logic
    );
end entity;

architecture structure of debouncer is

    signal sig_in_latched   : std_logic;
    signal sig_in_latched_2 : std_logic;
    signal enable           : std_logic;

    -- clk is assumed to be 50 MHz
    -- Want button to be held for 50 ms
    -- Counter must go to 2.5 M --> 22 bits wide
    constant MAX_COUNT      : unsigned(21 downto 0) := to_unsigned(2500000, 22);
    signal count            : unsigned(21 downto 0);
    signal rst_count        : std_logic;

begin

    -- Reset count when latched sig values are different
    rst_count <= sig_in_latched xor sig_in_latched_2;
    enable <= '1' when count = MAX_COUNT else '0';

    process(clk) begin
        if(rising_edge(clk)) then
            sig_in_latched      <= sig_in;
            sig_in_latched_2    <= sig_in_latched;
            
            if(enable = '1') then
                debounced_sig <= sig_in_latched_2;
            end if;

            if(rst_count = '1') then
                count <= to_unsigned(0, count'length);
            elsif(enable = '0') then
                count <= count + 1;
            end if;
        end if;
    end process;

end architecture;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_datapath is
    port(
        clk_i           : in std_logic;
        rst_i           : in std_logic;
        
        rx_i            : in std_logic;

        rec_data_i      : in std_logic;
        rec_parity_i    : in std_logic;

        rx_data_o       : out std_logic_vector(7 downto 0);
        data_done_o     : out std_logic;
        data_good_o     : out std_logic
    );
end entity;

architecture behaviour of rx_datapath is

    signal bit_counter_r    : unsigned(2 downto 0);
    
    signal data_shift_r     : std_logic_vector(7 downto 0);
    signal data_out_r       : std_logic_vector(7 downto 0);

    signal local_parity     : std_logic;
    signal data_good_r      : std_logic;

begin

    process(clk_i, rst_i) begin
        if(rst_i = '1') then
            bit_counter_r   <= "000";
            data_shift_r    <= "00000000";
            data_out_r      <= "00000000";
            data_good_r     <= '0';

        elsif(rising_edge(clk_i)) then
            if(rec_data_i = '1') then
                bit_counter_r   <= bit_counter_r + 1;
                data_shift_r    <= rx_i & data_shift_r(7 downto 1);
            end if;

            data_good_r <= '0';
            if(rec_parity_i = '1') then
                data_good_r <= local_parity xnor rx_i;
                data_out_r  <= data_shift_r;
            end if;

        end if;
    end process;

    rx_data_o   <= data_out_r;
    data_done_o <= '1' when (bit_counter_r = 7) else '0';

    local_parity <= data_shift_r(0) xor
                    data_shift_r(1) xor
                    data_shift_r(2) xor
                    data_shift_r(3) xor
                    data_shift_r(4) xor
                    data_shift_r(5) xor
                    data_shift_r(6) xor
                    data_shift_r(7);

    data_good_o <= data_good_r;

end architecture;
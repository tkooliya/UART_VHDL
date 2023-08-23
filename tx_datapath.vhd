library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_datapath is
    port(
        clk_i           : in std_logic;
        rst_i           : in std_logic;

        -- tx_controller
        send_start_i    : in std_logic;
        send_data_i     : in std_logic;
        send_parity_i   : in std_logic;
        
        data_done_o     : out std_logic;

        -- HS controller
        tx_data_en_i    : in std_logic;

        -- data
        tx_data_i       : in std_logic_vector (7 downto 0);
        tx_o            : out std_logic -- transmit bit by bit
    );
end entity;

architecture behaviour of tx_datapath is

    signal bit_counter_r    : unsigned(2 downto 0);
    signal tx_data_r        : std_logic_vector(7 downto 0);
    signal local_parity     : std_logic;
	 
begin

    process(clk_i, rst_i) begin
        if(rst_i = '1') then
            bit_counter_r   <= "000";
            tx_data_r       <= "00000000";
            tx_o            <= '1';

        elsif(rising_edge(clk_i)) then
            tx_o <= '1';

            if(tx_data_en_i = '1') then
                tx_data_r <= tx_data_i;
            end if;

            if(send_start_i = '1') then
                tx_o <= '0';
            end if;

            if(send_data_i = '1') then
                tx_o <= tx_data_r(to_integer(bit_counter_r));
                bit_counter_r <= bit_counter_r + 1;
            end if;

            if(send_parity_i = '1') then
                tx_o <= local_parity;
            end if;		 
        end if;
    end process;

data_done_o <= '1' when (bit_counter_r = 7) else '0';
 
local_parity <= tx_data_r(0) xor
                tx_data_r(1) xor
                tx_data_r(2) xor
                tx_data_r(3) xor
                tx_data_r(4) xor
                tx_data_r(5) xor
                tx_data_r(6) xor
                tx_data_r(7);

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_controller is
    port(
        clk_i           : in std_logic;
        rst_i           : in std_logic;

        send_start_o    : out std_logic;
        send_data_o     : out std_logic;
        send_parity_o   : out std_logic;
        
        data_done_i     : in std_logic;

        tx_start_i      : in std_logic
    );
end entity;

architecture behaviour of tx_controller is

    type tx_state_t is(
        TX_RESET,
        TX_IDLE,
        TX_START,
        TX_DATA,
        TX_PARITY,
        TX_STOP
    );

    signal curr_state  : tx_state_t;
    signal next_state  : tx_state_t;

begin

    process(clk_i, rst_i) begin
        if(rst_i = '1') then
            curr_state <= TX_RESET;
        elsif(rising_edge(clk_i)) then
            curr_state <= next_state;
        end if;
    end process;

    -- next_state logic
    process(
        curr_state,
        tx_start_i,
        data_done_i
    ) begin
        next_state <= curr_state;

        case curr_state is
            when TX_RESET =>
                next_state <= TX_IDLE;
            
            when TX_IDLE =>
                if(tx_start_i = '1') then
                    next_state <= TX_START;
                end if;
            
            when TX_START =>
                next_state <= TX_DATA;
            
            when TX_DATA =>
                if(data_done_i = '1') then
                    next_state <= TX_PARITY;
                end if;
            
            when TX_PARITY =>
                next_state <= TX_STOP;
            
            when TX_STOP =>
                next_state <= TX_IDLE;

            when others =>
        end case;
    end process;

    send_start_o    <= '1' when (curr_state = TX_START) else '0';
    send_data_o     <= '1' when (curr_state = TX_DATA) else '0';
    send_parity_o   <= '1' when (curr_state = TX_PARITY) else '0';

end architecture;
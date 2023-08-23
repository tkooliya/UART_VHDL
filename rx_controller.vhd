library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_controller is
    port(
        clk_i           : in std_logic;
        rst_i           : in std_logic;

        rx_i            : in std_logic;
        rx_receive_i    : in std_logic;

        rec_data_o      : out std_logic;
        rec_parity_o    : out std_logic;

        data_done_i     : in std_logic;
        data_good_i     : in std_logic;

        -- RV interface
        rx_ready_i      : in  std_logic;
        rx_valid_o      : out std_logic
    );
end entity;

architecture behaviour of rx_controller is

    type rx_state_t is(
        RX_RESET,
        RX_IDLE,
        RX_DATA,
        RX_PARITY,
        RX_STOP
    );

    signal curr_state   : rx_state_t;
    signal next_state   : rx_state_t;

    signal valid_r      : std_logic;

begin
    
    process(clk_i, rst_i) begin
        if(rst_i = '1') then
            curr_state  <= RX_RESET;
            valid_r     <= '0';

        elsif(rising_edge(clk_i)) then
            curr_state <= next_state;

            if(valid_r = '1' and rx_ready_i = '1') then
                valid_r <= '0';
            elsif(curr_state = RX_PARITY) then
                valid_r <= '0';
            elsif(curr_state = RX_STOP) then
                valid_r <= data_good_i; -- data_good_i pulses on state RX_STOP
            end if;
        end if;
    end process;

    -- next_state logic
    process(curr_state, rx_i, rx_receive_i, data_done_i) begin
        next_state <= curr_state;

        case curr_state is
            when RX_RESET =>
                next_state <= RX_IDLE;
            
            when RX_IDLE =>
                if(rx_i = '0' and rx_receive_i = '1') then
                    next_state <= RX_DATA;
                end if;
            
            when RX_DATA =>
                if(data_done_i = '1') then
                    next_state <= RX_PARITY;
                end if;
            
            when RX_PARITY =>
                next_state <= RX_STOP;
            
            when RX_STOP =>
                next_state <= RX_IDLE;

            when others =>
        end case;
    end process;

    rec_data_o      <= '1' when (curr_state = RX_DATA) else '0';
    rec_parity_o    <= '1' when (curr_state = RX_PARITY) else '0';

    rx_valid_o      <= valid_r;

end architecture;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hs_controller is
    port(
        clk_i           : in std_logic;
        rst_i           : in std_logic;

        -- Handshake signals
        rts_o           : out std_logic; -- ready to send
        cts_i           : in  std_logic; -- clear to send
        dtr_o           : out std_logic; -- data terminal ready
        dsr_i           : in  std_logic; -- data set ready

        -- Status signals
        tx_data_done_i  : in std_logic;
        rx_data_good_i  : in std_logic;

        -- Transmitter RV interface
        tx_ready_o      : out std_logic;
        tx_valid_i      : in  std_logic;

        -- Tx control signals
        tx_data_en_o    : out std_logic;
        tx_start_o      : out std_logic;

        -- Rx control signals
        rx_receive_o    : out std_logic
    );
end entity;

architecture behaviour of hs_controller is

    type hs_state_t is(
        HS_RESET,
        HS_IDLE,

        HS_INIT_TX,     -- Set RTS high
        HS_SENDING,     -- CTS high, doing transmission
        HS_WAIT_ON_ACK, -- Transmission done, waiting for DSR pulse, watchdog running

        HS_RECEIVING,   -- RTS high to acknowledge ready to receive
        HS_ACK          -- If no errors, acknowledge (pulse on DTR)
    );

    signal curr_state : hs_state_t;
    signal next_state : hs_state_t;

    -- Watchdog timer
    constant WDT_MAX_COUNT  : unsigned(7 downto 0) := to_unsigned(128, 8);
    signal wdt_r            : unsigned(7 downto 0);
    signal wdt_done         : std_logic;

    -- Send queue status
    signal send_queued_r    : std_logic;

begin

    process(clk_i, rst_i) begin
        if(rst_i = '1') then
            curr_state      <= HS_RESET;
            wdt_r           <= to_unsigned(0, wdt_r'length);
            send_queued_r   <= '0';
        
        elsif(rising_edge(clk_i)) then
            curr_state <= next_state;
            
            wdt_r <= to_unsigned(0, wdt_r'length);
            if(curr_state = HS_WAIT_ON_ACK) then
                wdt_r <= wdt_r + 1;
            end if;
            
            if(curr_state = HS_IDLE and tx_valid_i = '1' and cts_i = '1') then
                send_queued_r <= '1';
            end if;
            if(curr_state = HS_INIT_TX) then
                send_queued_r <= '0';
            end if;
        end if;
    end process;

    wdt_done <= '1' when (wdt_r = WDT_MAX_COUNT) else '0';

    -- next_state logic (combinational)
    process(
        curr_state,
        cts_i,
        tx_valid_i,
        tx_data_done_i,
        dsr_i,
        wdt_done,
        rx_data_good_i,
        send_queued_r
    ) begin
        next_state <= curr_state;

        case curr_state is
            when HS_RESET =>
                next_state <= HS_IDLE;

            when HS_IDLE =>
                if(cts_i = '1') then
                    next_state <= HS_RECEIVING;
                elsif(tx_valid_i = '1') then
                    next_state <= HS_INIT_TX;
                end if;


            when HS_INIT_TX =>
                if(cts_i = '1') then
                    next_state <= HS_SENDING;
                end if;

            when HS_SENDING =>
                if(tx_data_done_i = '1') then
                    next_state <= HS_WAIT_ON_ACK;
                end if;

            when HS_WAIT_ON_ACK =>
                if(dsr_i = '1') then
                    next_state <= HS_IDLE;
                elsif(wdt_done = '1') then
                    -- Retransmit if watchdog timer is up
                    next_state <= HS_SENDING;
                end if;


            when HS_RECEIVING =>
                -- No control signal if data bad, just wait for transmitter to retransmit
                if(rx_data_good_i = '1') then
                    next_state <= HS_ACK;
                end if;

            when HS_ACK =>
                -- Only need 1 cycle to pulse DTR for ACK
                next_state <= HS_IDLE;
                if(send_queued_r = '1') then
                    next_state <= HS_INIT_TX;
                end if;

            when others =>
        end case;
    end process;

    rts_o           <= '1' when (curr_state = HS_INIT_TX) or (curr_state = HS_RECEIVING and cts_i = '1') else '0';
    dtr_o           <= '1' when (curr_state = HS_ACK) else '0';

    rx_receive_o    <= '1' when (curr_state = HS_RECEIVING) else '0';

    tx_ready_o      <= '1' when (curr_state = HS_IDLE) else '0';

    tx_data_en_o    <= '1' when (curr_state = HS_IDLE) and (tx_valid_i = '1') else '0';
    tx_start_o      <= '1' when (curr_state = HS_SENDING) else '0';

end;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    generic(
        MAX_CLK_COUNT : positive := 5208
    );
    port(
        clk_i       : in std_logic;
        rst_i       : in std_logic;
        baud_clk_o  : out std_logic;
        -- uart interface
        tx_o        : out std_logic;
        rx_i        : in  std_logic;
        rts_o       : out std_logic;
        cts_i       : in  std_logic;
        dtr_o       : out std_logic;
        dsr_i       : in  std_logic;

        -- Transmit RV interface
        tx_ready_o  : out std_logic;
        tx_valid_i  : in  std_logic;
        tx_data_i   : in  std_logic_vector(7 downto 0);

        -- Receive RV interface
        rx_ready_i  : in  std_logic;
        rx_valid_o  : out std_logic;
        rx_data_o   : out std_logic_vector(7 downto 0)
    );
end entity;

architecture structure of uart is

    component baud_rate_generator is
        generic(
            MAX_CLK_COUNT : positive := 5208 -- number of times 9600 goes into 50 MHz
        );
        port(
            clk_i       : in std_logic; -- 50Mhz clock
            rst_i       : in std_logic;
            baud_clk_o  : out std_logic
        );
    end component;

    component hs_controller is
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
    end component;

    component transmitter is
        port(
            clk_i           : in std_logic;
            rst_i           : in std_logic;
    
            tx_data_i       : in std_logic_vector(7 downto 0);
    
            tx_data_en_i    : in std_logic;
            tx_start_i      : in std_logic;
            data_done_o     : out std_logic;
    
            tx_o            : out std_logic
        );
    end component;

    component receiver is
        port(
            clk_i           : in std_logic;
            rst_i           : in std_logic;
    
            rx_i            : in std_logic;
    
            rx_ready_i      : in  std_logic;
            rx_valid_o      : out std_logic;
            rx_data_good_o  : out std_logic;
            rx_receive_i    : in  std_logic;
    
            rx_data_o       : out std_logic_vector(7 downto 0)
        );
    end component;

    signal baud_clk     : std_logic;

    signal tx_data_done : std_logic;
    signal tx_data_en   : std_logic;
    signal tx_start     : std_logic;

    signal rx_data_good : std_logic;
    signal rx_receive   : std_logic;

begin

    baud_clk_o <= baud_clk;

    brg0 : baud_rate_generator
        generic map(
            MAX_CLK_COUNT => MAX_CLK_COUNT
        )
        port map(
            clk_i       => clk_i,
            rst_i       => rst_i,
            baud_clk_o  => baud_clk
        );

    hs_controller0 : hs_controller
        port map(
            clk_i           => baud_clk,
            rst_i           => rst_i,
            
            rts_o           => rts_o,
            cts_i           => cts_i,
            dtr_o           => dtr_o,
            dsr_i           => dsr_i,

            tx_data_done_i  => tx_data_done,
            rx_data_good_i  => rx_data_good,

            tx_ready_o      => tx_ready_o,
            tx_valid_i      => tx_valid_i,

            tx_data_en_o    => tx_data_en,
            tx_start_o      => tx_start,

            rx_receive_o    => rx_receive
        );

    transmitter0 : transmitter
        port map(
            clk_i           => baud_clk,
            rst_i           => rst_i,

            tx_data_i       => tx_data_i,
            tx_data_en_i    => tx_data_en,

            tx_start_i      => tx_start,
            data_done_o     => tx_data_done,

            tx_o            => tx_o
        );

    receiver0 : receiver
        port map(
            clk_i           => baud_clk,
            rst_i           => rst_i,

            rx_i            => rx_i,

            rx_ready_i      => rx_ready_i,
            rx_valid_o      => rx_valid_o,
            rx_data_good_o  => rx_data_good,
            rx_receive_i    => rx_receive,

            rx_data_o       => rx_data_o
        );

    baud_clk_o <= baud_clk;
    
end architecture;
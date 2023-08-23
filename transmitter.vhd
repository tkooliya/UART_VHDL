library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitter is
    port(
        clk_i           : in std_logic;
        rst_i           : in std_logic;

        tx_data_i       : in std_logic_vector(7 downto 0);

        tx_data_en_i    : in std_logic;
        tx_start_i      : in std_logic;
        data_done_o     : out std_logic;

        tx_o            : out std_logic
    );
end entity;

architecture structure of transmitter is

    component tx_controller is
        port(
            clk_i           : in std_logic;
            rst_i           : in std_logic;
    
            send_start_o    : out std_logic;
            send_data_o     : out std_logic;
            send_parity_o   : out std_logic;
            
            data_done_i     : in std_logic;
    
            tx_start_i      : in std_logic
        );
    end component;

    component tx_datapath is
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
    end component;

    signal send_start   : std_logic;
    signal send_data    : std_logic;
    signal send_parity  : std_logic;
    signal data_done    : std_logic;

begin

    data_done_o <= data_done;

    tx_controller0 : tx_controller
        port map(
            clk_i           => clk_i,
            rst_i           => rst_i,

            send_start_o    => send_start,
            send_data_o     => send_data,
            send_parity_o   => send_parity,

            data_done_i     => data_done,

            tx_start_i      => tx_start_i
        );

    tx_datapath0 : tx_datapath
        port map(
            clk_i           => clk_i,
            rst_i           => rst_i,

            tx_data_en_i    => tx_data_en_i,

            send_start_i    => send_start,
            send_data_i     => send_data,
            send_parity_i   => send_parity,

            data_done_o     => data_done,

            tx_data_i       => tx_data_i,
            tx_o            => tx_o
        );

end architecture;
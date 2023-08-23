library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver is
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
end entity;

architecture structure of receiver is

    component rx_controller is
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
    end component;

    component rx_datapath is
        port(
            clk_i           : in std_logic;
            rst_i           : in std_logic;
            
            rx_i            : in std_logic;

            rec_data_i      : in std_logic;
            rec_parity_i    : in std_logic;

            rx_data_o       : out std_logic_vector(7 downto 0);
            data_done_o     : out std_logic;
            data_good_o    : out std_logic
        );
    end component;

    signal rec_data     : std_logic;
    signal rec_parity   : std_logic;
    signal data_done    : std_logic;
    signal data_good    : std_logic;

begin

    rx_data_good_o <= data_good;

    rx_controller0 : rx_controller
        port map(
            clk_i           => clk_i,
            rst_i           => rst_i,
            rx_i            => rx_i,
            rx_receive_i    => rx_receive_i,
            rec_data_o      => rec_data,
            rec_parity_o    => rec_parity,
            data_done_i     => data_done,
            data_good_i     => data_good,
            rx_ready_i      => rx_ready_i,
            rx_valid_o      => rx_valid_o
        );

    rx_datapath0 : rx_datapath
        port map(
            clk_i           => clk_i,
            rst_i           => rst_i,
            rx_i            => rx_i,
            rec_data_i      => rec_data,
            rec_parity_i    => rec_parity,
            rx_data_o       => rx_data_o,
            data_done_o     => data_done,
            data_good_o     => data_good
     );

end architecture;
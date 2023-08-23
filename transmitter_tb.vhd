library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transmitter_tb is
end entity;

architecture tb of transmitter_tb is

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

    signal clk_i            : std_logic := '1';
    signal rst_i            : std_logic := '0';
    signal tx_data_i        : std_logic_vector(7 downto 0) := "00000000";
    signal tx_data_en_i     : std_logic := '0';
    signal tx_start_i       : std_logic := '0';
    signal data_done_o      : std_logic;
    signal tx_o             : std_logic;

    constant hT : time := 5 ns; -- Half Period
    constant T  : time := 2 * hT;

begin

    clk_i <= not clk_i after hT;

    DUT : transmitter
        port map(
            clk_i           => clk_i,
            rst_i           => rst_i,
            tx_data_i       => tx_data_i,
            tx_data_en_i    => tx_data_en_i,
            tx_start_i      => tx_start_i,
            data_done_o     => data_done_o,
            tx_o            => tx_o
        );

    process begin
        rst_i <= '1';
        wait for T;

        rst_i <= '0';
        wait for 12*T;
        


        tx_data_i <= "10010101";
        tx_data_en_i <= '1';
        wait for T;

        tx_data_i <= "00000000";
        tx_data_en_i <= '0';
        wait for 2 * T;

        tx_start_i <= '1';
        wait for T;

        tx_start_i <= '0';
        wait for 25 * T;
        


        tx_data_i <= "10010100";
        tx_data_en_i <= '1';
        wait for T;

        tx_data_i <= "00000000";
        tx_data_en_i <= '0';
        tx_start_i <= '1';
        wait for T;

        tx_start_i <= '0';
        wait;
	 
    end process;

end architecture;
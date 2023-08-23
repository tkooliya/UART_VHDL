library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver_tb is
end entity;

architecture tb of receiver_tb is

    component receiver is
        port(
            clk_i           : in std_logic;
            rst_i           : in std_logic;
    
            rx_i            : in std_logic;
    
            rx_ready_i      : in std_logic;
            rx_valid_o      : out std_logic;
            rx_data_good_o  : out std_logic;
    
            rx_data_o       : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk_i            : std_logic := '1';
    signal rst_i            : std_logic := '0';
    signal rx_i             : std_logic := '1';
    signal rx_ready_i       : std_logic := '0';
    signal rx_valid_o       : std_logic;
    signal rx_data_good_o   : std_logic;
    signal rx_data_o        : std_logic_vector(7 downto 0);



    type test_vector_t is record 
        data    : std_logic_vector(7 downto 0);
        parity  : std_logic;
        err     : std_logic;
    end record;

    constant NUM_TESTS : integer := 8;
    type test_vector_array_t is array (0 to NUM_TESTS - 1) of test_vector_t;

    constant test_vector_array : test_vector_array_t := (
        ("00110101", '0', '0'),
        ("00110101", '1', '1'),
        ("00000000", '0', '0'),
        ("00011100", '1', '0'),
        ("11111111", '1', '1'),
        ("01010111", '1', '0'),
        ("11110000", '1', '1'),
        ("01101011", '0', '1')
    );



    constant hT : time := 5 ns; -- Half Period
    constant T  : time := 2 * hT;

begin

    clk_i <= not clk_i after hT;

    DUT : receiver
        port map(
            clk_i           => clk_i,
            rst_i           => rst_i,
            rx_i            => rx_i,
            rx_ready_i      => rx_ready_i,
            rx_valid_o      => rx_valid_o,
            rx_data_good_o  => rx_data_good_o,
            rx_data_o       => rx_data_o
        );

    process begin

        rst_i <= '1';
        wait for T;

        rst_i <= '0';
        wait for 10 * T;


        for test_idx in 0 to (NUM_TESTS - 1) loop

            report "Test case " & integer'image(test_idx);
            
            rx_i <= '0';
            wait for T;

            -- Data
            for i in 0 to 7 loop
                rx_i <= test_vector_array(test_idx).data(i);
                wait for T;
            end loop;

            -- Parity
            rx_i <= test_vector_array(test_idx).parity;
            wait for T;

            -- Stop
            rx_i <= '1';
            wait for hT;

            assert(rx_data_o = test_vector_array(test_idx).data)
                report "Bad Data"
                severity failure;

            assert(rx_data_good_o /= test_vector_array(test_idx).err)
                report "Bad Error"
                severity failure;

            wait for hT;

            -- Idle
            wait for hT;
            
            assert(rx_valid_o /= test_vector_array(test_idx).err)
                report "Bad Valid"
                severity failure;

            wait for hT;

            report "PASSED";

        end loop;
        wait;

    end process;

end architecture;
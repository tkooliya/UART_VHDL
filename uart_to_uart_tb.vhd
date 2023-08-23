library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_to_uart_tb is
end entity;

architecture tb of uart_to_uart_tb is

    constant CLK_I_F        : positive := 50 * (10 ** 6);
    constant BAUD_RATE      : positive := CLK_I_F / 6;
    constant MAX_CLK_COUNT  : positive := CLK_I_F / BAUD_RATE;

    component uart is
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
    end component;

    signal clk          : std_logic := '1';
    signal rst_1        : std_logic := '0';
    signal rst_2        : std_logic := '0';
    signal baud_clk_1   : std_logic;
    signal baud_clk_2   : std_logic;

    signal tx_1         : std_logic;
    signal tx_2         : std_logic;
    signal rts_1        : std_logic;
    signal rts_2        : std_logic;
    signal dtr_1        : std_logic;
    signal dtr_2        : std_logic;

    signal tx_ready_1   : std_logic;
    signal tx_valid_1   : std_logic := '0';
    signal tx_data_1    : std_logic_vector(7 downto 0) := "00000000";
    signal rx_ready_1   : std_logic := '0';
    signal rx_valid_1   : std_logic;
    signal rx_data_1    : std_logic_vector(7 downto 0);

    signal tx_ready_2   : std_logic;
    signal tx_valid_2   : std_logic := '0';
    signal tx_data_2    : std_logic_vector(7 downto 0) := "00000000";
    signal rx_ready_2   : std_logic := '0';
    signal rx_valid_2   : std_logic;
    signal rx_data_2    : std_logic_vector(7 downto 0);


    constant hT_clk     : time := 5 ns; -- Half Period of clk_i
    constant T_clk      : time := 2 * hT_clk;

    constant hT         : time := hT_clk * MAX_CLK_COUNT; -- Half Period in UART time
    constant T          : time := 2 * hT;

begin

    clk <= not clk after hT_clk;

    UART1 : uart
        generic map(
            MAX_CLK_COUNT => MAX_CLK_COUNT
        )
        port map(
            clk_i       => clk,
            rst_i       => rst_1,
            baud_clk_o  => baud_clk_1,
            tx_o        => tx_1,
            rx_i        => tx_2,
            rts_o       => rts_1,
            cts_i       => rts_2,
            dtr_o       => dtr_1,
            dsr_i       => dtr_2,
            tx_ready_o  => tx_ready_1,
            tx_valid_i  => tx_valid_1,
            tx_data_i   => tx_data_1,
            rx_ready_i  => rx_ready_1,
            rx_valid_o  => rx_valid_1,
            rx_data_o   => rx_data_1
        );

    UART2 : uart
        generic map(
            MAX_CLK_COUNT => MAX_CLK_COUNT
        )
        port map(
            clk_i       => clk,
            rst_i       => rst_2,
            baud_clk_o  => baud_clk_2,
            tx_o        => tx_2,
            rx_i        => tx_1,
            rts_o       => rts_2,
            cts_i       => rts_1,
            dtr_o       => dtr_2,
            dsr_i       => dtr_1,
            tx_ready_o  => tx_ready_2,
            tx_valid_i  => tx_valid_2,
            tx_data_i   => tx_data_2,
            rx_ready_i  => rx_ready_2,
            rx_valid_o  => rx_valid_2,
            rx_data_o   => rx_data_2
        );

    process
        constant NUM_ITERATIONS : integer := 4;
        variable rand : real;
        variable seed : positive := 111;

        procedure test_transmit_receive is
            variable test_vector    : std_logic_vector(7 downto 0);
        begin
            uniform(seed, seed, rand);
            test_vector := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));

            report "TEST_TRANSMIT_RECEIVE " & to_string(test_vector);

            rst_1 <= '1';
            rst_2 <= '1';

            wait for T;

            -- Bring uarts out of reset at different times so their baud clks are skewed
            rst_1 <= '0';
            wait for 2 * T_clk;

            rst_2 <= '0';
            wait for 2 * T;
            wait for 1 ns;

            assert(tx_ready_1 = '1')
                report "Bad ready signal (1) after reset"
                severity failure;
            tx_data_1 <= test_vector;
            tx_valid_1 <= '1';
            wait for T;

            tx_data_1 <= "00000000";
            tx_valid_1 <= '0';

            wait until rx_valid_2 = '1';
            wait for 1 ns;

            assert(rx_data_2 = test_vector)
                report "Bad data at receiving end (2)"
                severity failure;

        end procedure;

        procedure test_simultaneous_tx is
            variable test_vector_1  : std_logic_vector(7 downto 0);
            variable test_vector_2  : std_logic_vector(7 downto 0);
        begin
            uniform(seed, seed, rand);
            test_vector_1 := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));
            uniform(seed, seed, rand);
            test_vector_2 := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));

            report "TEST_SIMULTANEOUS_TX " & to_string(test_vector_1) & " " & to_string(test_vector_2);

            rst_1 <= '1';
            rst_2 <= '1';

            wait for T;

            -- Bring uarts out of reset at different times so their baud clks are skewed
            rst_1 <= '0';
            wait for 2 * T_clk;

            rst_2 <= '0';
            wait for 2 * T;
            wait for 1 ns;

            -- Initiate tx on both uarts
            tx_data_1   <= test_vector_1;
            tx_valid_1  <= '1';
            tx_data_2   <= test_vector_2;
            tx_valid_2  <= '1';
            wait for T;

            tx_data_1   <= "00000000";
            tx_valid_1  <= '0';
            tx_data_2   <= "00000000";
            tx_valid_2  <= '0';
            wait until rx_valid_2 = '1';

            assert(rx_data_2 = test_vector_1)
                report "Bad data at receiving end (2)"
                severity failure;
            wait until rx_valid_1 = '1';

            assert(rx_data_1 = test_vector_2)
                report "Bad data at receiving end (1)"
                severity failure;

            wait for T;

        end procedure;

        procedure test_1_side_bombardment is
            type test_vector_array is array(0 to 7) of std_logic_vector(7 downto 0);
            variable test_vector_arr_1  : test_vector_array;
        begin
            for i in test_vector_arr_1'low to test_vector_arr_1'high loop
                uniform(seed, seed, rand);
                test_vector_arr_1(i) := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));
            end loop;

            report "TEST_1_SIDE_BOMBARDMENT";

            rst_1 <= '1';
            rst_2 <= '1';

            wait for T;

            -- Bring uarts out of reset at different times so their baud clks are skewed
            rst_1 <= '0';
            wait for 2 * T_clk;

            rst_2 <= '0';
            wait for 2 * T;
            wait for 1 ns;

            -- Set data on both uarts
            -- 1 will send
            -- 2 will receive
            tx_valid_1  <= '1';

            for i in 0 to test_vector_arr_1'high loop

                tx_data_1   <= test_vector_arr_1(i);
                wait for T;

                assert(tx_ready_1 = '0')
                    report "Bad ready after valid data"
                    severity failure;
            
                wait until rx_valid_2 = '1';
                wait for 1 ns;

                assert(rx_data_2 = test_vector_arr_1(i))
                    report "Bad data receiver side (2)"
                    severity failure;
                
                wait until tx_ready_1 = '1';
                wait for 1 ns;
            
            end loop;

            tx_data_1   <= "00000000";
            tx_valid_1  <= '0';

            wait for T;

        end procedure;

        procedure test_2_side_bombardment is
            type test_vector_array is array(0 to 7) of std_logic_vector(7 downto 0);
            variable test_vector_arr_1  : test_vector_array;
            variable test_vector_arr_2  : test_vector_array;
        begin
            for i in test_vector_arr_1'low to test_vector_arr_1'high loop
                uniform(seed, seed, rand);
                test_vector_arr_1(i) := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));
                uniform(seed, seed, rand);
                test_vector_arr_2(i) := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));
            end loop;

            report "TEST_2_SIDE_BOMBARDMENT";

            rst_1 <= '1';
            rst_2 <= '1';

            wait for T;

            -- Bring uarts out of reset at different times so their baud clks are skewed
            rst_1 <= '0';
            wait for 2 * T_clk;

            rst_2 <= '0';
            wait for 2 * T;
            wait for 1 ns;

            -- Set data on both uarts
            -- 1 will send
            -- 2 will receive and queue its data to send
            tx_data_1   <= test_vector_arr_1(0);
            tx_data_2   <= test_vector_arr_2(0);
            tx_valid_1  <= '1';
            tx_valid_2  <= '1';
            wait for T;

            for i in 1 to test_vector_arr_1'high loop

                tx_data_1   <= test_vector_arr_1(i);
                tx_data_2   <= test_vector_arr_2(i);
            
                wait until rx_valid_2 = '1';
                wait for 1 ns;

                assert(rx_data_2 = test_vector_arr_1(i - 1))
                    report "Bad data receiver side (2)"
                    severity failure;
                
                -- uart 2 will now send
                -- uart 1 will queue data 1
                wait until tx_ready_1 = '1';
                wait until tx_ready_1 = '0';

                wait until rx_valid_1 = '1';

                assert(rx_data_1 = test_vector_arr_2(i - 1))
                    report "Bad data receiver side (1)"
                    severity failure;

                -- uart 1 will now send its queued data
                -- uart 2 will queue its data

                wait until tx_ready_2 = '1';
                wait until tx_ready_2 = '0';
            
            end loop;

            tx_data_1   <= "00000000";
            tx_data_2   <= "00000000";
            tx_valid_1  <= '0';
            tx_valid_2  <= '0';

            wait until rx_valid_2 = '1';
            wait for 1 ns;

            assert(rx_data_2 = test_vector_arr_1(test_vector_arr_1'high))
                report "Bad data receiver side (2)"
                severity failure;

            wait until rx_valid_1 = '1';

            assert(rx_data_1 = test_vector_arr_2(test_vector_arr_1'high))
                report "Bad data receiver side (1)"
                severity failure;

            wait until tx_ready_2 = '1';

            wait for T;

        end procedure;

    begin
        for i in 0 to NUM_ITERATIONS - 1 loop
            test_transmit_receive;
        end loop;

        for i in 0 to NUM_ITERATIONS - 1 loop
            test_simultaneous_tx;
        end loop;

        for i in 0 to NUM_ITERATIONS - 1 loop
            test_1_side_bombardment;
        end loop;

        for i in 0 to NUM_ITERATIONS - 1 loop
            test_2_side_bombardment;
        end loop;

        report "TEST SUITE DONE";
        wait;
    end process;

end architecture;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_tb is
end entity;

architecture tb of uart_tb is

    constant CLK_I_F        : positive := 50 * (10 ** 6);
    constant BAUD_RATE      : positive := CLK_I_F / 4;
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

    signal clk_i        : std_logic := '1';
    signal rst_i        : std_logic := '0';
    signal baud_clk_o   : std_logic;

    signal tx_o         : std_logic;
    signal rx_i         : std_logic := '1';
    signal rts_o        : std_logic;
    signal cts_i        : std_logic := '0';
    signal dtr_o        : std_logic;
    signal dsr_i        : std_logic := '0';

    signal tx_ready_o   : std_logic;
    signal tx_valid_i   : std_logic := '0';
    signal tx_data_i    : std_logic_vector(7 downto 0) := "00000000";

    signal rx_ready_i   : std_logic := '0';
    signal rx_valid_o   : std_logic;
    signal rx_data_o    : std_logic_vector(7 downto 0);


    constant hT_clk_i   : time := 5 ns; -- Half Period of clk_i
    constant T_clk_i    : time := 2 * hT_clk_i;

    constant hT         : time := hT_clk_i * MAX_CLK_COUNT; -- Half Period in UART time
    constant T          : time := 2 * hT;

begin

    clk_i <= not clk_i after hT_clk_i;

    DUT : uart
        generic map(
            MAX_CLK_COUNT => MAX_CLK_COUNT
        )
        port map(
            clk_i       => clk_i,
            rst_i       => rst_i,
            baud_clk_o  => baud_clk_o,
            tx_o        => tx_o,
            rx_i        => rx_i,
            rts_o       => rts_o,
            cts_i       => cts_i,
            dtr_o       => dtr_o,
            dsr_i       => dsr_i,
            tx_ready_o  => tx_ready_o,
            tx_valid_i  => tx_valid_i,
            tx_data_i   => tx_data_i,
            rx_ready_i  => rx_ready_i,
            rx_valid_o  => rx_valid_o,
            rx_data_o   => rx_data_o
        );

    process
        constant NUM_ITERATIONS : integer := 4;
        variable rand : real;
        variable seed : positive := 999;

        procedure test_transmit is
            variable test_vector    : std_logic_vector(7 downto 0);
            variable parity         : std_logic;
        begin
            uniform(seed, seed, rand);
            test_vector := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));

            report "TEST_TRANSMIT " & to_string(test_vector);

            parity := xor test_vector;

            rst_i <= '1';
            wait for hT;

            rst_i <= '0';
            wait for 2 * T;
            wait until baud_clk_o = '1';

            assert(tx_ready_o = '1')
                report "Bad tx_ready after reset"
                severity failure;
            wait for 1 ns;

            tx_valid_i <= '1';
            tx_data_i <= test_vector;
            wait until tx_ready_o = '0';

            tx_valid_i <= '0';
            tx_data_i <= "00000000";
            wait for 1 ns;
            
            assert(rts_o = '1')
                report "RTS_O not high after accepting data via TX RV"
                severity failure;

            -- Accept handshake
            cts_i <= '1';

            -- Wait for start
            wait until tx_o = '0';
            wait for 1 ns;

            -- Start bit
            cts_i <= '0';
            wait for T;

            -- Data
            for i in 0 to 7 loop
                assert(tx_o = test_vector(i))
                    report "Bad transmission line on bit " & integer'image(i)
                    severity failure;
                wait for T;
            end loop;

            -- Parity bit
            assert(tx_o = parity)
                report "Bad Parity"
                severity failure;
            wait for T;

            -- Stop
            assert(tx_o = '1')
                report "Bad Stop"
                severity failure;
            wait for T;

            -- ACK transmission
            dsr_i <= '1';
            wait for T;
            
            dsr_i <= '0';
            assert(tx_ready_o = '1')
                report "Bad Ready after ACK"
                severity failure;
            wait for T;

            for i in 0 to 200 loop
                assert(tx_o = '1')
                    report "Retransmitting after ACK"
                    severity failure;
                wait for T;
            end loop;

        end procedure;

        procedure test_retransmit is
            variable test_vector    : std_logic_vector(7 downto 0);
            variable parity         : std_logic;
        begin
            uniform(seed, seed, rand);
            test_vector := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));

            report "TEST_RETRANSMIT " & to_string(test_vector);

            rst_i <= '1';
            wait for T;

            rst_i <= '0';
            wait for 2 * T;
            wait until baud_clk_o = '1';
            wait for 1 ns;

            tx_data_i <= test_vector;
            tx_valid_i <= '1';
            wait for T;

            tx_data_i <= "00000000";
            tx_valid_i <= '0';
            wait for T;

            -- Accept transmission handshake
            cts_i <= '1';
            wait until tx_o = '0';
            wait for 1 ns;
            cts_i <= '0';

            -- This should not affect the current transmision
            tx_data_i <= "11111111";
            tx_valid_i <= '1';
            wait for 2 * T;

            -- Wait for transmission to be over
            tx_data_i <= "00000000";
            tx_valid_i <= '0';
            wait for 10 * T;

            -- Wait for retransmit
            wait until tx_o = '0';
            wait for 10 * T;

            -- ACK the transmission
            dsr_i <= '1';
            wait for T;

            dsr_i <= '0';
            wait for T;

            for i in 0 to 200 loop
                assert(tx_o = '1')
                    report "Retransmitting after ACK"
                    severity failure;
                wait for T;
            end loop;
        end procedure;

        procedure test_receive_correct is 
            variable test_vector    : std_logic_vector(7 downto 0);
            variable parity         : std_logic;
        begin
            uniform(seed, seed, rand);
            test_vector := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));

            report "TEST_RECEIVE_CORRECT " & to_string(test_vector);

            parity := xor test_vector;

            rst_i <= '1';
            wait for hT;

            rst_i <= '0';
            wait for 2 * T;
            wait until baud_clk_o = '1';
            wait for 1 ns;

            cts_i <= '1';
            while rts_o = '0' loop
                wait for T;
            end loop;

            wait for T;

            -- Start
            rx_i <= '0';
            wait for T;

            for i in 0 to 7 loop
                rx_i <= test_vector(i);
                wait for T;
            end loop;

            rx_i <= parity;
            wait for T;

            -- Stop
            rx_i <= '1';
            cts_i <= '0';
            wait for hT;

            assert(rx_data_o = test_vector)
                report "Bad Data"
                severity failure;

            -- Receiver Idle
            wait for T;

            assert(rx_valid_o = '1')
                report "Bad Valid"
                severity failure;
        end procedure;

        procedure test_receive_incorrect is 
            variable test_vector    : std_logic_vector(7 downto 0);
            variable parity         : std_logic;
        begin
            uniform(seed, seed, rand);
            test_vector := std_logic_vector(to_unsigned(integer(256.0 * rand), 8));

            report "TEST_RECEIVE_INCORRECT " & to_string(test_vector);

            parity := xor test_vector;

            rst_i <= '1';
            wait for T;

            rst_i <= '0';
            wait for 2 * T;
            wait until baud_clk_o = '1';
            wait for 1 ns;

            cts_i <= '1';
            while rts_o = '0' loop
                wait for T;
            end loop;

            wait for T;

            -- Start
            rx_i <= '0';
            wait for T;

            for i in 0 to 7 loop
                rx_i <= test_vector(i);
                wait for T;
            end loop;

            -- Feed incorrect parity
            rx_i <= not parity;
            wait for T;

            -- Stop
            rx_i <= '1';
            wait for hT;

            assert(rx_data_o = test_vector)
                report "Bad Data"
                severity failure;

            -- Idle
            wait for T;

            assert(rx_valid_o = '0')
                report "Bad Valid"
                severity failure;

            wait for 20 * T;



            -- Start
            rx_i <= '0';
            wait for T;

            for i in 0 to 7 loop
                rx_i <= test_vector(i);
                wait for T;
            end loop;

            -- Feed correct parity this time
            rx_i <= parity;
            wait for T;

            -- Stop
            rx_i <= '1';
            wait for hT;

            assert(rx_data_o = test_vector)
                report "Bad Data"
                severity failure;

            -- Idle
            cts_i <= '0';
            wait for T;

            assert(rx_valid_o = '1')
                report "Bad Valid"
                severity failure;
        end procedure;
    
    begin
        for i in 0 to NUM_ITERATIONS - 1 loop
            test_transmit;
        end loop;
        
        for i in 0 to NUM_ITERATIONS - 1 loop
            test_retransmit;
        end loop;

        for i in 0 to NUM_ITERATIONS - 1 loop
            test_receive_correct;
        end loop;

        for i in 0 to NUM_ITERATIONS - 1 loop
            test_receive_incorrect;
        end loop;

        report "TEST SUITE DONE";
        wait;
    end process;

end architecture;
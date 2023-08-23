library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity messaging_unit is
    port(
        CLOCK_50        : in std_logic;
        SW              : in std_logic_vector(17 downto 0); -- data to be tx!
        KEY             : in std_logic_vector(3 downto 0); -- key(0) is reset
        GPIO            : inout std_logic_vector(35 downto 0); -- GPIO ports
        LEDG            : out std_logic_vector(7 downto 0);
		  LEDR				: out std_logic_vector(7 downto 0);
        lcd_rw          : out std_logic;
        lcd_en          : out std_logic;
        lcd_rs          : out std_logic;
        lcd_on          : out std_logic;
        lcd_blon        : out std_logic;
        lcd_data        : out std_logic_vector(7 downto 0) -- data to be rx!
    );
end entity;




architecture behaviour of messaging_unit is

component debouncer is
	port(
			  sig_in          : in std_logic;
			  clk             : in std_logic;
			  debounced_sig   : out std_logic
		 );
end component;

component uart is

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


component ic_lcd_driver is
    port(
        rst_i:	  in std_logic;
        data_i:     in std_logic_vector(7 downto 0);

        rx_valid_i   : in std_logic;
        rx_ready_o   : out std_logic;

        lcd_en:     out std_logic;
        lcd_data:   out std_logic_vector(7 downto 0);
        lcd_rs:     out std_logic;
        lcd_rw:     out std_logic;
        lcd_on:     out std_logic;
        lcd_blon:   out std_logic;

        clk_i:   in std_logic
    );
end component;

signal rst : std_logic;

signal baud_clk : std_logic;

signal tx_data : std_logic_vector(7 downto 0);
signal rx_data : std_logic_vector(7 downto 0);

signal tx_ready : std_logic;
signal tx_valid : std_logic;
signal rx_ready : std_logic;
signal rx_valid : std_logic;

signal tx_valid_r : std_logic; -- need to rename tx_valid, tx_valid_r and debounced_transmit!


signal debounced_transmit : std_logic;

signal prev_debounced_r  : std_logic;



begin 

debouncer0 : debouncer
port map(
	sig_in  => tx_valid,
	clk	  => CLOCK_50,
	debounced_sig => debounced_transmit
);

uart0 : uart 
port map(
    clk_i       => CLOCK_50,  -- NEEDS TO BE CLOCK_50
    rst_i       => rst,
    baud_clk_o  => baud_clk,
    -- uart interface
    tx_o        => GPIO(4),
    rx_i        => GPIO(1),
    rts_o       => GPIO(5),
    cts_i       => GPIO(2),
    dtr_o       => GPIO(6),
    dsr_i       => GPIO(3),

    -- Transmit RV interface
    tx_ready_o  => tx_ready,
    tx_valid_i  => tx_valid_r, -- set to key
    tx_data_i   => tx_data,

    -- Receive RV interface
    rx_ready_i  => rx_ready,
    rx_valid_o  => rx_valid,
    rx_data_o   => rx_data
);



ic_lcd_driver0 : ic_lcd_driver
port map(
    rst_i          => rst,
    data_i         => rx_data,

    rx_valid_i     => rx_valid,
    rx_ready_o     => rx_ready,

    lcd_en         => lcd_en,
    lcd_data       => lcd_data,
    lcd_rs         => lcd_rs,
    lcd_rw         => lcd_rw,
    lcd_on         => lcd_on,
    lcd_blon       => lcd_blon,

    clk_i          => baud_clk
);

rst <= NOT(KEY(0));

tx_data <= SW(7 downto 0);
tx_valid <= NOT(KEY(3));

LEDG(0) <= tx_ready or '0';

LEDR(7 downto 0) <= rx_data;

process(baud_clk) begin

if rising_edge(baud_clk) then

	prev_debounced_r <= debounced_transmit;
	
	if(debounced_transmit = '1' AND prev_debounced_r = '0') then
		tx_valid_r <= '1';
		
	elsif(tx_valid_r = '1' and tx_ready = '1') then
		tx_valid_r <= '0';
	end if;
	
end if;
end process;
	
	






end behaviour;
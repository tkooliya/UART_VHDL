library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity messaging_unit_tb is
end entity;

architecture tb of messaging_unit_tb is

	component messaging_unit is
        port(
            CLOCK_50        : in std_logic;
            SW              : in std_logic_vector(17 downto 0); -- data to be tx!
            KEY             : in std_logic_vector(3 downto 0); -- key(0) is reset
            GPIO            : inout std_logic_vector(35 downto 0); -- GPIO ports
            LEDG            : out std_logic_vector(7 downto 0);
            LEDR            : out std_logic_vector(7 downto 0);
            lcd_rw          : out std_logic;
            lcd_en          : out std_logic;
            lcd_rs          : out std_logic;
            lcd_on          : out std_logic;
            lcd_blon        : out std_logic;
            lcd_data        : out std_logic_vector(7 downto 0) -- data to be rx!
        );
    end component;
	
	signal rst : std_logic;
	signal baud_clk: std_logic;
    signal SW_1 : std_logic_vector(17 downto 0);
    signal SW_2 : std_logic_vector(17 downto 0);
    signal KEY_1 : std_logic_vector(3 downto 0);
    signal KEY_2 : std_logic_vector(3 downto 0);
    signal GPIO_1 : std_logic_vector(35 downto 0);
    signal GPIO_2 : std_logic_vector(35 downto 0);
    signal LEDG_1 : std_logic_vector(7 downto 0);
    signal LEDG_2 : std_logic_vector(7 downto 0);
    signal LEDR_1 : std_logic_vector(7 downto 0);
    signal LEDR_2 : std_logic_vector(7 downto 0);

    signal lcd_rw_1 : std_logic;
    signal lcd_en_1 : std_logic;
    signal lcd_rs_1 : std_logic;
    signal lcd_on_1 : std_logic;
    signal lcd_blon_1 : std_logic;
    signal lcd_data_1 : std_logic_vector(7 downto 0);
    signal lcd_rw_2 : std_logic;
    signal lcd_en_2 : std_logic;
    signal lcd_rs_2 : std_logic;
    signal lcd_on_2 : std_logic;
    signal lcd_blon_2 : std_logic;
    signal lcd_data_2 : std_logic_vector(7 downto 0);

    signal CLOCK_50 : std_logic := '0';


begin	
	
    DUT1 : messaging_unit
        port map(
            CLOCK_50    => CLOCK_50,
            SW          => SW_1,   
            KEY         => KEY_1,
            GPIO        => GPIO_1,    
            LEDG        => LEDG_1,  
            LEDR        => LEDR_1, 
            lcd_rw      => lcd_rw_1,    
            lcd_en      => lcd_en_1,    
            lcd_rs      => lcd_rs_1,     
            lcd_on      => lcd_on_1,     
            lcd_blon    => lcd_blon_1,     
            lcd_data    => lcd_data_1     
        );

    DUT2: messaging_unit
        port map(
            CLOCK_50    => CLOCK_50,
            SW          => SW_2,   
            KEY         => KEY_2,
            GPIO        => GPIO_2,    
            LEDG        => LEDG_2,   
            LEDR        => LEDR_2, 
            lcd_rw      => lcd_rw_2,    
            lcd_en      => lcd_en_2,    
            lcd_rs      => lcd_rs_2,     
            lcd_on      => lcd_on_2,     
            lcd_blon    => lcd_blon_2,     
            lcd_data    => lcd_data_2          
    );

    process begin
    
        KEY_1(0) <= '1';
        KEY_2(0) <= '1';
        
        wait for 10 ns;
        
        KEY_1(0) <= '0';
        KEY_2(0) <= '0';

        wait for 10 ns;

        SW_2(7 downto 0) <= "01000001";
        SW_1(7 downto 0) <= "00000000";
        KEY_2(3) <= '1';



        GPIO_1(1) <= GPIO_2(4);
        GPIO_1(2) <= GPIO_2(5);
        GPIO_1(3) <= GPIO_2(6);

        while true loop
            CLOCK_50 <= not CLOCK_50;
            wait for 20 ns;
        end loop;
    
    end process;
end architecture;
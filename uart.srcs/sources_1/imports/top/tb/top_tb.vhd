-----------------------------------------------------------------------------------------
--
--
-- File name     : top_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for top-level module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity top_tb is
end top_tb;

architecture testbench of top_tb is

    -- Components
    component top is
    generic(MAX_DISPLAY_COUNT : positive;
            DEBOUNCE_MAX_COUNT : positive);
    port(CLK_100MHZ : in  std_logic;                       -- 100MHz clock source
         ck_rst     : in  std_logic;                       -- Asynchronous reset signal
         ck_i       : in  std_logic;                       -- General I/O port signal (set to in)
         ck_o       : out std_logic;                       -- General I/O port signal (set to out)
         ja         : out std_logic_vector(4 downto 1);    -- Pmod JA connecter pin signals
         jb         : out std_logic_vector(3 downto 1);    -- Pmod JB connecter pin signals
         jb_c       : out std_logic;                       -- Pmod JB pin C15
         jc         : out std_logic_vector(4 downto 1);    -- Pmod JC connecter pin signals
         jd         : out std_logic_vector(3 downto 1);    -- Pmod JD connecter pin signals
         jd_c       : out std_logic;                       -- Pmod JD pin F3
         LEDs       : out std_logic_vector(3 downto 0);    -- LED connector pin signals (non-RGB)
         RGB0_Red   : out std_logic;                       -- REG_RED LED connector pin signal
         UART_TXD   : out std_logic;                       -- UART USB TX connector pin signal
         BTN        : in std_logic_vector(3 downto 0);     -- BTN connector pin signals
         SW         : in std_logic_vector(3 downto 0));    -- SW connector pin signals
    end component top; 
  
    -- Signals
    signal clk_100mhz   : std_logic := '1';
    signal clk_25mhz    : std_logic := '1';
    signal areset       : std_logic;
    signal ck_i         : std_logic;
    signal ck_o         : std_logic;
    signal ja           : std_logic_vector(4 downto 1);
    signal jb           : std_logic_vector(3 downto 1);
    signal jb_c         : std_logic;
    signal jc           : std_logic_vector(4 downto 1);
    signal jd           : std_logic_vector(3 downto 1);
    signal jd_c         : std_logic;
    signal leds	        : std_logic_vector(3 downto 0); 
    signal rgb0_red     : std_logic;
    signal uart_txd     : std_logic;
    signal btn          : std_logic_vector(3 downto 0);
    signal sw           : std_logic_vector(3 downto 0);

    signal uart_busy    : std_logic;

    -- Constants
    constant period : time := 10 ns;                                                    -- As the clock source runs at 100Mhz, 1/100000000 is the amount of time to complete one clock wave
    constant period_25mhz : time := 40 ns;                                              -- Amount of time to complete one clock wave at 25MHz
    constant next_hex : positive := 250000000;                                          -- 1s for a 25Mhz clock -> For testing we shall make the byte given by the source constant for a sufficient amount of time
    constant btn_delay : positive := 5;                                                 -- Number of cycles to count before registering the button input (at 25MHz)
    constant c_num_cycles_9k6 : positive := 2604;                                       -- number of clock cycles per bit at 9600 Bauds (at 25MHz)
    constant c_num_cycles_115k2 : positive := 218;                                      -- number of clock cycles per bit at 115200 Bauds (at 25MHz)
    constant c_test_packet_1 : std_logic_vector(9 downto 0)  := '1' & x"FF" & '0';      -- Test UART packets
    constant c_test_packet_2 : std_logic_vector(11 downto 0) := "101" & x"FF" & '0';
    constant c_test_packet_3 : std_logic_vector(11 downto 0) := "101" & x"FE" & '0';
    constant c_jc_test : std_logic_vector(4 downto 1) := "0111";                        -- Test segment displays
    constant c_jd_test : std_logic_vector(3 downto 1) := "111";

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_top : top
    generic map(
        MAX_DISPLAY_COUNT => next_hex,
        DEBOUNCE_MAX_COUNT => btn_delay)
    port map(
        CLK_100MHZ => clk_100mhz,
        ck_rst     => areset,
        ck_i       => ck_o,
        ck_o       => ck_o,
        ja         => ja,
        jb         => jb,
        jb_c       => jb_c,
        jc         => jc,
        jd         => jd,
        jd_c       => jd_c,
        LEDs       => leds,
        RGB0_Red   => rgb0_red,
        UART_TXD   => uart_txd,
        BTN        => btn,
        SW         => sw);

    -- Clock generation (100MHz)
    proc_clk : process
    begin
      wait for period/2;
      clk_100mhz <= not clk_100mhz;
    end process proc_clk;

    -- Clock generation (25MHz)
    proc_clk_25mhz : process
    variable shift : std_logic := '0';
    begin
        if shift = '0' then
            wait for period*2;
            shift := '1';
        end if;
        wait for period_25mhz/2;
        clk_25mhz <= not clk_25mhz;
    end process proc_clk_25mhz;

    -- Reset generation
    proc_rst : process
    begin
        areset <= '0';
        wait for period; 
        areset <= '1';
        wait;
    end process proc_rst;

    -- "UART busy" process
    uart_busy <= leds(0);

    -- Run test cases
    -- NB: We shall only test UART Tx / Rx modules, with multiple configurations.
    -- * USB UART Tx can be tested using usb_tx_tb.vhd
    -- * Pmod displays can be tested using ascii_display_tb/hex_display_tb/pmod_tb
    -- * simple/randomiser byte source can be tested using randomiser_tb/simple_tb
    proc_tests : process 
    begin 
        btn <= (others => '0');
        sw <= "0010";                       -- Switch to simple byte source for debugging + testing
        wait until rising_edge(areset);
        wait for 2 ms;                      -- Wait for the reset counter in USB UART to finish
        wait until rising_edge(clk_25mhz);

        -- Test ID:     top_tb_test_1
        -- Description: Push down and hold BTN0; transmit data at 9600 bauds afterwards with parity 
        --              checking disabled; depress BTN0
        btn(0) <= '1';
        wait for period_25mhz*13;
        for i in 0 to c_test_packet_1'length - 1 loop
            for j in 1 to c_num_cycles_9k6 loop
                wait for period_25mhz;
                if ck_o /= c_test_packet_1(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;
        btn(0) <= '0';

        wait until falling_edge(uart_busy);

        -- Test ID:     top_tb_test_2
        -- Description: Push down and depress BTN1; push down and hold BTN0; transmit data at 9600 
        --              bauds afterwards with parity checking enabled; push down and depress BTN1;
        --              depress BTN0
        btn(1) <= '1';
        wait for period_25mhz*13;
        btn(1) <= '0';
        btn(0) <= '1';
        wait for period_25mhz*13;
        for i in 0 to c_test_packet_2'length - 1 loop
            for j in 1 to c_num_cycles_9k6 loop
                wait for period_25mhz;
                if ck_o /= c_test_packet_2(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;
        btn(1) <= '1';
        wait for period_25mhz*13;
        btn(1) <= '0';
        btn(0) <= '0';

        wait until falling_edge(uart_busy);

        -- Test ID:     top_tb_test_3
        -- Description: Slide SW0; push down and hold BTN0; transmit data at 115200 bauds afterwards 
        --              with parity checking disabled; depress BTN0
        sw(0) <= '1';
        btn(0) <= '1';
        wait for period_25mhz*14;
        for i in 0 to c_test_packet_1'length - 1 loop
            for j in 1 to c_num_cycles_115k2 loop
                wait for period_25mhz;
                if ck_o /= c_test_packet_1(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;
        btn(0) <= '0';

        wait until falling_edge(uart_busy);

        -- Test ID:     top_tb_test_4
        -- Description: Push down and depress BTN1; Push down and depress BTN2; Push and hold BTN0; transmit 
        --              data at 115200 bauds afterwards with parity checking testing enabled; push down and 
        --              depress BTN1; Check that the parity checking test signal is set low; Check the signals 
        --              at the Pmod JC/JD pins are correct; slide SW0
        btn(1) <= '1';
        wait for period_25mhz*13;
        btn(1) <= '0';
        btn(2) <= '1';
        wait for period_25mhz*13;
        btn(2) <= '0';
        btn(0) <= '1';
        wait for period_25mhz*13;
        for i in 0 to c_test_packet_1'length - 1 loop
            for j in 1 to c_num_cycles_115k2 loop
                wait for period_25mhz;
                if ck_o /= c_test_packet_3(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;
        btn(1) <= '1';
        wait for period_25mhz*13;
        btn(1) <= '0';
        if btn(2) /= '0' then
            OK <= FAIL;
        end if;
        sw(0) <= '0';

        wait until falling_edge(uart_busy);

        if jc /= c_jc_test or jd /= c_jd_test then
            OK <= FAIL;
        end if;

        -- stop the sim
        report "END OF TESTING";
        if OK = FAIL then
            report "TESTS FAILED";
        else
            report "TESTS PASSED";
        end if;
        stop;
    end process proc_tests;

end architecture testbench;
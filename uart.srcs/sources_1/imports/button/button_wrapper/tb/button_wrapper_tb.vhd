-----------------------------------------------------------------------------------------
--
--
-- File name     : button_wrapper_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for button wrapper module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity button_wrapper_tb is
end button_wrapper_tb;

architecture testbench of button_wrapper_tb is

    -- Components
    component button_wrapper is
        generic(DEBOUNCE_MAX_COUNT    : natural);                        -- Debouncer maximum count value
        port(CLK                      : in  std_logic;                   -- Clock signal
             ARESET                   : in  std_logic;                   -- Reset signal
             i_BTN_0                  : in  std_logic;                   -- Button0 input signal (send LOAD signal)
             i_BTN_1                  : in  std_logic;                   -- Button1 input signal (toggle parity checking signal)
             i_BTN_2                  : in  std_logic;                   -- Button2 input signal (toggle parity checking test signal)
             i_BTN_3                  : in  std_logic;                   -- Button3 input signal (send "Button3 pressed down" signal)
             o_LOAD                   : out std_logic;                   -- "LOAD" output signal
             o_PARITY                 : out std_logic;                   -- Parity enabled output signal
             o_PARITY_TEST            : out std_logic;                   -- Parity Test enabled output signal
             o_BTN3_PRESSED           : out std_logic);                  -- "Button3 pressed down" signal
    end component button_wrapper;

    -- Constants
    constant period : time := 40 ns;
    constant dbnc_cnt : natural := 1;

    -- Signals
    signal clk_25mhz      : std_logic := '1';
    signal areset         : std_logic;
    signal i_btn_0        : std_logic;
    signal i_btn_1        : std_logic;
    signal i_btn_2        : std_logic;
    signal i_btn_3        : std_logic;    
    signal o_load         : std_logic;
    signal o_parity       : std_logic;
    signal o_parity_test  : std_logic;
    signal o_btn3_pressed : std_logic;
    signal btn_reg        : std_logic_vector(3 downto 0);
    signal vals           : std_logic_vector(3 downto 0);

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    i_btn_0 <= btn_reg(0);
    i_btn_1 <= btn_reg(1);
    i_btn_2 <= btn_reg(2);
    i_btn_3 <= btn_reg(3);
    vals <= (o_btn3_pressed, o_parity_test, o_parity, o_load);

    -- Instantiations
    inst_button_wrapper : button_wrapper
    generic map(
        DEBOUNCE_MAX_COUNT => dbnc_cnt)
    port map (
        CLK             => clk_25mhz,
        ARESET          => areset,
        i_BTN_0         => i_btn_0,
        i_BTN_1         => i_btn_1,
        i_BTN_2         => i_btn_2,
        i_BTN_3         => i_btn_3,
        o_LOAD          => o_load,
        o_PARITY        => o_parity,
        o_PARITY_TEST   => o_parity_test,
        o_BTN3_PRESSED  => o_btn3_pressed);

    -- Clock generation
    proc_clk : process
    begin
        wait for period/2;
        clk_25mhz <= not clk_25mhz;
    end process proc_clk;

    -- Reset generation
    proc_rst : process
    begin
        areset <= '0';
        wait for period*2; 
        areset <= '1';
        wait;
    end process proc_rst;

    -- -- Run test cases
    proc_tests : process 
    begin 
        btn_reg <= "0000";
        wait until rising_edge(areset);

        -- Test 1 -> Press each button in turn, validate that all output signals are set high after debouncing period
        for i in 0 to 3 loop
            btn_reg(i) <= '1';
            wait for period*5;
            if vals(i) /= btn_reg(i) then
                OK <= FAIL;
            end if;
        end loop;

        -- Test 2 -> Depress all buttons
        btn_reg <= "0000";
        wait for period*5;
        if vals /= "0110" then
            OK <= FAIL;
        end if;
        
        -- Test 3 -> press btn1 again + depress, parity + coverage should be turn off
        btn_reg(1) <= '1';
        wait for period*5;
        if vals /= "0100" then
            OK <= FAIL;
        end if;
        wait for period; -- Parity test signal will be disabled in the next cycle
        if vals /= "0000" then
            OK <= FAIL;
        end if;
        btn_reg(1) <= '0';
        wait for period;

        -- Test 4 -> press btn1 again + depress, ONLY parity checking should be turn on
        btn_reg(1) <= '1';
        wait for period*5;
        if vals /= "0010" then
            OK <= FAIL;
        end if;
        btn_reg(1) <= '0';
        wait for period;

        -- Test 5 -> Turn on coverage testing
        btn_reg(2) <= '1';
        wait for period*5;
        if vals /= "0110" then
            OK <= FAIL;
        end if;
        btn_reg(2) <= '0';
        wait for period;

        -- Test 6 -> Turn off coverage testing
        btn_reg(2) <= '1';
        wait for period*5;
        if vals /= "0010" then
            OK <= FAIL;
        end if;
        btn_reg(2) <= '0';
        wait for period;

        -- Test 7 -> Turn off parity checking
        btn_reg(1) <= '1';
        wait for period*5;
        if vals /= "0000" then
            OK <= FAIL;
        end if;
        btn_reg(1) <= '0';
        wait for period;

        -- Stop the sim
        report "END OF TESTING";
        if OK = FAIL then
            report "TESTS FAILED";
        else
            report "TESTS PASSED";
        end if;
        stop;
    end process proc_tests;

end architecture testbench;
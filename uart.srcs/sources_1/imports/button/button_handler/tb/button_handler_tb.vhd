-----------------------------------------------------------------------------------------
-- 
--
-- File name     : button_handler_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for button handler module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity button_handler_tb is
end button_handler_tb;

architecture testbench of button_handler_tb is

    -- Components
    component button_handler is
        generic(DEBOUNCE_MAX_COUNT    : natural);                        -- Debouncer maximum count value
        port(CLK                      : in  std_logic;                   -- Clock signal
             ARESET                   : in  std_logic;                   -- reset signal
             i_BTN                    : in  std_logic;                   -- Button input signal
             i_TOGGLE                 : in  std_logic;                   -- Toggle input signal
             i_ENABLE                 : in  std_logic;                   -- Enable signal - If low, o_VAL will always set to low
             o_VAL                    : out std_logic);                  -- Output signal
    end component button_handler;

    -- Constants
    constant period : time := 40 ns;
    constant dbnc_cnt : natural := 1;

    -- Signals
    signal clk_25mhz    : std_logic := '1';
    signal areset       : std_logic;
    signal i_btn        : std_logic;
    signal i_toggle     : std_logic;
    signal i_enable     : std_logic;
    signal o_val        : std_logic;

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_button_handler : button_handler
    generic map(
        DEBOUNCE_MAX_COUNT => dbnc_cnt)
    port map (
        CLK         => clk_25mhz,
        ARESET      => areset,
        i_BTN       => i_btn,
        i_TOGGLE    => i_toggle,
        i_ENABLE    => i_enable,
        o_VAL       => o_val);

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

    -- Run test cases
    proc_tests : process 
    begin 
        i_btn <= '0';
        i_toggle <= '0';
        i_enable <= '1';
        wait until rising_edge(areset);
        
        -- test 1 -> press a button, set output signal high when we enter state FIN
        i_btn <= '1';
        wait for period*5;
        if o_val /= i_btn then
            OK <= FAIL;
        end if;

        -- test 2 -> hold down button for five cycles
        for i in 0 to 4 loop
            wait for period;
            if o_val /= i_btn then
                OK <= FAIL;
            end if;
        end loop;

        -- test 3 -> depress button, set output signal low when we enter state INIT
        i_btn <= not i_btn;
        wait for period*2;
        if o_val /= i_btn then
            OK <= FAIL;
        end if;

        -- test 4 -> set toggling on, repeat test 1
        i_toggle <= '1';
        i_btn <= '1';
        wait for period*5;
        if o_val /= i_btn then
            OK <= FAIL;
        end if;

        -- test 5 -> depress and wait five cycles
        i_btn <= '0';
        for i in 0 to 4 loop
            wait for period;
            if o_val /= '1' then
                OK <= FAIL;
            end if;
        end loop;

        -- test 6 -> repeat test 3 to to set output signal off
        i_toggle <= '1';
        i_btn <= '1';
        wait for period*5;
        if o_val /= '0' then
            OK <= FAIL;
        end if;

        -- test 7 -> depress and wait five cycles
        i_btn <= '0';
        for i in 0 to 4 loop
            wait for period;
            if o_val /= i_btn then
                OK <= FAIL;
            end if;
        end loop;

        -- test 8 -> repeat test 4, disabling output during debouncing
        i_btn <= '1';
        wait for period*4;
        i_enable <= '0';
        wait for period;
        if o_val /= '0' then
            OK <= FAIL;
        end if;

        -- test 9 -> Keep pressing button multiple times, output should still be disabled
        i_btn <= '0';
        for i in 1 to 10 loop
            i_btn <= i_btn xor '1';
            wait for period*5;
            if o_val /= '0' then
                OK <= FAIL;
            end if;
        end loop;
        i_btn <= '0';
        wait for period;
        
        -- test 10 -> Enable output again, repeat test 1
        i_toggle <= '0';
        i_enable <= '1';
        i_btn <= '1';
        wait for period*5;
        if o_val /= i_btn then
            OK <= FAIL;
        end if;
        wait for period;
        
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
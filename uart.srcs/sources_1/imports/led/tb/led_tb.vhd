-----------------------------------------------------------------------------------------
-- 
--
-- File name     : led_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for LED module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity led_tb is
end led_tb;

architecture testbench of led_tb is

    -- Components
    component led is
        port(i_LOAD        : in  std_logic;                         -- "LOAD" signal
             i_PARITY      : in  std_logic;                         -- Parity checking enabled
             i_PARITY_TEST : in  std_logic;                         -- Parity testing enabled
             i_BAUD_RATE   : in  std_logic;                         -- Baud rate
             i_TX_BUSY     : in  std_logic;                         -- UART Tx module busy
             i_RX_BUSY     : in  std_logic;                         -- UART Rx module busy
             o_LED         : out std_logic_vector(3 downto 0);      -- LED signals
             o_RGB0_RED    : out std_logic);                        -- RGB0_RED signal
    end component led;

    -- Constants
    constant period : time := 40 ns;

    -- Signals
    signal i_load           : std_logic;
    signal i_parity         : std_logic;
    signal i_parity_test    : std_logic;
    signal i_baud_rate      : std_logic;
    signal i_tx_busy        : std_logic; 
    signal i_rx_busy        : std_logic;
    signal o_led            : std_logic_vector(3 downto 0);
    signal o_rgb0_red       : std_logic;

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_led : led
    port map (
        i_LOAD          => i_load,
        i_PARITY        => i_parity,
        i_PARITY_TEST   => i_parity_test,
        i_BAUD_RATE     => i_baud_rate,
        i_TX_BUSY       => i_tx_busy,  
        i_RX_BUSY       => i_rx_busy,
        o_LED           => o_led,
        o_RGB0_RED      => o_rgb0_red);

    proc_ok : process
    begin
        for i in 0 to 3 loop
            wait for period*5;
            if(o_led /= (i_load, i_parity, i_baud_rate, i_tx_busy or i_rx_busy) or (o_rgb0_red /= i_parity_test)) then
                OK <= FAIL;
                wait;
            end if;
            wait for period*5;
        end loop;

        wait;
    end process;

    -- -- Run test cases
    proc_tests : process 
    begin 
        i_load <= '0';
        i_parity <= '1';
        i_parity_test <= '0';
        i_baud_rate <= '1';
        i_tx_busy <= '1';
        i_rx_busy <= '1';
        wait for period*10;
        i_load <= '1';
        i_parity <= '0';
        i_parity_test <= '1';
        i_baud_rate <= '0';
        i_tx_busy <= '0';
        i_rx_busy <= '0';
        wait for period*10;
        i_tx_busy <= '1';
        i_rx_busy <= '0';
        wait for period*10;
        i_tx_busy <= '0';
        i_rx_busy <= '1';
        wait for period*10;

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
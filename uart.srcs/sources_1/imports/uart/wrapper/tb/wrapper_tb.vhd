-----------------------------------------------------------------------------------------
--
--
-- File name     : wrapper_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench UART wrapper module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity wrapper_tb is
end wrapper_tb;

architecture testbench of wrapper_tb is

    -- Components
    component wrapper is
    port(CLK           : in  std_logic;                        -- 25MHz Clock Signal
         ARESET        : in  std_logic;                        -- Reset Signal
         i_LOAD        : in  std_logic;                        -- "LOAD" input signal 
         i_PARITY      : in  std_logic;                        -- Enable Parity padding + checking 
         i_PARITY_TEST : in  std_logic;                        -- Parity checking testing signal
         i_BAUD_RATE   : in  std_logic;                        -- Frequency of signalling events per second   
         i_TX_INPUT    : in  std_logic_vector(7 downto 0);     -- Tx vector data input
         i_UART_BIT    : in  std_logic;                        -- Rx input bit
         o_TX_BUSY     : out std_logic;                        -- "Tx is busy" signal to send to an LED, for example
         o_RX_BUSY     : out std_logic;                        -- "Rx is busy" signal to send to an LED, for example
         o_UART_BIT    : out std_logic;                        -- Tx output bit
         o_RX_OUTPUT   : out std_logic_vector(7 downto 0));    -- Rx output data vector
    end component wrapper;

    -- Constants
    constant period : time := 40 ns;

    -- test data
    constant c_test_data_1 : std_logic_vector(7 downto 0) := x"95";
    constant c_test_data_2 : std_logic_vector(7 downto 0) := x"96";
    constant c_test_data_3 : std_logic_vector(7 downto 0) := x"AE";
    constant c_test_data_4 : std_logic_vector(7 downto 0) := x"0F";
    constant c_test_data_5 : std_logic_vector(7 downto 0) := x"12";
    constant c_test_data_6 : std_logic_vector(7 downto 0) := x"ED";

    -- Signals
    signal clk_25mhz          : std_logic := '1';
    signal areset             : std_logic;
    signal i_load             : std_logic := '0';
    signal i_parity           : std_logic;
    signal i_parity_test      : std_logic;
    signal i_baud_rate        : std_logic;
    signal i_tx_input         : std_logic_vector(7 downto 0);
    signal o_tx_busy          : std_logic;
    signal o_rx_busy          : std_logic;
    signal o_rx_output        : std_logic_vector(7 downto 0);
    signal begin_reset        : std_logic := '0';

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

    signal io_channel         : std_logic;  -- Tx bit is directly fed into Rx port

begin

    -- Instantiations
    inst_wrapper : wrapper
        port map (
            CLK             => clk_25mhz,
            ARESET          => areset,
            i_LOAD          => i_load,
            i_PARITY        => i_parity,
            i_PARITY_TEST   => i_parity_test,
            i_BAUD_RATE     => i_baud_rate,
            i_TX_INPUT      => i_tx_input,
            i_UART_BIT      => io_channel,
            o_TX_BUSY       => o_tx_busy,
            o_RX_BUSY       => o_rx_busy,
            o_UART_BIT      => io_channel,
            o_RX_OUTPUT     => o_rx_output);

    -- Clock generation
    proc_clk : process
    begin
      wait for period/2;
      CLK_25MHZ <= not CLK_25MHZ;
    end process proc_clk;
    
    -- Reset generation
    proc_rst : process
    begin
        areset <= '0';
        wait for period*2; 
        areset <= '1';
        wait until rising_edge(begin_reset);
        areset <= '0';
        wait for period; 
        areset <= '1';
        wait;
    end process proc_rst;
  
    -- Run test cases
    -- For tests 1 -> 4, the acceptance criteria is that the receiver obtained the data successfully after sampling
    -- For tests 5 and 6, the acceptance criteria is that the receiver drops the data after parity checking, outputting null data
    -- For test 7, the aceptance criteria is that the output signals must be set to the default values after reset
    proc_tests : process
    begin 
        i_parity   <= '1';
        i_parity_test <= '0';
        i_baud_rate <= '0';
        wait until rising_edge(areset);

        -- Test ID:     wrapper_tb_test_1
        -- Description: Send/Receive data with parity bit at 9600 bauds
        i_tx_input <= c_test_data_1;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait until falling_edge(o_rx_busy);
        wait for period;
        if o_rx_output /= c_test_data_1 then
            OK <= FAIL;
        end if;

        -- Test ID:     wrapper_tb_test_2
        -- Description: Send/Receive data with parity bit at 115200 bauds
        i_tx_input <= c_test_data_2;
        i_baud_rate <= '1';
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait until falling_edge(o_rx_busy);
        wait for period;
        if o_rx_output /= c_test_data_2 then
            OK <= FAIL;
        end if;

        -- Test ID:     wrapper_tb_test_3
        -- Description: Send/Receive data without parity bit at 115200 bauds
        i_parity   <= '0';
        i_tx_input <= c_test_data_3;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait until falling_edge(o_rx_busy);
        wait for period;
        if o_rx_output /= c_test_data_3 then
            OK <= FAIL;
        end if;

        -- Test ID:     wrapper_tb_test_4
        -- Description: Send/Receive data without parity bit at 9600 bauds
        i_parity   <= '0';
        i_baud_rate <= '0';
        i_tx_input <= c_test_data_4;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait until falling_edge(o_rx_busy);
        wait for period;
        if o_rx_output /= c_test_data_4 then
            OK <= FAIL;
        end if;

        -- Test ID:     wrapper_tb_test_5
        -- Description: Send/Receive data with parity checking testing enabled at 9600 bauds
        i_parity   <= '1';
        i_parity_test <= '1';
        i_baud_rate <= '0';
        i_tx_input <= c_test_data_5;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait until falling_edge(o_rx_busy);
        wait for period;
        if o_rx_output /= x"00" then
            OK <= FAIL;
        end if;
        wait for period;

        -- Test ID:     wrapper_tb_test_6
        -- Description: Send/Receive data with parity checking testing enabled at 115200 bauds
        i_parity   <= '1';
        i_parity_test <= '1';
        i_baud_rate <= '1';
        i_tx_input <= c_test_data_6;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait until falling_edge(o_rx_busy);
        wait for period;
        if o_rx_output /= x"00" then
            OK <= FAIL;
        end if;

        -- Test ID:     wrapper_tb_test_7
        -- Description: Set RESET signal low, transmitter/receiver reverts to default outputs
        begin_reset <= '1';
        wait for period;
        if o_rx_busy /= '0' or o_tx_busy /= '0' or io_channel /= '1' or o_rx_output /= x"00" then
            OK <= FAIL;
        end if;
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
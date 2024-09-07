-----------------------------------------------------------------------------------------
--
--
-- File name     : receive_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Testbench for receive module (UART Rx)
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity receive_tb is
end receive_tb;

architecture testbench of receive_tb is

    -- Components
    component receive is
        port(CLK         : in  std_logic;                        -- Clock signal
             ARESET      : in  std_logic;                        -- Reset signal
             i_PARITY    : in  std_logic;                        -- Enable Parity padding + checking
             i_BAUD_RATE : in  std_logic;                        -- Frequency of signalling events per second
             i_UART_BIT  : in  std_logic;                        -- Bit received over UART Rx
             o_RX_BUSY   : out std_logic;                        -- "Rx is busy" signal to send to an LED, for example
             o_RX_OUTPUT : out std_logic_vector(7 downto 0));    -- Rx output data vector
    end component receive;

    -- Constants
    constant period : time := 40 ns;

    constant c_num_cycles_9k6   : positive := 2604;
    constant c_num_cycles_115k2 : positive := 218;

    -- test packets
    constant c_test_packet_1 : std_logic_vector(11 downto 0)  := "111001110110"; -- data = 0x3B (w/ parity bit)
    constant c_test_packet_2 : std_logic_vector(11 downto 0)  := "101110001010"; -- data = 0xC5 (w/ parity bit)
    constant c_test_packet_3 : std_logic_vector(9 downto 0)   := "1011000100";   -- data = 0x62 (w/o parity bit)
    constant c_test_packet_4 : std_logic_vector(9 downto 0)   := "1001110100";   -- data = 0x3A (w/o parity bit)
    constant c_test_packet_5 : std_logic_vector(11 downto 0)  := "111011111010"; -- data = 0x7D (w parity bit, parity checking must fail!)
    constant c_test_packet_6 : std_logic_vector(11 downto 0)  := "101110101010"; -- data = 0xD5 (w parity bit, parity checking must fail!)

    -- Signals
    signal clk_25mhz    : std_logic := '1';
    signal areset       : std_logic;
    signal i_parity     : std_logic;
    signal i_baud_rate  : std_logic;
    signal o_rx_output  : std_logic_vector(7 downto 0) := "00000000";
    signal o_rx_busy    : std_logic; 
    signal i_uart_bit   : std_logic;
    signal begin_reset  : std_logic := '0';

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_receive : receive
    port map (
        CLK          => clk_25mhz,
        ARESET       => areset,
        i_PARITY     => i_parity,
        i_BAUD_RATE  => i_baud_rate,
        i_UART_BIT   => i_uart_bit,
        o_RX_OUTPUT  => o_rx_output,  
        o_RX_BUSY    => o_rx_busy);

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
        wait until rising_edge(begin_reset);
        areset <= '0';
        wait for period; 
        areset <= '1';
        wait;
    end process proc_rst;

    -- Run tests
    -- For tests 1 -> 4, the acceptance criteria is that the receiver obtained the data successfully after sampling
    -- For tests 5 and 6, the acceptance criteria is that the receiver drops the data after parity checking, outputting null data
    -- For test 7, the aceptance criteria is that the output signals must be set to the default values after reset
    proc_tests : process
    begin
        i_parity <= '1';
        i_baud_rate <= '0';
        i_uart_bit <= '1';
        wait until rising_edge(areset);

        -- Test ID:     receive_tb_test_1
        -- Description: Receiving packet transmitted at 9600 bauds, enabling parity checking
        for i in 0 to 11 loop
            wait for period*c_num_cycles_9k6;
            i_uart_bit <= c_test_packet_1(i);
        end loop;

        wait until falling_edge(o_rx_busy);
        if o_rx_output /= x"3B" then
            OK <= FAIL;
        end if;

        -- Test ID:     receive_tb_test_2
        -- Description: Receiving packet transmitted at 115200 bauds, enabling parity checking
        i_baud_rate <= '1';
        for i in 0 to 11 loop
            wait for period*c_num_cycles_115k2;
            i_uart_bit <= c_test_packet_2(i);
        end loop;

        wait until falling_edge(o_rx_busy);
        if o_rx_output /= x"C5" then
            OK <= FAIL;
        end if;

        -- Test ID:     receive_tb_test_3
        -- Description: Receiving packet transmitted at 115200 bauds, disabling parity checking
        i_parity <= '0';
        for i in 0 to 9 loop
            wait for period*c_num_cycles_115k2;
            i_uart_bit <= c_test_packet_3(i);
        end loop;

        wait until falling_edge(o_rx_busy);
        if o_rx_output /= x"62" then
            OK <= FAIL;
        end if;

        -- Test ID:     receive_tb_test_4
        -- Description: Receiving packet transmitted at 9600 bauds, disabling parity checking
        i_baud_rate <= '0';
        for i in 0 to 9 loop
            wait for period*c_num_cycles_9k6;
            i_uart_bit <= c_test_packet_4(i);
        end loop;

        wait until falling_edge(o_rx_busy);
        if o_rx_output /= x"3A" then
            OK <= FAIL;
        end if;

        -- Test ID:     receive_tb_test_5
        -- Description: Receiving corrupted packet transmitted at 9600 bauds, enabling parity checking,
        --              packet expected to be dropped
        i_parity <= '1';
        for i in 0 to 11 loop
            wait for period*c_num_cycles_9k6;
            i_uart_bit <= c_test_packet_5(i);
        end loop;

        wait until falling_edge(o_rx_busy);
        if o_rx_output /= x"00" then
            OK <= FAIL;
        end if;

        -- Test ID:     receive_tb_test_6
        -- Description: Receiving packet transmitted at 115200 bauds, enabling parity checking,
        --              packet expected to be dropped
        i_baud_rate <= '1';
        for i in 0 to 11 loop
            wait for period*c_num_cycles_115k2;
            i_uart_bit <= c_test_packet_6(i);
        end loop;

        wait until falling_edge(o_rx_busy);
        if o_rx_output /= x"00" then
            OK <= FAIL;
        end if;

        -- Test ID:     receive_tb_test_7
        -- Description: Set RESET signal low, transmitter reverts to default outputs
        begin_reset <= '1';
        wait for period;
        if o_rx_output /= x"00" or o_rx_busy /= '0' then
            OK <= FAIL;
        end if;

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
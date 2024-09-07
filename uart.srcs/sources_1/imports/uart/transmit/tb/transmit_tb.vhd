-----------------------------------------------------------------------------------------
-- 
--
-- File name     : transmit_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Testbench for transmit module (UART Tx)
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity transmit_tb is
end transmit_tb;

architecture testbench of transmit_tb is

    -- Components
    component transmit is
    port(CLK                    : in  std_logic;                    -- 100MHz clock signal
         ARESET                 : in  std_logic;                    -- Reset signal
         i_LOAD                 : in  std_logic;                    -- "LOAD" input signal
         i_PARITY               : in  std_logic;                    -- Enable Parity padding + checking
         i_PARITY_TEST          : in  std_logic;                    -- Parity checking testing signal
         i_BAUD_RATE            : in  std_logic;                    -- Fequency of signalling events per second (say '0' -> 9600, '1' -> 115200)
         i_TX_INPUT             : in  std_logic_vector(7 downto 0); -- Tx data input
         o_TX_BUSY              : out std_logic;                    -- "Tx is busy" signal to send to an LED, for example
         o_UART_BIT             : out std_logic);                   -- dummy 25MHz clock signal, useful for debugging
    end component transmit;

    -- Constants
    constant period      : time := 40 ns;

    constant c_test_input_1  : std_logic_vector(7 downto 0)     := "10110111";          -- 0xB7
    constant c_test_packet_1 : std_logic_vector(11 downto 0)    := "101101101110";      -- data = 0xB7 (w/ parity bit)
    constant c_test_input_2  : std_logic_vector(7 downto 0)     := "10010101";          -- 0x95
    constant c_test_packet_2 : std_logic_vector(11 downto 0)    := "101100101010";      -- data = 0x95 (w/ parity bit)
    constant c_test_input_3  : std_logic_vector(7 downto 0)     := "11000001";          -- 0xC1
    constant c_test_packet_3 : std_logic_vector(9 downto 0)     := "1110000010";        -- data = 0xC1 (w/o parity bit)
    constant c_test_input_4  : std_logic_vector(7 downto 0)     := "11111111";          -- 0xFF
    constant c_test_packet_4 : std_logic_vector(11 downto 0)    := "101111111100";      -- original data = 0xFF (w/ INCORRECT parity bit, corrupted data = 0xFE)
    constant c_test_input_5  : std_logic_vector(7 downto 0)     := "10010110";          -- 0x96
    constant c_test_packet_5 : std_logic_vector(11 downto 0)    := "101100101110";      -- original data = 0x96 (w/ INCORRECT parity bit, corrupted data = 0x97)

    constant c_num_cycles_9k6   : positive := 2604;
    constant c_num_cycles_115k2 : positive := 218;

    -- Signals
    signal clk_25mhz     : std_logic := '1';
    signal areset        : std_logic;
    signal i_load        : std_logic;
    signal i_parity      : std_logic;
    signal i_parity_test : std_logic;
    signal i_baud_rate   : std_logic;
    signal i_tx_input    : std_logic_vector(7 downto 0) := (others => '0');
    signal o_tx_busy     : std_logic; 
    signal o_uart_bit    : std_logic;
    signal begin_reset   : std_logic := '0';

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_transmit : transmit
    port map (
        CLK           => clk_25mhz,
        ARESET        => areset,
        i_LOAD        => i_load,
        i_PARITY      => i_parity,
        i_PARITY_TEST => i_parity_test,
        i_BAUD_RATE   => i_baud_rate,
        i_TX_INPUT    => i_tx_input,  
        o_TX_BUSY     => o_tx_busy,
        o_UART_BIT    => o_uart_bit);

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

    -- Run test cases
    -- For tests 1 -> 6, the acceptance criteria is that each bit in the packet must be sent for the required 
    -- number of clock cycles after loading the data and packet construction. 
    -- For test 7, the aceptance criteria is that the output signals must be set to the default values after reset
    proc_tests : process 
    begin 
        i_load <= '0';
        i_parity <= '1';                                        -- Parity Enabled
        i_parity_test <= '0';
        i_baud_rate <= '1';                                     -- 115200 bauds
        wait until rising_edge(areset);

        -- Test ID:     trasmit_tb_test_1
        -- Description: Toggle LOAD signal, transmit at baud rate 115200, enable parity bit
        i_tx_input <= c_test_input_1;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait for period*3;                                      -- wait until Tx starts sending the first bit
        for i in 0 to c_test_packet_1'length - 1 loop
            for j in 1 to c_num_cycles_115k2 loop
                wait for period;
                if o_uart_bit /= c_test_packet_1(i) then        -- check AFTER rising clock cycle edge
                    OK <= FAIL;
                end if;
            end loop;
        end loop;

        wait until falling_edge(o_tx_busy);

        -- Test ID:     trasmit_tb_test_2
        -- Description: Toggle LOAD signal, transmit at baud rate 9600, enable parity bit
        i_baud_rate <= '0';                                     -- 9600 bauds
        i_tx_input <= c_test_input_2;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait for period*3;
        for i in 0 to c_test_packet_2'length - 1 loop
            for j in 1 to c_num_cycles_9k6 loop
                wait for period;
                if o_uart_bit /= c_test_packet_2(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;

        wait until falling_edge(o_tx_busy);

        -- Test ID:             trasmit_tb_test_3
        -- Description:         Toggle LOAD signal, transmit at baud rate 115200, disable parity bit
        i_baud_rate <= '1';                                     -- 115200 bauds
        i_parity <= '0';                                        -- parity bit disabled
        i_tx_input <= c_test_input_3;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait for period*3;
        for i in 0 to c_test_packet_3'length - 1 loop
            for j in 1 to c_num_cycles_115k2 loop
                wait for period;
                if o_uart_bit /= c_test_packet_3(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;

        wait until falling_edge(o_tx_busy);

        -- Test ID:     trasmit_tb_test_4
        -- Description: Toggle LOAD signal, transmit at baud rate 9600, disable parity bit
        i_baud_rate <= '0';                                     -- 115200 bauds
        i_parity <= '0';                                        -- parity bit disabled
        i_tx_input <= c_test_input_3;                           -- Still using the same data as in trasmit_tb_test_3
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait for period*3;
        for i in 0 to c_test_packet_3'length - 1 loop
            for j in 1 to c_num_cycles_9k6 loop
                wait for period;
                if o_uart_bit /= c_test_packet_3(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;

        wait until falling_edge(o_tx_busy);

        -- Test ID:     trasmit_tb_test_5
        -- Description: Toggle LOAD signal, transmit at baud rate 115200, enable parity bit, enable parity checking testing
        i_baud_rate <= '1';                                     -- 115200 bauds
        i_parity <= '1';
        i_parity_test <= '1';                                   -- Parity checking testing enabled - flip the lsb of the data frame
        i_tx_input <= c_test_input_4;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait for period*3;
        for i in 0 to c_test_packet_4'length - 1 loop
            for j in 1 to c_num_cycles_115k2 loop
                wait for period;
                if o_uart_bit /= c_test_packet_4(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;

        wait until falling_edge(o_tx_busy);

        -- Test ID:     trasmit_tb_test_6
        -- Description: Toggle LOAD signal, transmit at baud rate 9600, enable parity bit, enable parity checking testing
        i_baud_rate <= '0';
        i_parity <= '1';
        i_parity_test <= '1';                                   -- Parity checking testing enabled - flip the lsb of the data frame
        i_tx_input <= c_test_input_5;
        i_load <= '1';
        wait for period*2;
        i_load <= '0';
        wait for period*3;
        for i in 0 to c_test_packet_5'length - 1 loop
            for j in 1 to c_num_cycles_9k6 loop
                wait for period;
                if o_uart_bit /= c_test_packet_5(i) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;

        wait until falling_edge(o_tx_busy);

        -- Test ID:     trasmit_tb_test_7
        -- Description: Set RESET signal low, transmitter reverts to default outputs
        begin_reset <= '1';
        wait for period;
        if o_tx_busy /= '0' or o_uart_bit /= '1' then
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
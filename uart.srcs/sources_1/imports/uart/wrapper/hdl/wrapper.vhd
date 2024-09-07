-----------------------------------------------------------------------------------------
--
--
-- File name     : UART Wrapper
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- UART Wrapper. Contains the Tx and Rx modules.
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------
-- Entity
-----------------------------------------------------------------------------------------
entity wrapper is
    port(CLK           : in  std_logic;                        -- Clock Signal
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
end entity wrapper; 

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture structural of wrapper is

    -- UART Tx component (transmit module)
    component transmit is
        port(CLK           : in  std_logic;                        -- Clock signal
             ARESET        : in  std_logic;                        -- Reset signal
             i_LOAD        : in  std_logic;                        -- "LOAD" input signal
             i_PARITY      : in  std_logic;                        -- Enable Parity padding + checking
             i_PARITY_TEST : in  std_logic;                        -- Parity checking testing signal
             i_BAUD_RATE   : in  std_logic;                        -- Frequency of signalling events per second
             i_TX_INPUT    : in  std_logic_vector(7 downto 0);     -- Tx vector data input
             o_TX_BUSY     : out std_logic;                        -- "Tx is busy" signal to send to an LED, for example
             o_UART_BIT    : out std_logic);                       -- The output bit that gets sent over Tx
    end component transmit;

    -- UART Rx component (receive module)
    component receive is
        port(CLK     : in  std_logic;                              -- Clock signal
             ARESET        : in  std_logic;                        -- Reset signal
             i_PARITY      : in  std_logic;                        -- Enable Parity padding + checking
             i_BAUD_RATE   : in  std_logic;                        -- Frequency of signalling events per second
             i_UART_BIT    : in  std_logic;                        -- Bit received over UART Rx
             o_RX_BUSY     : out std_logic;                        -- "Rx is busy" signal to send to an LED, for example
             o_RX_OUTPUT   : out std_logic_vector(7 downto 0));    -- Rx output data vector
    end component receive;

begin

    -- Instantiations
    uart_tx : component transmit
        port map (
            CLK           => CLK,
            ARESET        => ARESET,
            i_LOAD        => i_LOAD,
            i_PARITY      => i_PARITY,
            i_PARITY_TEST => i_PARITY_TEST,
            i_BAUD_RATE   => i_BAUD_RATE,
            i_TX_INPUT    => i_TX_INPUT,
            o_TX_BUSY     => o_TX_BUSY,
            o_UART_BIT    => o_UART_BIT);

    uart_rx : component receive
        port map (
            CLK           => CLK,
            ARESET        => ARESET,
            i_PARITY      => i_PARITY,
            i_BAUD_RATE   => i_BAUD_RATE,
            i_UART_BIT    => i_UART_BIT,
            o_RX_BUSY     => o_RX_BUSY,
            o_RX_OUTPUT   => o_RX_OUTPUT);

end architecture structural;
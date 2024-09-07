-----------------------------------------------------------------------------------------
--
--
-- File name     : led
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- LED driver
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------
-- Entity
-----------------------------------------------------------------------------------------
entity led is
    port(i_LOAD        : in  std_logic;                         -- "LOAD" signal
         i_PARITY      : in  std_logic;                         -- Parity checking enabled
         i_PARITY_TEST : in  std_logic;                         -- Parity testing enabled
         i_BAUD_RATE   : in  std_logic;                         -- Baud rate
         i_TX_BUSY     : in  std_logic;                         -- UART Tx module busy
         i_RX_BUSY     : in  std_logic;                         -- UART Rx module busy
         o_LED         : out std_logic_vector(3 downto 0);      -- LED signals
         o_RGB0_RED    : out std_logic);                        -- RGB0_RED signal
end led;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of led is
begin

    o_LED <= (i_LOAD, i_PARITY, i_BAUD_RATE, i_TX_BUSY or i_RX_BUSY);
    o_RGB0_RED <= i_PARITY_TEST;

end rtl;
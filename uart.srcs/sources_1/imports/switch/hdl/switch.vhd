-----------------------------------------------------------------------------------------
--
--
-- File name     : switch
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Switch Driver
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
entity switch is
    port(i_SW          : in  std_logic_vector(3 downto 0);     -- Incoming Switch signals
         o_BAUD_RATE   : out std_logic;                        -- Baud rate selector
         o_SIMPLE_MODE : out std_logic;                        -- Byte source selector
         o_PRINT       : out std_logic;                        -- "Print random byte to Putty" signal
         o_SW3_ON      : out std_logic);                       -- Switch 3 set at "on" or "off"
end switch;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of switch is

begin

    o_BAUD_RATE   <= i_SW(0);     -- Switch 0 -> Toggle UART Baud Rate
    o_SIMPLE_MODE <= i_SW(1);     -- Switch 1 -> Toggle between random and simple byte source
    o_PRINT       <= i_SW(2);     -- Switch 2 -> Toggle the random bytes being printed to the putty terminal
    o_SW3_ON      <= i_SW(3);     -- Swtich 3 -> "Dummy" switch to test switch change detection for USB UART

end rtl;
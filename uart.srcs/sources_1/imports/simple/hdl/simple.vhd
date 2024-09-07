-----------------------------------------------------------------------------------------
--
--
-- File name     : randomiser
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Periodically cycles through two fixed bytes. Works with VHDL 2008. Useful for
-- debugging.
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-----------------------------------------------------------------------------------------
-- Entity
-----------------------------------------------------------------------------------------
entity simple is
    generic(MAX_COUNT : positive := 25000000);                    -- Delay before changing the output byte - default is to wait 1 second
    port(CLK       : in  std_logic;                               -- Clock signal
         ARESET    : in  std_logic;                               -- Reset signal
         o_BYTE    : out std_logic_vector(7 downto 0));           -- Output byte
end simple;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of simple is
begin

    proc_simple : process (CLK, ARESET) is
    variable v_count : natural;
    variable v_vals : std_logic_vector(15 downto 0) := x"58FF";
    begin
        if ARESET = '0' then
            v_count := 0;
            o_BYTE <= x"FF";
        elsif rising_edge(CLK) then
            o_BYTE <= o_BYTE;
            v_count := v_count + 1;
            if v_count = MAX_COUNT then
                v_count := 0;
                v_vals := v_vals(7 downto 0) & v_vals(15 downto 8); 
                o_BYTE <= v_vals(7 downto 0);
            end if;
        end if;
    end process proc_simple;

end rtl;
-----------------------------------------------------------------------------------------
-- 
--
-- File name     : switch_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for switch module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity switch_tb is
end switch_tb;

architecture testbench of switch_tb is

    -- Components
    component switch is
        port(i_SW          : in  std_logic_vector(3 downto 0);     -- Incoming Switch signals
             o_BAUD_RATE   : out std_logic;                        -- Baud rate selector
             o_SIMPLE_MODE : out std_logic;                        -- Byte source selector
             o_PRINT       : out std_logic;                        -- "Print random byte to Putty" signal
             o_SW3_ON      : out std_logic);                       -- Switch 3 set at "on" or "off"
    end component switch;

    -- Constants
    constant period : time := 40 ns;

    -- Signals
    signal i_sw          : std_logic_vector(3 downto 0);
    signal o_baud_rate   : std_logic;
    signal o_simple_mode : std_logic;
    signal o_print       : std_logic; 
    signal o_sw3_on      : std_logic;

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_switch : component switch
    port map (
        i_SW          => i_sw,
        o_BAUD_RATE   => o_baud_rate,
        o_SIMPLE_MODE => o_simple_mode,
        o_PRINT       => o_print,
        o_SW3_ON      => o_sw3_on);

    proc_ok : process
    begin
        for i in 0 to 3 loop
            wait for period*5;
            if i_sw /= (o_sw3_on, o_print, o_simple_mode, o_baud_rate) then
                OK <= FAIL;
                wait;
            end if;
            wait for period*5;
        end loop;
        
        wait;
    end process;

    -- Run test cases
    proc_tests : process 
    begin 
        i_sw <= (others => '0');
        for i in 0 to 3 loop
            i_sw(i) <= '1';
            wait for period*10;
            i_sw(i) <= '0';
            wait for period*10;
        end loop;
        -- Stop the sim
        stop;
    end process proc_tests;

end architecture testbench;
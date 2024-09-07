-----------------------------------------------------------------------------------------
--
--
-- File name     : Pmod
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Pmod SDD 7-segment display driver.
-- Reference: https://github.com/timothystotts/fpga-serial-acl-tester-1/blob/main/ACL-Tester-Design-Single-Clock-VHDL/RTL/ssd_display.vhdl
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
entity pmod is
    port(CLK         : in  std_logic;                        -- Clock signal
         ARESET      : in  std_logic;                        -- Reset signal
         i_DISPLAY_0 : in  std_logic_vector(6 downto 0);     -- Segment display 0 signal
         i_DISPLAY_1 : in  std_logic_vector(6 downto 0);     -- Segment display 1 signal
         o_SELECT    : out std_logic;                        -- Digit selection signal 
         o_DISP      : out std_logic_vector(6 downto 0));    -- Digit display
end pmod;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of pmod is

    signal sig_display0         : std_logic_vector(6 downto 0);
    signal sig_display1         : std_logic_vector(6 downto 0);
    signal sig_current_display  : std_logic_vector(6 downto 0);
    signal sig_current_selector : std_logic;

begin

    proc_pmod : process(CLK, ARESET)
    begin
        if ARESET = '0' then
            sig_current_selector <= '0';
            sig_display0 <= (others => '0');
            sig_display1 <= (others => '0');
            sig_current_display <= (others => '0');
        elsif rising_edge(CLK) then
            sig_display0 <= i_DISPLAY_0;
            sig_display1 <= i_DISPLAY_1;
            if sig_current_selector = '0' then
                sig_current_selector <= '1';
                sig_current_display <= sig_display1;
            else
                sig_current_selector <= '0';
                sig_current_display <= sig_display0;
            end if;
        end if;
    end process proc_pmod;

    o_SELECT <= sig_current_selector;
    o_DISP <= sig_current_display;

end rtl;
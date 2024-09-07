-----------------------------------------------------------------------------------------
--
--
-- File name     : hexadecimal display
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Pmod SDD 7-segment display (hexadecimal).
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
entity hex_display is
    port(CLK       : in  std_logic;                        -- Clock Signal
         ARESET    : in  std_logic;                        -- Reset Signal
         i_VALUE   : in  std_logic_vector(7 downto 0);     -- Byte value to display (0 to 255)
         o_SELECT  : out std_logic;                        -- Digit Selection Signal
         o_DISP    : out std_logic_vector(6 downto 0));    -- Digit Display
end hex_display;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture structural of hex_display is

    -- Convert 4-bit value for hex display
    function hex_to_ssd(val : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable v_ret : std_logic_vector(6 downto 0);
    begin
        case val is
             when x"0"   => v_ret := "0111111";
             when x"1"   => v_ret := "0000110";
             when x"2"   => v_ret := "1011011";
             when x"3"   => v_ret := "1001111";
             when x"4"   => v_ret := "1100110";
             when x"5"   => v_ret := "1101101";
             when x"6"   => v_ret := "1111101";
             when x"7"   => v_ret := "0000111";
             when x"8"   => v_ret := "1111111";
             when x"9"   => v_ret := "1100111";
             when x"A"   => v_ret := "1110111";
             when x"B"   => v_ret := "1111100";
             when x"C"   => v_ret := "0111001";
             when x"D"   => v_ret := "1011110";
             when x"E"   => v_ret := "1111001";
             when x"F"   => v_ret := "1110001";
             when others => v_ret := "0000000";
        end case;
        return v_ret;
    end function hex_to_ssd;

    signal sig_display0         : std_logic_vector(6 downto 0);
    signal sig_display1         : std_logic_vector(6 downto 0);
    signal sig_current_display  : std_logic_vector(6 downto 0);
    signal sig_current_selector : std_logic;

    component pmod is
        port(CLK                : in  std_logic;
             ARESET             : in  std_logic;
             i_DISPLAY_0        : in  std_logic_vector(6 downto 0);
             i_DISPLAY_1        : in  std_logic_vector(6 downto 0);
             o_SELECT           : out std_logic;
             o_DISP             : out std_logic_vector(6 downto 0));
    end component;

begin

    -- Instantiations
    inst_pmod : component pmod
        port map(
            CLK         => CLK,
            ARESET      => ARESET,
            i_DISPLAY_0 => sig_display0,
            i_DISPLAY_1 => sig_display1,
            o_SELECT    => sig_current_selector,
            o_DISP      => sig_current_display);

    proc_display_handler : process(CLK, ARESET)
    begin
        if ARESET = '0' then
            sig_display0 <= (others => '0');
            sig_display1 <= (others => '0');
        elsif rising_edge(CLK) then
            sig_display0 <= hex_to_ssd(i_VALUE(3 downto 0));
            sig_display1 <= hex_to_ssd(i_VALUE(7 downto 4));
        end if;
    end process proc_display_handler; 

    o_SELECT <= sig_current_selector;
    o_DISP <= sig_current_display;

end structural;
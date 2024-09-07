-----------------------------------------------------------------------------------------
--
--
-- File name     : ASCII display
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Pmod SDD 7-segment display driver (ASCII).
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
entity ascii_display is
    port(CLK       : in  std_logic;                        -- Clock Signal
         ARESET    : in  std_logic;                        -- Reset Signal
         i_VALUE   : in  std_logic_vector(7 downto 0);     -- Byte value to display (0 to 255)
         o_SELECT  : out std_logic;                        -- Digit Selection Signal 
         o_DISP    : out std_logic_vector(6 downto 0));    -- Digit Display
end ascii_display;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture structural of ascii_display is

    -- Convert byte as ASCII into a digit or letter for display, if possible
    -- Otherwise, output display bits equivalent to 'NA'
    -- We reserve the byte "00" as a special case
    function ascii_to_ssd(val : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable v_ret : std_logic_vector(13 downto 0) := (others => '0');
    begin
        case val is
             -- SPECIAL CASE WHEN BYTE IS ALL ZEROES
             when x"00"   => v_ret               := "01111110111111"; -- 00
             -- DIGITS
             when x"30"   => v_ret(6 downto 0)   := "0111111"; -- 0
             when x"31"   => v_ret(6 downto 0)   := "0000110"; -- 1
             when x"32"   => v_ret(6 downto 0)   := "1011011"; -- 2
             when x"33"   => v_ret(6 downto 0)   := "1001111"; -- 3
             when x"34"   => v_ret(6 downto 0)   := "1100110"; -- 4
             when x"35"   => v_ret(6 downto 0)   := "1101101"; -- 5
             when x"36"   => v_ret(6 downto 0)   := "1111101"; -- 6
             when x"37"   => v_ret(6 downto 0)   := "0000111"; -- 7
             when x"38"   => v_ret(6 downto 0)   := "1111111"; -- 8
             when x"39"   => v_ret(6 downto 0)   := "1100111"; -- 9
             -- UPPERCASE LETTERS
             when x"41"   => v_ret(6 downto 0)   := "1110111"; -- A
             when x"42"   => v_ret(6 downto 0)   := "1111100"; -- B
             when x"43"   => v_ret(6 downto 0)   := "0111001"; -- C
             when x"44"   => v_ret(6 downto 0)   := "1011110"; -- D
             when x"45"   => v_ret(6 downto 0)   := "1111001"; -- E
             when x"46"   => v_ret(6 downto 0)   := "1110001"; -- F
             when x"48"   => v_ret(6 downto 0)   := "1110110"; -- H
             when x"49"   => v_ret(6 downto 0)   := "0000110"; -- I
             when x"4A"   => v_ret(6 downto 0)   := "0001110"; -- J
             when x"4C"   => v_ret(6 downto 0)   := "0111000"; -- L
             when x"4E"   => v_ret(6 downto 0)   := "0110111"; -- N
             when x"4F"   => v_ret(6 downto 0)   := "0111111"; -- O
             when x"50"   => v_ret(6 downto 0)   := "1110011"; -- P
             when x"53"   => v_ret(6 downto 0)   := "1101101"; -- S
             when x"55"   => v_ret(6 downto 0)   := "0111110"; -- U
             when x"58"   => v_ret(6 downto 0)   := "1110110"; -- X
             -- LOWERCASE LETTERS
             when x"62"   => v_ret(6 downto 0)   := "1111100"; -- b
             when x"63"   => v_ret(6 downto 0)   := "1011000"; -- c
             when x"64"   => v_ret(6 downto 0)   := "1011110"; -- d
             when x"68"   => v_ret(6 downto 0)   := "1110100"; -- h
             when x"69"   => v_ret(6 downto 0)   := "0000100"; -- i
             when x"6A"   => v_ret(6 downto 0)   := "0001100"; -- j
             when x"6C"   => v_ret(6 downto 0)   := "0011000"; -- l
             when x"6E"   => v_ret(6 downto 0)   := "1010100"; -- n
             when x"6F"   => v_ret(6 downto 0)   := "1011100"; -- o
             when x"72"   => v_ret(6 downto 0)   := "1010000"; -- r
             when x"74"   => v_ret(6 downto 0)   := "1111000"; -- t
             when x"75"   => v_ret(6 downto 0)   := "0011100"; -- u
             when x"79"   => v_ret(6 downto 0)   := "1101110"; -- y
             -- NOT APPLICABLE (NA)
             when others => v_ret                := "01101111110111";
        end case;

        return v_ret;
    end function ascii_to_ssd;

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
            sig_display0 <= ascii_to_ssd(i_VALUE)(6 downto 0);
            sig_display1 <= ascii_to_ssd(i_VALUE)(13 downto 7);
        end if;
    end process proc_display_handler; 

    o_SELECT <= sig_current_selector;
    o_DISP <= sig_current_display;

end structural;
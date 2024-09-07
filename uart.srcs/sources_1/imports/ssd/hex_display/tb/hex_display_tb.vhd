-----------------------------------------------------------------------------------------
-- 
--
-- File name     : hex_display_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for hex display module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity hex_display_tb is
end hex_display_tb;

architecture testbench of hex_display_tb is

    -- Components
    component hex_display is
        port(CLK                : in  std_logic;                        -- Clock Signal
             ARESET             : in  std_logic;                        -- Reset Signal
             i_VALUE            : in  std_logic_vector(7 downto 0);     -- Byte value to display (0 to 255)
             o_SELECT           : out std_logic;                        -- Digit Selection Signal 
             o_DISP             : out std_logic_vector(6 downto 0));    -- Digit Display
    end component hex_display;

    -- Constants
    constant period : time := 40 ns;

    constant c_test_1_value : std_logic_vector(7 downto 0) := x"00";     -- 00
    constant c_test_1_disp0 : std_logic_vector(6 downto 0) := "0111111"; -- 3F
    constant c_test_1_disp1 : std_logic_vector(6 downto 0) := "0111111"; -- 3F

    constant c_test_2_value : std_logic_vector(7 downto 0) := x"33";     -- 33
    constant c_test_2_disp0 : std_logic_vector(6 downto 0) := "1001111"; -- 4F
    constant c_test_2_disp1 : std_logic_vector(6 downto 0) := "1001111"; -- 4F

    constant c_test_3_value : std_logic_vector(7 downto 0) := x"4D";     -- 4D
    constant c_test_3_disp0 : std_logic_vector(6 downto 0) := "1011110"; -- 5E
    constant c_test_3_disp1 : std_logic_vector(6 downto 0) := "1100110"; -- 66

    constant c_test_4_value : std_logic_vector(7 downto 0) := x"68";     -- 68
    constant c_test_4_disp0 : std_logic_vector(6 downto 0) := "1111111"; -- 7F
    constant c_test_4_disp1 : std_logic_vector(6 downto 0) := "1111101"; -- 7D

    constant c_test_5_value : std_logic_vector(7 downto 0) := x"48";     -- 48
    constant c_test_5_disp0 : std_logic_vector(6 downto 0) := "1111111"; -- 7F
    constant c_test_5_disp1 : std_logic_vector(6 downto 0) := "1100110"; -- 66

    type TEST_VAL_ARR is array (0 to 4) of std_logic_vector(7 downto 0);
    constant test_val : TEST_VAL_ARR := (c_test_1_value, c_test_2_value, c_test_3_value, c_test_4_value, c_test_5_value);
    
    type DISP_VAL_ARR is array (0 to 4) of std_logic_vector(6 downto 0);
    constant test_disp0 : DISP_VAL_ARR := (c_test_1_disp0, c_test_2_disp0, c_test_3_disp0, c_test_4_disp0, c_test_5_disp0);
    constant test_disp1 : DISP_VAL_ARR := (c_test_1_disp1, c_test_2_disp1, c_test_3_disp1, c_test_4_disp1, c_test_5_disp1);

    -- Signals
    signal clk_25mhz    : std_logic := '1';
    signal areset       : std_logic;
    signal i_value      : std_logic_vector(7 downto 0);
    signal o_select     : std_logic; 
    signal o_disp       : std_logic_vector(6 downto 0);

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_hex_display : hex_display
    port map (
        CLK         => clk_25mhz,
        ARESET      => areset,
        i_VALUE     => i_value,
        o_SELECT    => o_select,
        o_DISP      => o_disp);

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
        wait;
    end process proc_rst;

    -- Run test cases
    proc_tests : process 
    begin 
        i_value <= (others => '0');
        wait until rising_edge(areset);

        for i in 0 to 4 loop
            i_value <= test_val(i);
            wait for period*2;              -- It takes two clock cycles for the display to start lighting up the required segments
            for j in 1 to 2 loop
                wait for period;
                if (o_select = '0' and o_disp /= test_disp0(i)) or (o_select = '1' and o_disp /= test_disp1(i)) then
                    OK <= FAIL;
                end if;
            end loop;
        end loop;

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
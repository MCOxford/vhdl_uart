-----------------------------------------------------------------------------------------
-- 
--
-- File name     : pmod_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for pmod module (7-segment display)
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity pmod_tb is
end pmod_tb;

architecture testbench of pmod_tb is

    -- Components
    component pmod is
        port(CLK                : in  std_logic;                        -- 25MHz Clock Signal
             ARESET             : in  std_logic;                        -- Reset Signal
             i_DISPLAY_0        : in  std_logic_vector(6 downto 0);     -- Byte value to display (0 to 255)
             i_DISPLAY_1        : in  std_logic_vector(6 downto 0);     -- Byte value to display (0 to 255)
             o_SELECT           : out std_logic;                        -- Digit Selection Signal 
             o_DISP             : out std_logic_vector(6 downto 0));    -- Digit Display
    end component pmod;

    -- Constants
    constant period : time := 40 ns;

    -- Signals
    signal clk_25mhz    : std_logic := '1';
    signal areset       : std_logic;
    signal i_display_0  : std_logic_vector(6 downto 0);
    signal i_display_1  : std_logic_vector(6 downto 0);
    signal o_select	    : std_logic; 
    signal o_disp       : std_logic_vector(6 downto 0);

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

begin

    -- Instantiations
    inst_pmod : component pmod
    port map (
        CLK         => clk_25mhz,
        ARESET      => areset,
        i_DISPLAY_0 => i_display_0,
        i_DISPLAY_1 => i_display_1,
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

    -- -- Run test cases
    proc_tests : process 
    begin 
        i_display_0 <= "0101010";
        i_display_1 <= "1010101";
        wait until rising_edge(areset);
        wait for period;

        for i in 1 to 40 loop
            wait for period;
            if (o_select = '1' and o_disp /= i_display_1) or (o_select = '0' and o_disp /= i_display_0) then
                OK <= FAIL;
            end if;
        end loop;

        i_display_0 <= "0000001";
        i_display_1 <= "0000010";
        wait for period;

        for i in 1 to 40 loop
            wait for period;
            if (o_select = '1' and o_disp /= i_display_1) or (o_select = '0' and o_disp /= i_display_0) then
                OK <= FAIL;
            end if;
        end loop;

        wait for period;
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
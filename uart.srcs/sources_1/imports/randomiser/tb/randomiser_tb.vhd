-----------------------------------------------------------------------------------------
-- 
--
-- File name     : randomiser_tb.vhd
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Test bench for randomiser byte source module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;
use std.textio.all;
use ieee.std_logic_textio.all;

entity randomiser_tb is
end randomiser_tb;

architecture testbench of randomiser_tb is

    -- Components
    component randomiser is
      generic (MAX_COUNT : positive);                          -- Delay before changing the output byte - default is to wait 1 second
      port (CLK          : in  std_logic;                      -- 25MHz clock signal
            ARESET       : in  std_logic;                      -- reset signal
            o_RANDOM     : out std_logic_vector(7 downto 0));  -- Parity enabled output signal 
    end component randomiser;
  
    -- Constants
    constant period : time := 40 ns;
    constant maxcount : positive := 1;                         -- output changes every clock period (DO NOT CHANGE! This is to ensure the test passes)

    -- Signals
    signal clk_25mhz    : std_logic := '1';
    signal areset       : std_logic;
    signal o_random     : std_logic_vector(7 downto 0);
    signal start_tests  : std_logic := '0';                    -- Enables proc_tests to start

    type STATE_OK_TYPE is (NA, PASS, FAIL);
    signal OK : STATE_OK_TYPE := NA;                           -- "NA" here means that we are not running tests at this point

    begin

    -- Instantiations
    inst_randomiser : randomiser
    generic map (
        MAX_COUNT => maxcount)
    port map (
        CLK         => clk_25mhz,
        ARESET      => areset,
        o_RANDOM    => o_random);

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

    -- Write out bytes to file (first half of test)
    proc_monitor : process 
    file F_1: text open WRITE_MODE is "vectors.txt";
    variable L : line;
    variable i_value: positive;
    variable rand_value : std_logic_vector(7 downto 0);
    begin
        wait until rising_edge(areset);

        -- write out random bytes to vectors.txt
        for i in 1 to 255 loop
            wait until falling_edge(clk_25mhz);
            write(L, i, Left, 4);
            write(L, o_random);
            writeline(F_1, L);
        end loop;

        -- Now wait
        start_tests <= '1';
        wait;
    end process proc_monitor;

    -- Compare output bytes to master file (second half of test)
    proc_tests : process
    file F_2: text open READ_MODE is "../tb/vectors - master.txt";
    variable L : line; 
    variable i_value: positive;
    variable rand_value : std_logic_vector(7 downto 0);
    begin
        wait until rising_edge(start_tests);

        -- We should now be repeating the pattern of bytes - read back in test vectors and ensure they match up
        while not endfile(F_2) loop
            readline(F_2, L);
            read(L, i_value);
            read(L, rand_value);
            wait until rising_edge(clk_25mhz);
            wait for 1 ns;
            if rand_value = '0' or o_random /= rand_value then
                OK <= FAIL;
            else
                OK <= PASS;
            end if;
        end loop;

        -- stop the sim
        report "END OF TESTING";
        if OK = FAIL then
            report "TESTS FAILED";
        else
            report "TESTS PASSED";
        end if;
        stop;
    end process proc_tests;

end architecture testbench;
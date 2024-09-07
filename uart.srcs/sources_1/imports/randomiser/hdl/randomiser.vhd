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
-- Multiple 8-bit LSFRs that cycles through 8-bit values being shifted within memory. 
-- Works with VHDL-2008.
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-----------------------------------------------------------------------------------------
-- Entity
-----------------------------------------------------------------------------------------
entity randomiser is
    generic(MAX_COUNT : positive := 25000000);                       -- Delay before changing the output byte - default is to wait 1 second
    port(CLK          : in  std_logic;                               -- Clock signal
         ARESET       : in  std_logic;                               -- Reset signal
         o_RANDOM     : out std_logic_vector(7 downto 0));           -- Random output byte
end randomiser;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of randomiser is
    
    type REG8 is array (0 to 7) of std_logic_vector(7 downto 0);  -- Declare custom array type of 8-bit registers
    signal reg_8 : REG8;
    
    -- The bit indexes to XOR, the output being the MSb of reg_8(i) after one clock cycle.
    -- Provided the initial byte in the register is non-zero, using these bit indexes ensures that
    -- we loop around all integers in the range [1, 255]
    constant c_tap_1 : positive := 3;
    constant c_tap_2 : positive := 4;
    constant c_tap_3 : positive := 5;
    constant c_tap_4 : positive := 7;

begin

    proc_lfsr : process (CLK, ARESET) is
    variable v_IV : std_logic_vector(7 downto 0);           -- Initialisation Vector
    variable v_sig_sel : unsigned(2 downto 0);              -- select signal - choose which register value to output (0 -> 7)
    variable v_count : natural;                             -- Counter
    begin
        if ARESET = '0' then
            v_IV := x"01";
            v_sig_sel := (others => '0');
            v_count := 0;
            o_RANDOM <= (others => '1');
            for I in 0 to 7 loop
                reg_8(I) <= v_IV;
                v_IV := v_IV(6 downto 0) & '0';             -- For the next register, set 1 in the [I]th place, the rest set to zero
            end loop;
        elsif rising_edge(CLK) then
            o_RANDOM <= o_RANDOM;
            for I in 0 to 7 loop                            -- Left-shift all the bytes in each register and append the XOR'ed bit
                reg_8(I) <= reg_8(I)(6 downto 0) & (reg_8(I)(c_tap_1) xor reg_8(I)(c_tap_2) xor reg_8(I)(c_tap_3) xor reg_8(I)(c_tap_4));
            end loop;
            v_count := v_count + 1;
            if v_count = MAX_COUNT then                     -- Read from the next register
                v_sig_sel := v_sig_sel + 1;
                v_count := 0;
                o_RANDOM <= reg_8(conv_integer(v_sig_sel));
            end if;
        end if;
    end process proc_lfsr;

end rtl;
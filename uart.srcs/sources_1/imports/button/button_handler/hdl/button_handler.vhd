-----------------------------------------------------------------------------------------
--
--
-- File name     : button handler
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Button driver - Output signal set high so long as button is pressed down or, if in
-- toggle mode, set either high or low constantly with every button press.
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
entity button_handler is
    generic(DEBOUNCE_MAX_COUNT    : natural := 1000);                -- Debouncer maximum count value
    port(CLK                      : in  std_logic;                   -- Clock signal
         ARESET                   : in  std_logic;                   -- reset signal
         i_BTN                    : in  std_logic;                   -- Button input signal
         i_TOGGLE                 : in  std_logic;                   -- Signal to set toggle mode on/off
         i_ENABLE                 : in  std_logic;                   -- Enable signal - If low, o_VAL will always set to low
         o_VAL                    : out std_logic);                  -- Output signal
end button_handler;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of button_handler is

    signal sig_btn_dbnc_counter : natural;
    signal output : std_logic;

    -- The type definition for the BTN state machine type. Here is a description of what
    -- occurs during each state:
    -- INIT     -- Do Nothing. This state is entered after button depressed or a async reset.
    --             When the button signal (i_BTN) is first set high, state is set to CNT.
    -- CNT      -- Start the timer which debounces the button signal the monent it goes high.
    --             state set to INIT when i_BTN set low. When the timer finishes, state goes
    --             to FIN.
    -- FIN      -- Timer has finished, configure output signal (i.e. o_VAL). state goes to HOLD
    --             at the next clock cycle.
    -- HOLD     -- Do nothing. When i_BTN is set low, state goes back to INIT.
    type STATE_BTN_TYPE is (INIT, CNT, FIN, HOLD);
    signal state_btn : STATE_BTN_TYPE;

begin

    -- FSM state handler
    proc_fsm : process(CLK, ARESET) is
    begin
        if ARESET = '0' then
            state_btn <= INIT;
        elsif rising_edge(CLK) then
            case state_btn is
                when INIT =>
                    if i_ENABLE = '1' and i_BTN = '1' then
                        state_btn <= CNT;
                    end if;
                when CNT =>
                    if i_BTN = '0' then
                        state_btn <= INIT;
                    elsif i_BTN = '1' and sig_btn_dbnc_counter = DEBOUNCE_MAX_COUNT then
                        state_btn <= FIN;
                    end if;
                when FIN =>
                    state_btn <= HOLD;
                when HOLD =>
                    if i_BTN = '0' then
                        state_btn <= INIT;
                    end if;
                when others =>
                    state_btn <= INIT;
            end case;
        end if;
    end process proc_fsm;

    -- Timer - starts incrementing the counter as soon as we enter the CNT state, resets when we exit
    proc_timer : process (CLK, ARESET) is
    begin
        if ARESET = '0' then
            sig_btn_dbnc_counter <= 0;
        elsif rising_edge(CLK) then
            if state_btn = CNT and sig_btn_dbnc_counter < DEBOUNCE_MAX_COUNT then
                sig_btn_dbnc_counter <= sig_btn_dbnc_counter + 1;
            else
                sig_btn_dbnc_counter <= 0;
            end if;
        end if; 
    end process proc_timer;

    -- output signal handler
    proc_output : process (CLK, ARESET) is
    begin
        if ARESET = '0' then
            output <= '0';
        elsif rising_edge(CLK) then
            if i_ENABLE = '0' then
                output <= '0';
            else
                if i_TOGGLE = '1' and state_btn = FIN then
                    output <= output xor '1';
                elsif i_TOGGLE = '0' and (state_btn = FIN or state_btn = HOLD) then
                    output <= '1';
                elsif state_btn = HOLD or i_TOGGLE = '1' then
                    output <= output;
                else
                    output <= '0';
                end if;
            end if;
        end if; 
    end process proc_output;

    o_VAL <= output;

end rtl;
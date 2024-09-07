-----------------------------------------------------------------------------------------
--
--
-- File name     : button wrapper
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Button wrapper - defines the four lower components that handles each button on the dev
-- board.
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
entity button_wrapper is
    generic(DEBOUNCE_MAX_COUNT    : natural := 1000);                -- debouncer maximum count value
    port(CLK                      : in  std_logic;                   -- Clock signal
         ARESET                   : in  std_logic;                   -- reset signal
         i_BTN_0                  : in  std_logic;                   -- Button0 input signal (send LOAD signal)
         i_BTN_1                  : in  std_logic;                   -- Button1 input signal (toggle parity checking signal)
         i_BTN_2                  : in  std_logic;                   -- Button2 input signal (toggle parity checking test signal)
         i_BTN_3                  : in  std_logic;                   -- Button3 input signal (send "Button3 pressed down" signal)
         o_LOAD                   : out std_logic;                   -- "LOAD" output signal
         o_PARITY                 : out std_logic;                   -- Parity enabled output signal
         o_PARITY_TEST            : out std_logic;                   -- Parity Test enabled output signal
         o_BTN3_PRESSED           : out std_logic);                  -- "Button3 pressed down" signal
end button_wrapper;

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture structural of button_wrapper is

    -- Set toggle mode for each button
    constant c_btn0_toggle : std_logic := '0';
    constant c_btn1_toggle : std_logic := '1';
    constant c_btn2_toggle : std_logic := '1';
    constant c_btn3_toggle : std_logic := '0';
    
    component button_handler is
        generic(DEBOUNCE_MAX_COUNT    : natural);                    -- Debouncer maximum count value
        port(CLK                      : in  std_logic;               -- Clock signal
             ARESET                   : in  std_logic;               -- reset signal
             i_BTN                    : in  std_logic;               -- Button input signal
             i_TOGGLE                 : in  std_logic;               -- Signal to set toggle mode on/off
             i_ENABLE                 : in  std_logic;               -- Enable signal - If low, o_VAL will always set to low
             o_VAL                    : out std_logic);              -- Output signal
    end component button_handler;

begin

    -- BTN0 handler -> Press to set LOAD signal high, depress to set low
    btn0_handler : component button_handler
        generic map(
            DEBOUNCE_MAX_COUNT => DEBOUNCE_MAX_COUNT)
        port map(
            CLK                => CLK,
            ARESET             => ARESET,
            i_BTN              => i_BTN_0,
            i_TOGGLE           => c_btn0_toggle,
            i_ENABLE           => '1',
            o_VAL              => o_LOAD);

    -- BTN1 handler -> Press to toggle PARITY signal high, press again to set low
    btn1_handler : component button_handler
        generic map(
            DEBOUNCE_MAX_COUNT => DEBOUNCE_MAX_COUNT)
        port map(
            CLK                => CLK,
            ARESET             => ARESET,
            i_BTN              => i_BTN_1,
            i_TOGGLE           => c_btn1_toggle,
            i_ENABLE           => '1',
            o_VAL              => o_PARITY);

    -- BTN2 handler -> Press to toggle PARITY COVERAGE TEST signal high, press again to set low
    -- Note that parity can only occur when parity is eneabled in the first place - when turned
    -- off, we reset the signal back to low and lock it down until parity is enabled again
    btn2_handler : component button_handler
        generic map(
            DEBOUNCE_MAX_COUNT => DEBOUNCE_MAX_COUNT)
        port map(
            CLK                => CLK,
            ARESET             => ARESET,
            i_BTN              => i_BTN_2,
            i_TOGGLE           => c_btn2_toggle,
            i_ENABLE           => o_PARITY,
            o_VAL              => o_PARITY_TEST);

    -- BTN3 handler -> Press to set o_BTN3_PRESSED signal high, depress to set low
    btn3_handler : component button_handler
        generic map(
            DEBOUNCE_MAX_COUNT => DEBOUNCE_MAX_COUNT)
        port map(
            CLK                => CLK,
            ARESET             => ARESET,
            i_BTN              => i_BTN_3,
            i_TOGGLE           => c_btn3_toggle,
            i_ENABLE           => '1',
            o_VAL              => o_BTN3_PRESSED);

end structural;
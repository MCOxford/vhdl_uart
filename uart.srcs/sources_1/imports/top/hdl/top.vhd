-----------------------------------------------------------------------------------------
--
--
-- File name     : top
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Top-level design for UART demo project. Compatible with VHDL-2008.
-- Uses a 100MHz clock source to emulate a 25MHz clock.
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
entity top is
    generic(MAX_DISPLAY_COUNT  : positive := 25000000;     -- Maximum counter value for which a hex can be diplayed on 7-segment. Default is 1 second
            DEBOUNCE_MAX_COUNT : positive := 500);         -- Maximum counter value for button debouncing. Default is set for 500 clock cycles
    port(CLK_100MHZ : in  std_logic;                       -- 100MHz clock source
         CK_RST     : in  std_logic;                       -- Asynchronous reset signal
         CK_I       : in  std_logic;                       -- General I/O port signal (set to in)
         CK_O       : out std_logic;                       -- General I/O port signal (set to out)
         JA         : out std_logic_vector(4 downto 1);    -- Pmod JA connecter pin signals
         JB         : out std_logic_vector(3 downto 1);    -- Pmod JB connecter pin signals
         JB_C       : out std_logic;                       -- Pmod JB pin C15
         JC         : out std_logic_vector(4 downto 1);    -- Pmod JC connecter pin signals
         JD         : out std_logic_vector(3 downto 1);    -- Pmod JD connecter pin signals
         JD_C       : out std_logic;                       -- Pmod JD pin F3
         LEDS       : out std_logic_vector(3 downto 0);    -- LEDS connector pin signals (non-RGB)
         RGB0_Red   : out std_logic;                       -- REG0_RED LED connector pin signal
         UART_TXD   : out std_logic;                       -- UART USB TX connector pin signal
         BTN        : in std_logic_vector(3 downto 0);     -- BTN connector pin signals
         SW         : in std_logic_vector(3 downto 0));    -- SW connector pin signals
end entity top; 

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------

architecture structural of top is

    signal clk_25mhz               : std_logic;                      -- 25MHz clock source to feed into processes
    signal button_load             : std_logic;
    signal parity_reg              : std_logic;
    signal parity                  : std_logic;
    signal parity_test             : std_logic;
    signal parity_test_reg         : std_logic;
    signal btn3_pressed            : std_logic;
    signal reg_dbnc                : std_logic_vector(1 downto 0);
    signal btn3_detect             : std_logic;
    signal sw3_detect              : std_logic;
    signal print                   : std_logic;
    signal baud_rate_reg           : std_logic;
    signal baud_rate               : std_logic;
    signal simple_mode             : std_logic;
    signal sw3_on                  : std_logic;
    signal ascii_output            : std_logic_vector(7 downto 0);
    signal random_byte             : std_logic_vector(7 downto 0);
    signal simple_byte             : std_logic_vector(7 downto 0);
    signal tx_busy                 : std_logic;
    signal rx_busy                 : std_logic;
    signal pmod_hex_display        : std_logic_vector(6 downto 0);
    signal pmod_ascii_display      : std_logic_vector(6 downto 0);
    signal hex_input               : std_logic_vector(7 downto 0);
    signal tx_input                : std_logic_vector(7 downto 0);
    signal load                    : std_logic;
    signal load_detect             : std_logic;

    -- Components
    component wrapper is
        port(CLK                   : in  std_logic;                        -- Clock Signal
             ARESET                : in  std_logic;                        -- Reset Signal
             i_LOAD                : in  std_logic;                        -- "LOAD" input signal 
             i_PARITY              : in  std_logic;                        -- Enable Parity padding + checking  
             i_PARITY_TEST         : in  std_logic;                        -- Enable parity checking test - invert a bit to ensure packet gets dropped
             i_BAUD_RATE           : in  std_logic;                        -- Frequency of signalling events per second   
             i_TX_INPUT            : in  std_logic_vector(7 downto 0);     -- Tx vector data input
             i_UART_BIT            : in  std_logic;                        -- Rx input bit
             o_TX_BUSY             : out std_logic;                        -- "Tx is busy" signal to send to an LEDS, for example
             o_RX_BUSY             : out std_logic;                        -- "Rx is busy" signal to send to an LEDS, for example
             o_UART_BIT            : out std_logic;                        -- Tx output bit
             o_RX_OUTPUT           : out std_logic_vector(7 downto 0));    -- Rx output data vector
    end component wrapper;

    component randomiser is
        generic(MAX_COUNT          : positive);                            -- Maximum delay before updating the output byte
        port(CLK                   : in  std_logic;                        -- Clock signal
             ARESET                : in  std_logic;                        -- reset signal
             o_RANDOM              : out std_logic_vector(7 downto 0));    -- random output byte
    end component randomiser;

    component simple is
        generic(MAX_COUNT          : positive);                            -- Maximum delay before updating the output byte
        port(CLK                   : in  std_logic;                        -- Clock signal
             ARESET                : in  std_logic;                        -- reset signal
             o_BYTE                : out std_logic_vector(7 downto 0));    -- output byte
    end component simple;

    component hex_display is
        port(CLK                   : in  std_logic;                        -- Clock Signal
             ARESET                : in  std_logic;                        -- Reset Signal
             i_VALUE               : in  std_logic_vector(7 downto 0);     -- Byte value to display (0 to 255)
             o_SELECT              : out std_logic;                        -- Digit Selection Signal 
             o_DISP                : out std_logic_vector(6 downto 0));    -- Digit Display
    end component hex_display;

    component ascii_display is
        port(CLK                   : in  std_logic;                        -- Clock Signal
             ARESET                : in  std_logic;                        -- Reset Signal
             i_VALUE               : in  std_logic_vector(7 downto 0);     -- Byte value to display (0 to 255)
             o_SELECT              : out std_logic;                        -- Digit Selection Signal 
             o_DISP                : out std_logic_vector(6 downto 0));    -- Digit Display
    end component ascii_display;

    component led is
        port(i_LOAD                : in  std_logic;                        -- "LOAD" signal
             i_PARITY              : in  std_logic;                        -- Parity checking enabled
             i_PARITY_TEST         : in  std_logic;                        -- Parity testing enabled
             i_BAUD_RATE           : in  std_logic;                        -- Baud rate
             i_TX_BUSY             : in  std_logic;                        -- UART Tx module busy
             i_RX_BUSY             : in  std_logic;                        -- UART Rx module busy
             o_LED                 : out std_logic_vector(3 downto 0);     -- LEDS signals
             o_RGB0_RED            : out std_logic);
    end component led;

    component button_wrapper is
        generic(DEBOUNCE_MAX_COUNT : positive);                            -- Debouncer maximum count value
        port(CLK                   : in  std_logic;                        -- Clock signal
             ARESET                : in  std_logic;                        -- reset signal
             i_BTN_0               : in  std_logic;                        -- Button0 input signal (send LOAD signal)
             i_BTN_1               : in  std_logic;                        -- Button1 input signal (toggle parity signal)
             i_BTN_2               : in  std_logic;                        -- Button2 input signal (toggle parity_test signal)
             i_BTN_3               : in  std_logic;                        -- Button3 input signal (send "Button3 pressed down" signal)
             o_LOAD                : out std_logic;                        -- "LOAD" output signal
             o_PARITY              : out std_logic;                        -- Parity enabled output signal
             o_PARITY_TEST         : out std_logic;                        -- Parity Test enabled output signal
             o_BTN3_PRESSED        : out std_logic);                       -- "Button3 pressed down" signal
    end component button_wrapper;

    component switch is
        port(i_SW                  : in  std_logic_vector(3 downto 0);     -- Switch signals
             o_BAUD_RATE           : out std_logic;                        -- Baud rate
             o_SIMPLE_MODE         : out std_logic;                        -- Byte source selector
             o_PRINT               : out std_logic;                        -- Print random byte putty via USB UART
             o_SW3_ON              : out std_logic);                       -- Switch 3 turned on/off
    end component switch;

    component usb_uart is
        port(CLK                   : in  std_logic;                        -- Clock signal
             ARESET                : in  std_logic;                        -- Reset signal
             i_BTN3                : in  std_logic;                        -- Debounced button 3 signal
             i_SW2                 : in  std_logic;                        -- Debounced switch 2 signal
             i_VALUE               : in  std_logic_vector(7 downto 0);     -- Incoming random byte
             i_SW3                 : in  std_logic;                        -- "Change to switch 3" signal
             o_UART_BIT            : out std_logic);                       -- The output bit that gets sent over Tx
    end component usb_uart;

begin

    -- Segment display bits
    JA <= pmod_hex_display(3 downto 0);
    JB <= pmod_hex_display(6 downto 4);
    JC <= pmod_ascii_display(3 downto 0);
    JD <= pmod_ascii_display(6 downto 4);

    -- Byte source currently being used
    hex_input <= random_byte when (simple_mode = '0') else simple_byte;

    -- Set load signal high when button_load signal is high and UART is
    -- not busy. This way, bytes can continuously be sent so long as
    -- BTN[0] is pressed down
    load_detect <= button_load when (tx_busy = '0' and rx_busy = '0') else '0';

    -- Registers the (debounced) BTN[3] & SW[3] signals, for edge detection.
    proc_reg : process (clk_25mhz) is
    begin
        if (rising_edge(clk_25mhz)) then
            reg_dbnc <= (btn3_pressed, sw3_on);
        end if;
    end process proc_reg;

    -- btn3_detect/sw3_detect goes high for a single clock cycle when a btn3_pressed/sw3_on is
    -- detected. This triggers a USB-UART message to begin being sent.
    btn3_detect <= '1' when (reg_dbnc(1) = '0' and btn3_pressed = '1') else '0';
    sw3_detect <= '1' when ((reg_dbnc(0) = '0' and sw3_on = '1') or (reg_dbnc(0) = '1' and sw3_on = '0')) else '0';

    -- Prepare tx_input + UART wrapper config settings on every rising signal upon detection of the button load signal
    -- set high. This 'locks in' the settings until the UART wrapper has finished transmission and receiving, preventing
    -- any erroneous behaviour when any setting are changed during these phases and effectively corrupting the packet.
    proc_uart_input : process (clk_25mhz, CK_RST) is
    begin
        if CK_RST = '0' then
            tx_input <= x"00";
            load <= '0';
            parity <= '0';
            baud_rate <= '0';
            parity_test <= '0';
        elsif rising_edge(clk_25mhz) then
            load <= '0';
            tx_input <= tx_input;
            parity <= parity;
            baud_rate <= baud_rate;
            parity_test <= parity_test;
            if load_detect = '1' then
                load <= '1';
                parity <= parity_reg;
                baud_rate <= baud_rate_reg;
                parity_test <= parity_test_reg;
                if simple_mode = '1' then
                    tx_input <= simple_byte;
                else
                    tx_input <= random_byte;
                end if;
            end if;
        end if;
    end process proc_uart_input;

    -- Emulate a 25MHz clock signal from the clock source
    proc_clock_divider : process (CLK_100MHZ, CK_RST) is
    variable v_clock_counter : std_logic_vector(1 downto 0);            -- Counter for clock divider
    begin
        if CK_RST = '0' then
            v_clock_counter := (others => '0');
            clk_25mhz <= '0';
        elsif rising_edge(CLK_100MHZ) then
            v_clock_counter := v_clock_counter + 1;
            clk_25mhz <= v_clock_counter(1);                            -- Always set clk_25mhz high when MSB in counter equals '1'
        end if;
    end process proc_clock_divider;

    -- UART Wrapper (Tx & Rx)
    uart_wrapper : component wrapper
        port map (
            CLK             => clk_25mhz,
            ARESET          => CK_RST,
            i_LOAD          => load,
            i_PARITY        => parity,
            i_PARITY_TEST   => parity_test,
            i_BAUD_RATE     => baud_rate,
            i_TX_INPUT      => tx_input,
            i_UART_BIT      => CK_I,
            o_TX_BUSY       => tx_busy,
            o_RX_BUSY       => rx_busy,
            o_RX_OUTPUT     => ascii_output,
            o_UART_BIT      => CK_O);

    -- "Entropy" Source
    entropy_source : component randomiser
        generic map (
            MAX_COUNT       => MAX_DISPLAY_COUNT)
        port map (
            CLK             => clk_25mhz,
            ARESET          => CK_RST,
            o_RANDOM        => random_byte);

    -- Simple byte source
    simple_source : component simple
        generic map (
            MAX_COUNT       => MAX_DISPLAY_COUNT)
        port map (
            CLK             => clk_25mhz,
            ARESET          => CK_RST,
            o_BYTE          => simple_byte);

    -- Pmod Header JA/JB (Hex Display)
    pmod_hex : component hex_display
        port map (
            CLK             => clk_25mhz,
            ARESET          => CK_RST,
            i_VALUE         => hex_input,
            o_SELECT        => JB_C,
            o_DISP          => pmod_hex_display);

    -- Pmod Header JC/JD (ASCII Display)
    pmod_ascii : component ascii_display
        port map (
            CLK             => clk_25mhz,
            ARESET          => CK_RST,
            i_VALUE         => ascii_output,
            o_SELECT        => JD_C,
            o_DISP          => pmod_ascii_display);

    -- LEDS Driver
    led_driver : component led
        port map (
            i_LOAD          => button_load,
            i_PARITY        => parity_reg,
            i_PARITY_TEST   => parity_test_reg,
            i_BAUD_RATE     => baud_rate_reg,
            i_TX_BUSY       => tx_busy,
            i_RX_BUSY       => rx_busy,
            o_LED           => LEDS,
            o_RGB0_RED      => RGB0_Red);

    -- Button Driver
    button_driver : component button_wrapper
        generic map(
            DEBOUNCE_MAX_COUNT => DEBOUNCE_MAX_COUNT)
        port map (
            CLK             => clk_25mhz,
            ARESET          => CK_RST,
            i_BTN_0         => BTN(0),
            i_BTN_1         => BTN(1),
            i_BTN_2         => BTN(2),
            i_BTN_3         => BTN(3),
            o_LOAD          => button_load,
            o_PARITY        => parity_reg,
            o_PARITY_TEST   => parity_test_reg,
            o_BTN3_PRESSED  => btn3_pressed);

    -- Switch Driver
    switch_driver : component switch
        port map (
            i_SW            => SW,
            o_BAUD_RATE     => baud_rate_reg,
            o_SIMPLE_MODE   => simple_mode,
            o_PRINT         => print,
            o_SW3_ON        => sw3_on);

    -- USB UART TX Driver
    usb_uart_driver : component usb_uart
        port map (
            CLK             => clk_25mhz,
            ARESET          => CK_RST,
            i_BTN3          => btn3_detect,
            i_SW2           => print,
            i_VALUE         => hex_input,
            i_SW3           => sw3_detect,
            o_UART_BIT      => UART_TXD);

end architecture structural;
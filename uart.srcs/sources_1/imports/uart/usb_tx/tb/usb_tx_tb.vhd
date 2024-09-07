-----------------------------------------------------------------------------------------
--
--
-- File name     : usb_tx_tb.vhd
-- Language      : VHDL    
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- Testbench for USB UART Tx module
-----------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity usb_tx_tb is
end usb_tx_tb;

architecture testbench of usb_tx_tb is

    -- Components
    component usb_uart is
    port(CLK           : in  std_logic;                      -- Clock signal
         ARESET        : in  std_logic;                      -- Reset signal
         i_BTN3        : in  std_logic;                      -- Debounced button 3 signal
         i_SW2         : in  std_logic;                      -- Debounced switch 2 signal
         i_VALUE       : in  std_logic_vector(7 downto 0);   -- Incoming random byte
         i_SW3         : in  std_logic;                      -- "Change to switch 3" signal
         o_UART_BIT    : out std_logic);                     -- The output bit that gets sent over Tx
    end component usb_uart;

    -- Constants
    constant period             : time := 40 ns;
    constant c_incoming_byte    : std_logic_vector(7 downto 0) := "01011010"; -- ASCII is "Z"
    constant c_control_byte     : std_logic_vector(7 downto 0) := x"06";      -- ASCII is "acknowledge" (or "ACK")
    constant c_num_cycles_9k6   : positive := 2604;
    constant str_len            : natural := 24;

    -- Signals
    signal clk_25mhz     : std_logic := '1';
    signal areset        : std_logic;
    signal i_btn3        : std_logic;
    signal i_sw2         : std_logic;
    signal i_value       : std_logic_vector(7 downto 0);
    signal i_sw3         : std_logic;
    signal o_uart_bit    : std_logic;
    signal uart_pckt     : std_logic_vector(9 downto 0) := (others => '0');

    type STATE_OK_TYPE is (PASS, FAIL);
    signal OK : STATE_OK_TYPE := PASS;

    type CHAR_ARRAY is array (integer range<>) of std_logic_vector(7 downto 0);
    constant WELCOME_STR : CHAR_ARRAY(0 to 23) := (X"0A",  -- \n
                                                   X"0D",  -- \r
                                                   X"55",  -- U
                                                   X"41",  -- A
                                                   X"52",  -- R
                                                   X"54",  -- T
                                                   X"20",  -- 
                                                   X"44",  -- D
                                                   X"45",  -- E
                                                   X"4D",  -- M
                                                   X"4F",  -- O
                                                   X"20",  -- 
                                                   X"50",  -- P
                                                   X"52",  -- R
                                                   X"4F",  -- O
                                                   X"4A",  -- J
                                                   X"45",  -- E
                                                   X"43",  -- C
                                                   X"54",  -- T
                                                   X"21",  -- !
                                                   X"20",  --
                                                   X"0A",  -- \n
                                                   X"0A",  -- \n
                                                   X"0D"); -- \r

    constant BTN_STR : CHAR_ARRAY(0 to 23) := (X"42",  -- B
                                               X"75",  -- u
                                               X"74",  -- t
                                               X"74",  -- t
                                               X"6F",  -- o
                                               X"6E",  -- n
                                               X"20",  --
                                               X"74",  -- t
                                               X"68",  -- h
                                               X"72",  -- r
                                               X"65",  -- e
                                               X"65",  -- e
                                               X"20",  -- 
                                               X"70",  -- p
                                               X"72",  -- r
                                               X"65",  -- e
                                               X"73",  -- s
                                               X"73",  -- s
                                               X"65",  -- e
                                               X"64",  -- d 
                                               X"21",  -- !
                                               X"20",  --
                                               X"0A",  -- \n
                                               X"0D"); -- \r

    constant SW_STR : CHAR_ARRAY(0 to 23) := (X"53",  -- S
                                              X"77",  -- w
                                              X"69",  -- i
                                              X"74",  -- t
                                              X"63",  -- c
                                              X"68",  -- h
                                              X"20",  --
                                              X"74",  -- t
                                              X"68",  -- h
                                              X"72",  -- r
                                              X"65",  -- e
                                              X"65",  -- e
                                              X"20",  -- 
                                              X"63",  -- c
                                              X"68",  -- h
                                              X"61",  -- a
                                              X"6E",  -- n
                                              X"67",  -- g
                                              X"65",  -- e
                                              X"64",  -- d
                                              X"21",  -- !
                                              X"20",  -- 
                                              X"0A",  -- \n
                                              X"0D"); -- \r

    constant BYTE_STR : CHAR_ARRAY(0 to 23) := (X"41",  -- A
                                                X"53",  -- S
                                                X"43",  -- C
                                                X"49",  -- I
                                                X"49",  -- I
                                                X"20",  -- 
                                                X"64",  -- d
                                                X"69",  -- i
                                                X"73",  -- s
                                                X"70",  -- p
                                                X"6C",  -- l
                                                X"61",  -- a
                                                X"79",  -- y
                                                X"3A",  -- :
                                                X"20",  -- 
                                                c_incoming_byte,  -- Z
                                                X"20",  --
                                                X"20",  --
                                                X"20",  --
                                                X"20",  --
                                                X"20",  --
                                                X"20",  --
                                                X"0A",  -- \n
                                                X"0D"); -- \r

    constant BYTE_2_STR : CHAR_ARRAY(0 to 23) := (X"41",  -- A
                                                  X"53",  -- S
                                                  X"43",  -- C
                                                  X"49",  -- I
                                                  X"49",  -- I
                                                  X"20",  -- 
                                                  X"64",  -- d
                                                  X"69",  -- i
                                                  X"73",  -- s
                                                  X"70",  -- p
                                                  X"6C",  -- l
                                                  X"61",  -- a
                                                  X"79",  -- y
                                                  X"3A",  -- :
                                                  X"20",  --
                                                  X"41",  -- A 
                                                  X"43",  -- C
                                                  X"4B",  -- K
                                                  X"20",  --
                                                  X"20",  --
                                                  X"20",  --
                                                  X"20",  --
                                                  X"0A",  -- \n
                                                  X"0D"); -- \r

    begin

    -- Instantiations
    inst_usb_tx : usb_uart
    port map (
        CLK           => clk_25mhz,
        ARESET        => areset,
        i_BTN3        => i_btn3,
        i_SW2         => i_sw2,
        i_VALUE       => i_value,
        i_SW3         => i_sw3,
        o_UART_BIT    => o_uart_bit);

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
        i_btn3 <= '0';
        i_sw2 <= '0';
        i_sw3 <= '0';
        i_value <= (others => '0');
        wait until rising_edge(areset);
        wait until falling_edge(o_uart_bit); -- Wait until the reset timer has elapsed

        -- Test ID:     usb_tx_tb_test_1
        -- Description: The WELCOME_STR message shall get immediately transmitted after 
        --              the reset counter elapses
        for i in 0 to str_len - 1 loop
            uart_pckt <= '1' & WELCOME_STR(i) & '0';
            for j in 0 to 9 loop
                for k in 1 to c_num_cycles_9k6 loop
                    wait for period;
                    if o_uart_bit /= uart_pckt(j) then
                        OK <= FAIL;
                    end if;
                end loop;
            end loop;
            wait for period*7;  -- Wait for the next byte in the message to be sent
        end loop;
        wait for period*10; -- cool-off period

        -- Test ID:     usb_tx_tb_test_2
        -- Description: BTN3 is pressed for a sufficient amount of time; the BTN_STR 
        --              message shall get transmitted afterwards
        i_btn3 <= '1';
        wait for period*7;
        i_btn3 <= '0';
        for i in 0 to str_len - 1 loop
            uart_pckt <= '1' & BTN_STR(i) & '0';
            for j in 0 to 9 loop
                for k in 1 to c_num_cycles_9k6 loop
                    wait for period;
                    if o_uart_bit /= uart_pckt(j) then
                        OK <= FAIL;
                    end if;
                end loop;
            end loop;
            wait for period*7;
        end loop;
        wait for period*10;

        -- Test ID:     usb_tx_tb_test_3
        -- Description: SW3 is switched on for a sufficient amount of time and 
        --              immediately switched off; SW_STR message shall get transmitted
        --              afterwards
        i_sw3 <= '1';
        wait for period*7;
        i_sw3 <= '0';
        for i in 0 to str_len - 1 loop
            uart_pckt <= '1' & SW_STR(i) & '0';
            for j in 0 to 9 loop
                for k in 1 to c_num_cycles_9k6 loop
                    wait for period;
                    if o_uart_bit /= uart_pckt(j) then
                        OK <= FAIL;
                    end if;
                end loop;
            end loop;
            wait for period*7;
        end loop;
        wait for period*10;

        -- Test ID:     usb_tx_tb_test_4
        -- Description: SW2 is switched on; a non-control ASCII byte is used to construct 
        --              a BYTE_STR message; the message is transmitted in full 
        i_sw2 <= '1';
        wait for period;
        i_value <= c_incoming_byte;
        wait for period*8;
        for i in 0 to str_len - 1 loop
            uart_pckt <= '1' & BYTE_STR(i) & '0';
            for j in 0 to 9 loop
                for k in 1 to c_num_cycles_9k6 loop
                    wait for period;
                    if o_uart_bit /= uart_pckt(j) then
                        OK <= FAIL;
                    end if;
                end loop;
            end loop;
            wait for period*7;
        end loop;
        wait for period*10;

        -- Test ID:     usb_tx_tb_test_5
        -- Description: A control ASCII byte is used to construct a BYTE_STR message; 
        --              the message is transmitted in full
        wait for period;
        i_value <= c_control_byte;
        wait for period*8;
        for i in 0 to str_len - 1 loop
            uart_pckt <= '1' & BYTE_2_STR(i) & '0';
            for j in 0 to 9 loop
                for k in 1 to c_num_cycles_9k6 loop
                    wait for period;
                    if o_uart_bit /= uart_pckt(j) then
                        OK <= FAIL;
                    end if;
                end loop;
            end loop;
            wait for period*7;
        end loop;
        wait for period*10;

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
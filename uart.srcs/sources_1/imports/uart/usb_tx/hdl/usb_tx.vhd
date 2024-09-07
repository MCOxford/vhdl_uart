-----------------------------------------------------------------------------------------
--
--
-- File name     : USB UART Tx
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- USB UART Driver (Tx only). Partially Adapted from Vivado "UART GPIO/UART Demo"
-- example.
-- NB: Tested at clock speed 25MHz.
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
entity usb_uart is
    port(CLK           : in  std_logic;                      -- Clock signal
         ARESET        : in  std_logic;                      -- Reset signal
         i_BTN3        : in  std_logic;                      -- Debounced button 3 signal
         i_SW2         : in  std_logic;                      -- Debounced switch 2 signal
         i_VALUE       : in  std_logic_vector(7 downto 0);   -- Incoming random byte
         i_SW3         : in  std_logic;                      -- "Change to switch 3" signal
         o_UART_BIT    : out std_logic);                     -- The output bit that gets sent over Tx
end entity usb_uart; 

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of usb_uart is

    -- The type definition for the UART state machine type. Here is a description of what
    -- occurs during each state:
    -- RST_REG     -- Do Nothing. This state is entered after configuration or a user reset.
    --                The state is set to LD_INIT_STR.
    -- LD_INIT_STR -- The Welcome String is loaded into the sig_send_str variable and the sig_str_index
    --                variable is set to zero. The welcome string length is stored in the StrEnd
    --                variable. The state is set to SEND_CHAR.
    -- SEND_CHAR   -- sig_uart_send is set high for a single clock cycle, signaling the character
    --                data at sig_send_str(sig_str_index) to be registered by the uart_tx at the next
    --                cycle. Also, sig_str_index is incremented (behaves as if it were post 
    --                incremented after reading the sig_send_str data). The state is set to RDY_LOW.
    -- RDY_LOW     -- Do nothing. Wait for the READY signal from the uart_tx to go low, 
    --                indicating a send operation has begun. State is set to WAIT_RDY.
    -- WAIT_RDY    -- Do nothing. Wait for the READY signal from the uart_tx to go high, 
    --                indicating a send operation has finished. If READY is high and sig_str_end = 
    --                StrIndex then state is set to WAIT_BTN, else if READY is high and sig_str_end /=
    --                StrIndex then state is set to SEND_CHAR.
    -- WAIT_BTN    -- Do nothing. Wait for a button press on BTNU, BTNL, BTND, or BTNR. If a 
    --                button press is detected, set the state to LD_BTN_STR.
    -- LD_BTN_STR  -- The Button String is loaded into the sig_send_str variable and the sig_str_index
    --                variable is set to zero. The button string length is stored in the StrEnd
    --                variable. The state is set to SEND_CHAR.
    -- LD_SW_STR   -- The Switch String is loaded into the sig_send_str variable and the sig_str_index
    --                variable is set to zero. The switch string length is stored in the StrEnd
    --                variable. The state is set to SEND_CHAR.
    -- LD_BYTE_STR -- The Byte String is loaded into the sig_send_str variable and the sig_str_index
    --                variable is set to zero. The incoming sig_byte is also appended at the end
    --                of the Byte String so it can be dispalyed. The sig_byte string length is 
    --                stored in the StrEnd variable. The state is set to SEND_CHAR.
    type STATE_UART_TYPE is (RST_REG, LD_INIT_STR, SEND_CHAR, RDY_LOW, WAIT_RDY, WAIT_BTN, LD_BTN_STR, LD_SW_STR, LD_BYTE_STR);

    --The CHAR_ARRAY type is a variable length array of 8 bit std_logic_vectors. 
    --Each std_logic_vector contains an ASCII value and represents a character in
    --a string. The character at index 0 is meant to represent the first
    --character of the string, the character at index 1 is meant to represent the
    --second character of the string, and so on.
    type CHAR_ARRAY is array (integer range<>) of std_logic_vector(7 downto 0);

    constant c_reset_cntr_max : std_logic_vector(17 downto 0) := "001100001101010000"; -- 25,000,000 * 0.002 = 50,000 = clk cycles per 2 ms
    constant c_max_str_len : integer := 24;
    constant c_welcome_str_len : natural := 24;
    constant c_btn_str_len : natural := 24;
    constant c_sw_str_len : natural := 24;
    constant c_byte_str_len : natural := 24;

    -- Welcome string definition. Note that the values stored at each index
    -- are the ASCII values of the indicated character.
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

    --Button press string definition.
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

    --Switch detected string definition.
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

    -- Byte String definition
    constant BYTE_STR : CHAR_ARRAY(0 to 14) := (X"41",  -- A
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
                                                X"20"); -- 

    --Contains the current string being sent over uart.
    signal sig_send_str : CHAR_ARRAY(0 to (c_max_str_len - 1));

    --Contains the length of the current string being sent over uart.
    signal sig_str_end : natural;

    --Contains the index of the next character to be sent over uart
    --within the sig_send_str variable.
    signal sig_str_index : natural;

    --uart_tx control signals
    signal sig_uart_rdy : std_logic;
    signal sig_uart_send : std_logic := '0';
    signal sig_uart_data : std_logic_vector (7 downto 0):= "00000000";
    signal sig_uart_tx : std_logic;

    --Current uart state signal
    signal state_uart : STATE_UART_TYPE := RST_REG;

    --this counter counts the amount of time paused in the UART reset state
    signal reset_cntr : std_logic_vector (17 downto 0) := (others=>'0');

    signal sig_changed : std_logic;
    signal sig_byte : std_logic_vector (7 downto 0);

    -- Convert the incoming byte into a string ready for printing. If the byte one of the special
    -- control characters, they are non-printable so instead we output the abbreviation. 
    -- Note that the output when displayed on putty varies depending on the translation being used.
    -- Recommended that ISO-8859-1:1998 is used as the character set.
    function convert_to_string(val: std_logic_vector (7 downto 0)) return CHAR_ARRAY is
        variable v_ret : CHAR_ARRAY(0 to 8) := (X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"0A", X"0D");
    begin
        case val is
            when x"00" => v_ret(0 to 2) := (X"4E", X"55", X"4C"); -- "NUL"
            when x"01" => v_ret(0 to 2) := (X"53", X"4F", X"48"); -- "SOH"
            when x"02" => v_ret(0 to 2) := (X"53", X"54", X"58"); -- "STX"
            when x"03" => v_ret(0 to 2) := (X"45", X"54", X"58"); -- "ETX"
            when x"04" => v_ret(0 to 2) := (X"45", X"4F", X"54"); -- "EOT"
            when x"05" => v_ret(0 to 2) := (X"45", X"4E", X"51"); -- "ENQ"
            when x"06" => v_ret(0 to 2) := (X"41", X"43", X"4B"); -- "ACK"
            when x"07" => v_ret(0 to 2) := (X"42", X"45", X"4C"); -- "BEL"
            when x"08" => v_ret(0 to 2) := (X"42", X"53", X"20"); -- "BS "
            when x"09" => v_ret(0 to 2) := (X"54", X"41", X"42"); -- "TAB"
            when x"0A" => v_ret(0 to 2) := (X"4C", X"46", X"20"); -- "LF "
            when x"0B" => v_ret(0 to 2) := (X"56", X"54", X"20"); -- "VT "
            when x"0C" => v_ret(0 to 2) := (X"46", X"46", X"20"); -- "FF "
            when x"0D" => v_ret(0 to 2) := (X"43", X"52", X"20"); -- "CR "
            when x"0E" => v_ret(0 to 2) := (X"53", X"4F", X"20"); -- "SO "
            when x"0F" => v_ret(0 to 2) := (X"53", X"49", X"20"); -- "SI "
            when x"10" => v_ret(0 to 2) := (X"44", X"4C", X"45"); -- "DLE"
            when x"11" => v_ret(0 to 2) := (X"44", X"43", X"31"); -- "DC1"
            when x"12" => v_ret(0 to 2) := (X"44", X"43", X"32"); -- "DC2"
            when x"13" => v_ret(0 to 2) := (X"44", X"43", X"33"); -- "DC3"
            when x"14" => v_ret(0 to 2) := (X"44", X"43", X"34"); -- "DC4"
            when x"15" => v_ret(0 to 2) := (X"4E", X"41", X"4B"); -- "NAK"
            when x"16" => v_ret(0 to 2) := (X"53", X"59", X"4E"); -- "SYN"
            when x"17" => v_ret(0 to 2) := (X"45", X"54", X"42"); -- "ETB"
            when x"18" => v_ret(0 to 2) := (X"43", X"51", X"4E"); -- "CAN"
            when x"19" => v_ret(0 to 2) := (X"45", X"4D", X"20"); -- "EM "
            when x"1A" => v_ret(0 to 2) := (X"53", X"55", X"42"); -- "SUB"
            when x"1B" => v_ret(0 to 2) := (X"45", X"53", X"43"); -- "ESC"
            when x"1C" => v_ret(0 to 2) := (X"46", X"53", X"20"); -- "FS "
            when x"1D" => v_ret(0 to 2) := (X"47", X"53", X"20"); -- "GS "
            when x"1E" => v_ret(0 to 2) := (X"52", X"53", X"20"); -- "RS "
            when x"1F" => v_ret(0 to 2) := (X"55", X"53", X"20"); -- "US "
            when others => v_ret(0) := val;
        end case;
        return v_ret;
    end function convert_to_string;

    -- USB Tx component
    component transmit is
        port(CLK           : in  std_logic;                      -- Clock signal
             ARESET        : in  std_logic;                      -- Reset signal
             i_LOAD        : in  std_logic;                      -- "LOAD" input signal
             i_PARITY      : in  std_logic;                      -- Enable Parity padding + checking
             i_PARITY_TEST : in  std_logic;                      -- Parity checking testing signal
             i_BAUD_RATE   : in  std_logic;                      -- Frequency of signalling events per second
             i_TX_INPUT    : in  std_logic_vector(7 downto 0);   -- Tx vector data input
             o_TX_BUSY     : out std_logic;                      -- "Tx is busy" signal to send to an LED, for example
             o_UART_BIT    : out std_logic);                     -- The output bit that gets sent over Tx
    end component transmit;

begin

    -- Registers the incoming byte, for edge detection.
    proc_sig_byte : process (CLK, ARESET)
    begin
        if ARESET = '0' then
            sig_byte <= (others => '0');
        elsif rising_edge(CLK) then
            sig_changed <= '0';
            sig_byte <= i_VALUE;
            if sig_byte /= i_VALUE then
                sig_changed <= '1';
            end if;
        end if;
    end process proc_sig_byte;

    ----------------------------------------------------------
    ------              UART Control                   -------
    ----------------------------------------------------------
    -- Messages are sent on reset and when a button is pressed.

    -- This counter holds the UART state machine in reset for ~2 milliseconds. This
    -- will complete transmission of any byte that may have been initiated during 
    -- FPGA configuration due to the UART_TX line being pulled low, preventing a 
    -- frame shift error from occuring during the first message.
    proc_reset_cntr : process(CLK, ARESET)
    begin
        if ARESET = '0' then
            reset_cntr <= (others => '0');
        elsif (rising_edge(CLK)) then
            if ((reset_cntr = c_reset_cntr_max) or (state_uart /= RST_REG)) then
                reset_cntr <= (others => '0');
            else
                reset_cntr <= reset_cntr + 1;
            end if;
        end if;
    end process proc_reset_cntr;

    -- Next Uart state logic (states described above)
    next_uartState_process : process (CLK, ARESET)
    begin
        if ARESET = '0' then
            state_uart <= RST_REG;
        elsif rising_edge(CLK) then  
            case state_uart is 
                when RST_REG =>
                    if (reset_cntr = c_reset_cntr_max) then
                    state_uart <= LD_INIT_STR;
                    end if;
                when LD_INIT_STR =>
                    state_uart <= SEND_CHAR;
                when SEND_CHAR =>
                    state_uart <= RDY_LOW;
                when RDY_LOW =>
                    state_uart <= WAIT_RDY;
                when WAIT_RDY =>
                    if (sig_uart_rdy = '0') then
                        if (sig_str_end = sig_str_index) then
                            state_uart <= WAIT_BTN;
                        else
                            state_uart <= SEND_CHAR;
                        end if;
                    end if;
                when WAIT_BTN =>
                    if i_SW2 = '1' and sig_changed = '1' then
                        state_uart <= LD_BYTE_STR;
                    elsif (i_BTN3 = '1' and i_SW3 = '0') then
                        state_uart <= LD_BTN_STR;
                    elsif i_SW3 = '1' then
                        state_uart <= LD_SW_STR;
                    end if;
                when LD_BTN_STR =>
                    state_uart <= SEND_CHAR;
                when LD_SW_STR =>
                    state_uart <= SEND_CHAR;
                when LD_BYTE_STR =>
                    state_uart <= SEND_CHAR;
                when others=> --should never be reached
                    state_uart <= RST_REG;
                end case;  
        end if;
    end process;

    -- Loads the sig_send_str and sig_str_end signals when a LD state is
    -- is reached.
    string_load_process : process (CLK, ARESET)
    begin
        if ARESET = '0' then
            sig_send_str <= WELCOME_STR; 
            sig_str_end <= c_welcome_str_len;
        elsif rising_edge(CLK) then
            if (state_uart = LD_INIT_STR) then
                sig_send_str <= WELCOME_STR;
                sig_str_end <= c_welcome_str_len;
            elsif (state_uart = LD_BTN_STR) then
                sig_send_str <= BTN_STR;
                sig_str_end <= c_btn_str_len;
            elsif (state_uart = LD_SW_STR) then
                sig_send_str <= SW_STR;
                sig_str_end <= c_sw_str_len;
            elsif (state_uart = LD_BYTE_STR) then
                sig_send_str <= BYTE_STR & convert_to_string(sig_byte);
                sig_str_end <= c_byte_str_len;
            end if;
        end if;
    end process;

    -- Conrols the sig_str_index signal so that it contains the index
    -- of the next character that needs to be sent over uart
    char_count_process : process (CLK, ARESET)
    begin
        if ARESET = '0' then
            sig_str_index <= 0;
        elsif rising_edge(CLK) then
            if (state_uart = LD_INIT_STR or state_uart = LD_BTN_STR or state_uart = LD_SW_STR or state_uart = LD_BYTE_STR) then
                sig_str_index <= 0;
            elsif (state_uart = SEND_CHAR) then
                sig_str_index <= sig_str_index + 1;
            end if;
        end if;
    end process;

    -- Controls the uart_tx signals
    char_load_process : process (CLK, ARESET)
    begin
        if ARESET = '0' then
            sig_uart_send <= '0';
            sig_uart_data <= (others => '0');
        elsif rising_edge(CLK) then
            if (state_uart = SEND_CHAR) then
                sig_uart_send <= '1';
                sig_uart_data <= sig_send_str(sig_str_index);
            else
                sig_uart_send <= '0';
            end if;
        end if;
    end process;

    -- Instantiations
    uart_tx : component transmit
       port map (
           CLK             => CLK,
           ARESET          => ARESET,
           i_LOAD          => sig_uart_send,
           i_PARITY        => '0',              -- Parity bit Disabled
           i_PARITY_TEST   => '0',              -- No coverage testing required
           i_BAUD_RATE     => '0',              -- Baud rate fixed at 9k6
           i_TX_INPUT      => sig_uart_data,
           o_TX_BUSY       => sig_uart_rdy,
           o_UART_BIT      => o_UART_BIT);

end architecture rtl;
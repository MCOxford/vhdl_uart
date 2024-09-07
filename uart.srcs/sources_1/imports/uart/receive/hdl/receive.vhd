-----------------------------------------------------------------------------------------
--
--
-- File name     : receive
-- Language      : VHDL
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- UART Rx. Compatible with baud rates 9k6, 115k2 with an optional parity checking
-- feature. Data frame is fixed to 8 bits and no. of stop bits is fixed to one.
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
entity receive is
    port(CLK         : in  std_logic;                        -- Clock signal
         ARESET      : in  std_logic;                        -- Reset signal
         i_PARITY    : in  std_logic;                        -- Enable Parity padding + checking
         i_BAUD_RATE : in  std_logic;                        -- Frequency of signalling events per second
         i_UART_BIT  : in  std_logic;                        -- Bit received over UART Rx
         o_RX_BUSY   : out std_logic;                        -- "Rx is busy" signal to send to an LED, for example
         o_RX_OUTPUT : out std_logic_vector(7 downto 0));    -- Rx output data vector
end entity receive; 

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of receive is

    constant c_cycles_9600bd        : positive := 2604;                             -- number of clock cycles per bit at 9600 Bauds
    constant c_cycles_115200bd      : positive := 218;                              -- number of clock cycles per bit at 115200 Bauds
    constant c_half_cycles_9600bd   : positive := 1302;                             -- ceiling(c_cycles_9600bd / 2)
    constant c_half_cycles_115200bd : positive := 109;                              -- ceiling(c_cycles_115200bd / 2)
    constant c_uart_max_ind         : natural := 11;                                -- Max index value for uart packet 
    constant c_parity_en_ind        : natural := 9;                                 -- Parity enabled bit index
    constant c_max_data_ind         : natural := 8;                                 -- Data frame MSB index
    constant c_parity_bit_ind       : natural := 10;                                -- Parity bit value index

    signal sig_cycles_per_bit : positive := c_cycles_9600bd;                        -- clock frequency / baud rate, i.e. cycles per bit
    signal sig_half_cycles    : positive := c_half_cycles_9600bd;                   -- clock frequency / (2 * baud rate)
    signal sig_uart_packet    : std_logic_vector(c_uart_max_ind downto 0);          -- UART Packet with metadata and payload together
    signal sig_rx_busy        : std_logic;                                          -- "Rx busy" Set high when i_UART_BIT set low, set high when data parsed and outputted
    signal sig_rx_start       : std_logic;                                          -- UART packet sending in progress
    signal sig_rx_finish      : std_logic;                                          -- Rx has finished receiving and parsing bit (or dropped the packet after parity checking failed)
    signal sig_rx_ready       : std_logic;                                          -- Rx ready to receive bits
    signal sig_parse_packet   : std_logic;                                          -- Rx ready to parse packet
    signal sig_uart_size      : positive;                                           -- Size of of uart packet being received
    signal sig_data_output    : std_logic_vector(c_max_data_ind - 1 downto 0);      -- Resulting output byte

    type STATE_RX_TYPE is (LISTENING, SAMPLING, PARSING);
    signal state_rx : STATE_RX_TYPE;

    -- UART Packet frame figure---------------------------------------------------------------
    
                        ----------------------------------------------------------------------
                        --  START |      DATA       |    PARITY     |    PARITY    |  STOP  --
                        --   BIT  |     FRAME       |    ENABLED?   |     BIT      |  BIT   --
                        --    0   |   (payload)     |               |              |   1    --
                        ----------------------------------------------------------------------
    -- INDEX WITH             0         1 - 8              9               10          11
    -- PARITY
    
    -- INDEX WITH             0         1 - 8             n/a             n/a          9 
    -- NO PARITY
    
    -- The figure above depicts the bit field for sig_uart_packet
    -- We design our UART packet to be 12 bits maximum when parity checking is enabled.
    ------------------------------------------------------------------------------------------

begin

    sig_cycles_per_bit <= c_cycles_9600bd when i_BAUD_RATE = '0' else c_cycles_115200bd;
    sig_half_cycles <= c_half_cycles_9600bd when i_BAUD_RATE = '0' else c_half_cycles_115200bd;
    sig_uart_size <= c_uart_max_ind when i_PARITY = '1' else c_uart_max_ind - 2;

    proc_fsm : process(CLK, ARESET)
    begin
        if ARESET = '0' then
            state_rx <= LISTENING;
        elsif rising_edge(CLK) then
            case state_rx is
                when LISTENING =>
                    if sig_rx_ready = '1' then
                        state_rx <= SAMPLING;
                    end if;
                when SAMPLING =>
                    if sig_parse_packet = '1' then
                        state_rx <= PARSING;
                    end if;
                when PARSING =>
                    if sig_rx_finish = '1' then
                        state_rx <= LISTENING;
                    end if;
            end case;
        end if;
    end process;

    -- Listen on the wire until start bit is sent, wait half the bit cycle wait until we start sampling
    proc_listening : process (CLK, ARESET) is
    variable v_count : natural;
    begin
        if ARESET = '0' then
            o_RX_BUSY <= '0';
            sig_rx_ready <= '0';
            v_count := 0;
        elsif rising_edge(CLK) then
            sig_rx_ready <= '0';
            o_RX_BUSY <= o_RX_BUSY when sig_rx_finish = '0' else '0';
            if state_rx = LISTENING then
                if i_UART_BIT = '0' then
                    o_RX_BUSY <= '1';
                    if v_count < sig_half_cycles - 1 then
                        v_count := v_count + 1;
                    else
                        sig_rx_ready <= '1';
                        v_count := 0;
                    end if;
                end if;
             else
                 v_count := 0;
             end if;
        end if;
    end process proc_listening;

    -- Receive UART packet according to the chosen Baud rate
    proc_sampling : process (CLK, ARESET) is
    variable v_count : natural;
    variable v_offset : natural;
    begin
        if ARESET = '0' then
            sig_uart_packet <= (others => '0');
            v_count := 0;
            v_offset := 0;
            sig_parse_packet <= '0';
        elsif rising_edge(CLK) then
            sig_parse_packet <= '0';
            sig_uart_packet <= sig_uart_packet when sig_rx_finish = '0' else (others => '0');
            if state_rx = SAMPLING then
                if v_count < sig_cycles_per_bit - 1 then
                    v_count := v_count + 1;
                elsif v_offset < sig_uart_size then
                    if i_PARITY = '0' then
                        sig_uart_packet <= "00" & i_UART_BIT & sig_uart_packet(sig_uart_packet'high-2 downto 1);
                    else
                        sig_uart_packet <= i_UART_BIT & sig_uart_packet(sig_uart_packet'high downto 1);
                    end if;
                    v_offset := v_offset + 1;
                    v_count := 0;
                else
                    sig_parse_packet <= '1';
                end if;
            else
                v_count := 0;
                v_offset := 0;
            end if;
        end if;
    end process proc_sampling;

    -- Parse the UART and obtain the payload, perform parity checking if enabled
    proc_parse_packet : process (CLK, ARESET) is
    begin
        if ARESET = '0' then
            sig_data_output <= (others => '0');
            sig_rx_finish <= '0';
        elsif rising_edge(CLK) then
            sig_rx_finish <= '0';
            sig_data_output <= sig_data_output;
            if state_rx = PARSING then
                if i_PARITY = '0' or (i_PARITY = '1' and xor(sig_uart_packet(8 downto 1)) = sig_uart_packet(c_parity_bit_ind)) then
                    sig_data_output <= sig_uart_packet(c_max_data_ind downto 1); 
                else
                    sig_data_output <= (others => '0');
                end if;
                sig_rx_finish <= '1';
            end if;
        end if;
    end process proc_parse_packet;

    o_RX_OUTPUT <= sig_data_output;

end architecture rtl;
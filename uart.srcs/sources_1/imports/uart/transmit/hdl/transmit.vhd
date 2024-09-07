-----------------------------------------------------------------------------------------
--
--
-- File name     : transmit
-- Language      : VHDL  
-- Author        : MCO
-- Date          : 14/09/2023
-- Version       : 2.0
--
--
-----------------------------------------------------------------------------------------
-- OVERVIEW:
-- UART Tx. Compatible with baud rates 9k6, 115k2 with an optional parity checking
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
entity transmit is
  port(CLK           : in  std_logic;                      -- Clock signal
       ARESET        : in  std_logic;                      -- Reset signal
       i_LOAD        : in  std_logic;                      -- "LOAD" input signal
       i_PARITY      : in  std_logic;                      -- Enable Parity padding + checking
       i_PARITY_TEST : in  std_logic;                      -- Parity checking testing signal
       i_BAUD_RATE   : in  std_logic;                      -- Frequency of signalling events per second
       i_TX_INPUT    : in  std_logic_vector(7 downto 0);   -- Tx vector data input
       o_TX_BUSY     : out std_logic;                      -- "Tx is busy" signal to send to an LED, for example
       o_UART_BIT    : out std_logic);                     -- The output bit that gets sent over Tx
end entity transmit; 

-----------------------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------------------
architecture rtl of transmit is

    constant c_cycles_9600bd     : natural := 2604;                               -- number of clock cycles per bit at 9600 Bauds
    constant c_cycles_115200bd   : natural := 218;                                -- number of clock cycles per bit at 115200 Bauds
    constant c_uart_max_ind      : natural := 11;                                 -- Max index value for uart packet 
    constant c_data_max_ind      : natural := 7;                                  -- Max sig_data_frame index
    constant c_parity_en_ind     : natural := 9;                                  -- Parity enabled bit index
    constant c_parity_bit_ind    : natural := 10;                                 -- Parity bit value index
    constant c_parity_test_ind   : natural := 1;                                  -- Index for which data bit to flip to ensure parity checking fails

    signal sig_cycles_per_bit    : positive := c_cycles_9600bd;                   -- clock frequency / baud rate, i.e. cycles per bit
    signal sig_data_frame        : std_logic_vector(c_data_max_ind downto 0);     -- Payload (we make this eight bits long)
    signal sig_data_ready        : std_logic;                                     -- Data has been copied into buffer
    signal sig_ready_to_transmit : std_logic;                                     -- UART packet ready to transmit at Tx pin
    signal sig_tx_busy           : std_logic;                                     -- Set high when Tx is in the process of sending data
    signal sig_sending           : std_logic;                                     -- UART packet sending in progress
    signal sig_tx_finish         : std_logic;                                     -- Tx has finished transmitting all bits
    signal sig_uart_size         : positive;                                      -- Size of of uart packet to transmit
    signal sig_uart_packet       : std_logic_vector(c_uart_max_ind downto 0);     -- UART Packet with metadata and payload together

    type STATE_TX_TYPE is (READY, CONSTRUCTING, SENDING);
    signal state_tx : STATE_TX_TYPE;

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
    o_TX_BUSY <= '1' when (sig_data_ready = '1' or state_tx = CONSTRUCTING or state_tx = SENDING) else '0';
    sig_uart_size <= c_uart_max_ind when i_PARITY = '1' else c_uart_max_ind - 2;

    proc_fsm : process(CLK, ARESET)
    begin
        if ARESET = '0' then
            state_tx <= READY;
        elsif rising_edge(CLK) then
            case state_tx is
                when READY =>
                    if sig_data_ready = '1' then
                        state_tx <= CONSTRUCTING;
                    end if;
                when CONSTRUCTING =>
                    if sig_ready_to_transmit = '1' then
                        state_tx <= SENDING;
                    end if;
                when SENDING =>
                    if sig_tx_finish = '1' then
                        state_tx <= READY;
                    end if;
            end case;
        end if;
    end process proc_fsm;

    -- Convert parallel data bits recieved and convert into serial format
    proc_ready : process (CLK, ARESET) is
    begin
        if ARESET = '0' then
            sig_data_ready <= '0';
            sig_data_frame <= (others => '0');
        elsif rising_edge(CLK) then 
            sig_data_ready <= '0';
            sig_data_frame <= sig_data_frame;
            if state_tx = READY then
                if i_LOAD = '1' and o_TX_BUSY = '0' then
                    sig_data_frame <= i_TX_INPUT;
                    sig_data_ready <= '1';
                end if;
            end if;
        end if;
    end process proc_ready;

    -- Pad data frame with metadata ready for transmission
    proc_construct : process (CLK, ARESET) is
    begin
        if ARESET = '0' then
            sig_uart_packet <= (others => '0');
            sig_ready_to_transmit <= '0';
        elsif rising_edge(CLK) then
            sig_ready_to_transmit <= '0';
            sig_uart_packet <= sig_uart_packet;
            if state_tx = CONSTRUCTING then
                sig_uart_packet(c_uart_max_ind-3 downto 1) <= sig_data_frame(c_data_max_ind downto 0);
                if i_PARITY = '1' then
                    sig_uart_packet(c_parity_en_ind) <= '1';
                    sig_uart_packet(c_parity_bit_ind) <= xor(sig_data_frame);
                    sig_uart_packet(c_uart_max_ind) <= '1';
                else
                    sig_uart_packet(c_uart_max_ind downto c_uart_max_ind - 2) <= "111";
                end if;
                sig_ready_to_transmit <= '1';
            end if;
        end if;
    end process proc_construct;

    -- Send serial Tx data according to the selected baud rate
    proc_send : process (CLK, ARESET) is
    variable v_count  : natural;    -- counter to track how many cycles used for the currently transmitting bit
    variable v_offset : natural;    -- bit index for transmitting sig_uart_packet
    variable v_started : std_logic;
    variable v_uart_buffer : std_logic_vector(c_uart_max_ind downto 0);
    begin
        if ARESET = '0' then
            v_count := 0;
            v_offset := 0;
            v_started := '0';
            v_uart_buffer := (others => '1');
            o_UART_BIT <= '1';
            sig_tx_finish <= '0';
        elsif rising_edge(CLK) then
            sig_tx_finish <= '0';
            o_UART_BIT <= '1';
            if state_tx = SENDING then
                if sig_tx_finish = '0' then
                    if v_started = '0' then
                        v_uart_buffer := sig_uart_packet;
                        if i_PARITY = '1' and i_PARITY_TEST = '1' then
                            -- Flip the first data bit to change parity, ensuring the parity check fails
                            v_uart_buffer(c_parity_test_ind) := v_uart_buffer(c_parity_test_ind) xor '1';
                        end if;
                        v_started := '1';
                    end if;
                    o_UART_BIT <= v_uart_buffer(0);
                    -- If the max number of cycles not reached, continue
                    if v_count < sig_cycles_per_bit - 1 then
                        v_count := v_count + 1;
                    -- If we reached the max cycle number, transmit the next bit
                    elsif v_offset < sig_uart_size then
                        v_uart_buffer := '0' & v_uart_buffer(sig_uart_packet'high downto 1);
                        v_offset := v_offset + 1;
                        v_count := 0;
                    -- All done, finish
                    else
                        sig_tx_finish <= '1';
                        v_started := '0';
                        v_offset := 0;
                        v_count := 0;
                        v_uart_buffer := (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process proc_send;

end architecture rtl;
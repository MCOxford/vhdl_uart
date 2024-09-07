onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -divider CLOCK
add wave -noupdate /transmit_tb/inst_transmit/CLK
add wave -divider ARESET
add wave -noupdate /transmit_tb/inst_transmit/ARESET
add wave -divider UART_TX
add wave -noupdate /transmit_tb/inst_transmit/i_LOAD
add wave -noupdate /transmit_tb/inst_transmit/i_PARITY
add wave -noupdate /transmit_tb/inst_transmit/i_PARITY_TEST
add wave -noupdate /transmit_tb/inst_transmit/i_BAUD_RATE
add wave -noupdate /transmit_tb/inst_transmit/i_TX_INPUT
add wave -noupdate /transmit_tb/inst_transmit/o_TX_BUSY
add wave -noupdate /transmit_tb/inst_transmit/o_UART_BIT
add wave -divider RESULT
add wave -noupdate /transmit_tb/OK
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {161 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ns} {588 ns}

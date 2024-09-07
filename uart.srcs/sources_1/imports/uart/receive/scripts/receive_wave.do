onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -divider CLOCK
add wave -noupdate /receive_tb/inst_receive/CLK
add wave -divider ARESET
add wave -noupdate /receive_tb/inst_receive/ARESET
add wave -divider UART_RX
add wave -noupdate /receive_tb/inst_receive/i_PARITY
add wave -noupdate /receive_tb/inst_receive/i_BAUD_RATE
add wave -noupdate /receive_tb/inst_receive/i_UART_BIT
add wave -noupdate /receive_tb/inst_receive/o_RX_OUTPUT
add wave -noupdate /receive_tb/inst_receive/o_RX_BUSY
add wave -divider RESULT
add wave -noupdate /receive_tb/OK
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

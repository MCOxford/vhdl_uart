onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /led_tb/inst_led/i_LOAD
add wave -noupdate /led_tb/inst_led/o_LED(3)
add wave -noupdate /led_tb/inst_led/i_PARITY
add wave -noupdate /led_tb/inst_led/o_LED(2)
add wave -noupdate /led_tb/inst_led/i_BAUD_RATE
add wave -noupdate /led_tb/inst_led/o_LED(1)
add wave -noupdate /led_tb/inst_led/i_TX_BUSY
add wave -noupdate /led_tb/inst_led/i_RX_BUSY
add wave -noupdate /led_tb/inst_led/o_LED(0)
add wave -noupdate /led_tb/inst_led/i_PARITY_TEST
add wave -noupdate /led_tb/inst_led/o_RGB0_RED
add wave -divider RESULT
add wave -noupdate /led_tb/OK
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

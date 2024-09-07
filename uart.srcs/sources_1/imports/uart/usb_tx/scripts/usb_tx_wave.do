onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -divider CLOCK
add wave -noupdate /usb_tx_tb/inst_usb_tx/CLK
add wave -divider ARESET
add wave -noupdate /usb_tx_tb/inst_usb_tx/ARESET
add wave -divider USB_UART_TX
add wave -noupdate /usb_tx_tb/inst_usb_tx/i_BTN3
add wave -noupdate /usb_tx_tb/inst_usb_tx/i_SW2
add wave -noupdate /usb_tx_tb/inst_usb_tx/i_VALUE
add wave -noupdate /usb_tx_tb/inst_usb_tx/i_SW3
add wave -noupdate /usb_tx_tb/inst_usb_tx/o_UART_BIT
add wave -divider PACKET
add wave -noupdate /usb_tx_tb/uart_pckt
add wave -divider RESULT
add wave -noupdate /usb_tx_tb/OK
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

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider CLOCKS
add wave -noupdate /top_tb/inst_top/CLK_100MHZ
add wave -noupdate /top_tb/inst_top/clk_25mhz
add wave -noupdate -divider ARESET
add wave -noupdate /top_tb/inst_top/CK_RST
add wave -noupdate -divider I/O_CHANNELS
add wave -noupdate /top_tb/inst_top/CK_I
add wave -noupdate /top_tb/inst_top/CK_O
add wave -noupdate -divider PMOD_HEX
add wave -noupdate /top_tb/inst_top/JA
add wave -noupdate /top_tb/inst_top/JB
add wave -noupdate /top_tb/inst_top/pmod_hex/i_VALUE
add wave -noupdate -divider PMOD_ASCII
add wave -noupdate /top_tb/inst_top/JC
add wave -noupdate /top_tb/inst_top/JD
add wave -noupdate /top_tb/inst_top/pmod_ascii/i_VALUE
add wave -noupdate -divider LEDs
add wave -noupdate /top_tb/inst_top/LEDs
add wave -noupdate /top_tb/inst_top/RGB0_Red
add wave -noupdate -divider USB_TX
add wave -noupdate /top_tb/inst_top/UART_TXD
add wave -noupdate -divider BUTTONS
add wave -noupdate /top_tb/inst_top/BTN
add wave -noupdate -divider SWITCHES
add wave -noupdate /top_tb/inst_top/SW
add wave -noupdate -divider RESULT
add wave -noupdate /top_tb/OK
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

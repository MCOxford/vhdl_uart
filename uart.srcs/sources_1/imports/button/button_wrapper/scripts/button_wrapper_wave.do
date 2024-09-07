onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -divider CLOCK
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/CLK
add wave -divider ARESET
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/ARESET
add wave -divider BTN0
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/i_BTN_0
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/o_LOAD
add wave -divider BTN1
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/i_BTN_1
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/o_PARITY
add wave -divider BTN2
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/i_BTN_2
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/o_PARITY_TEST
add wave -divider BTN3
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/i_BTN_3
add wave -noupdate /button_wrapper_tb/inst_button_wrapper/o_BTN3_PRESSED
add wave -divider RESULT
add wave -noupdate /button_wrapper_tb/OK
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

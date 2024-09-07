onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -divider CLOCK
add wave -noupdate /button_handler_tb/inst_button_handler/CLK
add wave -divider ARESET
add wave -noupdate /button_handler_tb/inst_button_handler/ARESET
add wave -divider BTN_HANDLER
add wave -noupdate /button_handler_tb/inst_button_handler/i_BTN
add wave -noupdate /button_handler_tb/inst_button_handler/i_TOGGLE
add wave -noupdate /button_handler_tb/inst_button_handler/i_ENABLE
add wave -noupdate /button_handler_tb/inst_button_handler/o_VAL
add wave -divider FSM
add wave -noupdate /button_handler_tb/inst_button_handler/state_btn
add wave -divider RESULT
add wave -noupdate /button_handler_tb/OK
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

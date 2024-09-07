onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -divider SW0
add wave -noupdate /switch_tb/inst_switch/i_SW(0)
add wave -noupdate /switch_tb/inst_switch/o_BAUD_RATE
add wave -divider SW1
add wave -noupdate /switch_tb/inst_switch/i_SW(1)
add wave -noupdate /switch_tb/inst_switch/o_SIMPLE_MODE
add wave -divider SW2
add wave -noupdate /switch_tb/inst_switch/i_SW(2)
add wave -noupdate /switch_tb/inst_switch/o_PRINT
add wave -divider SW3
add wave -noupdate /switch_tb/inst_switch/i_SW(3)
add wave -noupdate /switch_tb/inst_switch/o_SW3_ON
add wave -divider RESULT
add wave -noupdate /switch_tb/OK
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

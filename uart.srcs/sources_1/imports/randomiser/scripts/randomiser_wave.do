onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -divider CLOCK
add wave -noupdate /randomiser_tb/inst_randomiser/CLK
add wave -divider RESET
add wave -noupdate /randomiser_tb/inst_randomiser/ARESET
add wave -divider RANDOMISER
add wave -position insertpoint /randomiser_tb/inst_randomiser/reg_8
add wave -position insertpoint /randomiser_tb/inst_randomiser/proc_lfsr/v_sig_sel
add wave -noupdate /randomiser_tb/inst_randomiser/o_RANDOM
add wave -divider RESULT
add wave -position insertpoint /randomiser_tb/OK
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

vlib work

vcom -explicit -2008 "../hdl/randomiser.vhd"
vcom -explicit -2008 "../tb/randomiser_tb.vhd"

vsim randomiser_tb

do "../scripts/randomiser_wave.do"

run -all 
vlib work

vcom -explicit -2008 "../hdl/simple.vhd"
vcom -explicit -2008 "../tb/simple_tb.vhd"

vsim simple_tb

do "../scripts/simple_wave.do"

run -all 
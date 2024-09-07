vlib work

vcom -explicit -2008 "../hdl/receive.vhd"
vcom -explicit -2008 "../tb/receive_tb.vhd"

vsim receive_tb

do "../scripts/receive_wave.do"

run -all 
vlib work

vcom -explicit -2008 "../hdl/transmit.vhd"
vcom -explicit -2008 "../tb/transmit_tb.vhd"

vsim transmit_tb

do "../scripts/transmit_wave.do"

run -all 
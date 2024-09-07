vlib work

vcom -explicit -2008 "../hdl/button_handler.vhd"
vcom -explicit -2008 "../tb/button_handler_tb.vhd"

vsim button_handler_tb

do "../scripts/button_handler_wave.do"

run -all 
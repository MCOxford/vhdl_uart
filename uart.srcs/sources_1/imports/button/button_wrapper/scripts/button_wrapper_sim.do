vlib work

vcom -explicit -2008 "../../button_handler/hdl/button_handler.vhd"
vcom -explicit -2008 "../hdl/button_wrapper.vhd"
vcom -explicit -2008 "../tb/button_wrapper_tb.vhd"

vsim button_wrapper_tb

do "../scripts/button_wrapper_wave.do"

run -all 
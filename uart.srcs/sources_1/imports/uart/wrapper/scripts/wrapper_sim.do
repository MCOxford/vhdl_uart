vlib work

vcom -explicit -2008 "../../transmit/hdl/transmit.vhd"
vcom -explicit -2008 "../../receive/hdl/receive.vhd"
vcom -explicit -2008 "../hdl/wrapper.vhd"
vcom -explicit -2008 "../tb/wrapper_tb.vhd"

vsim wrapper_tb

do "../scripts/wrapper_wave.do"

run -all 
vlib work

# Include relevant .vdl files here
vcom -explicit -2008 "../../button/button_handler/hdl/button_handler.vhd"
vcom -explicit -2008 "../../button/button_wrapper/hdl/button_wrapper.vhd"
vcom -explicit -2008 "../../led/hdl/led.vhd"
vcom -explicit -2008 "../../simple/hdl/simple.vhd"
vcom -explicit -2008 "../../randomiser/hdl/randomiser.vhd"
vcom -explicit -2008 "../../ssd/pmod/hdl/pmod.vhd"
vcom -explicit -2008 "../../ssd/ascii_display/hdl/ascii_display.vhd"
vcom -explicit -2008 "../../ssd/hex_display/hdl/hex_display.vhd"
vcom -explicit -2008 "../../switch/hdl/switch.vhd"
vcom -explicit -2008 "../../uart/transmit/hdl/transmit.vhd"
vcom -explicit -2008 "../../uart/receive/hdl/receive.vhd"
vcom -explicit -2008 "../../uart/wrapper/hdl/wrapper.vhd"
vcom -explicit -2008 "../../uart/usb_tx/hdl/usb_tx.vhd"
vcom -explicit -2008 "../hdl/top.vhd"
vcom -explicit -2008 "../tb/top_tb.vhd"

vsim top_tb

do "../scripts/top_wave.do"

run -all 
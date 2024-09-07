vlib work

vcom -explicit -2008 "../../transmit/hdl/transmit.vhd"
vcom -explicit -2008 "../hdl/usb_tx.vhd"
vcom -explicit -2008 "../tb/usb_tx_tb.vhd"

vsim usb_tx_tb

do "../scripts/usb_tx_wave.do"

run -all 
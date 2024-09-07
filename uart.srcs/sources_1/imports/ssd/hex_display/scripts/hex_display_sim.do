vlib work

vcom -explicit -2008 "../../pmod/hdl/pmod.vhd"
vcom -explicit -2008 "../hdl/hex_display.vhd"
vcom -explicit -2008 "../tb/hex_display_tb.vhd"

vsim hex_display_tb

do "../scripts/hex_display_wave.do"

run -all 
vlib work

vcom -explicit -2008 "../../pmod/hdl/pmod.vhd"
vcom -explicit -2008 "../hdl/ascii_display.vhd"
vcom -explicit -2008 "../tb/ascii_display_tb.vhd"

vsim ascii_display_tb

do "../scripts/ascii_display_wave.do"

run -all 
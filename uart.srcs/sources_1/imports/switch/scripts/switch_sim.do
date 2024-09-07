vlib work

vcom -explicit -2008 "../hdl/switch.vhd"
vcom -explicit -2008 "../tb/switch_tb.vhd"

vsim switch_tb

do "../scripts/switch_wave.do"

run -all 
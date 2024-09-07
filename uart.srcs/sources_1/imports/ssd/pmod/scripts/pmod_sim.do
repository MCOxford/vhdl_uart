vlib work

vcom -explicit -2008 "../hdl/pmod.vhd"
vcom -explicit -2008 "../tb/pmod_tb.vhd"

vsim pmod_tb

do "../scripts/pmod_wave.do"

run -all 
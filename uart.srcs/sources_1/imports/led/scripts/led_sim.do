vlib work

vcom -explicit -2008 "../hdl/led.vhd"
vcom -explicit -2008 "../tb/led_tb.vhd"

vsim led_tb

do "../scripts/led_wave.do"

run -all 
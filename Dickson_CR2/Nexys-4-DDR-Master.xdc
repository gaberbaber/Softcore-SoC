#======================================================================================================================
# Clock signal (100 MHz)
#======================================================================================================================
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

#======================================================================================================================
# Buttons
#======================================================================================================================
# CPU reset button; active low → maps to rst (your RTL reset is active-low)
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports rst]

# Other buttons; active high
# btn up  -> start
# btn right not used here
# btn down -> stop
# btn left not used here
# btn center -> clear
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports btn_start]  ;# BTNU
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports btn_clear]  ;# BTNR in ref, but you're using this pin for clear per buddy's file
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports btn_stop]   ;# BTNR/BTND per board silkscreen-matches buddy's mapping

#======================================================================================================================
# Discrete LED (use LED0 to mirror stim_led)
#======================================================================================================================
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports stim_led]

#======================================================================================================================
# 7 segment display (active-low)
# Your RTL uses sseg[7:0] = {dp,g,f,e,d,c,b,a} and an[7:0] (active-low)
# These pin maps match that ordering: sseg[0]=a ... sseg[6]=g, sseg[7]=dp
#======================================================================================================================
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {sseg[0]}]  ;# CA
set_property -dict {PACKAGE_PIN R10 IOSTANDARD LVCMOS33} [get_ports {sseg[1]}]  ;# CB
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {sseg[2]}]  ;# CC
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {sseg[3]}]  ;# CD
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {sseg[4]}]  ;# CE
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {sseg[5]}]  ;# CF
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {sseg[6]}]  ;# CG
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {sseg[7]}]  ;# DP

set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {an[3]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {an[4]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {an[5]}]
set_property -dict {PACKAGE_PIN K2  IOSTANDARD LVCMOS33} [get_ports {an[6]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {an[7]}]

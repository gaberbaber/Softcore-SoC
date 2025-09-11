## This file is a general .xdc for the Nexys4 DDR Rev. C
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

#======================================================================================================================
# Clock signal
#======================================================================================================================
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

#======================================================================================================================
# To facilitate Quad-SPI flash programming 
#======================================================================================================================
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]


#======================================================================================================================
#Switches
#======================================================================================================================
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {enable}] ; sw[0]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {dir}] ; sw[1]


#======================================================================================================================
#Buttons
#======================================================================================================================
# ***** CPU_reset button; active low
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports rst]
# ***** Other buttons; active highs
# ***** btn(0): btnu;  btn(1): btnr;  btn(2): btnd; btn(3): btnl;  btn(4): btnc;


#======================================================================================================================
# discrete LEDs
#======================================================================================================================


#======================================================================================================================
# tri-color LEDs
#======================================================================================================================


#======================================================================================================================
#7 segment display
#======================================================================================================================
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {sseg[0]}]
set_property -dict {PACKAGE_PIN R10 IOSTANDARD LVCMOS33} [get_ports {sseg[1]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {sseg[2]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {sseg[3]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {sseg[4]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {sseg[5]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {sseg[6]}]
#decimal point
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {sseg[7]}]
# enable
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {an[3]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {an[4]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {an[5]}]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {an[6]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {an[7]}]


#====================================================================================================
# PWM Audio Amplifier
#====================================================================================================


#====================================================================================================
# USB-RS232 Interface
#====================================================================================================

# ************CTS/RTS not used
#set_property -dict { PACKAGE_PIN D3    IOSTANDARD LVCMOS33 } [get_ports { uart_cts }]; #IO_L12N_T1_MRCC_35 Sch=uart_cts
#set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { uart_rts }]; #IO_L5N_T0_AD13N_35 Sch=uart_rts

#====================================================================================================
# USB HID (PS/2)
#====================================================================================================



#====================================================================================================
# I2C temperature sensor
# tmp_int / tmp_ct signals are not used
#====================================================================================================

# ************ tmp_int / tmp_ct not used
#set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS33 } [get_ports { tmp_int }]; #IO_L6N_T0_VREF_15 Sch=tmp_int
#set_property -dict { PACKAGE_PIN B14   IOSTANDARD LVCMOS33 } [get_ports { tmp_ct }]; #IO_L2N_T0_AD8N_15 Sch=tmp_ct


#====================================================================================================
# SPI Accelerometer
# aclInt1 / aclInt2 signals are not used
#====================================================================================================

# *********** aclInt1 / aclInt2 signals are not used
#set_property -dict { PACKAGE_PIN B13   IOSTANDARD LVCMOS33 } [get_ports { aclInt1[1] }]; #IO_L2P_T0_AD8P_15 Sch=acl_int[1]
#set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { aclInt1[2] }]; #IO_L20P_T3_A20_15 Sch=acl_int[2]


#====================================================================================================
# VGA Port
#====================================================================================================

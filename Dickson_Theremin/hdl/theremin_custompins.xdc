#====================================================================================================
# Ultrasonic Theremin Custom Pins
# Supplementary constraints for ultrasonic sensors and audio output
#====================================================================================================

# Ultrasonic Sensor 1 - Pmod JA (Pitch Control)
# Using JA Pin 1 (Trig) and JA Pin 2 (Echo)
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports ja_trig]  ;# JA Pin 1
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports ja_echo]  ;# JA Pin 2

# Ultrasonic Sensor 2 - Pmod JB (Volume Control)  
# Using JB Pin 1 (Trig) and JB Pin 2 (Echo)
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports jb_trig]  ;# JB Pin 1
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports jb_echo]  ;# JB Pin 2

# PWM Audio Output (already defined in nexys4_ddr_chu.xdc as audio_pdm on A11)

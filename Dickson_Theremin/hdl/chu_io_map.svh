// chu_io_map.svh
// IO map for ultrasonic theremin system
// Based on Dr. Chu's original with streamlined slot assignments

`ifndef _CHU_IO_MAP_INCLUDED
`define _CHU_IO_MAP_INCLUDED

// system clock rate in MHz; used for timer, uart, ddfs etc
`define SYS_CLK_FREQ 100

// io base address for microBlaze MCS
`define BRIDGE_BASE 0xc0000000

// ================================================================
// Slot module definition for Theremin
// format: SLOT`_ModuleType_Name
// ================================================================
`define S0_SYS_TIMER  0
`define S1_SW         1
`define S2_LED        2
`define S3_US1        3   // Ultrasonic sensor 1 (pitch control)
`define S4_US2        4   // Ultrasonic sensor 2 (volume control)
`define S5_DDFS       5   // Direct Digital Frequency Synthesizer (tone generation)
`define S6_PWM_AUDIO  6   // PWM audio output

`endif //_CHU_IO_MAP_INCLUDED

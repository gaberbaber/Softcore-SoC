# Ultrasonic Theremin - Final Project

**Course:** Softcore System-on-Chip  
**Student:** Gabe Dickson  
**Institution:** Baylor University  
**Date:** December 2025

## Project Overview

A digital theremin implementation using two ultrasonic distance sensors for contactless musical control. The system demonstrates the softcore hardware acceleration philosophy by offloading sensor timing, distance calculation, and audio generation to custom FPGA cores, minimizing software complexity while achieving real-time musical performance.

**Demo Video:** [YouTube Link](https://youtu.be/your_video_id_here)

## Features

- **Dual Ultrasonic Sensor Control**
  - Pitch control via hand distance (2-8 inches / 51-203mm range)
  - Full octave range: D4 (294Hz) to D5 (587Hz)
  - Volume control via continuous envelope (0.0 to 1.0) based on hand distance
  
- **Custom Hardware Cores**
  - Two ultrasonic sensor controllers (autonomous triggering and measurement)
  - DDFS (Direct Digital Frequency Synthesis) audio core with envelope control
  - Visual LED feedback for both pitch and volume levels
  
- **Real-time Performance**
  - 50ms update interval for smooth response
  - Deterministic hardware timing for microsecond-precision measurements
  - Smooth, continuous frequency and amplitude control

## Hardware Requirements

- Nexys4 DDR FPGA Development Board
- 2x Ultrasonic Distance Sensors
  - Pitch sensor connected to Pmod JA (pins C17 trigger, D18 echo)
  - Volume sensor connected to Pmod JB (pins D14 trigger, F16 echo)
- Audio output via onboard audio jack (J8, pin A11)

## Software Requirements

- Xilinx Vivado 2024.1 (Hardware synthesis)
- Xilinx Vitis 2024.1 (Embedded software development)
- Dr. Chu's FPro MMIO Framework (sampler system)

## System Architecture

### Hardware Cores (MMIO Slots)

| Slot | Core | Base Address | Function |
|------|------|--------------|----------|
| 2 | LED Output | 0xC0001000 | 16-bit LED control |
| 3 | Pitch Sensor | 0xC0001800 | Ultrasonic sensor 1 (Pmod JA) |
| 4 | Volume Sensor | 0xC0002000 | Ultrasonic sensor 2 (Pmod JB) |
| 5 | DDFS Audio | 0xC0002800 | Direct Digital Frequency Synthesis with envelope |

### Register Maps

**Sensor Controllers (Slots 3 & 4):**
- Offset 0x00 (read): Distance in millimeters (32-bit)
- Returns 0xFFFFFFFF for invalid/out-of-range measurements

**DDFS Audio Core (Slot 5):**
- Carrier frequency control (sets pitch)
- Envelope control (sets volume/amplitude, range 0.0 to 1.0)
- Modulation offset control
- Amplitude modulation depth control

## Project Structure

```
Dickson_FinalProject/
├── hardware/
│   ├── mcs_top_theremin.sv                 # Top-level system integration
│   ├── mmio_sys_theremin.sv                # MMIO subsystem with all cores
│   ├── ultrasonic_core.sv                  # Ultrasonic sensor controller
│   ├── chu_ddfs_core.sv                    # DDFS audio synthesis core
│   └── chu_mcs_bridge.sv                   # MicroBlaze-to-FPro bridge
├── software/
│   ├── ultrasonic_core.h                   # Sensor driver header
│   ├── ultrasonic_core.cpp                 # Sensor driver implementation
│   ├── ddfs_core.h                         # DDFS audio driver header
│   ├── ddfs_core.cpp                       # DDFS audio driver implementation
│   ├── gpio_cores.h                        # LED/switch driver header
│   └── main.cpp                            # Main theremin application
├── constraints/
│   └── nexys4ddr.xdc                       # Pin assignments and constraints
└── README.md
```

### Hardware Connections

**Ultrasonic Pitch Sensor (Slot 3) - Pmod JA:**
- VCC → 3.3V
- GND → Ground
- TRIG → JA Pin 2 (FPGA pin C17)
- ECHO → JA Pin 3 (FPGA pin D18)

**Ultrasonic Volume Sensor (Slot 4) - Pmod JB:**
- VCC → 3.3V
- GND → Ground
- TRIG → JB Pin 2 (FPGA pin D14)
- ECHO → JB Pin 3 (FPGA pin F16)

**Audio Output:**
- PWM signal → Onboard audio jack J8 (FPGA pin A11)
- Audio enable → Tied high internally
- Connect headphones or powered speakers to 3.5mm audio jack

## Usage

1. Power on the Nexys4 DDR board
2. Program with hardware bitstream
3. Run software application (LEDs will flash briefly on startup)
4. **Pitch Control (Left Sensor):**
   - Move hand closer (2 inches) = higher pitch (D5 - 587Hz)
   - Move hand farther (8 inches) = lower pitch (D4 - 294Hz)
   - Full octave range with smooth transitions
   - Lower 8 LEDs show pitch distance level
5. **Volume Control (Right Sensor):**
   - Move hand closer (2 inches) = maximum volume (envelope = 1.0)
   - Move hand farther (8 inches) = minimum volume (envelope = 0.0)
   - Continuous amplitude control via envelope
   - Upper 8 LEDs show volume distance level
6. Play musical melodies by varying hand distances on both sensors!

### Key Technical Challenges Solved

1. **MMIO Address Calculation:** Proper word-aligned addressing for register access was critical. Registers must be accessed using word offsets (index × 4) not byte offsets.

2. **Sensor Integration:** Ultrasonic sensors provide distance measurements in millimeters. Software maps these to musical parameters (frequency and envelope).

3. **DDFS Audio Synthesis:** Direct Digital Frequency Synthesis provides smooth frequency control and envelope-based amplitude modulation for professional-quality audio output.

4. **Real-time LED Feedback:** Visual feedback system shows both pitch and volume levels simultaneously using the 16 onboard LEDs (8 for pitch, 8 for volume).

## Distance-to-Frequency Mapping

```
Distance Range: 2 inches (51mm) - 8 inches (203mm)
Frequency Range: D5 (587Hz) - D4 (294Hz)
Full octave range with linear interpolation

Mapping formula:
  dist_offset = distance - PITCH_MIN_DIST
  dist_range = PITCH_MAX_DIST - PITCH_MIN_DIST  
  freq_range = HIGH_FREQ - BASE_FREQ
  freq_delta = (dist_offset * freq_range) / dist_range
  frequency = HIGH_FREQ - freq_delta

Volume envelope (0.0 to 1.0):
  envelope = 1.0 - ((distance - VOLUME_MIN_DIST) / (VOLUME_MAX_DIST - VOLUME_MIN_DIST))
  Closer = louder (envelope approaches 1.0)
  Farther = quieter (envelope approaches 0.0)
```

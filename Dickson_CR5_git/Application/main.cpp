/********************************************************************
 * @file main.cpp
 *
 * @brief Thermometer application using ADT7420 I2C sensor 
 *        and seven-segment display
 *
 * @author Gabe Dickson
 * @date December 2024
 *
 * @description
 * Reads temperature from ADT7420 sensor via I2C (Slot 10)
 * Displays temperature on seven-segment LEDs (Slot 8)
 * Format: "XX.XXC" (e.g., "23.50C" for 23.5 degrees Celsius)
 ********************************************************************/

#include "chu_init.h"
#include "i2c_core.h"
#include "sseg_core.h"

// Global hardware instances
SsegCore sseg(get_slot_addr(BRIDGE_BASE, S8_SSEG));
I2cCore adt7420(get_slot_addr(BRIDGE_BASE, S10_I2C));

/********************************************************************
 * Read temperature from ADT7420 sensor
 * 
 * @return temperature in degrees Celsius
 * 
 * @note ADT7420 stores 13-bit signed temperature in registers 0-1
 *       Format: MSB in reg 0, LSB in reg 1
 *       Resolution: 1/16 degree C per LSB
 ********************************************************************/
float readTemperature() {
   const uint8_t DEV_ADDR = 0x4B;  // ADT7420 I2C address
   uint8_t wbytes[1];
   uint8_t rbytes[2];
   uint16_t raw;
   float tempC;
   
   // Write register address 0x00 (temperature MSB register)
   wbytes[0] = 0x00;
   adt7420.write_transaction(DEV_ADDR, wbytes, 1, 1);  // 1 = restart
   
   // Read 2 bytes (MSB and LSB)
   adt7420.read_transaction(DEV_ADDR, rbytes, 2, 0);   // 0 = stop
   
   // Combine bytes into 16-bit value
   raw = ((uint16_t)rbytes[0] << 8) | (uint16_t)rbytes[1];
   
   // Extract 13-bit temperature (bits 15:3)
   // Check sign bit and handle negative temperatures
   if (raw & 0x8000) {
      // Negative temperature
      raw = raw >> 3;                           // Shift to get 13-bit value
      tempC = (float)((int)raw - 8192) / 16.0; // Sign extend and convert
   } else {
      // Positive temperature  
      raw = raw >> 3;                           // Shift to get 13-bit value
      tempC = (float)raw / 16.0;               // Convert to Celsius
   }
   
   return tempC;
}

/********************************************************************
 * Display temperature on seven-segment display
 * 
 * @param tempC temperature in degrees Celsius
 * 
 * @note Display format: "XX.XXC__" (left-aligned)
 *       Position 7 (leftmost): tens digit
 *       Position 6: ones digit (with decimal point)
 *       Position 5: tenths digit  
 *       Position 4: hundredths digit
 *       Position 3: 'C'
 *       Positions 2-0: blank
 ********************************************************************/
void displayTemperature(float tempC) {
   int temp_int;
   int tens, ones, tenths, hundredths;
   uint8_t dp_mask = 0x00;
   
   // Handle negative temperatures by displaying as positive
   // (You could add a minus sign if desired)
   if (tempC < 0) {
      tempC = -tempC;
   }
   
   // Convert to integer (multiply by 100 to preserve 2 decimal places)
   temp_int = (int)(tempC * 100.0 + 0.5);  // +0.5 for rounding
   
   // Extract individual digits
   hundredths = temp_int % 10;
   temp_int = temp_int / 10;
   tenths = temp_int % 10;
   temp_int = temp_int / 10;
   ones = temp_int % 10;
   temp_int = temp_int / 10;
   tens = temp_int % 10;
   
   // Clear display first
   for (int i = 0; i < 8; i++) {
      sseg.write_1ptn(0xff, i);  // 0xff = all segments off
   }
   
   // Write digits to display (LEFT-ALIGNED)
   // Position 7 (leftmost): tens digit
   if (tens > 0) {
      sseg.write_1ptn(sseg.h2s(tens), 7);
   } else {
      sseg.write_1ptn(0xff, 7);  // Blank leading zero
   }
   
   // Position 6: ones digit  
   sseg.write_1ptn(sseg.h2s(ones), 6);
   
   // Position 5: tenths digit
   sseg.write_1ptn(sseg.h2s(tenths), 5);
   
   // Position 4: hundredths digit
   sseg.write_1ptn(sseg.h2s(hundredths), 4);
   
   // Position 3: 'C' character (CORRECTED PATTERN)
   // Segments needed for 'C': A, F, E, D (top, top-left, bottom-left, bottom)
   // Pattern: 0bDP_G_F_E_D_C_B_A = 0b0_1_0_0_0_1_1_1 = 0x47
   sseg.write_1ptn(0xC6, 3);  // Correct pattern for 'C'
   
   // Positions 2-0: blank (rightmost)
   sseg.write_1ptn(0xff, 2);
   sseg.write_1ptn(0xff, 1);
   sseg.write_1ptn(0xff, 0);
   
   // Set decimal point after ones digit (position 6)
   sseg.set_dp(1 << 6);  // Bit 6 = position 6
}

/********************************************************************
 * Verify ADT7420 presence by reading device ID
 * 
 * @return true if device ID is correct (0xCB), false otherwise
 ********************************************************************/
bool verifyADT7420() {
   const uint8_t DEV_ADDR = 0x4B;
   uint8_t wbytes[1];
   uint8_t id;
   
   // Read ID register (0x0B) - should return 0xCB
   wbytes[0] = 0x0B;
   adt7420.write_transaction(DEV_ADDR, wbytes, 1, 1);
   adt7420.read_transaction(DEV_ADDR, &id, 1, 0);
   
   return (id == 0xCB);
}

/********************************************************************
 * Main function
 ********************************************************************/
int main() {
   float temperature;
   bool sensor_ok;
   
   // Optional: Verify ADT7420 is present
   sensor_ok = verifyADT7420();
   
   if (!sensor_ok) {
      // Display error pattern on seven-segment (optional)
      // For now, continue anyway - useful for debugging
      uart.disp("Warning: ADT7420 ID check failed\n\r");
   } else {
      uart.disp("ADT7420 sensor detected\n\r");
   }
   
   // Main loop: read and display temperature continuously
   while(1) {
      // Read temperature from sensor
      temperature = readTemperature();
      
      // Display on seven-segment LEDs
      displayTemperature(temperature);
      
      // Optional: Output to UART for debugging
      uart.disp("Temperature: ");
      uart.disp(temperature, 2);  // 2 decimal places
      uart.disp(" C\n\r");
      
      // Update rate: 1 second
      sleep_ms(1000);
   }
   
   return 0;
}

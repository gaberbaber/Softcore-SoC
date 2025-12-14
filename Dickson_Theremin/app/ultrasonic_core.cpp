/*****************************************************************//**
 * @file ultrasonic_core.cpp
 *
 * @brief Implementation of ultrasonic sensor driver
 *
 * @author Gabe Dickson
 * @version v1.0: initial release
 *********************************************************************/

#include "ultrasonic_core.h"

/**
 * Constructor - saves base address for this sensor
 */
UltrasonicCore::UltrasonicCore(uint32_t core_base_addr) {
   base_addr = core_base_addr;
}

/**
 * Destructor - nothing to clean up
 */
UltrasonicCore::~UltrasonicCore() {
}

/**
 * Trigger a new distance measurement
 * 
 * Writes 1 to control register to start hardware measurement.
 * Non-blocking - returns immediately while hardware works.
 */
void UltrasonicCore::trigger() {
   io_write(base_addr, CONTROL_REG, 1);  // Write 1 to start measurement
}

/**
 * Check if sensor is busy measuring
 * 
 * Reads bit 0 of status register:
 *   - 1 = measurement in progress
 *   - 0 = ready for new measurement
 */
bool UltrasonicCore::isBusy() {
   uint32_t status = io_read(base_addr, CONTROL_REG);
   return (status & 0x01);  // Bit 0 is busy flag
}

/**
 * Wait until current measurement completes
 * 
 * Polls busy flag in a loop until hardware finishes.
 * Typical wait time: 20-40ms depending on distance.
 */
void UltrasonicCore::waitUntilReady() {
   while (isBusy()) {
      // Poll until measurement complete
      // Hardware clears busy flag when done
   }
}

/**
 * Read the measured distance
 * 
 * Returns pre-calculated distance from hardware.
 * Hardware already did the math:
 *   distance_mm = (echo_time_us × 343 m/s) / 2
 * 
 * Special value 0xFFFFFFFF means timeout (no echo received).
 */
uint32_t UltrasonicCore::readDistance() {
   return io_read(base_addr, DISTANCE_REG);
}

/**
 * Read raw echo pulse width
 * 
 * Returns the time in microseconds that echo pulse was high.
 * Advanced function - distance is more useful for most applications.
 */
uint32_t UltrasonicCore::readEchoTime() {
   return io_read(base_addr, ECHO_TIME_REG);
}

/**
 * Complete measurement cycle (blocking)
 * 
 * Does everything in one function call:
 *   1. Triggers measurement
 *   2. Waits for hardware to finish
 *   3. Reads and returns distance
 * 
 * Typical execution time: 20-40ms
 * 
 * Example usage:
 *   uint32_t dist = sensor.getDistance();
 *   if (dist != 0xFFFFFFFF) {
 *      // Valid measurement
 *      printf("Distance: %d mm\n", dist);
 *   } else {
 *      // Timeout - no object detected
 *   }
 */
uint32_t UltrasonicCore::getDistance() {
   trigger();           // Start measurement
   waitUntilReady();    // Wait for completion (polls busy flag)
   return readDistance(); // Read result
}
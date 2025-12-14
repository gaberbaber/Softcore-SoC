/*****************************************************************//**
 * @file ultrasonic_core.h
 *
 * @brief Driver for ultrasonic distance sensor core (RCWL-1601)
 *
 * @description
 * This driver controls the ultrasonic sensor hardware core that
 * autonomously measures distance using echo pulse timing.
 * 
 * Hardware does all the work:
 *   - Generates 10us trigger pulse
 *   - Measures echo pulse width in microseconds
 *   - Calculates distance in millimeters
 * 
 * Software just needs to:
 *   - Trigger a measurement
 *   - Wait for completion
 *   - Read the distance
 *
 * Register Map (each sensor has these 3 registers):
 *   Offset 0x00 (Write): Control register
 *     - Write 1 to start measurement
 *   Offset 0x00 (Read): Status register
 *     - Bit 0: Busy flag (1 = measuring, 0 = ready)
 *   Offset 0x01 (Read): Echo time in microseconds
 *   Offset 0x02 (Read): Distance in millimeters
 *
 * @author Gabe Dickson
 * @version v1.0: initial release
 *********************************************************************/

#ifndef _ULTRASONIC_CORE_H_INCLUDED
#define _ULTRASONIC_CORE_H_INCLUDED

#include "chu_init.h"

/**
 * @brief Ultrasonic sensor core driver class
 * 
 * Controls one ultrasonic distance sensor (RCWL-1601).
 * Hardware autonomously handles timing and distance calculation.
 */
class UltrasonicCore {
public:
   /**
    * @brief Constructor - initializes ultrasonic sensor core
    * @param core_base_addr Base address of the sensor core slot
    */
   UltrasonicCore(uint32_t core_base_addr);
   
   /**
    * @brief Destructor
    */
   ~UltrasonicCore();

   /**
    * @brief Trigger a distance measurement
    * 
    * Starts the hardware measurement process:
    *   1. Hardware sends 10us trigger pulse
    *   2. Hardware waits for echo
    *   3. Hardware measures echo pulse width
    *   4. Hardware calculates distance
    * 
    * Non-blocking - returns immediately.
    * Use isBusy() to check completion.
    */
   void trigger();

   /**
    * @brief Check if sensor is currently measuring
    * @return true if measurement in progress, false if ready
    */
   bool isBusy();

   /**
    * @brief Wait for current measurement to complete
    * 
    * Blocking function - polls busy flag until measurement done.
    * Use after trigger() before reading distance.
    */
   void waitUntilReady();

   /**
    * @brief Read the measured distance
    * @return Distance in millimeters (0-4000 typical range)
    *         Returns 0xFFFFFFFF if measurement timed out
    * 
    * Call after trigger() and waitUntilReady().
    */
   uint32_t readDistance();

   /**
    * @brief Read the raw echo time
    * @return Echo pulse width in microseconds
    * 
    * Advanced function - normally just use readDistance().
    * Useful for debugging or custom distance calculations.
    */
   uint32_t readEchoTime();

   /**
    * @brief Perform complete measurement cycle
    * @return Distance in millimeters
    * 
    * Convenience function that does everything:
    *   1. Triggers measurement
    *   2. Waits for completion
    *   3. Returns distance
    * 
    * Blocking - takes ~20-40ms depending on distance.
    */
   uint32_t getDistance();

private:
   uint32_t base_addr;  ///< Base address of this sensor core

   // Register offsets
   enum {
      CONTROL_REG = 0,   ///< Control/Status register
      ECHO_TIME_REG = 1, ///< Echo time register (microseconds)
      DISTANCE_REG = 2   ///< Distance register (millimeters)
   };
};

#endif // _ULTRASONIC_CORE_H_INCLUDED
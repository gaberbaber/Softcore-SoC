/*****************************************************************//**
 * @file main.cpp
 *
 * @brief Ultrasonic Theremin - Extended Range for Song
 *
 * @description
 * Pitch mapping with full octave range:
 *   - 2 inches (51mm) = D5 (587 Hz) - highest note
 *   - 8 inches (203mm) = D4 (294 Hz) - lowest note
 *   - Full octave range
 *
 * @author Gabe Dickson
 *********************************************************************/

#include "chu_init.h"
#include "gpio_cores.h"
#include "ultrasonic_core.h"
#include "ddfs_core.h"

// Theremin configuration - Full octave D4 to D5
const uint32_t BASE_FREQ = 294;        // D4 as the LOW note
const uint32_t HIGH_FREQ = 587;        // D5 as the HIGH note (one octave up)
const uint32_t PITCH_MIN_DIST = 51;    // 2 inches = highest pitch
const uint32_t PITCH_MAX_DIST = 203;   // 8 inches = lowest pitch

const uint32_t VOLUME_MIN_DIST = 51;
const uint32_t VOLUME_MAX_DIST = 203;

const uint32_t UPDATE_INTERVAL_MS = 50;

/**
 * Map distance to frequency (D4 to D5 - full octave)
 */
uint32_t mapDistanceToFrequency(uint32_t distance) {
   if (distance < PITCH_MIN_DIST) distance = PITCH_MIN_DIST;
   if (distance > PITCH_MAX_DIST) distance = PITCH_MAX_DIST;
   
   // Full octave: 2x frequency relationship
   uint32_t dist_offset = distance - PITCH_MIN_DIST;
   uint32_t dist_range = PITCH_MAX_DIST - PITCH_MIN_DIST;
   uint32_t freq_range = HIGH_FREQ - BASE_FREQ;
   
   uint32_t freq_delta = (dist_offset * freq_range) / dist_range;
   uint32_t frequency = HIGH_FREQ - freq_delta;
   
   return frequency;
}

float mapDistanceToVolume(uint32_t distance) {
   if (distance < VOLUME_MIN_DIST) distance = VOLUME_MIN_DIST;
   if (distance > VOLUME_MAX_DIST) distance = VOLUME_MAX_DIST;
   
   uint32_t dist_range = VOLUME_MAX_DIST - VOLUME_MIN_DIST;
   float volume = 1.0f - ((float)(distance - VOLUME_MIN_DIST) / (float)dist_range);
   
   return volume;
}

int main() {
   GpoCore led(get_slot_addr(BRIDGE_BASE, S2_LED));
   UltrasonicCore pitch_sensor(get_slot_addr(BRIDGE_BASE, S3_US1));
   UltrasonicCore volume_sensor(get_slot_addr(BRIDGE_BASE, S4_US2));
   DdfsCore tone_gen(get_slot_addr(BRIDGE_BASE, S5_DDFS));
   
   tone_gen.init();
   
   led.write(0xFFFF);
   sleep_ms(500);
   led.write(0x0000);
   
   while (1) {
      uint32_t pitch_distance = pitch_sensor.getDistance();
      uint32_t volume_distance = volume_sensor.getDistance();
      
      uint32_t led_pattern = 0;
      
      if (pitch_distance != 0xFFFFFFFF) {
         uint32_t frequency = mapDistanceToFrequency(pitch_distance);
         tone_gen.set_carrier_freq(frequency);
         
         uint32_t pitch_level = pitch_distance / 25;
         if (pitch_level > 8) pitch_level = 8;
         for (uint32_t i = 0; i < pitch_level; i++) {
            led_pattern |= (1 << i);
         }
      }
      
      if (volume_distance != 0xFFFFFFFF) {
         float envelope = mapDistanceToVolume(volume_distance);
         tone_gen.set_env(envelope);
         
         uint32_t vol_level = volume_distance / 25;
         if (vol_level > 8) vol_level = 8;
         for (uint32_t i = 0; i < vol_level; i++) {
            led_pattern |= (1 << (i + 8));
         }
      } else {
         tone_gen.set_env(0.0f);
      }
      
      led.write(led_pattern);
      sleep_ms(UPDATE_INTERVAL_MS);
   }
   
   return 0;
}
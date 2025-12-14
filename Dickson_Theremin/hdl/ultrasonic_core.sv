// ultrasonic_core.sv
// Ultrasonic sensor controller for RCWL-1601
// Measures distance by timing echo pulse width

module ultrasonic_core (
   input  logic clk,
   input  logic reset,
   // Slot interface
   input  logic cs,
   input  logic read,
   input  logic write,
   input  logic [4:0] addr,
   input  logic [31:0] wr_data,
   output logic [31:0] rd_data,
   // External sensor interface
   output logic trig,
   input  logic echo
);

   // Register map:
   // 0x00: Control register (write: bit 0 = trigger, read: bit 0 = busy)
   // 0x01: Echo time in microseconds (read-only)
   // 0x02: Distance in mm (read-only)

   // State machine
   typedef enum {IDLE, TRIG_HIGH, TRIG_LOW, WAIT_ECHO, MEASURE_ECHO, DONE} state_type;
   state_type state_reg, state_next;
   
   // Registers
   logic [31:0] echo_time_reg, echo_time_next;
   logic [31:0] distance_reg, distance_next;
   logic trigger_req;
   logic busy;
   
   // Timing counters
   logic [15:0] trig_counter_reg, trig_counter_next;
   logic [31:0] echo_counter_reg, echo_counter_next;
   
   // Clock divider for microsecond timing (100 MHz / 100 = 1 MHz = 1 us)
   logic [6:0] us_tick_counter_reg, us_tick_counter_next;
   logic us_tick;
   
   // Generate 1 MHz tick (1 microsecond)
   assign us_tick = (us_tick_counter_reg == 99);
   
   always_ff @(posedge clk, posedge reset) begin
      if (reset) begin
         us_tick_counter_reg <= 0;
      end else begin
         us_tick_counter_reg <= us_tick_counter_next;
      end
   end
   
   always_comb begin
      if (us_tick)
         us_tick_counter_next = 0;
      else
         us_tick_counter_next = us_tick_counter_reg + 1;
   end

   // State and data registers
   always_ff @(posedge clk, posedge reset) begin
      if (reset) begin
         state_reg <= IDLE;
         echo_time_reg <= 0;
         distance_reg <= 0;
         trig_counter_reg <= 0;
         echo_counter_reg <= 0;
      end else begin
         state_reg <= state_next;
         echo_time_reg <= echo_time_next;
         distance_reg <= distance_next;
         trig_counter_reg <= trig_counter_next;
         echo_counter_reg <= echo_counter_next;
      end
   end

   // Trigger request from CPU
   assign trigger_req = cs && write && (addr == 5'd0) && wr_data[0];

   // FSM for ultrasonic measurement
   always_comb begin
      // Default values
      state_next = state_reg;
      echo_time_next = echo_time_reg;
      distance_next = distance_reg;
      trig_counter_next = trig_counter_reg;
      echo_counter_next = echo_counter_reg;
      trig = 1'b0;
      busy = 1'b1;
      
      case (state_reg)
         IDLE: begin
            busy = 1'b0;
            echo_counter_next = 0;
            trig_counter_next = 0;
            if (trigger_req) begin
               state_next = TRIG_HIGH;
            end
         end
         
         TRIG_HIGH: begin
            // Send 10us trigger pulse
            trig = 1'b1;
            if (us_tick) begin
               trig_counter_next = trig_counter_reg + 1;
               if (trig_counter_reg >= 10) begin  // 10 us pulse
                  state_next = TRIG_LOW;
                  trig_counter_next = 0;
               end
            end
         end
         
         TRIG_LOW: begin
            // Wait a bit after trigger
            if (us_tick) begin
               trig_counter_next = trig_counter_reg + 1;
               if (trig_counter_reg >= 5) begin  // 5 us delay
                  state_next = WAIT_ECHO;
                  trig_counter_next = 0;
               end
            end
         end
         
         WAIT_ECHO: begin
            // Wait for echo to go high (with timeout)
            if (echo) begin
               state_next = MEASURE_ECHO;
               echo_counter_next = 0;
            end else if (us_tick) begin
               echo_counter_next = echo_counter_reg + 1;
               // Timeout after 30ms (max range ~5m)
               if (echo_counter_reg >= 30000) begin
                  echo_time_next = 32'hFFFFFFFF;  // Indicate timeout
                  distance_next = 32'hFFFFFFFF;
                  state_next = DONE;
               end
            end
         end
         
         MEASURE_ECHO: begin
            // Measure echo pulse width
            if (!echo) begin
               // Echo pulse ended, calculate distance
               echo_time_next = echo_counter_reg;
               // Distance (mm) = (echo_time_us * 343 m/s) / 2
               // Distance (mm) = (echo_time_us * 0.343 mm/us) / 2
               // Distance (mm) = echo_time_us * 0.1715
               // Approximate: distance_mm ≈ (echo_time_us * 343) / 2000
               distance_next = (echo_counter_reg * 343) >> 11;  // Divide by 2048 ≈ 2000
               state_next = DONE;
            end else if (us_tick) begin
               echo_counter_next = echo_counter_reg + 1;
               // Timeout if echo too long
               if (echo_counter_reg >= 30000) begin
                  echo_time_next = 32'hFFFFFFFF;
                  distance_next = 32'hFFFFFFFF;
                  state_next = DONE;
               end
            end
         end
         
         DONE: begin
            // Measurement complete, return to idle
            state_next = IDLE;
         end
         
         default: state_next = IDLE;
      endcase
   end

   // Read multiplexing
   always_comb begin
      rd_data = 32'h0;
      if (cs && read) begin
         case (addr)
            5'd0: rd_data = {31'h0, busy};           // Status
            5'd1: rd_data = echo_time_reg;           // Echo time (us)
            5'd2: rd_data = distance_reg;            // Distance (mm)
            default: rd_data = 32'h0;
         endcase
      end
   end

endmodule
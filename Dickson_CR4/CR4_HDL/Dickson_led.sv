`timescale 1ns / 1ps
// dickson_led.sv
// Simple single LED blinker module
// Takes a rate in milliseconds and blinks one LED at that rate

module dickson_led
(
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] rate_ms,    // Blink rate in milliseconds
    output logic        led          // LED output (1 = on, 0 = off)
);

    // 100 MHz clock 
    // 1 ms = 100,000 clock cycles
    localparam int CLK_FREQ_MHZ = 100;
    localparam int CYCLES_PER_MS = CLK_FREQ_MHZ * 1000;
    
    logic [31:0] counter;
    logic [31:0] rate_cycles;
    
    // Convert milliseconds to clock cycles
    assign rate_cycles = rate_ms * CYCLES_PER_MS;
    
    // Counter and LED toggle logic
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            led <= 0;
        end
        else begin
            if (rate_ms == 0) begin
                // If rate is 0, turn LED off
                led <= 0;
                counter <= 0;
            end
            else if (counter >= rate_cycles - 1) begin
                // Toggle LED and reset counter when rate is reached
                counter <= 0;
                led <= ~led;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
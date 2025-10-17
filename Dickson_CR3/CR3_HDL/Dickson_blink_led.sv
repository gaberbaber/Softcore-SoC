`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2025 03:45:55 PM
// Design Name: 
// Module Name: Dickson_blink_led
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Dickson_blink_led#( parameter W = 4 // number of LEDs to control 
    )(
    input  logic clk,
    input  logic reset,
    // slot interface
    input  logic cs,
    input  logic read,
    input  logic write,
    input  logic [4:0] addr,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data,
    // external port    
    output logic [W-1:0] led_out
   );
   
   // Registers to hold blinking intervals 
   logic [15:0] blink_interval [W-1:0];
   // Counters for each LED
   logic [31:0] counter [W-1:0];
   // LED state
   logic [W-1:0] led_state;
   parameter CLEAR = 0;
   // Register interface
   always_ff @(posedge clk or posedge reset) begin
       if (reset) begin
           for (int i = 0; i < W; i++) begin
               blink_interval[i] <= CLEAR;
               counter[i] <= 0;
               led_state[i] <= 0;
           end
       end else if (cs && write) begin
           // Write the blink rate to the selected LED
           if (addr < W)
               blink_interval[addr] <= wr_data[15:0];
       end
   end
   // Blinking logic
   genvar i;
   generate
       for (i = 0; i < W; i = i + 1) begin : led_blink
           always_ff @(posedge clk or posedge reset) begin
               if (reset) begin
                   counter[i] <= 0;
                   led_state[i] <= 0;
               end else begin
                   if (counter[i] >= blink_interval[i] * 100000) begin
                       counter[i] <= 0;
                       led_state[i] <= ~led_state[i];
                   end else begin
                       counter[i] <= counter[i] + 1;
                   end
               end
           end
       end
   endgenerate
   // LED output
   assign led_out = led_state;
endmodule
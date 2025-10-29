`timescale 1ns / 1ps
// dickson_blink_led.sv
// Wrapper module that instantiates 4 dickson_led modules
// Follows the same interface pattern as chu_gpo

module Dickson_blink_led
   #(parameter W = 4)  // number of LEDs (4)
   (
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

   // declaration
   logic [15:0] rate_reg [3:0];  // Four 16-bit registers for blink rates
   logic wr_en;
   
   // body
   // Register write logic - stores blink rate when written to
   always_ff @(posedge clk, posedge reset)
      if (reset) begin
         rate_reg[0] <= 16'd0;
         rate_reg[1] <= 16'd0;
         rate_reg[2] <= 16'd0;
         rate_reg[3] <= 16'd0;
      end
      else if (wr_en) begin
         // Use addr[2:1] to select which of the 4 registers to write
         // addr[4:0] comes from reg_addr_array which is 5 bits
         case (addr)
            5'd0: rate_reg[0] <= wr_data;
            5'd1: rate_reg[1] <= wr_data;
            5'd2: rate_reg[2] <= wr_data;
            5'd3: rate_reg[3] <= wr_data;
         endcase
      end
   
   // decoding logic 
   assign wr_en = cs && write;
   
   // slot read interface - read back the rate registers
   always_comb begin
      case (addr[2:1])
         2'd0: rd_data = {16'd0, rate_reg[0]};
         2'd1: rd_data = {16'd0, rate_reg[1]};
         2'd2: rd_data = {16'd0, rate_reg[2]};
         2'd3: rd_data = {16'd0, rate_reg[3]};
         default: rd_data = 32'd0;
      endcase
   end
   
   // Instantiate 4 LED blinker modules
   dickson_led led0_inst (
      .clk(clk),
      .reset(reset),
      .rate_ms(rate_reg[0]),
      .led(led_out[0])
   );
   
   dickson_led led1_inst (
      .clk(clk),
      .reset(reset),
      .rate_ms(rate_reg[1]),
      .led(led_out[1])
   );
   
   dickson_led led2_inst (
      .clk(clk),
      .reset(reset),
      .rate_ms(rate_reg[2]),
      .led(led_out[2])
   );
   
   dickson_led led3_inst (
      .clk(clk),
      .reset(reset),
      .rate_ms(rate_reg[3]),
      .led(led_out[3])
   );

endmodule
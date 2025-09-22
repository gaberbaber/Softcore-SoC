`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09/22/2025
// Design Name: Reaction Timer
// Module Name: reaction_timer_tb
// Description: Simple TB for reaction_timer_top (rotator_tb style).
//              - 100 MHz clock
//              - Active-low reset (held low, then released once)
//              - One normal run, then one false-start run
//////////////////////////////////////////////////////////////////////////////////

module reaction_timer_tb;

  // DUT signals
  logic       clk;
  logic       rst;          // active-low
  logic       btn_clear;
  logic       btn_start;
  logic       btn_stop;
  logic       stim_led;     
  logic [7:0] an;
  logic [7:0] sseg;

  // DUT (override clock freq)
  // reaction_timer_top #(.CLK_FREQ_HZ(100_000)) dut ( // <- faster sim
  reaction_timer_top dut (
    .clk       (clk),
    .rst       (rst),
    .btn_clear (btn_clear),
    .btn_start (btn_start),
    .btn_stop  (btn_stop),
    .stim_led  (stim_led),
    .an        (an),
    .sseg      (sseg)
  );

  // clock: 100 MHz
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // stimulus
  initial begin
    // init
    rst        = 1'b0;   // hold reset asserted (active-low)
    btn_clear  = 1'b0;
    btn_start  = 1'b0;
    btn_stop   = 1'b0;

    // release reset
    #20 rst = 1'b1;

    // WELCOME → press clear (optional; keeps style consistent)
    #20 btn_clear = 1'b1; #10 btn_clear = 1'b0;

    // -------- Run 1: normal reaction --------
    #40 btn_start = 1'b1; #10 btn_start = 1'b0;   // start
    @(posedge stim_led);                          // wait for GO
    #50;                                      // human delay (adjust as you like)
    btn_stop = 1'b1; #10 btn_stop = 1'b0;         // stop
    #100;

    // -------- Run 2: false start (stop before LED) --------
    btn_clear = 1'b1; #10 btn_clear = 1'b0;       // back to WELCOME/ARM
    #40 btn_start = 1'b1; #10 btn_start = 1'b0;   // start
    #20 btn_stop = 1'b1; #10 btn_stop = 1'b0; // false stop
    #200;

    $finish;
  end

endmodule

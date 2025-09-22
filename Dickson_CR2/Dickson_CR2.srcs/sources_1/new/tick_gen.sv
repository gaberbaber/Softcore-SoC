`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simple tick generator: raises tick for 1 clk every 1/TICK_HZ seconds
//////////////////////////////////////////////////////////////////////////////////

module tick_gen #(
  parameter int CLK_FREQ_HZ = 100_000_000,
  parameter int TICK_HZ     = 1000
)(
  input  logic clk,
  input  logic rst,   // active-low
  output logic tick
);

  localparam int COUNT_MAX = CLK_FREQ_HZ / TICK_HZ - 1;

  //signals
  logic [$clog2(COUNT_MAX+1)-1:0] cnt_q, cnt_next;      //clog2()=ceil(log2())=n bits for 0-max_count

  //register
  always_ff @(posedge clk, negedge rst) begin
    if (!rst)
      cnt_q <= '0;
    else
      cnt_q <= cnt_next;
  end

  //next-state
  always_comb begin
    if (cnt_q == COUNT_MAX)
      cnt_next = '0;
    else
      cnt_next = cnt_q + 1;
  end

  // output pulse
  assign tick = (cnt_q == COUNT_MAX);

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 16-bit maximal LFSR (x^16 + x^14 + x^13 + x^11 + 1)
// Runs continuously; seed on reset (active-low)
//////////////////////////////////////////////////////////////////////////////////

module lfsr16(
  input  logic       clk,
  input  logic       rst,   // active-low
  output logic [15:0] q
);
  //signals
  logic feedback;

  assign feedback = q[15] ^ q[13] ^ q[12] ^ q[10];

  //register
  always_ff @(posedge clk, negedge rst) begin
    if (!rst)
      q <= 16'hACE1;  // non-zero seed
    else
      q <= {q[14:0], feedback};
  end

endmodule

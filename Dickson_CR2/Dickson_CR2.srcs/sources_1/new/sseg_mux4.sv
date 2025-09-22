`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 4-digit seven-seg scanner (active-low an & segments)
// Inputs are nibbles 0..9 plus special tokens: H=0xH, I=0xI, F=0xF(blank)
// dp is off by default.
//////////////////////////////////////////////////////////////////////////////////

module sseg_mux4(
  input  logic       clk,
  input  logic       rst,        // active-low
  input  logic       tick_scan,  // ~4 kHz tick
  input  logic [3:0] d3, d2, d1, d0,
  output logic [7:0] an,         // active-low digit selects
  output logic [7:0] sseg        // {dp,g,f,e,d,c,b,a}, active-low
);

  //==========================================================================
  // signals
  //==========================================================================
  logic [1:0] sel_q;
  logic [3:0] cur_nib;

  //==========================================================================
  // digit select (scan)
  //==========================================================================
  //register
  always_ff @(posedge clk, negedge rst) begin
    if (!rst)
      sel_q <= 2'd0;
    else if (tick_scan)
      sel_q <= sel_q + 2'd1;
  end

  // anodes (active-low) + current nibble
  always_comb begin
    unique case (sel_q)
      2'd0: begin an = 8'b1111_1110; cur_nib = d0; end
      2'd1: begin an = 8'b1111_1101; cur_nib = d1; end
      2'd2: begin an = 8'b1111_1011; cur_nib = d2; end
      2'd3: begin an = 8'b1111_0111; cur_nib = d3; end
    endcase
  end

  //==========================================================================
  // glyphs (active-low; 0 lights a segment). Edit if your board differs.
  //==========================================================================
  // Digits 0..9
  localparam logic [7:0] G0 = 8'b1100_0000;
  localparam logic [7:0] G1 = 8'b1111_1001;
  localparam logic [7:0] G2 = 8'b1010_0100;
  localparam logic [7:0] G3 = 8'b1011_0000;
  localparam logic [7:0] G4 = 8'b1001_1001;
  localparam logic [7:0] G5 = 8'b1001_0010;
  localparam logic [7:0] G6 = 8'b1000_0010;
  localparam logic [7:0] G7 = 8'b1111_1000;
  localparam logic [7:0] G8 = 8'b1000_0000;
  localparam logic [7:0] G9 = 8'b1001_0000;

  // Specials
  localparam logic [7:0] GH = 8'b1000_1001; // "H"
  localparam logic [7:0] GI = 8'b1111_1001; // "I" (stylized)
  localparam logic [7:0] GB = 8'b1111_1111; // BLANK

  // Nibble codes
  localparam logic [3:0] NIB_H     = 4'd10;
  localparam logic [3:0] NIB_I     = 4'd11;
  localparam logic [3:0] NIB_BLANK = 4'hF;

  function automatic logic [7:0] map_glyph(input logic [3:0] nib);
    case (nib)
      4'd0:  map_glyph = G0;
      4'd1:  map_glyph = G1;
      4'd2:  map_glyph = G2;
      4'd3:  map_glyph = G3;
      4'd4:  map_glyph = G4;
      4'd5:  map_glyph = G5;
      4'd6:  map_glyph = G6;
      4'd7:  map_glyph = G7;
      4'd8:  map_glyph = G8;
      4'd9:  map_glyph = G9;
      NIB_H: map_glyph = GH;
      NIB_I: map_glyph = GI;
      default: map_glyph = GB; // 4'hF or anything else → blank
    endcase
  endfunction

  always_comb begin
    sseg = map_glyph(cur_nib);
  end

endmodule

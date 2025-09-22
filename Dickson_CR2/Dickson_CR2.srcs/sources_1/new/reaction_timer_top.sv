`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2025
// Design Name: Reaction Timer (Chu 6.5.6)
// Module Name: reaction_timer_top
// Description: Eye-hand reaction timer per ASMD spec (WELCOME, ARMED, FAILURE,
//              GO, TIMEOUT, FINISH). Active-low async reset like prior lab.
// 
// Dependencies: tick_gen.sv, lfsr16.sv, sseg_mux4.sv
// 
// Revision:
// Revision 0.03 - Sticky rnd_load_req; ARMED now waits reliably
// 0.02 - Single-driver fixes for rnd_ms_cnt and ms_cnt
// 
//////////////////////////////////////////////////////////////////////////////////

module reaction_timer_top #(
  parameter int CLK_FREQ_HZ = 100_000_000
)(
  input  logic        clk,
  input  logic        rst,          // active-low async
  input  logic        btn_clear,    // async pushbuttons
  input  logic        btn_start,
  input  logic        btn_stop,
  output logic        stim_led,     // stimulus LED
  output logic [7:0]  an,           // 7-seg anodes (active-low: 0=on)
  output logic [7:0]  sseg          // {dp,g,f,e,d,c,b,a} (active-low: 0=on)
);

  //==========================================================================
  // signals
  //==========================================================================
  // ticks
  logic tick_1ms;
  logic tick_scan;  // ~4 kHz digit scan

  // button sync + edges
  logic clr_q, clr_qq, start_q, start_qq, stop_q, stop_qq;
  logic clr_pe, start_pe, stop_pe;

  // LFSR / random
  logic [15:0] lfsr_q;
  logic [13:0] rnd_ms_load;   // 2000 to 15000
  logic [13:0] rnd_ms_cnt;    // down-counter during ARMED
  logic        rnd_done;
  logic        rnd_loaded;
  logic        rnd_load_req;  // sticky request until serviced on tick_1ms

  // ms counter during GO
  logic [13:0] ms_cnt;        // up to 9999; clamp
  logic        ms_tick_en;    // asserted in GO

  // output mux digits (0..9, plus special codes)
  logic [3:0] dig3, dig2, dig1, dig0;

  // nibble codes for glyphs
  localparam logic [3:0] NIB_H     = 4'd10;
  localparam logic [3:0] NIB_I     = 4'd11;
  localparam logic [3:0] NIB_BLANK = 4'hF;

  // FSM
  typedef enum logic [2:0] {
    WELCOME = 3'd0,
    ARMED   = 3'd1,
    FAILURE = 3'd2,
    GO      = 3'd3,
    TIMEOUT = 3'd4,
    FINISH  = 3'd5
  } state_t;

  state_t state_reg, state_next;

  // latched result
  logic [13:0] result_ms, result_next;

  // control strobes from next-state logic
  logic ms_tick_en_next;
  logic load_random;
  logic clr_ms;

  // decimal decode temps (declare at top for Vivado)
  int thousands, hundreds, tens, ones;

  //==========================================================================
  // clocks/ticks
  //==========================================================================
  tick_gen #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .TICK_HZ(1000)) u_tick_1ms (
    .clk(clk), .rst(rst), .tick(tick_1ms)
  );

  tick_gen #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .TICK_HZ(4000)) u_tick_scan (
    .clk(clk), .rst(rst), .tick(tick_scan)
  );

  //==========================================================================
  // button sync + rising-edge detect
  //==========================================================================
  always_ff @(posedge clk, negedge rst) begin
    if (!rst) begin
      {clr_q,   clr_qq}   <= '0;
      {start_q, start_qq} <= '0;
      {stop_q,  stop_qq}  <= '0;
    end else begin
      clr_q   <= btn_clear;   clr_qq   <= clr_q;
      start_q <= btn_start;   start_qq <= start_q;
      stop_q  <= btn_stop;    stop_qq  <= stop_q;
    end
  end

  assign clr_pe   =  clr_q & ~clr_qq;
  assign start_pe =  start_q & ~start_qq;
  assign stop_pe  =  stop_q & ~stop_qq;

  //==========================================================================
  // LFSR 
  //==========================================================================
  lfsr16 u_lfsr16 (.clk(clk), .rst(rst), .q(lfsr_q));

  function automatic [13:0] mod13001(input logic [15:0] x);
    mod13001 = x % 14'd13001;
  endfunction

  //==========================================================================
  // ms up-counter (GO) 
  //   - counts while ms_tick_en
  //   - clears on clr_ms (entry to GO)
  //==========================================================================
  always_ff @(posedge clk, negedge rst) begin
    if (!rst) begin
      ms_cnt <= 14'd0;
    end else if (tick_1ms) begin
      if (clr_ms) begin
        ms_cnt <= 14'd0;
      end else if (ms_tick_en && ms_cnt < 14'd9999) begin
        ms_cnt <= ms_cnt + 14'd1;
      end
      // else: hold
    end
  end

  //==========================================================================
  // rnd_load_req latch - make load_random sticky until tick_1ms services it
  //==========================================================================
  always_ff @(posedge clk, negedge rst) begin
    if (!rst) begin
      rnd_load_req <= 1'b0;
    end else begin
      if (load_random)
        rnd_load_req <= 1'b1;
      if (tick_1ms && rnd_load_req)
        rnd_load_req <= 1'b0;
    end
  end

  //==========================================================================
  // random load + down-counter (ARMED)
  //   - on rnd_load_req at a 1ms tick: load 2000 to 15000 ms, set rnd_loaded
  //   - while ARMED and >0, decrement by 1 each ms
  //==========================================================================
  always_ff @(posedge clk, negedge rst) begin
    if (!rst) begin
      rnd_ms_load <= 14'd2000;
      rnd_ms_cnt  <= 14'd0;
      rnd_loaded  <= 1'b0;
    end else if (tick_1ms) begin
      if (rnd_load_req) begin
        logic [13:0] rnd_val;
        rnd_val     = 14'd2000 + mod13001(lfsr_q); // 2000 to 15000
        rnd_ms_load <= rnd_val;
        rnd_ms_cnt  <= rnd_val;
        rnd_loaded  <= 1'b1;
      end else if (state_reg == ARMED && rnd_ms_cnt != 14'd0) begin
        rnd_ms_cnt  <= rnd_ms_cnt - 14'd1;
      end
      // Clear the loaded flag when we leave ARMED
      if (state_reg != ARMED)
        rnd_loaded <= 1'b0;
    end
  end

  assign rnd_done = (rnd_ms_cnt == 14'd0);

  //==========================================================================
  // FSM: state, outputs, and control
  //==========================================================================
  // register
  always_ff @(posedge clk, negedge rst) begin
    if (!rst)
      state_reg <= WELCOME;
    else
      state_reg <= state_next;
  end

  // next-state + control + outputs
  // defaults
  logic [3:0] d3_next, d2_next, d1_next, d0_next;

  always_comb begin
    // defaults
    state_next       = state_reg;
    ms_tick_en_next  = 1'b0;
    load_random      = 1'b0;
    clr_ms           = 1'b0;
    result_next      = result_ms;
    stim_led         = 1'b0;

    d3_next = NIB_BLANK; d2_next = NIB_BLANK; d1_next = NIB_BLANK; d0_next = NIB_BLANK;

    // global clear → WELCOME
    if (clr_pe) begin
      state_next      = WELCOME;
      ms_tick_en_next = 1'b0;
      d3_next = NIB_H; d2_next = NIB_I; d1_next = NIB_BLANK; d0_next = NIB_BLANK;
    end
    else case (state_reg)
      //----------------------------------------------------------------------
      WELCOME: begin
        stim_led = 1'b0;
        d3_next = NIB_H; d2_next = NIB_I; d1_next = NIB_BLANK; d0_next = NIB_BLANK;
        if (start_pe) begin
          state_next  = ARMED;
          load_random = 1'b1;   // one-cycle pulse (captured by rnd_load_req)
        end
      end

      //----------------------------------------------------------------------
      ARMED: begin
        stim_led = 1'b0;
        d3_next = NIB_BLANK; d2_next = NIB_BLANK; d1_next = NIB_BLANK; d0_next = NIB_BLANK;

        if (stop_pe) begin
          state_next  = FAILURE;
          result_next = 14'd9999;
        end else if (rnd_loaded && rnd_done) begin
          state_next  = GO;
          clr_ms      = 1'b1;
        end
      end

      //----------------------------------------------------------------------
      GO: begin
        stim_led        = 1'b1;
        ms_tick_en_next = 1'b1;

        // live ms count
        thousands = (ms_cnt/1000) % 10;
        hundreds  = (ms_cnt/100)  % 10;
        tens      = (ms_cnt/10)   % 10;
        ones      = (ms_cnt/1)    % 10;

        d3_next = thousands[3:0];
        d2_next = hundreds [3:0];
        d1_next = tens     [3:0];
        d0_next = ones     [3:0];

        if (stop_pe) begin
          state_next  = FINISH;
          result_next = ms_cnt;
        end else if (ms_cnt >= 14'd1000) begin
          state_next  = TIMEOUT;
          result_next = 14'd1000;
        end
      end

      //----------------------------------------------------------------------
      TIMEOUT: begin
        stim_led = 1'b1;
        d3_next = 4'd1; d2_next = 4'd0; d1_next = 4'd0; d0_next = 4'd0;
        if (start_pe) begin
          state_next  = ARMED;
          load_random = 1'b1;
        end
      end

      //----------------------------------------------------------------------
      FAILURE: begin
        stim_led = 1'b0;
        d3_next = 4'd9; d2_next = 4'd9; d1_next = 4'd9; d0_next = 4'd9;
        if (start_pe) begin
          state_next  = ARMED;
          load_random = 1'b1;
        end
      end

      //----------------------------------------------------------------------
      FINISH: begin
        stim_led = 1'b1;

        thousands = (result_ms/1000) % 10;
        hundreds  = (result_ms/100)  % 10;
        tens      = (result_ms/10)   % 10;
        ones      = (result_ms/1)    % 10;

        d3_next = thousands[3:0];
        d2_next = hundreds [3:0];
        d1_next = tens     [3:0];
        d0_next = ones     [3:0];

        if (start_pe) begin
          state_next  = ARMED;
          load_random = 1'b1;
        end
      end

      default: begin
        state_next = WELCOME;
      end
    endcase
  end

  // result latch
  always_ff @(posedge clk, negedge rst) begin
    if (!rst)
      result_ms <= 14'd0;
    else
      result_ms <= result_next;
  end

  // ms_tick_en reg
  always_ff @(posedge clk, negedge rst) begin
    if (!rst)
      ms_tick_en <= 1'b0;
    else
      ms_tick_en <= ms_tick_en_next;
  end

  // digit regs
  always_ff @(posedge clk, negedge rst) begin
    if (!rst) begin
      dig3 <= NIB_H; dig2 <= NIB_I; dig1 <= NIB_BLANK; dig0 <= NIB_BLANK;
    end else begin
      dig3 <= d3_next;
      dig2 <= d2_next;
      dig1 <= d1_next;
      dig0 <= d0_next;
    end
  end

  //==========================================================================
  // 7-seg MUX (active-low)
  //==========================================================================
  sseg_mux4 u_sseg (
    .clk(clk),
    .rst(rst),
    .tick_scan(tick_scan),
    .d3(dig3), .d2(dig2), .d1(dig1), .d0(dig0),
    .an(an),
    .sseg(sseg)
  );

endmodule

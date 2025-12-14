// mcs_top_theremin.sv
// Top-level module for ultrasonic theremin

module mcs_top_theremin (
   input  logic clk,
   input  logic reset_n,
   // Switches and LEDs
   input  logic [15:0] sw,
   output logic [15:0] led,
   // Ultrasonic sensor 1 (pitch) - Pmod JA
   output logic ja_trig,      // JA Pin 2 (C17)
   input  logic ja_echo,      // JA Pin 3 (D18)
   // Ultrasonic sensor 2 (volume) - Pmod JB
   output logic jb_trig,      // JB Pin 2 (D14)
   input  logic jb_echo,      // JB Pin 3 (F16)
   // PWM audio output
   output logic audio_pwm,     // AUD_PWM (A11) - Audio Jack J8
   output logic audio_on
);

   // Signal declarations
   logic clk_100M;
   logic reset_sys;
   
   // MicroBlaze MCS IO bus
   logic io_addr_strobe;
   logic io_read_strobe;
   logic io_write_strobe;
   logic [3:0] io_byte_enable;
   logic [31:0] io_address;
   logic [31:0] io_write_data;
   logic [31:0] io_read_data;
   logic io_ready;
   
   // FPro bus  
   logic fp_mmio_cs;
   logic fp_wr;
   logic fp_rd;
   logic [20:0] fp_addr;
   logic [31:0] fp_wr_data;
   logic [31:0] fp_rd_data;

   // Clock and reset
   assign clk_100M = clk;
   assign reset_sys = !reset_n;

   // =====================================================================
   // MicroBlaze MCS
   // =====================================================================
   cpu cpu_unit (
      .Clk(clk_100M),
      .Reset(reset_sys),
      .IO_addr_strobe(io_addr_strobe),
      .IO_address(io_address),
      .IO_byte_enable(io_byte_enable),
      .IO_read_data(io_read_data),
      .IO_read_strobe(io_read_strobe),
      .IO_ready(io_ready),
      .IO_write_data(io_write_data),
      .IO_write_strobe(io_write_strobe)
   );

   // =====================================================================
   // FPro bus bridge (combinational - no clock/reset)
   // =====================================================================
   chu_mcs_bridge bridge_unit (
      // MCS interface
      .io_addr_strobe(io_addr_strobe),
      .io_read_strobe(io_read_strobe),
      .io_write_strobe(io_write_strobe),
      .io_byte_enable(io_byte_enable),
      .io_address(io_address),
      .io_write_data(io_write_data),
      .io_read_data(io_read_data),
      .io_ready(io_ready),
      // FPro interface
      .fp_video_cs(),  // Not used in theremin
      .fp_mmio_cs(fp_mmio_cs),
      .fp_wr(fp_wr),
      .fp_rd(fp_rd),
      .fp_addr(fp_addr),
      .fp_wr_data(fp_wr_data),
      .fp_rd_data(fp_rd_data)
   );

   // =====================================================================
   // MMIO subsystem
   // =====================================================================
   mmio_sys_theremin mmio_unit (
      .clk(clk_100M),
      .reset(reset_sys),
      // FPro bus
      .mmio_cs(fp_mmio_cs),
      .mmio_wr(fp_wr),
      .mmio_rd(fp_rd),
      .mmio_addr(fp_addr),
      .mmio_wr_data(fp_wr_data),
      .mmio_rd_data(fp_rd_data),
      // Ultrasonic sensors
      .us1_trig(ja_trig),
      .us1_echo(ja_echo),
      .us2_trig(jb_trig),
      .us2_echo(jb_echo),
      // PWM audio
      .audio_pwm(audio_pwm),
      // Switches and LEDs
      .sw(sw),
      .led(led)
   );
   
   // Enable audio amplifier (tie high)
   assign audio_on = 1'b1;

endmodule
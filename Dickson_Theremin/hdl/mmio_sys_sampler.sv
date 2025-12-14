// mmio_sys_theremin.sv
// Streamlined MMIO subsystem for ultrasonic theremin
// Based on sampler system but with only necessary cores

`include "chu_io_map.svh"

module mmio_sys_theremin
#(
  parameter N_SW = 16,
            N_LED = 16
)
(
   input  logic clk,
   input  logic reset,
   // FPro bus
   input  logic mmio_cs,
   input  logic mmio_wr,
   input  logic mmio_rd,
   input  logic [20:0] mmio_addr,
   input  logic [31:0] mmio_wr_data,
   output logic [31:0] mmio_rd_data,
   // Ultrasonic sensor 1 (pitch control) - Pmod JA
   output logic us1_trig,
   input  logic us1_echo,
   // Ultrasonic sensor 2 (volume control) - Pmod JB  
   output logic us2_trig,
   input  logic us2_echo,
   // Audio output (PDM from DDFS)
   output logic audio_pwm,
   // Switches and LEDs for debugging
   input  logic [N_SW-1:0] sw,
   output logic [N_LED-1:0] led
);

   // Declaration
   logic [63:0] mem_rd_array;
   logic [63:0] mem_wr_array;
   logic [63:0] cs_array;
   logic [4:0] reg_addr_array [63:0];
   logic [31:0] rd_data_array [63:0];
   logic [31:0] wr_data_array [63:0];

   // DDFS audio signals
   logic signed [11:0] ddfs_pcm_out;
   logic ddfs_pdm_audio;  // PDM audio output from DDFS

   // Body
   // ================================================================
   // Instantiate MMIO controller
   // ================================================================
   chu_mmio_controller ctrl_unit (
      .clk(clk),
      .reset(reset),
      .mmio_cs(mmio_cs),
      .mmio_wr(mmio_wr),
      .mmio_rd(mmio_rd),
      .mmio_addr(mmio_addr),
      .mmio_wr_data(mmio_wr_data),
      .mmio_rd_data(mmio_rd_data),
      // Slot interface
      .slot_cs_array(cs_array),
      .slot_mem_rd_array(mem_rd_array),
      .slot_mem_wr_array(mem_wr_array),
      .slot_reg_addr_array(reg_addr_array),
      .slot_rd_data_array(rd_data_array),
      .slot_wr_data_array(wr_data_array)
   );

   // ================================================================
   // Slot 0: System timer
   // ================================================================
   chu_timer timer_slot0 (
      .clk(clk),
      .reset(reset),
      .cs(cs_array[`S0_SYS_TIMER]),
      .read(mem_rd_array[`S0_SYS_TIMER]),
      .write(mem_wr_array[`S0_SYS_TIMER]),
      .addr(reg_addr_array[`S0_SYS_TIMER]),
      .rd_data(rd_data_array[`S0_SYS_TIMER]),
      .wr_data(wr_data_array[`S0_SYS_TIMER])
   );

   // ================================================================
   // Slot 1: Input switches (GPI)
   // ================================================================
   chu_gpi #(.W(N_SW)) gpi_slot1 (
      .clk(clk),
      .reset(reset),
      .cs(cs_array[`S1_SW]),
      .read(mem_rd_array[`S1_SW]),
      .write(mem_wr_array[`S1_SW]),
      .addr(reg_addr_array[`S1_SW]),
      .rd_data(rd_data_array[`S1_SW]),
      .wr_data(wr_data_array[`S1_SW]),
      .din(sw)
   );

   // ================================================================
   // Slot 2: Output LEDs (GPO)
   // ================================================================
   chu_gpo #(.W(N_LED)) gpo_slot2 (
      .clk(clk),
      .reset(reset),
      .cs(cs_array[`S2_LED]),
      .read(mem_rd_array[`S2_LED]),
      .write(mem_wr_array[`S2_LED]),
      .addr(reg_addr_array[`S2_LED]),
      .rd_data(rd_data_array[`S2_LED]),
      .wr_data(wr_data_array[`S2_LED]),
      .dout(led)
   );

   // ================================================================
   // Slot 3: Ultrasonic Sensor 1 Core (Pitch Control)
   // ================================================================
   ultrasonic_core us1_slot3 (
      .clk(clk),
      .reset(reset),
      .cs(cs_array[`S3_US1]),
      .read(mem_rd_array[`S3_US1]),
      .write(mem_wr_array[`S3_US1]),
      .addr(reg_addr_array[`S3_US1]),
      .wr_data(wr_data_array[`S3_US1]),
      .rd_data(rd_data_array[`S3_US1]),
      .trig(us1_trig),
      .echo(us1_echo)
   );

   // ================================================================
   // Slot 4: Ultrasonic Sensor 2 Core (Volume Control)
   // ================================================================
   ultrasonic_core us2_slot4 (
      .clk(clk),
      .reset(reset),
      .cs(cs_array[`S4_US2]),
      .read(mem_rd_array[`S4_US2]),
      .write(mem_wr_array[`S4_US2]),
      .addr(reg_addr_array[`S4_US2]),
      .wr_data(wr_data_array[`S4_US2]),
      .rd_data(rd_data_array[`S4_US2]),
      .trig(us2_trig),
      .echo(us2_echo)
   );

   // ================================================================
   // Slot 5: DDFS Audio Core (Tone Generation)
   // ================================================================
   chu_ddfs_core ddfs_slot5 (
      .clk(clk),
      .reset(reset),
      .cs(cs_array[`S5_DDFS]),
      .read(mem_rd_array[`S5_DDFS]),
      .write(mem_wr_array[`S5_DDFS]),
      .addr(reg_addr_array[`S5_DDFS]),
      .rd_data(rd_data_array[`S5_DDFS]),
      .wr_data(wr_data_array[`S5_DDFS]),
      .focw_ext(26'h0),      // External frequency control (not used)
      .pha_ext(26'h0),       // External phase (not used)
      .env_ext(16'hFFFF),    // Full envelope (max volume)
      .pcm_out(ddfs_pcm_out), // 12-bit PCM audio output (not used for audio out)
      .digital_out(),        // Square wave (not used)
      .pdm_out(ddfs_pdm_audio) // PDM output - AUDIO!
   );

   // ================================================================
   // Audio Output: Direct connection from DDFS PDM to audio pin
   // No PWM core needed - DDFS has built-in PDM for audio
   // ================================================================
   assign audio_pwm = ddfs_pdm_audio;

   // ================================================================
   // Assign 0's to all unused slot rd_data signals
   // Slots 6-63 are unused (PWM core removed)
   // ================================================================
   generate
      genvar i;
      for (i=6; i<64; i=i+1) begin
         assign rd_data_array[i] = 32'h0;
      end
   endgenerate

endmodule
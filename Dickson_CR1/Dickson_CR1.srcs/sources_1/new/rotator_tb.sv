`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2025 05:58:23 PM
// Design Name: 
// Module Name: rotator_tb
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


module rotator_tb;
parameter N = 4;
logic enable, dir;
logic clk, rst;
logic [7:0] sseg;
logic [7:0] an;

rotator#(.N(N)) dut(
    .enable(enable),
    .dir(dir),
    .clk(clk),
    .rst(rst),
    .sseg(sseg),
    .an(an)
    );

    initial 
        begin
            clk = 0;
            forever
                #5 clk = ~clk;
        end
    
    initial
        begin
            dir = 1;
            enable = 0;
            rst = 0;
            #20 enable = 1;
            #20 rst = 1;
            #20 rst = 0;
            #200 dir = 0;
            #200;
            $finish;
        end
    

endmodule

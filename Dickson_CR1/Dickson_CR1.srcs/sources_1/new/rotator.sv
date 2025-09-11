`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2025 05:58:23 PM
// Design Name: 
// Module Name: rotator
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


module rotator#(parameter N = 28)(
    input logic clk, rst,
    input logic enable, dir,
    output logic [7:0] an,
    output logic [7:0] sseg
    );
    
    //signals
    logic [N-1:0] q_reg;
    logic [N-1:0] q_next;
    
    //N-bit counter
    //register
    always_ff @(posedge clk, negedge rst)
        if (!rst)
            q_reg <= 0;
        else
            q_reg <= q_next;
            
    //next-state logic: if enable, increment, else, hold
    //                  if enabled, increment if dir, decrement if !dir
    assign q_next = enable ? (dir ? q_reg + 1 : q_reg - 1) : q_reg;
    
    //fix left four 7-seg's
    assign an[7:4]=4'b1111;
    
    //
    always_comb
        begin
            case(q_reg[N-1:N-3])
                3'b000:
                    begin
                        an[3:0] = 4'b0111;
                        sseg[7:0] = 8'b10011100;
                    end
                3'b001:
                    begin
                        an[3:0] = 4'b1011;
                        sseg[7:0] = 8'b10011100;
                    end
                3'b010:
                    begin
                        an[3:0] = 4'b1101;
                        sseg[7:0] = 8'b10011100;
                    end
                3'b011:
                    begin
                        an[3:0] = 4'b1110;
                        sseg[7:0] = 8'b10011100;
                    end
                3'b100:
                    begin
                        an[3:0] = 4'b1110;
                        sseg[7:0] = 8'b10100011;
                    end
                3'b101:
                    begin
                        an[3:0] = 4'b1101;
                        sseg[7:0] = 8'b10100011;
                    end
                3'b110:
                    begin
                        an[3:0] = 4'b1011;
                        sseg[7:0] = 8'b10100011;
                    end
                3'b111:
                    begin
                        an[3:0] = 4'b0111;
                        sseg[7:0] = 8'b10100011;
                    end
            endcase      
        end
    
endmodule

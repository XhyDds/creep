`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 21:04:07
// Design Name: 
// Module Name: Dache_lru
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


module L2cache_replace#(//PLRU
    parameter   addr_width=4,
                way=4
)
(
    input       clk,
    input       use0,use1,ues2,ues3,
    input       [addr_width-1:0]addr,
    output reg  [1:0]way_sel
    );
reg [(1<<addr_width)-1:0]record[2:0];
always @(*) begin
    if(!record[addr][0])begin
        if(!record[addr][1])way_sel = 2'd0;
        else way_sel = 2'd1;
    end
    else begin
        if(!record[addr][2])way_sel = 2'd2;
        else way_sel = 2'd3;
    end
end
always @(posedge clk) begin
    if(use0)begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b1;
    end
    else if(use1)begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b0;
    end
    else if(use2)begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b1;
    end
    else if(use3)begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b0;
    end
end
endmodule

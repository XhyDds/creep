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


module Dache_lru#(
    parameter   addr_width=4,
                way=2
)
(
    input       clk,
    input       use0,use1,
    input       [addr_width-1:0]addr,
    output      way_sel_up
    );
reg [(1<<addr_width)-1:0]record;
assign way_sel_up=record[addr];
always @(posedge clk) begin
    if(use0)record[addr]<=1;//下一次用1
    else if(use1)record[addr]<=0;//下一次用0
end   
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:39:44
// Design Name: 
// Module Name: L2cache_Dirtytable
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


module L2cache_Dirtytable#(
    parameter   addr_width=4,
                way=4
)
(   
    input       clk,
    input       [addr_width-1:0]Dirtytable_addr,
    input       [1:0]Dirtytable_way_select,
    input       Dirtytable_set1,
    input       Dirtytable_set0,
    output      Dirty
    );
reg [(1<<addr_width)-1:0]dirty_table[way-1:0];//注意
assign Dirty=dirty_table[Dirtytable_way_select][Dirtytable_addr];
always @(posedge clk) begin
    if(Dirtytable_set1)dirty_table[Dirtytable_way_select][Dirtytable_addr]<=1;
    else if(Dirtytable_set0)dirty_table[Dirtytable_way_select][Dirtytable_addr]<=0;
end
endmodule

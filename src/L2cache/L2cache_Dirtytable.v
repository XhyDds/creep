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
                way=8
)
(   
    input       clk,
    // input       [way-1:0]valid,
    input       [addr_width-1:0]Dirtytable_addr,
    input       [addr_width-1:0]Dirtytable_addrw,
    input       [2:0]Dirtytable_way_select,
    input       Dirtytable_set1,
    input       Dirtytable_set0,
    output      Dirty
    );
reg [(1<<addr_width)-1:0]dirty_table[0:way-1];
reg Dirty_reg;
always @(posedge clk) begin
    Dirty_reg <= dirty_table[Dirtytable_way_select][Dirtytable_addr];
end
assign Dirty=Dirty_reg;
always @(posedge clk) begin
    if(Dirtytable_set1)dirty_table[Dirtytable_way_select][Dirtytable_addrw]<=1;
    else if(Dirtytable_set0)dirty_table[Dirtytable_way_select][Dirtytable_addrw]<=0;
end
endmodule

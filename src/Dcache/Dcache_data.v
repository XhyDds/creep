`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:32:12
// Design Name: 
// Module Name: Dcache_data
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


module Dcache_Data#(
    parameter   addr_width=4,
                data_width=64,
                way=2
)
(
    input       clk,
    input       [addr_width-1:0]Data_addr_read,
    output      [data_width-1:0]Data_dout0,
    output      [data_width-1:0]Data_dout1,

    input       [data_width-1:0]Data_din_write,
    input       [addr_width-1:0]Data_addr_write,
    input       [addr_width-1:0]Data_we,
    input       Data_way_select
    );
endmodule

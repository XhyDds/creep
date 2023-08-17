`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 21:10:40
// Design Name: 
// Module Name: Icache_Data
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


module Icache_Data#(
    parameter   addr_width=4,
                data_width=128,
                offset_width=2,
                way=2
)
(
    input       clk,rstn,
    
    input       [addr_width-1:0]Data_addr_read,
    output      [data_width-1:0]Data_dout0,
    output      [data_width-1:0]Data_dout1,

    input       [data_width-1:0]Data_din_write,
    input       [addr_width-1:0]Data_addr_write,
    input       [1:0]Data_we
    
    );
bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way0(
    .clk(clk),.rstn(rstn),

    .waddr(Data_addr_write),
    .din(Data_din_write),
    .we(Data_we[0]),

    .raddr(Data_addr_read),
    .dout(Data_dout0)
);

bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)way1(
    .clk(clk),.rstn(rstn),

    .waddr(Data_addr_write),
    .din(Data_din_write),
    .we(Data_we[1]),

    .raddr(Data_addr_read),
    .dout(Data_dout1)
);
endmodule

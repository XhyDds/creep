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
                data_width=128,
                way=2
)
(
    input       clk,
    input       [addr_width-1:0]Data_addr_read,
    output      [data_width-1:0]Data_dout0,
    output      [data_width-1:0]Data_dout1,

    input       [data_width-1:0]Data_din_write,
    input       [addr_width-1:0]Data_addr_write,
    input       [way-1:0]Data_we
    // input       Data_way_select
    );
//对单byte操作  暂时想法为8个bram  上一次单字操作也没改 一起改
//并且需要写优先
bram way0(
    .clk(clk),

    .addra(Data_addr_write),//写口
    .dina(Data_din_write),
    .we(Data_we[0]),

    .addrb(Data_addr_read),
    .doutb(Data_dout0)
);
defparam way0.DATA_WIDTH=data_width,way0.ADDR_WIDTH=addr_width;

bram way1(
    .clk(clk),

    .addra(Data_addr_write),//写口
    .dina(Data_din_write),
    .we(Data_we[1]),

    .addrb(Data_addr_read),
    .doutb(Data_dout1)
);
defparam way1.DATA_WIDTH=data_width,way1.ADDR_WIDTH=addr_width;
endmodule

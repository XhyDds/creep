`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 21:14:48
// Design Name: 
// Module Name: Icache_TagV
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


module Icache_TagV#(
    parameter   addr_width=4,
                data_width=1+25,
                way=2
)
(
    input       clk,
    input       [addr_width-1:0]TagV_addr_read,
    input       [data_width-1:0]TagV_din_compare,//用于比较
    output      [way-1:0]hit,

    input       [data_width-1:0]TagV_din_write,
    input       [addr_width-1:0]TagV_addr_write,
    input       [way-1:0]TagV_we
    // input       TagV_way_select
    );
wire [data_width-1:0]TagV_data[way-1:0];

bram way0(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din(TagV_din_write),
    .we(TagV_we[0]),

    .raddr(TagV_addr_read),
    .dout(TagV_data[0])
);
defparam way0.DATA_WIDTH=data_width,way0.ADDR_WIDTH=addr_width;

bram way1(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din(TagV_din_write),
    .we(TagV_we[1]),

    .raddr(TagV_addr_read),
    .dout(TagV_data[1])
);
defparam way1.DATA_WIDTH=data_width,way1.ADDR_WIDTH=addr_width;

generate
    genvar i;
    for (i=0;i<way;i=i+1) begin
        assign hit[i]=(TagV_data[i]==TagV_din_compare);
    end
endgenerate
endmodule

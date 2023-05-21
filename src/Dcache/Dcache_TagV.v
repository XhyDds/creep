`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:21:08
// Design Name: 
// Module Name: Dcache_TagV
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


module Dcache_TagV#(
    parameter   addr_width=4,
                data_width=1+25,
                way=2
)
(
    input       clk,
    input       [addr_width-1:0]TagV_addr_read,
    input       [data_width-1:0]TagV_din_read,//用于比较
    output      [way-1:0]hit,

    input       [data_width-1:0]TagV_din_write,
    input       [addr_width-1:0]TagV_addr_write,
    input       TagV_we,
    input       TagV_way_select
    );
wire [way-1:0]TagV_data[data_width-1:0];

bram way0(
    .clk(clk),

    .addra(TagV_addr_write),//写口
    .dina(TagV_din_write),
    .we((TagV_way_select==1'b0)&&TagV_we),

    .addrb(TagV_addr_read),
    .doutb(TagV_data[0])
);
defparam way0.DATA_WIDTH=data_width,way0.ADDR_WIDTH=addr_width;

bram way1(
    .clk(clk),

    .addra(TagV_addr_write),//写口
    .dina(TagV_din_write),
    .we((TagV_way_select==1'b1)&&TagV_we),

    .addrb(TagV_addr_read),
    .doutb(TagV_data[1])
);
defparam way1.DATA_WIDTH=data_width,way1.ADDR_WIDTH=addr_width;

for (i=0;i<way;i++) begin
    assign hit[i]=(TagV_data[i]==TagV_din_read);
end
endmodule

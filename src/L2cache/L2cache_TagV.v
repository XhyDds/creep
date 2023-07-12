`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:21:08
// Design Name: 
// Module Name: L2cache_TagV
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


module L2cache_TagV#(
    parameter   addr_width=4,
                data_width=25,
                way=4
)
(
    input       clk,
    input       [addr_width-1:0]TagV_addr_read,
    input       [data_width-1:0]TagV_din_compare,//用于比较
    input       [1:0]TagV_way_select,
    output      [data_width-1:0]TagV_dout,
    output      [way-1:0]hit,
    output      [way-1:0]valid,

    input       [data_width-1:0]TagV_din_write,
    input       [addr_width-1:0]TagV_addr_write,
    input       [way-1:0]TagV_we
    );
wire [data_width-1:0]TagV_data[way-1:0];

reg [(1<<addr_width)-1:0]valid0; 
reg [(1<<addr_width)-1:0]valid1;
reg [(1<<addr_width)-1:0]valid2; 
reg [(1<<addr_width)-1:0]valid3;
assign valid={valid3[TagV_addr_write],valid2[TagV_addr_write],valid1[TagV_addr_write],valid0[TagV_addr_write]};
assign TagV_dout=TagV_data[TagV_way_select];

always @(posedge clk) begin
    if(TagV_we[0])valid0[TagV_addr_write]<=1;
    if(TagV_we[1])valid1[TagV_addr_write]<=1;
    if(TagV_we[2])valid2[TagV_addr_write]<=1;
    if(TagV_we[3])valid3[TagV_addr_write]<=1;
end

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

bram way2(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din(TagV_din_write),
    .we(TagV_we[2]),

    .raddr(TagV_addr_read),
    .dout(TagV_data[2])
);
defparam way2.DATA_WIDTH=data_width,way2.ADDR_WIDTH=addr_width;

bram way3(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din(TagV_din_write),
    .we(TagV_we[3]),

    .raddr(TagV_addr_read),
    .dout(TagV_data[3])
);
defparam way3.DATA_WIDTH=data_width,way3.ADDR_WIDTH=addr_width;

assign hit[0]=(TagV_data[0]==TagV_din_compare)&&(valid0[TagV_addr_write]);//这个地址就是rbuf的地址
assign hit[1]=(TagV_data[1]==TagV_din_compare)&&(valid1[TagV_addr_write]);
assign hit[2]=(TagV_data[2]==TagV_din_compare)&&(valid2[TagV_addr_write]);
assign hit[3]=(TagV_data[3]==TagV_din_compare)&&(valid3[TagV_addr_write]);
endmodule

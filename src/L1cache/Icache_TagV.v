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
                data_width=25,
                way=2
)
(
    input       clk,rstn,
    input       [addr_width-1:0]TagV_addr_read,
    input       [data_width-1:0]TagV_din_compare,//用于比较
    output      [way-1:0]hit,

    input       [data_width-1:0]TagV_din_write,
    input       [addr_width-1:0]TagV_addr_write,
    input       [way-1:0]TagV_we
    // input       TagV_way_select
    );
wire [data_width-1:0]TagV_data[way-1:0];

reg [(1<<addr_width)-1:0]valid0; 
reg [(1<<addr_width)-1:0]valid1;

always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        valid0<=0;
        valid1<=0;
    end
    else begin
        if(TagV_we[0])valid0[TagV_addr_write]<=1;
        if(TagV_we[1])valid1[TagV_addr_write]<=1;
    end
end

bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way0(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din(TagV_din_write),
    .we(TagV_we[0]),

    .raddr(TagV_addr_read),
    .dout(TagV_data[0])
);

bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way1(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din(TagV_din_write),
    .we(TagV_we[1]),

    .raddr(TagV_addr_read),
    .dout(TagV_data[1])
);

assign hit[0]=(TagV_data[0]==TagV_din_compare)&&(valid0[TagV_addr_write]);//这个地址就是rbuf的地址
assign hit[1]=(TagV_data[1]==TagV_din_compare)&&(valid1[TagV_addr_write]);

endmodule

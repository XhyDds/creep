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
                data_width=25,
                way=2
)
(
    input       clk,
    input       [addr_width-1:0]TagV_addr_read,
    input       [data_width-1:0]TagV_din_compare,//用于比较
    output      [way-1:0]hit,

    input       [1:0]TagV_init,
    input       [data_width-1:0]TagV_din_write,
    input       [addr_width-1:0]TagV_addr_write,
    input       [way-1:0]TagV_unvalid,
    input       [way-1:0]TagV_we
    // input       TagV_way_select
    );
wire [data_width-1:0]TagV_data[way-1:0];

reg [(1<<addr_width)-1:0]valid0; 
reg [(1<<addr_width)-1:0]valid1;

always @(posedge clk) begin
    if(TagV_init[1])begin
        if(!TagV_init[0])valid0[TagV_addr_write] <= 0;
        else valid1[TagV_addr_write] <= 0;
    end
    else begin
        if(TagV_unvalid[0])valid0[TagV_addr_write] <= 0;
        else if(TagV_we[0])valid0[TagV_addr_write] <= 1;
        if(TagV_unvalid[1])valid1[TagV_addr_write] <= 0;
        else if(TagV_we[1])valid1[TagV_addr_write] <= 1;
    end
end

reg v0,v1;
always @(posedge clk) begin
    if(TagV_addr_write != TagV_addr_read)begin
        v0 <= valid0[TagV_addr_read];
        v1 <= valid1[TagV_addr_read];
    end
    else begin
        if(TagV_init[1])begin
            if(!TagV_init[0])v0 <= 0;
            else v1 <= 0;
        end
        else begin
            if(TagV_unvalid[0])v0 <= 0;
            else if(TagV_we[0])v0 <= 1;
            else v0 <= valid0[TagV_addr_read];
            if(TagV_unvalid[1])v1 <= 0;
            else if(TagV_we[1])v1 <= 1;
            else v1 <= valid1[TagV_addr_read];
        end
        
    end
end

wire [data_width-1:0]zero = 0;
wire [way-1:0]hit_t;
lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width))
way0(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din((TagV_init == 2'b10) ? zero:TagV_din_write),
    .we(TagV_we[0] || (TagV_init == 2'b10)),

    .raddr(TagV_addr_read),
    .dout(TagV_data[0]),
    .din_comp(TagV_din_compare),
    .hit(hit_t[0])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width))
way1(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din((TagV_init == 2'b11) ? zero:TagV_din_write),
    .we(TagV_we[1] || (TagV_init == 2'b11)),

    .raddr(TagV_addr_read),
    .dout(TagV_data[1]),
    .din_comp(TagV_din_compare),
    .hit(hit_t[1])
);

assign hit[0]=(hit_t[0])&&(v0);//这个地址就是rbuf的地址
assign hit[1]=(hit_t[1])&&(v1);

endmodule

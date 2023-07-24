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
                offset_width=2,
                way=2
)
(
    input       clk,
    
    input       [addr_width-1:0]Data_addr_read,
    output      [data_width-1:0]Data_dout0,
    output      [data_width-1:0]Data_dout1,

    input       [data_width-1:0]Data_din_write,
    input       [31:0]Data_din_write_32,
    input       [addr_width-1:0]Data_addr_write,
    input       [offset_width-1:0]Data_offset,
    input       [3:0]Data_choose_byte,
    input       [way-1:0]Data_we,
    input       Data_replace//为1替换，否则对单字操作
    
    );
reg [data_width/8-1:0]we0,we1;
reg [data_width-1:0]Data_din;

wire [offset_width+1:0]Data_offset_2 = {2'b0,Data_offset} << 2;
wire [offset_width+4:0]Data_offset_5 = {5'b0,Data_offset} << 5;

wire [data_width/8-1:0] we = Data_choose_byte;

wire [data_width-1:0]Data_din_1 = Data_din_write_32;

always @(*) begin
    if(!Data_we[0])we0 = 0;
    else begin
        if(Data_replace)we0 = -1;//全部有效
        else begin
            we0 = we << Data_offset_2;//左移4*Data_offset
        end
    end
    if(!Data_we[1])we1 = 0;
    else begin
        if(Data_replace)we1 = -1;//全部有效
        else begin
            we1 = we << Data_offset_2;//左移4*Data_offset
        end
    end
    if(Data_replace)Data_din = Data_din_write;
    else Data_din = Data_din_1 << Data_offset_5;//左移32*Data_offset
end

bram_bytewrite #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width))
way0(
    .clk(clk),

    .waddr(Data_addr_write),
    .din(Data_din),
    .we(we0),

    .raddr(Data_addr_read),
    .dout(Data_dout0)
);

bram_bytewrite #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width))
way1(
    .clk(clk),

    .waddr(Data_addr_write),
    .din(Data_din),
    .we(we1),

    .raddr(Data_addr_read),
    .dout(Data_dout1)
);
endmodule

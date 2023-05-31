`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 19:13:48
// Design Name: 
// Module Name: test
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


module test(
    input clk,rstn,
    input [31:0]addr1,addr2,
    input [31:0]data1,
    input we,
    output [31:0]dout1,dout2
    );
bram bram1(
    .clk(clk),
    .we(we),
    .addra(addr1),
    .addrb(addr2),
    .dina(data1),
    .douta(dout1),
    .doutb(dout2)
);
defparam bram1.DATA_WIDTH=32,bram1.ADDR_WIDTH=32;
endmodule

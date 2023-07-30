`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30 14:34:24
// Design Name: 
// Module Name: Dcache_rbuf
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


module Dcache_rbuf
(
    input clk,rbuf_we,
    input [31:0]addr,data,opcode,pc,paddr,
    output reg [31:0]rbuf_addr,rbuf_data,rbuf_opcode,rbuf_pc,rbuf_paddr,
    input opflag,type1,SUC,
    output reg rbuf_opflag,rbuf_type,rbuf_SUC,
    input [3:0]wstrb,
    output reg [3:0]rbuf_wstrb,
    input [1:0]size,
    output reg [1:0]rbuf_size
    );
always @(posedge clk) begin
    if(rbuf_we)begin
        rbuf_addr<=addr;
        rbuf_data<=data;
        rbuf_opcode<=opcode;
        rbuf_opflag<=opflag;
        rbuf_wstrb<=wstrb;
        rbuf_type<=type1;
        rbuf_pc<=pc;
        rbuf_SUC <= SUC;
        rbuf_paddr <= paddr;
        rbuf_size <= size;
    end
end
endmodule

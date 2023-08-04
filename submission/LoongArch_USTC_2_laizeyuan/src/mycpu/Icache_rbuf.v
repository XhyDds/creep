`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 21:04:21
// Design Name: 
// Module Name: Icache_rbuf
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


module Icache_rbuf#(
    parameter   offset_width=2
)//MMU的数据迟一拍写并且需要写优先：rbuf_paddr、rbuf_SUC
(
    input clk,rbuf_we,rbuf_stall,
    input [31:0]addr,paddr,opcode,
    output reg [31:0]rbuf_addr,rbuf_paddr,rbuf_opcode,
    input opflag,SUC,
    output reg rbuf_opflag,rbuf_SUC
    );
wire we = rbuf_we & ~rbuf_stall;
always @(posedge clk) begin
    if(we)begin
        rbuf_addr <= addr;
        rbuf_opcode <= opcode;
        rbuf_opflag <= opflag;
        rbuf_paddr <= addr;
        rbuf_SUC <= SUC;
    end
end
endmodule

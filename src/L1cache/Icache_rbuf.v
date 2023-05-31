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
)
(
    input clk,rstn,rbuf_we,rbuf_stall,
    input [31:0]addr,opcode,
    output reg [31:0]rbuf_addr,rbuf_opcode,
    input opflag,
    output reg rbuf_opflag
    );
always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        rbuf_addr<=0;
        rbuf_opcode<=0;
        rbuf_opflag<=0;
    end
    else if(rbuf_we&&(!rbuf_stall))begin
        rbuf_addr<=addr;
        rbuf_opcode<=opcode;
        rbuf_opflag<=opflag;
    end
end
endmodule

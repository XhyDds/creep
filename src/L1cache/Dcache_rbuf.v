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
    input clk,rstn,rbuf_we,
    input [31:0]addr,data,opcode,pc,
    output reg [31:0]rbuf_addr,rbuf_data,rbuf_opcode,rbuf_pc,
    input opflag,type1,SUC,
    output reg rbuf_opflag,rbuf_type,
    output rbuf_SUC,
    input [3:0]wstrb,
    output reg [3:0]rbuf_wstrb
    );
reg we_reg,rbuf_SUC1;
always @(posedge clk) begin
    we_reg <= rbuf_we;
end
always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        rbuf_addr<=0;
        rbuf_data<=0;
        rbuf_opcode<=0;
        rbuf_opflag<=0;
        rbuf_wstrb<=0;
        rbuf_type<=0;
        rbuf_pc<=0;
    end
    else if(rbuf_we)begin
        rbuf_addr<=addr;
        rbuf_data<=data;
        rbuf_opcode<=opcode;
        rbuf_opflag<=opflag;
        rbuf_wstrb<=wstrb;
        rbuf_type<=type1;
        rbuf_pc<=pc;
    end
    if(!rstn)begin
        rbuf_SUC1<=0;
    end
    else if(we_reg)begin
        rbuf_SUC1<=SUC;
    end
end
assign rbuf_SUC = rbuf_SUC1|SUC;
endmodule

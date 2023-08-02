`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30 14:34:24
// Design Name: 
// Module Name: L2cache_rbuf
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


module L2cache_rbuf#(
    parameter   offset_width=2
)
(
    input clk,rstn,rbuf_we,
    input [31:0]addr,data,opcode,opaddr,
    output reg [31:0]rbuf_addr,rbuf_data,rbuf_opcode,rbuf_opaddr,
    input opflag,SUC,prefetch,pref_type,
    output reg rbuf_opflag,rbuf_SUC,rbuf_prefetch,rbuf_pref_type,
    input [3:0]wstrb,
    output reg [3:0]rbuf_wstrb,
    input [1:0]from,//0-No 1-I 2-Dr 3-Dw
    output reg[1:0]rbuf_from,
    input [1:0]size,
    output reg rbuf_size
    );
// reg rbuf_SUC1;
always @(posedge clk)begin
    if(!rstn)begin
        rbuf_addr <= 0;
        rbuf_data <= 0;
        rbuf_opcode <= 0;
        rbuf_opflag <= 0;
        rbuf_wstrb <= 0;
        rbuf_from <= 0;
        rbuf_SUC <= 0;
        rbuf_opaddr <= 0;
        rbuf_size <= 0;
        rbuf_prefetch <= 0;
        rbuf_pref_type <= 0;
    end
    else if(rbuf_we)begin
        rbuf_addr <= addr;
        rbuf_data <= data;
        rbuf_opcode <= opcode;
        rbuf_opflag <= opflag;
        rbuf_wstrb <= wstrb;
        rbuf_from <= from;
        rbuf_SUC <= SUC;
        rbuf_opaddr <= opaddr;
        rbuf_size <= size;
        rbuf_prefetch <= prefetch;
        rbuf_pref_type <= pref_type;
    end
end
// always @(*) begin
//     rbuf_SUC = rbuf_we ? SUC : rbuf_SUC1;
// end
endmodule

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
    input [31:0]addr,data,opcode,
    output reg [31:0]rbuf_addr,rbuf_data,rbuf_opcode,
    input opflag,type,
    output reg rbuf_opflag,rbuf_type,
    input [3:0]wstrb,
    output reg [3:0]rbuf_wstrb
    );
always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        rbuf_addr<=0;
        rbuf_data<=0;
        rbuf_opcode<=0;
        rbuf_opflag<=0;
        rbuf_wstrb<=0;
    end
    else if(rbuf_we)begin
        rbuf_addr<=addr;
        rbuf_data<=data;
        rbuf_opcode<=opcode;
        rbuf_opflag<=opflag;
        rbuf_wstrb<=wstrb;
    end
end
endmodule

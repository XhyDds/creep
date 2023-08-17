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
    input clk,rbuf_we,rbuf_stall,rstn,
    input [31:0]addr,paddr,opcode,
    output reg [31:0]rbuf_addr,rbuf_opcode,rbuf_paddr,
    input opflag,SUC,
    output reg rbuf_opflag,rbuf_SUC
    );
wire we = rbuf_we & ~rbuf_stall;
reg we_reg;
reg [31:0]rbuf_paddr1;
reg rbuf_SUC1;
always @(posedge clk) begin
    if(!rstn)begin
        we_reg <= 0;
        rbuf_addr <= 0;
        rbuf_opcode <= 0;
        rbuf_opflag <= 0;
        rbuf_paddr1 <= 0;
        rbuf_SUC1 <= 0;
    end
    else begin
        we_reg <= we;
        if(we)begin
            rbuf_addr <= addr;
            rbuf_opcode <= opcode;
            rbuf_opflag <= opflag;
        end
        if(we_reg)begin
            rbuf_paddr1 <= paddr;
            rbuf_SUC1 <= SUC; 
        end
    end
end
always @(*) begin
    rbuf_paddr = we_reg ? paddr : rbuf_paddr1;
    rbuf_SUC = we_reg ? SUC : rbuf_SUC1;
end
endmodule

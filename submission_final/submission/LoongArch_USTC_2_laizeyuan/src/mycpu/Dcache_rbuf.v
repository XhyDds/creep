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
    input clk,rbuf_we,rstn,
    input [31:0]addr,data,opcode,pc,paddr,
    output reg [31:0]rbuf_addr,rbuf_data,rbuf_opcode,rbuf_pc,rbuf_paddr,
    input opflag,type1,SUC,
    output reg rbuf_opflag,rbuf_type,rbuf_SUC,
    input [3:0]wstrb,
    output reg [3:0]rbuf_wstrb,
    input [1:0]size,
    output reg [1:0]rbuf_size
    );
reg [31:0]rbuf_paddr1;
reg rbuf_SUC1;
reg we_reg;
always @(posedge clk) begin
    if(!rstn)begin
        we_reg <= 0;
        rbuf_addr <= 0;
        rbuf_data <= 0;
        rbuf_opcode <= 0;
        rbuf_opflag <= 0;
        rbuf_wstrb <= 0;
        rbuf_type <= 0;
        rbuf_pc <= 0;
        rbuf_size <= 0;
        rbuf_paddr1 <= 0;
        rbuf_SUC1 <= 0;
    end
    else begin
        we_reg <= rbuf_we;
        if(rbuf_we)begin
            rbuf_addr<=addr;
            rbuf_data<=data;
            rbuf_opcode<=opcode;
            rbuf_opflag<=opflag;
            rbuf_wstrb<=wstrb;
            rbuf_type<=type1;
            rbuf_pc<=pc;
            rbuf_size <= size;
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

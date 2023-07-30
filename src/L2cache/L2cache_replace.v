`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 21:04:07
// Design Name: 
// Module Name: Dache_lru
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


module L2cache_replace#(//PLRU
    parameter   addr_width=4,
                way=4
)
(
    input       clk,
    input       [way-1:0]use1,
    input       [way-1:0]valid,

    input       [addr_width-1:0]addr,//读写同地址
    output      [1:0]way_sel_d,
    output      way_sel_i
    );
reg [(1<<addr_width)-1:0]record[2:0];
reg [1:0]d;
reg i;
assign way_sel_d = d;
assign way_sel_i = i;
//d_sel
always @(posedge clk) begin
    if(!valid[3])d <= 2'd3;
    else if(!valid[2])d <= 2'd2;
    else if(!valid[1])d <= 2'd1;
    else if(!valid[0])d <= 2'd0;
    if(!record[addr][0])begin
        if(!record[addr][1])d <= 2'd0;
        else d <= 2'd1;
    end
    else begin
        if(!record[addr][2])d <= 2'd2;
        else d <= 2'd3;
    end
end
//i_sel
always @(posedge clk) begin
    if(!valid[0])i <= 2'd0;
    else if(!valid[1])i <= 2'd1;
    else i <= record[addr][1];
end
//Write
always @(posedge clk) begin
    if(use1[0])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b1;
    end
    else if(use1[1])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b0;
    end
    else if(use1[2])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b1;
    end
    else if(use1[3])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b0;
    end
end
endmodule

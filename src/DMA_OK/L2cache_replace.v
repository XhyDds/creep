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
                way=8
)
(
    input       clk,
    input       [way-1:0]use1,
    input       [way-1:0]valid,

    input       [addr_width-1:0]addr,//读写同地址
    output      [2:0]way_sel_d,
    output      [1:0]way_sel_i
    );
reg [(1<<addr_width)-1:0]record[6:0];
reg [2:0]d;
reg [1:0]i;
assign way_sel_d = d;
assign way_sel_i = i;
//d_sel
always @(posedge clk) begin
    if(!valid[7])d <= 3'd7;
    else if(!valid[6])d <= 3'd6;
    else if(!valid[5])d <= 3'd5;
    else if(!valid[4])d <= 3'd4;
    else if(!valid[3])d <= 3'd3;
    else if(!valid[2])d <= 3'd2;
    else if(!valid[1])d <= 3'd1;
    else if(!valid[0])d <= 3'd0;
    if(!record[addr][0])begin
        if(!record[addr][1])begin
            if(!record[addr][3])d <= 3'd0;
            else d <= 3'd1;
        end
        else begin
            if(!record[addr][4])d <= 3'd2;
            else d <= 3'd3;
        end
    end
    else begin
        if(!record[addr][2])begin
            if(!record[addr][5])d <= 3'd4;
            else d <= 3'd5;
        end
        else begin
            if(!record[addr][6])d <= 3'd6;
            else d <= 3'd7;
        end
    end
end
//i_sel
always @(posedge clk) begin
    if(!valid[0])i <= 2'd0;
    else if(!valid[1])i <= 2'd1;
    else if(!valid[2])i <= 2'd2;
    else if(!valid[3])i <= 2'd3;
    else begin
        if(!record[addr][1])begin
            if(!record[addr][3])i <= 2'd0;
            else i <= 2'd1;
        end
        else begin
            if(!record[addr][4])i <= 2'd2;
            else i <= 2'd3;
        end
    end
end
//Write
always @(posedge clk) begin
    if(use1[0])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b1;
        record[addr][3] <= 1'b1;
    end
    else if(use1[1])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b1;
        record[addr][3] <= 1'b0;
    end
    else if(use1[2])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b0;
        record[addr][4] <= 1'b1;
    end
    else if(use1[3])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b0;
        record[addr][4] <= 1'b0;
    end
    else if(use1[4])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b1;
        record[addr][5] <= 1'b1;
    end
    else if(use1[5])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b1;
        record[addr][5] <= 1'b0;
    end
    else if(use1[6])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b0;
        record[addr][6] <= 1'b1;
    end
    else if(use1[7])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b0;
        record[addr][6] <= 1'b0;
    end
end
endmodule

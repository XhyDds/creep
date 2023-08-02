`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:21:08
// Design Name: 
// Module Name: L2cache_TagV
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


module L2cache_TagV#(
    parameter   addr_width=4,
                data_width=25,
                way=8
)
(
    input       clk,
    input       [addr_width-1:0]TagV_addr_read,
    input       [data_width-1:0]TagV_din_compare,//用于比较
    input       [2:0]TagV_way_select,
    output      [data_width-1:0]TagV_dout,
    output      [way-1:0]hit,
    output      [way-1:0]valid,

    input       [3:0]TagV_init,
    input       [data_width-1:0]TagV_din_write,
    input       [addr_width-1:0]TagV_addr_write,
    input       [way-1:0]TagV_unvalid,
    input       [way-1:0]TagV_we
    );
wire [data_width-1:0]TagV_data[way-1:0];

reg [(1<<addr_width)-1:0]valid0; 
reg [(1<<addr_width)-1:0]valid1;
reg [(1<<addr_width)-1:0]valid2; 
reg [(1<<addr_width)-1:0]valid3;
reg [(1<<addr_width)-1:0]valid4; 
reg [(1<<addr_width)-1:0]valid5;
reg [(1<<addr_width)-1:0]valid6; 
reg [(1<<addr_width)-1:0]valid7;
assign TagV_dout=TagV_data[TagV_way_select];

always @(posedge clk) begin
    if(TagV_init[3])begin
        if(TagV_init[2:0] == 3'd0)valid0[TagV_addr_write] <= 0;
        else if(TagV_init[2:0] == 3'd1)valid1[TagV_addr_write] <= 0;
        else if(TagV_init[2:0] == 3'd2)valid2[TagV_addr_write] <= 0;
        else if(TagV_init[2:0] == 3'd3)valid3[TagV_addr_write] <= 0;
        else if(TagV_init[2:0] == 3'd4)valid4[TagV_addr_write] <= 0;
        else if(TagV_init[2:0] == 3'd5)valid5[TagV_addr_write] <= 0;
        else if(TagV_init[2:0] == 3'd6)valid6[TagV_addr_write] <= 0;
        else if(TagV_init[2:0] == 3'd7)valid7[TagV_addr_write] <= 0;
    end
    else begin
        if(TagV_unvalid[0])valid0[TagV_addr_write] <= 0;
        else if(TagV_we[0])valid0[TagV_addr_write] <= 1;
        if(TagV_unvalid[1])valid1[TagV_addr_write] <= 0;
        else if(TagV_we[1])valid1[TagV_addr_write] <= 1;
        if(TagV_unvalid[2])valid2[TagV_addr_write] <= 0;
        else if(TagV_we[2])valid2[TagV_addr_write] <= 1;
        if(TagV_unvalid[3])valid3[TagV_addr_write] <= 0;
        else if(TagV_we[3])valid3[TagV_addr_write] <= 1;
        if(TagV_unvalid[4])valid4[TagV_addr_write] <= 0;
        else if(TagV_we[4])valid4[TagV_addr_write] <= 1;
        if(TagV_unvalid[5])valid5[TagV_addr_write] <= 0;
        else if(TagV_we[5])valid5[TagV_addr_write] <= 1;
        if(TagV_unvalid[6])valid6[TagV_addr_write] <= 0;
        else if(TagV_we[6])valid6[TagV_addr_write] <= 1;
        if(TagV_unvalid[7])valid7[TagV_addr_write] <= 0;
        else if(TagV_we[7])valid7[TagV_addr_write] <= 1;
    end
end

//valid 寄存 写优先
reg v0,v1,v2,v3,v4,v5,v6,v7;
assign valid={v7,v6,v5,v4,v3,v2,v1,v0};
always @(posedge clk) begin
    if(TagV_addr_write != TagV_addr_read)begin
        v0 <= valid0[TagV_addr_read];
        v1 <= valid1[TagV_addr_read];
        v2 <= valid2[TagV_addr_read];
        v3 <= valid3[TagV_addr_read];
        v4 <= valid4[TagV_addr_read];
        v5 <= valid5[TagV_addr_read];
        v6 <= valid6[TagV_addr_read];
        v7 <= valid7[TagV_addr_read];
    end
    else begin
        if(TagV_init[3])begin
            if(TagV_init[2:0] == 3'd0)v0 <= 0;
            else if(TagV_init[2:0] == 3'd1)v1 <= 0;
            else if(TagV_init[2:0] == 3'd2)v2 <= 0;
            else if(TagV_init[2:0] == 3'd3)v3 <= 0;
            else if(TagV_init[2:0] == 3'd4)v4 <= 0;
            else if(TagV_init[2:0] == 3'd5)v5 <= 0;
            else if(TagV_init[2:0] == 3'd6)v6 <= 0;
            else if(TagV_init[2:0] == 3'd7)v7 <= 0;
        end
        else begin
            if(TagV_unvalid[0])v0 <= 0;
            else if(TagV_we[0])v0 <= 1;
            else v0 <= valid0[TagV_addr_read];
            if(TagV_unvalid[1])v1 <= 0;
            else if(TagV_we[1])v1 <= 1;
            else v1 <= valid1[TagV_addr_read];
            if(TagV_unvalid[2])v2 <= 0;
            else if(TagV_we[2])v2 <= 1;
            else v2 <= valid2[TagV_addr_read];
            if(TagV_unvalid[3])v3 <= 0;
            else if(TagV_we[3])v3 <= 1;
            else v3 <= valid3[TagV_addr_read];
            if(TagV_unvalid[4])v4 <= 0;
            else if(TagV_we[4])v4 <= 1;
            else v4 <= valid4[TagV_addr_read];
            if(TagV_unvalid[5])v5 <= 0;
            else if(TagV_we[5])v5 <= 1;
            else v5 <= valid5[TagV_addr_read];
            if(TagV_unvalid[6])v6 <= 0;
            else if(TagV_we[6])v6 <= 1;
            else v6 <= valid6[TagV_addr_read];
            if(TagV_unvalid[7])v7 <= 0;
            else if(TagV_we[7])v7 <= 1;
            else v7 <= valid7[TagV_addr_read];
        end
    end
end

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way0(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd0}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[0] || (TagV_init == {1'b1,3'd0})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[0])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way1(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd1}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[1] || (TagV_init == {1'b1,3'd1})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[1])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way2(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd2}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[2] || (TagV_init == {1'b1,3'd2})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[2])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way3(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd3}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[3] || (TagV_init == {1'b1,3'd3})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[3])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way4(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd4}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[4] || (TagV_init == {1'b1,3'd4})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[4])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way5(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd5}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[5] || (TagV_init == {1'b1,3'd5})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[5])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way6(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd6}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[6] || (TagV_init == {1'b1,3'd6})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[6])
);

lutram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way7(
    .clk(clk),

    .waddr(TagV_addr_write),
    .din((TagV_init == {1'b1,3'd7}) ? {(data_width){1'b0}}:TagV_din_write),
    .we(TagV_we[7] || (TagV_init == {1'b1,3'd7})),

    .raddr(TagV_addr_read),
    .dout(TagV_data[7])
);

assign hit[0]=(TagV_data[0]==TagV_din_compare)&&(v0);
assign hit[1]=(TagV_data[1]==TagV_din_compare)&&(v1);
assign hit[2]=(TagV_data[2]==TagV_din_compare)&&(v2);
assign hit[3]=(TagV_data[3]==TagV_din_compare)&&(v3);
assign hit[4]=(TagV_data[4]==TagV_din_compare)&&(v4);
assign hit[5]=(TagV_data[5]==TagV_din_compare)&&(v5);
assign hit[6]=(TagV_data[6]==TagV_din_compare)&&(v6);
assign hit[7]=(TagV_data[7]==TagV_din_compare)&&(v7);
endmodule

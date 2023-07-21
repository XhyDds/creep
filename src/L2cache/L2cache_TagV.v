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
                way=4
)
(
    input       clk,
    input       [addr_width-1:0]TagV_addr_read,
    input       [data_width-1:0]TagV_din_compare,//用于比较
    input       [1:0]TagV_way_select,
    output      [data_width-1:0]TagV_dout,
    output      [way-1:0]hit,
    output      [way-1:0]valid,

    input       [2:0]TagV_init,
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
assign valid={valid3[TagV_addr_write],valid2[TagV_addr_write],valid1[TagV_addr_write],valid0[TagV_addr_write]};
assign TagV_dout=TagV_data[TagV_way_select];

always @(posedge clk) begin
    if(TagV_init[2])begin
        if(TagV_init[1:0] == 2'd0)valid0[TagV_addr_write] <= 0;
        else if(TagV_init[1:0] == 2'd1)valid1[TagV_addr_write] <= 0;
        else if(TagV_init[1:0] == 2'd2)valid2[TagV_addr_write] <= 0;
        else valid3[TagV_addr_write] <= 0;
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
    end
end

bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way0(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din((TagV_init == 3'b100) ? 0:TagV_din_write),
    .we(TagV_we[0] || (TagV_init == 3'b100)),

    .raddr(TagV_addr_read),
    .dout(TagV_data[0])
);

bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way1(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din((TagV_init == 3'b101) ? 0:TagV_din_write),
    .we(TagV_we[1] || (TagV_init == 3'b101)),

    .raddr(TagV_addr_read),
    .dout(TagV_data[1])
);

bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way2(
    .clk(clk),

    .waddr(TagV_addr_write),//写口
    .din((TagV_init == 3'b110) ? 0:TagV_din_write),
    .we(TagV_we[2] || (TagV_init == 3'b110)),

    .raddr(TagV_addr_read),
    .dout(TagV_data[2])
);

bram #(
    .DATA_WIDTH(data_width),
    .ADDR_WIDTH(addr_width)
)
way3(
    .clk(clk),

    .waddr((TagV_init == 3'b111) ? 0:TagV_addr_write),//写口
    .din(TagV_din_write),
    .we(TagV_we[3] || (TagV_init == 3'b111)),

    .raddr(TagV_addr_read),
    .dout(TagV_data[3])
);

assign hit[0]=(TagV_data[0]==TagV_din_compare)&&(valid0[TagV_addr_write]);//这个地址就是rbuf的地址
assign hit[1]=(TagV_data[1]==TagV_din_compare)&&(valid1[TagV_addr_write]);
assign hit[2]=(TagV_data[2]==TagV_din_compare)&&(valid2[TagV_addr_write]);
assign hit[3]=(TagV_data[3]==TagV_din_compare)&&(valid3[TagV_addr_write]);
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:32:12
// Design Name: 
// Module Name: L2cache_data
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


module L2cache_Data#(
    parameter   addr_width=4,
                data_width=512,
                offset_width=2,
                way=4
)
(
    input       clk,
    
    input       [addr_width-1:0]Data_addr_read,
    output      [data_width-1:0]Data_dout0,
    output      [data_width-1:0]Data_dout1,
    output      [data_width-1:0]Data_dout2,
    output      [data_width-1:0]Data_dout3,

    input       [data_width-1:0]Data_din_write,
    input       [31:0]Data_din_write_32,
    input       [addr_width-1:0]Data_addr_write,
    input       [offset_width-1:0]Data_offset,
    input       [3:0]Data_choose_byte,
    input       [way-1:0]Data_we,
    input       Data_replace//为1替换，否则对单字操作
    
    );
reg [data_width/8-1:0]we0,we1,we2,we3;
reg [data_width-1:0]Data_din;
always @(*) begin
    if(!Data_we[0])we0 = 0;
    else begin
        if(Data_replace)we0 = -1;//全部有效
        else begin
            we0 = Data_choose_byte << (Data_offset << 2);//左移4*Data_offset
        end
    end
    if(!Data_we[1])we1 = 0;
    else begin
        if(Data_replace)we1 = -1;
        else begin
            we1 = Data_choose_byte << (Data_offset << 2);
        end
    end
    if(!Data_we[2])we2 = 0;
    else begin
        if(Data_replace)we2 = -1;
        else begin
            we2 = Data_choose_byte << (Data_offset << 2);
        end
    end
    if(!Data_we[3])we3 = 0;
    else begin
        if(Data_replace)we3 = -1;
        else begin
            we3 = Data_choose_byte << (Data_offset << 2);
        end
    end
    if(Data_replace)Data_din = Data_din_write;
    else Data_din = Data_din_write_32 << (Data_offset << 5);
end

bram_bytewrite way0(
    .clk(clk),

    .waddr(Data_addr_write),
    .din(Data_din),
    .we(we0),

    .raddr(Data_addr_read),
    .dout(Data_dout0)
);
defparam way0.DATA_WIDTH=data_width,way0.ADDR_WIDTH=addr_width;

bram_bytewrite way1(
    .clk(clk),

    .waddr(Data_addr_write),
    .din(Data_din),
    .we(we1),

    .raddr(Data_addr_read),
    .dout(Data_dout1)
);
defparam way1.DATA_WIDTH=data_width,way1.ADDR_WIDTH=addr_width;

bram_bytewrite way2(
    .clk(clk),

    .waddr(Data_addr_write),
    .din(Data_din),
    .we(we2),

    .raddr(Data_addr_read),
    .dout(Data_dout2)
);
defparam way2.DATA_WIDTH=data_width,way2.ADDR_WIDTH=addr_width;

bram_bytewrite way3(
    .clk(clk),

    .waddr(Data_addr_write),
    .din(Data_din),
    .we(we3),

    .raddr(Data_addr_read),
    .dout(Data_dout3)
);
defparam way3.DATA_WIDTH=data_width,way3.ADDR_WIDTH=addr_width;
endmodule

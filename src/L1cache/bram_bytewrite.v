`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30 19:18:44
// Design Name: 
// Module Name: bram_bytewrite
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

// 0 warning
module bram_bytewrite#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 8
            //   INIT_FILE = ""
)(
    input                   clk,   // Clock
    input [ADDR_WIDTH-1:0]  raddr, // read Address
    input [ADDR_WIDTH-1:0]  waddr, // write Address
    input [DATA_WIDTH-1:0]  din,   // Data Input
    input [DATA_WIDTH/8-1:0]we,    // Write Enable
    output [DATA_WIDTH-1:0] dout   // Data Output
); 
wire [DATA_WIDTH-1:0]dout1;
reg [DATA_WIDTH-1:0]din_reg;
reg [DATA_WIDTH/8-1:0]choose;
always @(posedge clk)begin
    din_reg <= din;
    if(raddr == waddr)choose <= we;
    else choose <= 0;
end
generate
    genvar i;
    for(i = 0; i < DATA_WIDTH/8; i = i+1) begin
        assign dout[(i+1)*8-1:(i*8)] = (choose[i]) ? din_reg[(i+1)*8-1:(i*8)] : dout1[(i+1)*8-1:(i*8)];
    end
endgenerate

ip_bytewrite #(
    .NB_COL(DATA_WIDTH/8),
    .COL_WIDTH(8),
    .RAM_DEPTH(1<< ADDR_WIDTH)
)
ip_bytewrite(
    .clka(clk),
    .addra(waddr),
    .addrb(raddr),
    .dina(din),
    .wea(we),
    .enb(1'b1),
    .doutb(dout1)
);
endmodule

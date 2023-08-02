`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 19:11:03
// Design Name: 
// Module Name: bram
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
module bram #(
    parameter DATA_WIDTH = 32,
            //   INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
              ADDR_WIDTH = 8
            //   INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
)
(
    input clk,                    // Clock
    input [ADDR_WIDTH-1:0] raddr,  // Read Address
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] din,   // Data Input
    input we,                     // Write Enable
    output [DATA_WIDTH-1:0] dout
); 

wire [DATA_WIDTH-1:0]dout_1,din_reg;
reg choose;
always @(posedge clk)begin
    din_reg <= din;
    choose <= we && (raddr == waddr);
end
assign dout = choose ? din_reg : dout_1;

ip_bram #(
    .RAM_WIDTH(DATA_WIDTH),
    .RAM_DEPTH(1<<ADDR_WIDTH)
)
ip_bram(
    .aclk(clk),
    .addra(waddr),
    .addrb(raddr),
    .dina(din),
    .wea(we),
    .enb(1'b1),
    .doutb(dout_1)
);



endmodule

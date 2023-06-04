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


module bram #(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 8,
              INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
)
(
    input clk,                    // Clock
    input [ADDR_WIDTH-1:0] raddr,  // Read Address
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] din,   // Data Input
    input we,                     // Write Enable
    output [DATA_WIDTH-1:0] dout
); 
    reg [ADDR_WIDTH-1:0] addr_r;  // Address Register
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    integer i;
    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
            ram[i] = 0;
        end
    end

    assign dout = (addr_r==waddr)?din:ram[addr_r];//write first

    always @(posedge clk) begin
        addr_r <= raddr;
        if (we) ram[waddr] <= din;
    end

endmodule

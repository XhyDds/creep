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
    parameter DATA_WIDTH = 8,
              ADDR_WIDTH = 8,
              INIT_FILE = ""
)
//a是写口，b是读口
(
    input clk,                    // Clock
    input [ADDR_WIDTH-1:0] addra,  // Address
    input [ADDR_WIDTH-1:0] addrb,
    input [DATA_WIDTH-1:0] dina,   // Data Input
    input we,                     // Write Enable
    // output [DATA_WIDTH-1:0] douta,  // Data Output
    output [DATA_WIDTH-1:0] doutb
); 
    reg [ADDR_WIDTH-1:0] addr_r;  // Address Register
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    initial $readmemh(INIT_FILE, ram); // initialize memory

    assign doutb = ram[addr_r]; 

    always @(posedge clk) begin
        addr_r <= addrb;
        if (we) ram[addra] <= dina;
    end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30 13:07:48
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


module bram_bytewrite#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 8,
              INIT_FILE = ""
)(
    input                   clk,   // Clock
    input [ADDR_WIDTH-1:0]  raddr, // read Address
    input [ADDR_WIDTH-1:0]  waddr, // write Address
    input [DATA_WIDTH-1:0]  din,   // Data Input
    input [DATA_WIDTH/8-1:0]we,    // Write Enable
    output [DATA_WIDTH-1:0] dout   // Data Output
); 
    reg [ADDR_WIDTH-1:0] addr_r;  // Address Register
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    initial $readmemh(INIT_FILE, ram); // initialize memory

    always @(posedge clk) begin
        addr_r <= raddr;
    end
    assign dout = (addr_r==waddr)?din:ram[addr_r];//write first

    generate
        genvar i;
        for(i = 0; i < DATA_WIDTH/8; i = i+1) begin
            always @(posedge clk) begin
                if(we[i])
                    ram[waddr][(i+1)*8-1:(i*8)] <= din[(i+1)*8-1:(i*8)];
            end
        end
    endgenerate
endmodule

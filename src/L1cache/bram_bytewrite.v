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
    reg [DATA_WIDTH-1:0] dout_r;  
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    // initial $readmemh(INIT_FILE, ram); // initialize memory
    integer j;
    initial begin
        for (j = 0; j < (1 << ADDR_WIDTH); j = j + 1) begin
            ram[j] = 0;
        end
    end

    always @(posedge clk) begin
        dout_r <= ram[raddr];
    end
    assign dout = dout_r;
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

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
module lutram #(
    parameter DATA_WIDTH = 32,
            //   INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
              ADDR_WIDTH = 8
            //   INIT_FILE = "C:\Users\lenovo\Desktop\data_init.coe"
)
(
    input clk,rstn,                    // Clock
    input [ADDR_WIDTH-1:0] raddr,  // Read Address
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] din,   // Data Input
    input we,                     // Write Enable
    output [DATA_WIDTH-1:0] dout,
    input  [DATA_WIDTH-1:0] din_comp,
    output reg hit
); 
    reg [DATA_WIDTH-1:0] dout_r;
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];

    integer i;
    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
            ram[i] = 0;
        end
    end

    assign dout = dout_r;

    always @(posedge clk) begin
        if (we) ram[waddr] <= din;
        if(!rstn)begin
            hit <= 0;
            dout_r <= 0;
        end
        else begin
            hit <=  din_comp == ((waddr == raddr && we) ? din : ram[raddr]);
            dout_r <= (waddr == raddr && we) ? din : ram[raddr];
        end
    end

endmodule

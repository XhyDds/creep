`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30 21:00
// Design Name: 
// Module Name: AXI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 刚完成接口定义，还未实现
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module AXI (
    //时钟与复位
    input                   aclk,   // Clock
    iuput                   aresetn, // Reset

    //AXI从端
    //读请求通道
    input [3:0]             arid,   // Read address ID
    input [31:0]            araddr, // Address
    input [7:0]             arlen,  // Burst length
    input [1:0]             arsize, // Burst size
    input [1:0]             arburst,// Burst type
    input                   arlock, // Lock type
    input [3:0]             arcache,// Cache type
    input [2:0]             arprot, // Protection type
    input                   arvalid,// Read address valid
    output                  arready,// Read address ready

    //读响应通道
    output [3:0]            rid,    // Read ID
    output [31:0]           rdata,  // Read data
    output [1:0]            rresp,  // Read response
    output                  rlast,  // Read last
    output                  rvalid, // Read valid
    input                   rready, // Read ready

    //写请求通道
    input [3:0]             awid,   // Write address ID
    input [31:0]            awaddr, // Address
    input [7:0]             awlen,  // Burst length
    input [1:0]             awsize, // Burst size
    input [1:0]             awburst,// Burst type
    input                   awlock, // Lock type
    input [3:0]             awcache,// Cache type
    input [2:0]             awprot, // Protection type
    input                   awvalid,// Write address valid
    output                  awready,// Write address ready

    //写数据通道
    input [3:0]             wid,    // Write ID
    input [31:0]            wdata,  // Write data
    input [3:0]             wstrb,  // Write strobes
    input                   wlast,  // Write last
    input                   wvalid, // Write valid
    output                  wready, // Write ready

    //写响应通道
    output [3:0]            bid,    // Write ID
    output [1:0]            bresp,  // Write response
    output                  bvalid, // Write valid
    input                   bready  // Write ready

    //AXI主端
    //待完成
    );


    
endmodule

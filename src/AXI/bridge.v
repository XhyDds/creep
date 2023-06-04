`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30 21:33
// Design Name: 
// Module Name: SRAM-AXI-Bridge
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

module bridge#(
    parameter   offset_width=2,
)(
    //时钟与复位
    input                   clk,    // Clock

    //AXI主端
    //读请求通道
    output [3:0]            arid,   // Read address ID
    output [31:0]           araddr, // Address
    output [7:0]            arlen,  // Burst length
    output [1:0]            arsize, // Burst size
    output [1:0]            arburst,// Burst type
    output                  arlock, // Lock type
    output [3:0]            arcache,// Cache type
    output [2:0]            arprot, // Protection type
    output                  arvalid,// Read address valid
    input                   arready,// Read address ready

    //读响应通道
    input [3:0]             rid,    // Read ID
    input [31:0]            rdata,  // Read data
    input [1:0]             rresp,  // Read response
    input                   rlast,  // Read last
    input                   rvalid, // Read valid
    output                  rready, // Read ready

    //写请求通道
    output [3:0]            awid,   // Write address ID
    output [31:0]           awaddr, // Address
    output [7:0]            awlen,  // Burst length
    output [1:0]            awsize, // Burst size
    output [1:0]            awburst,// Burst type
    output                  awlock, // Lock type
    output [3:0]            awcache,// Cache type
    output [2:0]            awprot, // Protection type
    output                  awvalid,// Write address valid
    input                   awready,// Write address ready

    //写数据通道
    output [3:0]            wid,    // Write ID
    output [31:0]           wdata,  // Write data
    output [3:0]            wstrb,  // Write strobes
    output                  wlast,  // Write last
    output                  wvalid, // Write valid
    input                   wready, // Write ready

    //写响应通道
    input [3:0]             bid,    // Write ID
    input [1:0]             bresp,  // Write response
    input                   bvalid, // Write valid
    output                  bready  // Write ready

    //SRAM从端
    input                   dcache_mem_req,
    input                   dcache_mem_wr,
    input [1:0]             dcache_mem_size,
    input [3:0]             dcache_mem_wstrb,
    output                  dcache_mem_addrOK,
    output                  dcache_mem_dataOK,

    input [31:0]            addr_dcache_mem,
    input [31:0]            din_dcache_mem
    output                  [32*(2<<offset_width)-1:0] dout_mem_dcache,
);
    
endmodule
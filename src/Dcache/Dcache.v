`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 19:06:47
// Design Name: 
// Module Name: Dcache
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


module Dcache#(
    parameter   index_width=4,
                offset_width=2
)
// 写直达 非写分配 暂定延迟一周期出
(  
    input       clk,rstn,
    output      [31:0]test1,test2,test3,

    //pipeli    ne port
    input       [31:0]addrin_read_dcache,
    input       [31:0]addrin_write_dcache,
    input       [31:0]din_pipeline_dcache,
    output      [31:0]dout_dcache_pipeline,


    input       pipeline_dcahe_vaild,
    output reg  dcache_pipeline_ready,
    
    input       [3:0]pipeline_dcache_wstrb,
    input       [31:0]pipeline_dcache_opcode,
    input       [31:0]pipeline_dcache_ctrl,//wirte stall flush branch ...
    output      dcache_pipeline_ctrl,//stall form dcache     不知道可不可以用ready代替，先留着

    //mem prot
    output      [31:0]addrout_dcache,
    output      [31:0]dout_dcache_mem,
    input       [31:0]din_mem_dcache,

    output reg  dcache_mem_req,
    output reg  dcache_mem_wr,//write-1  read-0
    output reg  [1:0]dcache_mem_size,//0-1byte  1-2b    2-4b
    output reg  [3:0]dcache_mem_wstrb,//字节写使能
    input       mem_dcache_addrOK,
    input       mem_dcache_dataOK
    );
endmodule
//锁存出去的data，上一个周期有stall则发上一个周期锁存的data

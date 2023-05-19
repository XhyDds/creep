`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:17:30
// Design Name: 
// Module Name: Dcache_FSMmain
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


module Dcache_FSMmain#(
    parameter   index_width=4,
                offset_width=2
)
(
    input clk,rstn

    //上下游信号
    input       pipeline_dcahe_vaild,
    output reg  dcache_pipeline_ready,
    input       [3:0]pipeline_dcache_wstrb,
    input       [31:0]pipeline_dcache_opcode,
    input       [31:0]pipeline_dcache_ctrl,//stall flush branch ...
    output      dcache_pipeline_ctrl,//stall form dcache
    output reg  dcache_mem_req,
    output reg  dcache_mem_wr,//write-1  read-0
    output reg  [1:0]dcache_mem_size,//0-1byte  1-2b    2-4b
    output reg  [3:0]dcache_mem_wstrb,//字节写使能
    input  reg  mem_dcache_addrOK,
    input  reg  mem_dcache_dataOK,

    //模块间信号
    
    //lru
    output reg  FSM_use0,FSM_use1,
    input       FSM_wal_sel,

    //data TagV dirty
    output reg  [addr_width-1:0]FSM_Data_we,
    output reg  [addr_width-1:0]FSM_TagV_we,
    output reg  FSM_way_select,
    input       FSM_Dirty,
    output reg  FSM_Dirtytable_set1,FSM_Dirtytable_set0,

    //return buffer

    //数据选择
    output reg  FSM_choose_way,
    output reg  FSM_choose_return,
    output reg  [offset_width-1:0]FSM_choose_word
    
    );
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/11 14:27:44
// Design Name: 
// Module Name: Queue
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

// Queue泛用缓冲队列
// 支持query,insert,get三项功能
// - query:根据地址查询最近入队的相同地址的数据
// - insert:获取队尾
// - get:获取队首


module WriteBuffer #(
    length=5,
    addr_width=32,
    data_width=32,
) (
    input  clk,
    input  rstn,

    input  [addr_width-1:0] queue_in_addr,
    input  [data_width-1:0] queue_in_data,
    input  queue_in_valid,
    output queue_in_ready,

    output [addr_width-1:0] queue_out_addr,
    output [data_width-1:0] queue_out_data,
    output queue_out_valid,
    input  queue_out_ready,

    input  [addr_width-1:0] queue_query_addr,
    output [addr_width-1:0] queue_query_data,
    output queue_query_ok                        //query是否成功
);


    
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/11 13:36:52
// Design Name: 
// Module Name: Icache_DMA
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

module Icache_DMA#(
    parameter   index_width=4,
                offset_width=2,
                way=2
)
//写直达 非写分配 暂定延迟一周期出
(  
    input       clk,rstn,
    // output      [31:0]test1,test2,test3,

    //pipeline port
    input       [31:0]addr_pipeline_icache,
    output      [63:0]dout_icache_pipeline,//双发射 [31:0]是给定地址处的指令
    output      flag_icache_pipeline,//0-后一条指令（[64:32]）无效 1-有效

    input       pipeline_icache_valid,
    output reg  icache_pipeline_ready,
    
    input       [31:0]pipeline_icache_opcode,//cache操作
    input       pipeline_icache_opflag,//0-正常访存 1-cache操作    
    input       [31:0]pipeline_icache_ctrl,//stall flush branch ...
    output      icache_pipeline_stall,//stall form icache     不知道可不可以用ready代替，先留着

    //mem prot
    output      [31:0]addr_icache_mem,
    input       [32*(1<<offset_width)-1:0]din_mem_icache,

    output  reg icache_mem_req,
    output      [1:0]icache_mem_size,//0-1byte  1-2b    2-4b
    input       mem_icache_addrOK,
    input       mem_icache_dataOK
    );
assign addr_icache_mem = addr_pipeline_icache;
assign dout_icache_pipeline = din_mem_icache[63:0];
assign flag_icache_pipeline = 1;
assign icache_pipeline_stall = ~ icache_pipeline_ready;
assign icache_mem_size = 2'd2;

wire stall = pipeline_icache_ctrl[0];
reg [4:0]state,next_state;
localparam Idle=5'd0,req=5'd1,send=5'd2;
always @(posedge clk)begin
    if(!rstn)state<=Idle;
    else state<=next_state;
end
always @(*) begin
    case (state)
        Idle:begin
            if(stall)next_state = Idle;
            else begin
                if(pipeline_icache_valid)next_state = req;
                else next_state = Idle;
            end
        end 
        req:begin
            if(mem_icache_addrOK)next_state = send;
            else next_state = req;
        end
        send:begin
            if(mem_icache_dataOK)next_state = Idle;
            else next_state = send;
        end
        default: next_state = Idle;
    endcase
end
always @(*) begin
    icache_mem_req = 0;
    icache_pipeline_ready = 0;
    case (state)
        Idle:begin
            if(next_state == req)begin
                icache_mem_req = 1;
            end
            else begin
                icache_pipeline_ready = 1;
            end
        end 
        req:begin
            icache_mem_req = 1;
        end
        send:begin
            if(next_state == Idle)begin
                icache_pipeline_ready = 1;
            end
        end
        default: begin
            
        end
    endcase
end


endmodule

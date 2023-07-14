`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/11 14:10:44
// Design Name: 
// Module Name: Dcache_DMA
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

module Dcache_DMA#(
    parameter   index_width=4,
                offset_width=2,
                way=2
)
//写直达 非写分配 暂定延迟一周期出
//读 无论byte还是字都返回一个字，外部解决存入一个byte
//写 根据外部生成的wstrb决定 一个字则生成4'b1111，单byte存入则生成一位的1即可，并且传入的byte放在字对应的八位处，以字传入
//也支持同时修改多个byte
(  
    input       clk,rstn,
    output      [31:0]test1,test2,test3,

    //pipeline port
    input       [31:0]addr_pipeline_dcache,
    input       [31:0]din_pipeline_dcache,
    output      [31:0]dout_dcache_pipeline,
    input       type_pipeline_dcache,//0-read 1-write

    input       pipeline_dcache_valid,
    output reg  dcache_pipeline_ready,
    
    input       [3:0]pipeline_dcache_wstrb,//字节处理位
    input       [31:0]pipeline_dcache_opcode,//cache操作
    input       pipeline_dcache_opflag,//0-正常访存 1-cache操作    
    input       [31:0]pipeline_dcache_ctrl,//stall flush branch ...
    output      dcache_pipeline_stall,//stall form dcache     不知道可不可以用ready代替，先留着

    //mem prot
    output      [31:0]addr_dcache_mem,
    output      [31:0]dout_dcache_mem,
    input       [32*(2<<offset_width)-1:0]din_mem_dcache,

    output  reg dcache_mem_req,
    output  reg dcache_mem_wr,//0-read 1-write
    output      [1:0]dcache_mem_size,//0-1byte  1-2b    2-4b
    output      [3:0]dcache_mem_wstrb,//字节写使能
    input       mem_dcache_addrOK,
    input       mem_dcache_dataOK
    );
assign addr_dcache_mem = addr_pipeline_dcache;
assign dout_dcache_mem = din_pipeline_dcache;
assign dout_dcache_pipeline = din_mem_dcache[32:0];
assign dcache_mem_wr = type_pipeline_dcache;
assign dcache_mem_wstrb = pipeline_dcache_wstrb;
assign dcache_pipeline_stall = ~ dcache_pipeline_ready;
assign dcache_mem_size = 2'd2;

reg [4:0]state,next_state;
localparam Idle=5'd0,req=5'd1,send=5'd2;
always @(posedge clk,negedge rstn) begin
    if(!rstn)state<=Idle;
    else state<=next_state;
end
always @(*) begin
    case (state)
        Idle:begin
            if(pipeline_dcache_valid)next_state = req;
            else next_state = Idle;
        end 
        req:begin
            if(mem_dcache_addrOK)begin
               if(type_pipeline_dcache == 0)next_state = send;
               else next_state = Idle; 
            end
            else next_state = req;
        end
        send:begin
            if(mem_dcache_dataOK)next_state = Idle;
            else next_state = send;
        end
        default: next_state = Idle;
    endcase
end
always @(*) begin
    dcache_mem_req = 0;
    dcache_pipeline_ready = 0;
    case (state)
        Idle:begin
            if(next_state == req)begin
                dcache_mem_req = 1;
            end
            else begin
                dcache_pipeline_ready = 1;
            end
        end 
        req:begin
            dcache_mem_req = 1;
            if(next_state == Idle)begin
                dcache_pipeline_ready = 1;
            end
        end
        send:begin
            if(next_state == Idle)begin
                dcache_pipeline_ready = 1;
            end
        end
        default: begin
            
        end
    endcase
end

// always @(posedge clk,negedge rstn)begin
//     if(!rstn)begin
//         dcache_mem_wr<=0;
//     end
//     else begin
//     case(state)
//         Idle:begin
//             if(next_state == req)begin
//                 dcache_mem_wr<=type_pipeline_dcache;
//             end
//             else begin
//                 dcache_mem_wr<=0;
//             end
//         end
//         req:begin
//             if(next_state == Idle)begin
//                 dcache_mem_wr<=0;
//             end
//         end
//         send:begin
//             dcache_mem_wr<=0;
//         end
//         default:begin
//             dcache_mem_wr<=0;
//         end
//     endcase
//     end
// end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 21:17:07
// Design Name: 
// Module Name: Icache_FSMmain
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


module Icache_FSMmain#(
    parameter   index_width=4,
                offset_width=2,
                way=2
)
(
    input clk,rstn,

    //上下游信号
    input       pipeline_icache_valid,
    output      icache_pipeline_valid1,
    input       [31:0]pipeline_icache_opcode,//好像不需要 用rbuf的即可
    input       pipeline_icache_opflag,
    output      icache_pipeline_doneop,
    output reg  ack_op,
    input       [31:0]pipeline_icache_ctrl,//stall flush branch ...
    output reg  icache_pipeline_stall,//stall form icache

    output reg  icache_mem_req,
    input       mem_icache_dataOK,//返回的数据有效

    //模块间信号
    
    //reqbuf
    output reg  FSM_rbuf_we,
    input       [31:0]FSM_rbuf_opcode,
    input       FSM_rbuf_opflag,
    input       [31:0]FSM_rbuf_addr,
    input       FSM_rbuf_SUC,

    //lru
    output reg  FSM_use0,FSM_use1,
    input       FSM_wal_sel_lru,

    //data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output      [way-1:0]FSM_TagV_we,//两个相同
    output reg  [way-1:0]FSM_TagV_unvalid,
    output reg  FSM_TagV_ibar,
    output reg  [1:0]FSM_TagV_init,

    //数据选择
    output reg  FSM_choose_way,
    output reg  FSM_choose_return
    
    );
//对字节和byte的选择暂未加入

reg icache_pipeline_valid;
assign FSM_TagV_we=FSM_Data_we;
wire hit0,hit1;
assign hit0=FSM_hit[0];
assign hit1=FSM_hit[1];
wire fStall_outside=pipeline_icache_ctrl[0];//注意编号
wire flush_outside=pipeline_icache_ctrl[1];
wire opflag;
assign opflag=pipeline_icache_opflag;
reg rstn_reg;
always @(posedge clk) begin
    if(~rstn) rstn_reg <= 0;
    else rstn_reg <= rstn;
end
reg [31:0]hit_cnt,miss_cnt;
reg we_hit_cnt,we_miss_cnt;
always @(posedge clk) begin
    if(!rstn)begin
        hit_cnt <= 0;
        miss_cnt <= 0;
    end
    else begin
        if(we_hit_cnt)hit_cnt <= hit_cnt + 1;
        if(we_miss_cnt)miss_cnt <= miss_cnt + 1;
    end
end
assign icache_pipeline_valid1=icache_pipeline_valid&rstn_reg;//初始态不能给ready
wire Miss = ((!hit0)&&(!hit1)) || FSM_rbuf_SUC;
reg [4:0]state;
reg [4:0]next_state;
localparam Idle=5'd0,Lookup=5'd1,Miss_r_waitdata=5'd2,Operation=5'd3,Flush=5'd4;
assign icache_pipeline_doneop = (state == Operation);
always @(posedge clk)begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    next_state = Idle;
    case (state)
        Idle:begin
            if(fStall_outside)next_state = Idle;
            else if(opflag)next_state = Operation;
            else if(pipeline_icache_valid)next_state = Lookup;
        end
        Lookup:begin
            if(Miss)begin//Miss优先级应该比Stall高
                if(flush_outside)next_state = Flush;
                else next_state = Miss_r_waitdata;
            end
            else begin//Hit
                if(flush_outside)next_state = Flush;
                else if(fStall_outside)next_state = Lookup;
                else if(opflag)next_state = Operation;
                else if(pipeline_icache_valid)next_state = Lookup;
            end
        end
        Flush:begin
            if(flush_outside)next_state = Flush;
            else if(opflag)next_state = Operation;
            else if(pipeline_icache_valid)next_state = Lookup;
        end
        Operation:begin
            if(flush_outside)next_state = Flush;
            else if(pipeline_icache_valid)begin
                // if(opflag)next_state = Operation;
                next_state = Lookup;
            end
        end
        Miss_r_waitdata:begin
            if(!mem_icache_dataOK)next_state = Miss_r_waitdata;
            else if(opflag)next_state = Operation;
            else if(pipeline_icache_valid)next_state = Lookup;
        end
        default:next_state = Idle;
    endcase
end
always @(*) begin
    icache_pipeline_valid = 0;
    icache_mem_req = 0;
    FSM_rbuf_we = 0;
    FSM_use0 = 0;
    FSM_use1 = 0;
    FSM_Data_we = 2'd0;
    FSM_choose_way = 0;
    FSM_choose_return = 0;
    FSM_TagV_init = 2'b0;
    FSM_TagV_ibar = 0;
    FSM_TagV_unvalid = 2'b0;
    ack_op = (next_state == Operation);
    icache_pipeline_stall = 1;
    we_hit_cnt = 0;
    we_miss_cnt = 0;
    case (state)
        Idle:begin
            icache_pipeline_stall = 0;
            FSM_rbuf_we=1;
        end
        Lookup:begin
            if(~Miss)we_hit_cnt = 1;
            else we_miss_cnt = 1;
            if(~Miss & ~flush_outside)icache_pipeline_valid = 1;
            if(Miss)icache_mem_req = 1;//flush去l2撤销
            else begin
                icache_pipeline_stall = 0;
                FSM_rbuf_we = 1;
            end
            if(hit0)begin FSM_choose_way=0; end
            else if(hit1)begin FSM_choose_way=1; end
            if(!flush_outside)begin
                if(FSM_rbuf_SUC)begin
                    if(hit0)FSM_TagV_unvalid = 2'b01;
                    else if(hit1)FSM_TagV_unvalid = 2'b10;
                end
                else begin
                    if(hit0)begin FSM_use0=1; end
                    else if(hit1)begin FSM_use1=1; end
                end
            end
        end
        Flush:begin
            icache_pipeline_stall = 0;
            FSM_rbuf_we=1;
        end
        Operation:begin//所有op一周期可以做完 流水
            icache_pipeline_stall = 0;
            FSM_rbuf_we=1;
            if(!flush_outside)begin
                if(FSM_rbuf_opcode[31])FSM_TagV_ibar = 1;
                else if(FSM_rbuf_opcode[4:3] == 2'd0)begin
                    FSM_TagV_init = {1'b1,FSM_rbuf_addr[0]};
                end
                else if(FSM_rbuf_opcode[4:3] == 2'd1)begin
                    if(!FSM_rbuf_addr[0])FSM_TagV_unvalid = 2'b01;
                    else FSM_TagV_unvalid = 2'b10;
                end
                else if(FSM_rbuf_opcode[4:3] == 2'd2)begin
                    if(hit0)FSM_TagV_unvalid = 2'b01;
                    else if(hit1)FSM_TagV_unvalid = 2'b10;
                end
            end
        end
        Miss_r_waitdata:begin
            icache_mem_req=1;
            if(mem_icache_dataOK)begin
                FSM_rbuf_we=1;
                FSM_choose_return=1;
                icache_pipeline_valid = 1;
                icache_pipeline_stall = 0;
                if(!FSM_rbuf_SUC)begin
                    if(~FSM_wal_sel_lru)begin FSM_use0=1; FSM_Data_we[0]=1;end
                    else begin FSM_use1=1; FSM_Data_we[1]=1;end
                end
            end
        end
        default:;
    endcase
end
endmodule

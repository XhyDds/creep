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
                offset_width=2,
                way=2
)
(
    input clk,rstn,

    //上下游信号
    input       pipeline_dcache_valid,
    output reg  dcache_pipeline_ready,
    input       [3:0]pipeline_dcache_wstrb,
    input       [31:0]pipeline_dcache_opcode,//好像不需要 用rbuf的即可
    input       pipeline_dcache_opflag,
    output      dcache_pipeline_doneop,
    output reg  ack_op,
    input       [31:0]pipeline_dcache_ctrl,//stall flush branch ...
    output      dcache_pipeline_stall,//stall form dcache

    output reg  dcache_mem_req,
    output reg  dcache_mem_wr,//write-1  read-0
    input       mem_dcache_addrOK,//发送的地址和数据都被接收
    input       mem_dcache_dataOK,//返回的数据有效

    //模块间信号
    
    //reqbuf
    output reg  FSM_rbuf_we,
    input       [31:0]FSM_rbuf_opcode,
    input       FSM_rbuf_opflag,//好像不需要
    input       [31:0]FSM_rbuf_addr,
    input       FSM_rbuf_type,//0-read  1-write
    input       [3:0]FSM_rbuf_wstrb,
    input       FSM_rbuf_SUC,//强序非缓存

    //lru
    output reg  FSM_use0,FSM_use1,
    input       FSM_wal_sel_lru,

    //data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output      [way-1:0]FSM_TagV_we,//两个相同
    output reg  FSM_Data_replace,
    output reg  [way-1:0]FSM_TagV_unvalid,
    output reg  [1:0]FSM_TagV_init,
    // output reg  FSM_way_select,

    //数据选择
    output reg  FSM_choose_way,
    output reg  FSM_choose_return
    
    );
assign dcache_pipeline_stall = ~ dcache_pipeline_ready;
assign FSM_TagV_we=FSM_Data_we;
wire hit0,hit1;
assign hit0=FSM_hit[0];
assign hit1=FSM_hit[1];
wire fStall_outside=pipeline_dcache_ctrl[0];
wire opflag;
assign opflag=pipeline_dcache_opflag;
wire Miss = ((!hit0)&&(!hit1)) || FSM_rbuf_SUC;
wire flush_outside = pipeline_dcache_ctrl[1];
reg [4:0]state;
reg [4:0]next_state;
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
localparam Idle=5'd0,Lookup=5'd1,Miss_r_waitdata=5'd3,Miss_w=5'd4,Operation=5'd5,Hit_w=5'd6,Miss_r_waitdata1=5'd7;
localparam Flush=5'd8;
assign dcache_pipeline_doneop = (state == Operation);
always @(posedge clk) begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    next_state = Idle;
    case (state)
        Idle:begin
            if(fStall_outside)next_state = Idle;
            else if(opflag)next_state=Operation;
            else if(pipeline_dcache_valid)next_state=Lookup;
        end
        Lookup:begin
                if(Miss)begin
                    if(flush_outside)next_state = Flush;
                    else if(!FSM_rbuf_type)begin//r
                        next_state = Miss_r_waitdata;
                    end
                    else begin
                        if(!mem_dcache_addrOK)next_state=Miss_w;
                        else if(opflag)next_state=Operation;
                        else if(pipeline_dcache_valid)next_state=Lookup;
                        else next_state=Idle;
                    end
                end
                else begin//hit
                    if(flush_outside)next_state = Flush;
                    // else if(fStall_outside)next_state = Lookup;
                    else if(!FSM_rbuf_type)begin//r
                        if(opflag)next_state=Operation;
                        else if(pipeline_dcache_valid)next_state=Lookup;
                        else next_state=Idle;
                    end
                    else begin
                        if(!mem_dcache_addrOK)next_state=Hit_w;
                        else begin
                            if(opflag)next_state=Operation;
                            else if(pipeline_dcache_valid)next_state=Lookup;
                            else next_state=Idle;
                        end
                    end
                end
        end
        Flush:begin
            if(flush_outside)begin
                next_state = Flush;
            end
            else begin
                if(opflag)next_state=Operation;
                else if(pipeline_dcache_valid)next_state=Lookup;
                else next_state=Idle;
            end
        end
        Operation:begin
            if(flush_outside)begin
                next_state = Flush;
            end
            else begin
                if(pipeline_dcache_valid)begin
                    // if(opflag)next_state=Operation;
                    next_state=Lookup;
                end
                else next_state=Idle;
            end
        end
        Hit_w:begin
            if(!mem_dcache_addrOK)next_state = Hit_w;
            else begin
                if(opflag)next_state=Operation;
                else if(pipeline_dcache_valid)next_state=Lookup;
                else next_state=Idle;
            end
        end
        Miss_r_waitdata:begin
            if(!mem_dcache_dataOK)next_state=Miss_r_waitdata;
            else next_state = Miss_r_waitdata1;
        end
        Miss_r_waitdata1:begin
            if(opflag)next_state=Operation;
            else if(pipeline_dcache_valid)next_state=Lookup;
            else next_state=Idle;
        end
        Miss_w:begin
            if(!mem_dcache_addrOK)next_state=Miss_w;
            else begin
                if(opflag)next_state=Operation;
                else if(pipeline_dcache_valid)next_state=Lookup;
                else next_state=Idle;
            end
        end
        default:next_state = Idle;
    endcase
end
always @(*) begin
    dcache_pipeline_ready = 0;
    dcache_mem_req = 0;
    dcache_mem_wr = 0;
    FSM_rbuf_we = 0;
    FSM_use0 = 0;
    FSM_use1 = 0;
    FSM_Data_we = 2'd0;
    FSM_TagV_unvalid = 2'd0;
    FSM_choose_way = 0;
    FSM_choose_return = 0;
    FSM_Data_replace = 0;
    FSM_TagV_init = 0;
    ack_op = (next_state == Operation);
    we_hit_cnt = 0;
    we_miss_cnt = 0;
    case (state)
        Idle:begin
            dcache_pipeline_ready=1;
            FSM_rbuf_we=1;
        end
        Lookup:begin
            if(~Miss)we_hit_cnt = 1;
            else we_miss_cnt = 1;
            if(!flush_outside)begin
                if(FSM_rbuf_SUC)begin
                    if(hit0)FSM_TagV_unvalid = 2'b01;
                    else if(hit1)FSM_TagV_unvalid = 2'b10;
                end
                if(FSM_rbuf_type)begin dcache_mem_req = 1; dcache_mem_wr = 1; end
                if(Miss & ~FSM_rbuf_type)begin dcache_mem_req = 1; dcache_mem_wr = 0; end
                if(~Miss)begin
                    if(FSM_rbuf_type)begin//Write Hit
                        if(hit0)begin FSM_Data_we[0] = 1; FSM_use0 = 1; end
                        else if(hit1)begin FSM_Data_we[1] = 1; FSM_use1 = 1; end
                    end
                    else begin//Read Hit
                        if(hit0)begin FSM_choose_way = 0; FSM_use0 = 1; end
                        else if(hit1)begin FSM_choose_way = 1; FSM_use1 = 1; end
                    end
                end
            end
            if(mem_dcache_addrOK && FSM_rbuf_type)begin //写请求
                dcache_pipeline_ready = 1; FSM_rbuf_we = 1; 
            end
            else if(!Miss && !FSM_rbuf_type)begin //读且命中
                dcache_pipeline_ready = 1; FSM_rbuf_we = 1;
            end
        end
        Operation:begin
            dcache_pipeline_ready = 1;
            FSM_rbuf_we = 1;
            if(!flush_outside)begin
                if(FSM_rbuf_opcode[4:3] == 2'd0)begin
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
        Flush:begin
            dcache_pipeline_ready=1;
            FSM_rbuf_we=1;
        end
        Hit_w:begin
            dcache_mem_wr=1;
            dcache_mem_req=1;
            if(mem_dcache_addrOK)begin
                dcache_pipeline_ready = 1;
                FSM_rbuf_we = 1;
            end
        end
        Miss_r_waitdata:begin
            dcache_mem_wr=0;
            dcache_mem_req=1;
            if(mem_dcache_dataOK)begin
                FSM_choose_return=1;
            end
        end
        Miss_r_waitdata1:begin
            FSM_rbuf_we=1;
            dcache_pipeline_ready=1;
            FSM_Data_replace=1;
            if(!FSM_rbuf_SUC)begin//强序读不需要写入cache
                if(FSM_wal_sel_lru==1'd0)begin
                    FSM_Data_we[0]=1;
                    FSM_use0=1;
                end
                else if(FSM_wal_sel_lru==1'd1)begin
                    FSM_Data_we[1]=1;
                    FSM_use1=1;
                end
            end
        end
        Miss_w:begin
            dcache_mem_wr=1;
            dcache_mem_req=1;
            if(mem_dcache_addrOK)begin
                dcache_pipeline_ready = 1;
                FSM_rbuf_we = 1;
            end
        end
        default:;
    endcase
end
endmodule

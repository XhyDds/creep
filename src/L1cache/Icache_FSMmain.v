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
    output      icache_pipeline_ready1,
    input       [31:0]pipeline_icache_opcode,//好像不需要 用rbuf的即可
    input       pipeline_icache_opflag,
    input       [31:0]pipeline_icache_ctrl,//stall flush branch ...
    output      icache_pipeline_stall,//stall form icache

    output reg  icache_mem_req,
    output reg  [1:0]icache_mem_size,//0-1byte  1-2b    2-4b
    input       mem_icache_addrOK,//发送的地址和数据都被接收
    input       mem_icache_dataOK,//返回的数据有效

    //模块间信号
    
    //reqbuf
    output reg  FSM_rbuf_we,
    input       [31:0]FSM_rbuf_opcode,
    input       FSM_rbuf_opflag,//好像不需要
    input       [31:0]FSM_rbuf_addr,

    //lru
    output reg  FSM_use0,FSM_use1,
    input       FSM_wal_sel_lru,

    //data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output      [way-1:0]FSM_TagV_we,//两个相同
    // output reg  FSM_way_select,

    //dirty 暂无
    // input       FSM_Dirty,
    // output reg  FSM_Dirtytable_set1,FSM_Dirtytable_set0,
   
    //数据选择
    // output reg  FSM_choose_stall,
    output reg  FSM_send_nop,
    output reg  FSM_choose_way,
    output reg  FSM_choose_return,
    output reg  [offset_width-1:0]FSM_choose_word
    
    );
//对字节和byte的选择暂未加入

reg icache_pipeline_ready;
assign icache_pipeline_stall= ~ icache_pipeline_ready;
assign FSM_TagV_we=FSM_Data_we;
wire hit0,hit1;
assign hit0=FSM_hit[0];
assign hit1=FSM_hit[1];
wire fStall_outside=pipeline_icache_ctrl[0];//注意编号
wire flush_outside=pipeline_icache_ctrl[1];
wire opflag;
assign opflag=pipeline_icache_opflag;
// wire opflag_rbuf;
// assign opflag_rbuf=FSM_rbuf_opflag;

reg rstn_reg;
always @(posedge clk) begin
    rstn_reg <= rstn;
end
assign icache_pipeline_ready1=icache_pipeline_ready&rstn_reg;

reg [4:0]state;
reg [4:0]next_state;
localparam Idle=5'd0,Lookup=5'd1,Miss_r=5'd2,Miss_r_waitdata=5'd3,Stall=5'd5,Operation=5'd6,Flush=5'd7;
always @(posedge clk,negedge rstn) begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    case (state)
        Idle:begin
            if(pipeline_icache_valid & ~ fStall_outside)begin//7.14
                if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        Lookup:begin
            if(fStall_outside)next_state = Lookup;
            else if((!hit0)&&(!hit1))begin
                if(flush_outside)next_state=Flush;
                else next_state=Miss_r;
            end
            else if(pipeline_icache_valid)begin
                if(flush_outside)next_state=Flush;
                else if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        Flush:begin
            if(flush_outside)begin
                next_state=Flush;
            end
            else begin
                if(pipeline_icache_valid)begin
                    if(opflag)next_state=Operation;
                    else next_state=Lookup;
                end
                else next_state=Idle;
            end
        end
        Operation:begin
            next_state=Idle;
        end
        Miss_r:begin
            if(!mem_icache_addrOK)next_state=Miss_r;
            else next_state=Miss_r_waitdata;
        end
        Miss_r_waitdata:begin
            if(!mem_icache_dataOK)next_state=Miss_r_waitdata;
            else begin//数据可信赖，内存准备写
                if(fStall_outside)next_state=Stall;
                else begin
                    if(pipeline_icache_valid)begin
                        if(opflag)next_state=Operation;
                        else next_state=Lookup;
                    end
                    else next_state=Idle;
                end
            end
        end
        Stall:begin
            if(pipeline_icache_valid)begin
                if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        default:next_state=Idle;
    endcase
end
always @(*) begin
    icache_pipeline_ready=0;
    icache_mem_req=0;
    icache_mem_size=2'd0;
    FSM_rbuf_we=0;
    FSM_use0=0;
    FSM_use1=0;
    FSM_Data_we=2'd0;
    // FSM_Dirtytable_set0=0;
    // FSM_Dirtytable_set1=0;
    // FSM_choose_stall = 0;
    FSM_choose_way=0;
    FSM_choose_return=0;
    FSM_choose_word=FSM_rbuf_addr[2+offset_width-1:2];
    FSM_send_nop=0;
    case (state)
        Idle:begin
            case (next_state)
                Lookup:begin
                    icache_pipeline_ready=1;
                    FSM_rbuf_we=1;
                end
                Idle:begin
                    icache_pipeline_ready=1;
                end
                default:begin
                    
                end
            endcase
        end
        Lookup:begin
            case (next_state)
                Miss_r:begin
                    icache_mem_req=1;
                    icache_mem_size=2'd2;
                end
                Lookup:begin//命中
                    //接着流
                    icache_pipeline_ready=1;
                    FSM_rbuf_we=1;
                    if(hit0)begin
                        FSM_choose_way=0;
                        FSM_use0=1;
                    end
                    else if(hit1)begin
                        FSM_choose_way=1;
                        FSM_use1=1;
                    end
                end
                Idle:begin
                    icache_pipeline_ready=1;
                    if(hit0)begin
                        FSM_choose_way=0;
                        FSM_use0=1;
                    end
                    else if(hit1)begin
                        FSM_choose_way=1;
                        FSM_use1=1;
                    end
                end
                Flush:begin
                    icache_pipeline_ready=1;
                    FSM_send_nop=1;
                end
                default:begin
                    
                end
            endcase
        end
        Flush:begin
            icache_pipeline_ready=1;
            FSM_send_nop=1;
            FSM_rbuf_we=1;
        end
        Operation:begin
            case (next_state)
                default:begin
                    
                end
            endcase
        end
        Miss_r:begin
            case (next_state)
                Miss_r:begin
                    icache_mem_req=1;
                    icache_mem_size=2'd2;
                end
                Miss_r_waitdata:begin
                    //nothing
                end
                default:begin
                    
                end
            endcase
        end
        Miss_r_waitdata:begin
            case (next_state)
                Miss_r_waitdata:begin
                    //nothing
                end
                Lookup:begin//这一拍是dataOK
                    FSM_rbuf_we=1;
                    FSM_choose_return=1;//前递
                    icache_pipeline_ready=1;
                    if(FSM_wal_sel_lru==1'd0)begin
                        FSM_Data_we=2'b01;
                        FSM_use0=1;
                    end
                    else if(FSM_wal_sel_lru==1'd1)begin
                        FSM_Data_we=2'b10;
                        FSM_use1=1;
                    end
                end
                Idle:begin
                    FSM_rbuf_we=1;
                    FSM_choose_return=1;//前递
                    icache_pipeline_ready=1;
                    if(FSM_wal_sel_lru==1'd0)begin
                        FSM_Data_we=2'b01;
                        FSM_use0=1;
                    end
                    else if(FSM_wal_sel_lru==1'd1)begin
                        FSM_Data_we=2'b10;
                        FSM_use1=1;
                    end
                end
                Operation:begin
                    FSM_rbuf_we=1;
                    FSM_choose_return=1;//前递
                    // icache_pipeline_ready=1;//???
                    if(FSM_wal_sel_lru==1'd0)begin
                        FSM_Data_we=2'b01;
                        FSM_use0=1;
                    end
                    else if(FSM_wal_sel_lru==1'd1)begin
                        FSM_Data_we=2'b10;
                        FSM_use1=1;
                    end
                end
                Stall:begin
                    FSM_rbuf_we=1;
                    FSM_choose_return=1;//这是必须的
                    icache_pipeline_ready=1;
                    if(FSM_wal_sel_lru==1'd0)begin
                        FSM_Data_we=2'b01;
                        FSM_use0=1;
                    end
                    else if(FSM_wal_sel_lru==1'd1)begin
                        FSM_Data_we=2'b10;
                        FSM_use1=1;
                    end
                end
                default:begin
                    
                end
            endcase
        end
        Stall:begin//考虑Stall情况  让外面多流一拍
            icache_pipeline_ready=1;
            // FSM_choose_stall = 1;
        end
        default:begin
                    
        end 
    endcase
end
endmodule

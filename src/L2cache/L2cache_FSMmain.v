`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:17:30
// Design Name: 
// Module Name: L2cache_FSMmain
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

//写回写分配
module L2cache_FSMmain#(
    parameter   index_width=8,
                offset_width=2,
                way=4
)
(
    input clk,rstn,

    //上下游信号
    input       pipeline_L2cache_vaild,
    output reg  L2cache_pipeline_ready,
    input       [3:0]pipeline_L2cache_wstrb,
    input       [31:0]pipeline_L2cache_opcode,//好像不需要 用rbuf的即可
    input       pipeline_L2cache_opflag,
    input       [31:0]pipeline_L2cache_ctrl,//stall flush branch ...
    output      L2cache_pipeline_stall,//stall form L2cache
    // output reg  [31:0]L2cache_mem_addr,
    // output reg  [31:0]L2cache_mem_data,
    output reg  L2cache_mem_req,
    output reg  L2cache_mem_wr,//write-1  read-0
    output reg  [1:0]L2cache_mem_size,//0-1byte  1-2b    2-4b
    output reg  [3:0]L2cache_mem_wstrb,//字节写使能
    input       mem_L2cache_addrOK,//发送的地址和数据都被接收
    input       mem_L2cache_dataOK,//返回的数据有效

    //模块间信号

    //reqbuf
    output reg  FSM_rbuf_we,
    input       [31:0]FSM_rbuf_opcode,
    input       FSM_rbuf_opflag,//好像不需要
    input       [31:0]FSM_rbuf_addr,
    input       FSM_rbuf_type,//0-read  1-write
    input       [3:0]FSM_rbuf_wstrb,

    //lru
    output reg  FSM_use0,FSM_use1,
    input       FSM_wal_sel_lru,

    //data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output      [way-1:0]FSM_TagV_we,//两个相同
    output reg  FSM_Data_replace,
    // output reg  FSM_way_select,


    input       FSM_Dirty,
    
    output reg  FSM_Dirtytable_set1,FSM_Dirtytable_set0,

    //Return Buffer
   
    //数据选择
    output reg  FSM_choose_way,
    output reg  FSM_choose_return,
    output reg  [offset_width-1:0]FSM_choose_word
    
    );
//对字节和byte的选择暂未加入


assign L2cache_pipeline_stall=L2cache_pipeline_ready;
assign FSM_TagV_we=FSM_Data_we;
wire hit0,hit1;
assign hit0=FSM_hit[0];
assign hit1=FSM_hit[1];
wire fStall_outside=0;//注意编号        好像不需要响应stall？？
wire opflag;
assign opflag=pipeline_L2cache_opflag;
// wire opflag_rbuf;
// assign opflag_rbuf=FSM_rbuf_opflag;


reg [4:0]state;
reg [4:0]next_state;
localparam Idle=5'd0,Lookup=5'd1,Miss_r=5'd2,Miss_r_waitdata=5'd3,Miss_w=5'd4,Replace=5'd5,Replace1=5'd6,Operation=5'd7;
always @(posedge clk,negedge rstn) begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    case (state)
        Idle:begin
            if(pipeline_L2cache_vaild)begin
                if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        Lookup:begin
            if((!hit0)&&(!hit1))begin
                if(!FSM_rbuf_type)next_state=Miss_r;//0-read
                else next_state=Miss_w;
            end
            else if(pipeline_L2cache_vaild)begin
                if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        Operation:begin
            next_state=Idle;
        end
        Miss_r:begin
            if(!mem_L2cache_addrOK)next_state=Miss_r;
            else next_state=Miss_r_waitdata;
        end
        Miss_r_waitdata:begin
            if(!mem_L2cache_dataOK)next_state=Miss_r_waitdata;
            else begin//数据可信赖，内存准备写
                if(fStall_outside)next_state=Replace1;
                else next_state=Replace;
            end
        end
        Miss_w:begin
            if(!mem_L2cache_addrOK)next_state=Miss_w;
            else begin
                if(pipeline_L2cache_vaild)begin
                    if(opflag)next_state=Operation;
                    else next_state=Lookup;
                end
                else next_state=Idle;
            end
        end
        Replace:begin
            if(pipeline_L2cache_vaild)begin
                if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        Replace1:begin
            next_state=Replace;
        end
        default:next_state=Idle;
    endcase
end
always @(*) begin
    L2cache_pipeline_ready=0;
    L2cache_mem_req=0;
    L2cache_mem_wr=0;
    L2cache_mem_size=2'd0;
    L2cache_mem_wstrb=4'd0;
    FSM_rbuf_we=0;
    FSM_use0=0;
    FSM_use1=0;
    FSM_Data_we=2'd0;
    // FSM_Dirtytable_set0=0;
    // FSM_Dirtytable_set1=0;
    FSM_choose_way=0;
    FSM_choose_return=0;
    FSM_Data_replace=0;
    FSM_choose_word=FSM_rbuf_addr[2+offset_width-1:2];
    case (state)
        Idle:begin
            case (next_state)
                Lookup:begin
                    L2cache_pipeline_ready=1;
                    FSM_rbuf_we=1;
                end
                Idle:begin
                    L2cache_pipeline_ready=1;
                end
                default:begin
                    
                end
            endcase
        end
        Lookup:begin
            case (next_state)
                Miss_r:begin
                    L2cache_mem_req=1;
                    L2cache_mem_wr=0;
                    L2cache_mem_size=2'd2;
                    L2cache_mem_wstrb=4'b0000;
                end
                Miss_w:begin
                    L2cache_mem_req=1;
                    L2cache_mem_wr=1;
                    L2cache_mem_size=2'd2;
                    L2cache_mem_wstrb=4'b1111;

                    //写Miss的时候同时写入主存和cache
                    if(FSM_wal_sel_lru==1'd0)begin
                        FSM_Data_we[0]=1;
                        FSM_use0=1;
                    end
                    else if(FSM_wal_sel_lru==1'd1)begin
                        FSM_Data_we[1]=1;
                        FSM_use1=1;
                    end
                end
                Lookup:begin//命中
                    //接着流
                    L2cache_pipeline_ready=1;
                    FSM_rbuf_we=1;
                    if(!FSM_rbuf_type)begin//读
                        if(hit0)begin
                            FSM_choose_way=0;
                            FSM_use0=1;
                        end
                        else if(hit1)begin
                            FSM_choose_way=1;
                            FSM_use1=1;
                        end
                    end
                    else begin//写
                        if(hit0)begin
                            FSM_Data_we[0]=1;//这个Data的使能和Tag是相同的
                            FSM_use0=1;
                        end
                        else if(hit1)begin
                            FSM_Data_we[1]=1;
                            FSM_use1=1;
                        end
                    end
                end
                Idle:begin
                    L2cache_pipeline_ready=1;
                    if(!FSM_rbuf_type)begin//读
                        if(hit0)begin
                            FSM_choose_way=0;
                            FSM_use0=1;
                        end
                        else if(hit1)begin
                            FSM_choose_way=1;
                            FSM_use1=1;
                        end
                    end
                    else begin//写
                        if(hit0)begin
                            FSM_Data_we[0]=1;//这个Data的使能和Tag是相同的
                            FSM_use0=1;
                        end
                        else if(hit1)begin
                            FSM_Data_we[1]=1;
                            FSM_use1=1;
                        end
                    end
                end
                default:begin
                    
                end
            endcase
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
                    L2cache_mem_req=1;
                    L2cache_mem_wr=0;
                    L2cache_mem_size=2'd2;
                    L2cache_mem_wstrb=4'b0000;
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
                Replace:begin//这一拍是dataOK
                    FSM_Data_replace=1;
                    FSM_rbuf_we=1;
                    FSM_choose_return=1;//前递
                    L2cache_pipeline_ready=1;//5.30改动
                    if(FSM_wal_sel_lru==1'd0)begin
                        FSM_Data_we[0]=1;
                        FSM_use0=1;
                    end
                    else if(FSM_wal_sel_lru==1'd1)begin
                        FSM_Data_we[1]=1;
                        FSM_use1=1;
                    end
                end
                Replace1:begin
                    FSM_Data_replace=1;
                    FSM_rbuf_we=1;
                    FSM_choose_return=1;//这是必须的
                    L2cache_pipeline_ready=1;//5.30改动
                    if(FSM_wal_sel_lru==1'd0)begin
                        FSM_Data_we[0]=1;
                        FSM_use0=1;
                    end
                    else if(FSM_wal_sel_lru==1'd1)begin
                        FSM_Data_we[1]=1;
                        FSM_use1=1;
                    end
                end
                default:begin
                    
                end
            endcase
        end
        Miss_w:begin
            case (next_state)
                Miss_w:begin
                    L2cache_mem_req=1;
                    L2cache_mem_wr=1;
                    L2cache_mem_size=2'd2;
                    L2cache_mem_wstrb=4'b1111;
                end
                Lookup:begin
                    L2cache_pipeline_ready=1;
                    FSM_rbuf_we=1;
                end
                Idle:begin
                    L2cache_pipeline_ready=1;
                end
                default:begin
                    
                end
            endcase
        end
        Replace:begin
            //nothing 此拍空出 但是可以优化一个周期 之后再说
        end
        Replace1:begin//考虑fStall情况  让外面多流一拍
            L2cache_pipeline_ready=1;
        end
        default:begin
                    
        end 
    endcase
end
endmodule
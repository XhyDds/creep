// `define onlyDcache
// `define DMA
`define withL2cache
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
    input       [31:0]pipeline_dcache_ctrl,//stall flush branch ...
    output      dcache_pipeline_stall,//stall form dcache
    // output reg  [31:0]dcache_mem_addr,
    // output reg  [31:0]dcache_mem_data,
    output reg  dcache_mem_req,
    output reg  dcache_mem_wr,//write-1  read-0
    output reg  [1:0]dcache_mem_size,//0-1byte  1-2b    2-4b
    output reg  [3:0]dcache_mem_wstrb,//字节写使能
    input       mem_dcache_addrOK,//发送的地址和数据都被接收
    input       mem_dcache_bvalid,//写有效
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

    //paddr寄存器
    output reg  FSM_paddr_we,

    //lru
    output reg  FSM_use0,FSM_use1,
    input       FSM_wal_sel_lru,

    //data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output      [way-1:0]FSM_TagV_we,//两个相同
    output reg  FSM_Data_replace,
    output reg  [way-1:0]FSM_TagV_unvalid,
    // output reg  FSM_way_select,

    //dirty 暂无
    // input       FSM_Dirty,
    // output reg  FSM_Dirtytable_set1,FSM_Dirtytable_set0,

    //Return Buffer
   
    //数据选择
    output reg  FSM_choose_way,
    output reg  FSM_choose_return,
    output reg  [offset_width-1:0]FSM_choose_word
    
    );
wire [index_width:0]useparam1 = pipeline_dcache_wstrb;
wire [31:0]usesignal1 = pipeline_dcache_opcode;
wire [31:0]usesignal2 = pipeline_dcache_ctrl;
wire [31:0]usesignal3 = mem_dcache_bvalid;
wire [31:0]usesignal4 = FSM_rbuf_opcode;
wire [31:0]usesignal5 = FSM_rbuf_opflag;
wire [31:0]usesignal6 = FSM_rbuf_addr;

assign dcache_pipeline_stall = ~ dcache_pipeline_ready;
assign FSM_TagV_we=FSM_Data_we;
wire hit0,hit1;
assign hit0=FSM_hit[0];
assign hit1=FSM_hit[1];
wire fStall_outside=0;//注意编号        好像不需要响应stall？？
wire opflag;
assign opflag=pipeline_dcache_opflag;
// wire opflag_rbuf;
// assign opflag_rbuf=FSM_rbuf_opflag;

reg [4:0]state;
reg [4:0]next_state;//需要响应stall吗？？
localparam Idle=5'd0,Lookup=5'd1,Miss_r=5'd2,Miss_r_waitdata=5'd3,Miss_w=5'd4,Stall=5'd6,Operation=5'd7,Hit_w=5'd8,Hit_w1=5'd9;
always @(posedge clk,negedge rstn) begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    case (state)
        Idle:begin
            if(pipeline_dcache_valid)begin
                if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        Lookup:begin
            if(FSM_rbuf_SUC)begin//若hit则置无效
                if(FSM_rbuf_type)next_state = Miss_r;
                else next_state = Miss_w;
            end
            else begin
                `ifdef DMA
                if(1)begin
                    if(!FSM_rbuf_type)next_state=Miss_r;//0-read
                    else next_state=Miss_w;
                end
                `else 
                if((!hit0)&&(!hit1))begin//强制缺失
                    if(!FSM_rbuf_type)next_state=Miss_r;//0-read
                    else next_state=Miss_w;
                end
                `endif
                else if(!FSM_rbuf_type)begin//r
                    if(pipeline_dcache_valid)begin
                        if(opflag)next_state=Operation;
                        else next_state=Lookup;
                    end
                    else next_state=Idle;
                end
                else next_state = Hit_w;//r
            end
        end
        Operation:begin
            next_state=Idle;
        end

        `ifdef withL2cache
        Hit_w:begin
            if(!mem_dcache_addrOK)next_state = Hit_w;
            else begin
                if(pipeline_dcache_valid)begin
                    if(opflag)next_state=Operation;
                    else next_state=Lookup;
                end
                else next_state=Idle;
            end
        end
        `endif

        `ifdef onlyDcache
        Hit_w:begin
            if(!mem_dcache_addrOK)next_state = Hit_w;
            else next_state = Hit_w1;
        end
        Hit_w1:begin
            if(!mem_dcache_bvalid)next_state = Hit_w1;
            else begin
                if(pipeline_dcache_valid)begin
                    if(opflag)next_state=Operation;
                    else next_state=Lookup;
                end
                else next_state=Idle;
            end
        end
        `endif

        Miss_r:begin
            if(!mem_dcache_addrOK)next_state=Miss_r;
            else next_state=Miss_r_waitdata;
        end
        Miss_r_waitdata:begin
            if(!mem_dcache_dataOK)next_state=Miss_r_waitdata;
            else begin//数据可信赖，内存准备写
                if(fStall_outside)next_state=Stall;
                else begin
                    if(pipeline_dcache_valid)begin
                        if(opflag)next_state=Operation;
                        else next_state=Lookup;
                    end
                    else next_state=Idle;
                end
            end
        end
        Miss_w:begin//若强序写 addrOK是dataOK
            if(!mem_dcache_addrOK)next_state=Miss_w;
            else begin
                if(pipeline_dcache_valid)begin
                    if(opflag)next_state=Operation;
                    else next_state=Lookup;
                end
                else next_state=Idle;
            end
        end
        Stall:begin
            if(pipeline_dcache_valid)begin
                if(opflag)next_state=Operation;
                else next_state=Lookup;
            end
            else next_state=Idle;
        end
        default:next_state=Idle;
    endcase
end
always @(*) begin
    dcache_pipeline_ready = 0;
    dcache_mem_req = 0;
    dcache_mem_wr = 0;
    dcache_mem_size = 2'd2;
    dcache_mem_wstrb = FSM_rbuf_wstrb;
    FSM_rbuf_we = 0;
    FSM_paddr_we = 0;
    FSM_use0 = 0;
    FSM_use1 = 0;
    FSM_Data_we = 2'd0;
    FSM_TagV_unvalid = 2'd0;
    FSM_choose_way = 0;
    FSM_choose_return = 0;
    FSM_Data_replace = 0;
    FSM_choose_word = FSM_rbuf_addr[2+offset_width-1:2];
    case (state)
        Idle:begin
            case (next_state)
                Lookup:begin
                    dcache_pipeline_ready=1;
                    FSM_rbuf_we=1;
                end
                Idle:begin
                    dcache_pipeline_ready=1;
                end
                default:begin
                    
                end
            endcase
        end
        Lookup:begin
            if(FSM_rbuf_SUC)begin
                if(hit0)FSM_TagV_unvalid = 2'b01;
                else if(hit1)FSM_TagV_unvalid = 2'b10;
            end
            case (next_state)
                Miss_r:begin
                    FSM_paddr_we = 1;
                    dcache_mem_wr=0;
                end
                Miss_w:begin
                    dcache_mem_wr=1;
                    FSM_paddr_we = 1;
                end
                Lookup:begin//命中
                    //接着流
                    dcache_pipeline_ready=1;
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
                Hit_w:begin
                    dcache_mem_req=1;
                    dcache_mem_wr=1;
                    if(hit0)begin
                        FSM_Data_we[0]=1;
                        FSM_use0=1;
                    end
                    else if(hit1)begin
                        FSM_Data_we[1]=1;
                        FSM_use1=1;
                    end
                end
                Idle:begin
                    dcache_pipeline_ready=1;
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
        Hit_w:begin
            dcache_mem_wr=1;//conbination
            dcache_mem_req=1;
            if(next_state == Hit_w || next_state == Hit_w1)begin
                // dcache_mem_req=1;
            end
            else begin
                dcache_pipeline_ready = 1;
                FSM_rbuf_we = 1;
            end
        end
        Hit_w1:begin
            if(next_state == Hit_w1)begin
                //nothing
            end
            else begin
                dcache_pipeline_ready = 1;
                FSM_rbuf_we = 1;
            end
        end
        Miss_r:begin
            dcache_mem_wr=0;//conbination
            dcache_mem_req=1;
        end
        Miss_r_waitdata:begin
            if(next_state != Miss_r_waitdata)begin
                FSM_Data_replace=1;
                FSM_rbuf_we=1;
                FSM_choose_return=1;
                dcache_pipeline_ready=1;
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
            else begin
                
            end
        end
        Miss_w:begin
            dcache_mem_wr=1;//conbination
            dcache_mem_req=1;
            case (next_state)
                Miss_w:begin

                end
                Lookup:begin
                    dcache_pipeline_ready=1;
                    FSM_rbuf_we=1;
                end
                Idle:begin
                    dcache_pipeline_ready=1;
                end
                default:begin
                    
                end
            endcase
        end
        Stall:begin//考虑fStall情况  让外面多流一拍
            dcache_pipeline_ready=1;
        end
        default:begin
                    
        end 
    endcase
end
endmodule

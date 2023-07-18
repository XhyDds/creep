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

// 写缓冲队列
// 非循环队列
// 支持query,insert,get三项功能
// - query:根据地址查询最近入队的相同地址的数据
// - insert:获取队尾
// - get:获取队首

// query:当周期组合给出数据以及是否命中，下周期开始即可用
// push时

module WriteBuffer #(
    parameter   length=5,
                offset_width=2
) (
    input  clk,
    input  rstn,
    //PULL
    input  [31:0] in_addr,
    input  [(1<<offset_width)*32-1:0] in_data,
    input  in_valid,
    output reg in_ready,
    //PUSH
    output [31:0] out_addr,
    output [31:0] out_data,
    output reg out_valid,
    input  out_awready,
    input  out_wready,
    output reg out_last,
    input  out_bvalid,
    output reg out_bready,

    //query
    input  [31:0] query_addr,
    output [(1<<offset_width)*32-1:0] query_data,
    output query_ok                        //query是否成功
);
    parameter WORD = (1<<offset_width)*32;
    reg [31:0] pointer;
    reg [31:0] buffer_addr[length-1:0];
    reg [WORD-1:0] buffer_data[0:length-1];

    wire _in_valid=in_valid&&(pointer!=length-1);
    wire _out_awready=out_awready&&(pointer!=0);

    reg [(1<<offset_width)*32-1:0] _out_data;

    //pull(->axi)

    //state machine
    parameter IDLE_L = 4'd0,PULL=4'd1,
            SEND_0=4'd2,SEND_1=4'd3,SEND_2=4'd4,SEND_3=4'd5,_SEND=4'd6;
    reg [3:0] crt_pull,nxt_pull;
    always @(posedge clk,negedge rstn) begin
        if (!rstn) begin
            crt_pull<=IDLE_L;
        end
        else begin
            crt_pull<=nxt_pull;
        end
    end
    always @(*) begin
        case (crt_pull)
            IDLE_L: begin
                                    nxt_pull=PULL;
            end 
            PULL:       begin
                if(_out_awready)    nxt_pull=SEND_0;
                else                nxt_pull=PULL;
            end
            SEND_0: begin
                if(out_wready)      nxt_pull=SEND_1;
                else                nxt_pull=SEND_0;
            end
            SEND_1: begin
                if(out_wready)      nxt_pull=SEND_2;
                else                nxt_pull=SEND_1;
            end
            SEND_2: begin
                if(out_wready)      nxt_pull=SEND_3;
                else                nxt_pull=SEND_2;
            end
            SEND_3: begin
                if(out_wready)      nxt_pull=_SEND;
                else                nxt_pull=SEND_3;
            end
            _SEND: begin
                if(out_bvalid)      nxt_pull=IDLE_L;
                else                nxt_pull=_SEND;
            end
            default:                nxt_pull=IDLE_L;
        endcase
    end
    //signal
    //组合action
    always @(*) begin
        out_valid=0;
        out_last=0;
        out_addr=0;
        out_data=0;
        out_bready=0;
        case (crt_pull)
            IDLE_L: begin
                
            end
            PULL: begin
                out_valid=1;
                out_addr=buffer_addr[pointer];
            end
            SEND_0: begin
                out_valid=1;
                out_data=_out_data[31:0];           //大小端之后处理
            end
            SEND_1: begin
                out_valid=1;
                out_data=_out_data[63:32];
            end
            SEND_2: begin
                out_valid=1;
                out_data=_out_data[95:64];
            end
            SEND_3: begin
                out_valid=1;
                out_last=1;
                out_data=_out_data[127:96];
            end
            _SEND: begin
                out_bready=1;
            end
            default: ;
        endcase
    end
    //时序action
    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            _out_data<=0;
        end
        else begin
            case (crt_pull)
                IDLE_L: begin
                end
                PULL: begin
                    _out_data<=buffer_data[pointer];
                end
                PULL_PUSH: begin
                    _out_data<=buffer_data[pointer];
                end
                default: ;
            endcase
        end
    end

    //push(cache->)
    
    //statemachine
    parameter IDLE_H = 4'd0,PUSH=4'd1,PULL_PUSH=4'd2,PULL_H=4'd3;
    reg [3:0] crt_push,nxt_push;
    always @(posedge clk,negedge rstn) begin
        if (!rstn) begin
            crt_push<=IDLE_L;
        end
        else begin
            crt_push<=nxt_push;
        end
    end

    always @(*) begin
        case (crt_push)
            IDLE_H: begin
                if(_in_valid) begin
                    if(_out_awready)    nxt_push=PULL_PUSH;
                    else                nxt_push=PUSH;
                end
                else if(_out_awready)   nxt_push=PULL_H;
                else                    nxt_push=IDLE_H;
            end 
            PUSH: begin
                if(_out_awready)        nxt_push=PULL_H;
                else                    nxt_push=IDLE_H;
            end
            PULL_H: begin
                if(_out_awready)        nxt_push=PULL_H;
                else                    nxt_push=IDLE_H;
            end
            PULL_PUSH: begin
                if(_out_awready)        nxt_push=PULL_H;
                else                    nxt_push=IDLE_H;
            end
            default:                    nxt_push=IDLE_H;
        endcase
    end

    //signal
    //组合action
    always @(*) begin
        in_ready=0;
        case (crt_push)
            IDLE_H: begin
                
            end
            PULL_H: begin
                
            end
            PUSH: begin
                in_ready=1;
            end
            PULL_PUSH: begin
                in_ready=1;
            end
            default: ;
        endcase
    end
    //时序action
    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            pointer<=0;
            buffer_addr[32'd0]<=0;
            buffer_data[32'd0]<=0;
            buffer_addr[32'd1]<=0;
            buffer_data[32'd1]<=0;
            buffer_addr[32'd2]<=0;
            buffer_data[32'd2]<=0;
            buffer_addr[32'd3]<=0;
            buffer_data[32'd3]<=0;
            buffer_addr[32'd4]<=0;
            buffer_data[32'd4]<=0;
        end
        else begin
            case (nxt_push)
                PULL_H: pointer<=pointer-1;
                PUSH:   pointer<=pointer+1;
                PULL_PUSH: ;
                IDLE_H: ;
                default: pointer<=0;
            endcase

            case (crt_push)
                IDLE_H: begin
                    if(nxt_push==PUSH) begin
                        buffer_addr[32'd0]<=in_addr;
                        buffer_data[32'd0]<=in_data;
                        buffer_addr[32'd1]<=buffer_addr[32'd0];
                        buffer_data[32'd1]<=buffer_data[32'd0];
                        buffer_addr[32'd2]<=buffer_addr[32'd1];
                        buffer_data[32'd2]<=buffer_data[32'd1];
                        buffer_addr[32'd3]<=buffer_addr[32'd2];
                        buffer_data[32'd3]<=buffer_data[32'd2];
                        buffer_addr[32'd4]<=buffer_addr[32'd3];
                        buffer_data[32'd4]<=buffer_data[32'd3];
                    end
                    else if(nxt_push==PULL_PUSH) begin
                        buffer_addr[32'd0]<=in_addr;
                        buffer_data[32'd0]<=in_data;
                        buffer_addr[32'd1]<=buffer_addr[32'd0];
                        buffer_data[32'd1]<=buffer_data[32'd0];
                        buffer_addr[32'd2]<=buffer_addr[32'd1];
                        buffer_data[32'd2]<=buffer_data[32'd1];
                        buffer_addr[32'd3]<=buffer_addr[32'd2];
                        buffer_data[32'd3]<=buffer_data[32'd2];
                        buffer_addr[32'd4]<=buffer_addr[32'd3];
                        buffer_data[32'd4]<=buffer_data[32'd3];
                    end
                end
                default: ;
            endcase
        end
    end

    //query
    reg res[length-1:0];
    always @(*) begin
        res[32'd0]=(query_addr==buffer_addr[32'd0]);
        res[32'd1]=(query_addr==buffer_addr[32'd1]);
        res[32'd2]=(query_addr==buffer_addr[32'd2]);
        res[32'd3]=(query_addr==buffer_addr[32'd3]);
        res[32'd4]=(query_addr==buffer_addr[32'd4]);
    end

    always @(*) begin
             if(res[3'd0]==1'b1) begin query_ok=1;query_data=buffer_data[32'd0]; end
        else if(res[3'd1]==1'b1) begin query_ok=1;query_data=buffer_data[32'd1]; end
        else if(res[3'd2]==1'b1) begin query_ok=1;query_data=buffer_data[32'd2]; end
        else if(res[3'd3]==1'b1) begin query_ok=1;query_data=buffer_data[32'd3]; end
        else if(res[3'd4]==1'b1) begin query_ok=1;query_data=buffer_data[32'd4]; end
        else begin
            query_ok=0;
            query_data=0;
        end
    end

endmodule

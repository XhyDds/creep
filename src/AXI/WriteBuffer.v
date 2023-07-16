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

    //pull&push
    //state machine
    parameter IDLE = 4'd0,PULL=4'd1,PUSH=4'd2,PULL_PUSH=4'd3,
            SEND_0=4'd4,SEND_1=4'd5,SEND_2=4'd6,SEND_3=4'd7,_SEND=4'd8;
    reg [3:0] crt,nxt;
    always @(posedge clk,negedge rstn) begin
        if (!rstn) begin
            crt<=IDLE;
        end
        else begin
            crt<=nxt;
        end
    end
    always @(*) begin
        case (crt)
            IDLE: begin
               if (_out_awready) begin
                    if(_in_valid)   nxt=PULL_PUSH;
                    else            nxt=PULL;
               end
               else if(_in_valid) begin
                                    nxt=PUSH;
               end
               else                 nxt=IDLE;
            end 
            PULL:       begin
                if(_out_awready)    nxt=SEND_0;
                else                nxt=PULL;
            end
            PUSH:                   nxt=IDLE;
            PULL_PUSH:  begin
                if(_out_awready)    nxt=SEND_0;
                else                nxt=PULL_PUSH;
            end
            SEND_0: begin
                if(out_wready)      nxt=SEND_1;
                else                nxt=SEND_0;
            end
            SEND_1: begin
                if(out_wready)      nxt=SEND_2;
                else                nxt=SEND_1;
            end
            SEND_2: begin
                if(out_wready)      nxt=SEND_3;
                else                nxt=SEND_2;
            end
            SEND_3: begin
                if(out_wready)      nxt=_SEND;
                else                nxt=SEND_3;
            end
            _SEND: begin
                if(out_bvalid)      nxt=IDLE;
                else                nxt=_SEND;
            end
            default:                nxt=IDLE;
        endcase
    end
    //signal
    //组合action
    always @(*) begin
        in_ready=0;
        out_valid=0;
        out_last=0;
        out_addr=0;
        out_data=0;
        out_bready=0;
        case (crt)
            IDLE: begin
                
            end
            PULL: begin
                out_valid=1;
                out_addr=buffer_addr[pointer];
            end
            PUSH: begin
                in_ready=1;
            end
            PULL_PUSH: begin
                in_ready=1;
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

            _out_data<=0;
        end
        else begin
            case (crt)
                IDLE: begin
                    if(nxt==PULL)begin
                        pointer<=pointer-1;
                    end
                    else if(nxt==PUSH) begin
                        pointer<=pointer+1;
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
                    else if(nxt==PULL_PUSH) begin
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
                PUSH: begin
                    
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
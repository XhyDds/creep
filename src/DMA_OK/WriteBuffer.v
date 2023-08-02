
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
                offset_width=3
) (
    input  clk,
    input  rstn,
    //PULL
    input  [31:0] in_addr,
    input  [(1<<offset_width)*32-1:0] in_data,
    input  in_valid,
    output reg in_ready,
    //PUSH
    output reg [31:0] out_addr,
    output reg [31:0] out_data,
    output reg out_valid,
    output reg out_wvalid,
    input  out_awready,
    input  out_wready,
    output reg out_last,
    input  out_bvalid,
    output reg out_bready,

    //query
    input  [31:0] query_addr,
    output reg[(1<<offset_width)*32-1:0] query_data,
    output reg query_ok,                       //query是否成功

    //状态机
    input  [3:0] crt_pull,
    input  [3:0] nxt_pull,
    output reg [31:0] pointer,
    input  dma_sign
);
    parameter WORD = (1<<offset_width)*32;
    reg [31:0] buffer_addr[length-1:0];
    reg [WORD-1:0] buffer_data[0:length-1];

    wire _in_valid=in_valid&&(pointer!=length-1)&&!dma_sign;
    // wire _out_awready=out_awready&&(pointer!=0);

    reg [(1<<offset_width)*32-1:0] _out_data;

    //pull(->axi)
    //state machine
    parameter IDLE_L = 4'd0,
            PULL=4'd4,SEND_0=4'd5,SEND_1=4'd6,SEND_2=4'd7,SEND_3=4'd8,SEND_4=4'd9,SEND_5=4'd10,SEND_6=4'd11,SEND_7=4'd12,_SEND=4'd13;
    //外部输入
    //组合action
    reg pointer_minus;
    always @(*) begin
        out_valid=0;
        out_last=0;
        out_addr=0;
        out_data=0;
        out_bready=0;
        out_wvalid=0;

        pointer_minus=0;
        case (crt_pull)
            IDLE_L: begin
                if(nxt_pull==PULL) begin
                    pointer_minus=1;
                end
                else ;
            end
            PULL: begin
                out_valid=1;
                out_addr=buffer_addr[pointer];
            end
            SEND_0: begin
                out_valid=1;
                out_data=_out_data[31:0];
                out_wvalid=1;
            end
            SEND_1: begin
                out_valid=1;
                out_data=_out_data[63:32];
                out_wvalid=1;
            end
            SEND_2: begin
                out_valid=1;
                out_data=_out_data[95:64];
                out_wvalid=1;
            end
            SEND_3: begin
                out_valid=1;
                out_data=_out_data[127:96];
                out_wvalid=1;
            end
            SEND_4: begin
                out_valid=1;
                out_data=_out_data[159:128];
                out_wvalid=1;
            end
            SEND_5: begin
                out_valid=1;
                out_data=_out_data[191:160];
                out_wvalid=1;
            end
            SEND_6: begin
                out_valid=1;
                out_data=_out_data[223:192];
                out_wvalid=1;
            end
            SEND_7: begin
                out_valid=1;
                out_last=1;
                out_data=_out_data[255:224];
                out_wvalid=1;
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
                default: ;
            endcase
        end
    end

    //push(cache->)
    
    //statemachine
    localparam IDLE_H = 4'd0,PUSH=4'd1;
    reg [3:0] crt_push,nxt_push;
    always @(posedge clk,negedge rstn) begin
        if (!rstn) begin
            crt_push<=IDLE_H;
        end
        else begin
            crt_push<=nxt_push;
        end
    end

    always @(*) begin
        case (crt_push)
            IDLE_H: begin
                if(_in_valid)           nxt_push=PUSH;
                else                    nxt_push=IDLE_H;
            end
            PUSH:                       nxt_push=IDLE_H;
            default:                    nxt_push=IDLE_H;
        endcase
    end

    //signal
    //组合action
    reg pointer_plus;
    always @(*) begin
        in_ready=0;
        pointer_plus=0;
        case (crt_push)
            IDLE_H: begin
                if(nxt_push==PUSH)  pointer_plus=1;
                else ;
            end
            PUSH: begin
                in_ready=1;
            end
            default: ;
        endcase
    end
    //时序action
    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
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
                    else ;
                end
                default: ;
            endcase
        end
    end

    //pointer仲裁
    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            pointer<=0;
        end
        else begin
            if(pointer_minus&&pointer_plus) ;
            else if(pointer_minus) pointer<=pointer-1;
            else if(pointer_plus) pointer<=pointer+1;
            else ;
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
        else                     begin query_ok=0;query_data=0                 ; end
    end

endmodule

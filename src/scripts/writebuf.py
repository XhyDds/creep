# len=5
# offset=2
with open('config.txt','r') as file:
    config=file.read()
for line in config.split('\n'):
    if line.startswith('L2_offset_width'):
        offset=int(line.split('=')[1])
    if line.startswith('WriteBuffer_len'):
        len=int(line.split('=')[1])
code='''
// 写缓冲队列
// 非循环队列
// 支持query,insert,get三项功能
// - query:根据地址查询最近入队的相同地址的数据
// - insert:获取队尾
// - get:获取队首

// query:当周期组合给出数据以及是否命中，下周期开始即可用
// push时

module WriteBuffer #(
    parameter   length='''+str(len)+''',
                offset_width='''+str(offset)+'''
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
    output reg [(1<<offset_width)*32-1:0] query_data,
    output reg query_ok,                       //query是否成功

    //互斥锁
    input  dma_lock,
    output reg wrt_lock
);
    parameter WORD = (1<<offset_width)*32;
    reg [31:0] pointer;
    reg [31:0] buffer_addr[length-1:0];
    reg [WORD-1:0] buffer_data[0:length-1];

    wire _in_valid=in_valid&&(pointer!=length-1);
    // wire _out_awready=out_awready&&(pointer!=0);

    reg [(1<<offset_width)*32-1:0] _out_data;

    //pull(->axi)

    //state machine
    parameter IDLE_L = 4'd0,PULL=4'd1,
            '''
offset=1<<offset
for i in range(offset):
    code+='''SEND_'''+str(i)+'''=4'd'''+str(i+2)+''','''
code+='''_SEND=4'd'''+str(offset+2)+''';
    reg [3:0] crt_pull,nxt_pull;
    always @(posedge clk)begin
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
                if(dma_lock==0 && pointer!=0)      nxt_pull=PULL;
                else                nxt_pull=IDLE_L;
            end 
            PULL:       begin
                if(out_awready)     nxt_pull=SEND_0;
                else                nxt_pull=PULL;
            end'''
for i in range(offset-1):
    code+='''
            SEND_'''+str(i)+''': begin
                if(out_wready)      nxt_pull=SEND_'''+str(i+1)+''';
                else                nxt_pull=SEND_'''+str(i)+''';
            end'''
code+='''
            SEND_'''+str(offset-1)+''': begin
                if(out_wready)      nxt_pull=_SEND;
                else                nxt_pull=SEND_'''+str(offset-1)+''';
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
    reg pointer_minus;
    always @(*) begin
        out_valid=0;
        out_last=0;
        out_addr=0;
        out_data=0;
        out_bready=0;
        out_wvalid=0;

        pointer_minus=0;

        wrt_lock=0;
        case (crt_pull)
            IDLE_L: begin
                if(nxt_pull==PULL) begin
                    pointer_minus=1;
                    wrt_lock=1;
                end 
                else ;
            end
            PULL: begin
                out_valid=1;
                wrt_lock=1;
                out_addr=buffer_addr[pointer];
            end'''
for i in range(offset-1):
    code+='''
            SEND_'''+str(i)+''': begin
                out_valid=1;
                wrt_lock=1;
                out_data=_out_data['''+str(i*32+31)+''':'''+str(i*32)+'''];
                out_wvalid=1;
            end'''
code+='''
            SEND_'''+str(offset-1)+''': begin
                out_valid=1;
                out_last=1;
                wrt_lock=1;
                out_data=_out_data['''+str(offset*32-1)+''':'''+str(offset*32-32)+'''];
                out_wvalid=1;
            end
            _SEND: begin
                out_bready=1;
                wrt_lock=1;
            end
            default: ;
        endcase
    end
    //时序action
    always @(posedge clk)begin
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
    parameter IDLE_H = 4'd0,PUSH=4'd1;
    reg [3:0] crt_push,nxt_push;
    always @(posedge clk)begin
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
    always @(posedge clk)begin
        if(!rstn) begin'''
for i in range(len):
    code+='''
            buffer_addr[32'd'''+str(i)+''']<=0;
            buffer_data[32'd'''+str(i)+''']<=0;'''
code+='''
        end
        else begin
            case (crt_push)
                IDLE_H: begin
                    if(nxt_push==PUSH) begin
                        buffer_addr[32'd0]<=in_addr;
                        buffer_data[32'd0]<=in_data;'''
for i in range(0,len-1):
    code+='''
                        buffer_addr[32'd'''+str(i+1)+''']<=buffer_addr[32'd'''+str(i)+'''];
                        buffer_data[32'd'''+str(i+1)+''']<=buffer_data[32'd'''+str(i)+'''];'''
code+='''
                    end
                    else ;
                end
                default: ;
            endcase
        end
    end

    //pointer仲裁
    always @(posedge clk)begin
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
    always @(*) begin'''
for i in range(len):
    code+='''
        res[32'd'''+str(i)+''']=(query_addr==buffer_addr[32'd'''+str(i)+''']);'''
code+='''
    end

    always @(*) begin
             if(res[3'd0]==1'b1) begin query_ok=1;query_data=buffer_data[32'd0]; end'''
for i in range(1,len):
    code+='''
        else if(res[3'd'''+str(i)+''']==1'b1) begin query_ok=1;query_data=buffer_data[32'd'''+str(i)+''']; end'''
code+='''
        else                     begin query_ok=0;query_data=0                 ; end
    end

endmodule
'''
# print(code)
with open('WriteBuffer.v','w+') as f:
    f.write(code)
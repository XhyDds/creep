# len=5
# offset=2
with open('config.txt','r') as file:
    config=file.read()
for line in config.split('\n'):
    if line.startswith('L2_offset_width'):
        offset=int(line.split('=')[1])
    if line.startswith('WriteBuffer_len'):
        len=int(line.split('=')[1])
code='''module Write_FSM(
    input  clk,
    input  rstn,

    input  l2cache_mem_req_w,
    input  dma_sign,
    input  [31:0]pointer,
    input  l2_waddrOK,
    input  l2_wready,
    input  l2_bvalid,
    input  out_awready,
    input  out_wready,
    input  out_bvalid,

    output reg [4:0] crt,
    output reg [4:0] nxt
);
    parameter IDLE = 5'd0,DMA_AW=5'd1 , DMA_W=5'd2 , DMA_R=5'd3,
        PULL=5'd4,'''
offset=1<<offset
for i in range(offset):
    code+='''SEND_'''+str(i)+'''=5'd'''+str(i+5)+''','''
code+='''_SEND=5'd'''+str(offset+5)+''';

    always @(posedge clk)begin
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
                if(l2cache_mem_req_w) begin
                    if(dma_sign)
                                    nxt = DMA_AW;
                    else            nxt = IDLE;
                end
                else if(pointer!=0) nxt = PULL;
                else                nxt = IDLE;
            end 
            DMA_AW: begin
                if(l2_waddrOK)      nxt = DMA_W;
                else                nxt = DMA_AW;
            end
            DMA_W: begin
                if(l2_wready)       nxt = DMA_R;
                else                nxt = DMA_W;
            end
            DMA_R: begin
                if(l2_bvalid)       nxt = IDLE;
                else                nxt = DMA_R;
            end

            PULL:       begin
                if(out_awready)     nxt=SEND_0;
                else                nxt=PULL;
            end'''
for i in range(offset-1):
    code+='''
            SEND_'''+str(i)+''': begin
                if(out_wready)      nxt=SEND_'''+str(i+1)+''';
                else                nxt=SEND_'''+str(i)+''';
            end'''
code+='''
            SEND_'''+str(offset-1)+''': begin
                if(out_wready)      nxt=_SEND;
                else                nxt=SEND_'''+str(offset-1)+''';
            end
            _SEND: begin
                if(out_bvalid)      nxt=IDLE;
                else                nxt=_SEND;
            end
            default:                nxt=IDLE;
        endcase
    end
    //signal
endmodule
'''
# print(code)
with open('Write_FSM.v','w+') as f:
    f.write(code)
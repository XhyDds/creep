module Write_FSM(
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
        PULL=5'd4,SEND_0=5'd5,SEND_1=5'd6,SEND_2=5'd7,SEND_3=5'd8,SEND_4=5'd9,SEND_5=5'd10,SEND_6=5'd11,SEND_7=5'd12,SEND_8=5'd13,SEND_9=5'd14,SEND_10=5'd15,SEND_11=5'd16,SEND_12=5'd17,SEND_13=5'd18,SEND_14=5'd19,SEND_15=5'd20,_SEND=5'd21;

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
                if(out_wready)      nxt=SEND_4;
                else                nxt=SEND_3;
            end
            SEND_4: begin
                if(out_wready)      nxt=SEND_5;
                else                nxt=SEND_4;
            end
            SEND_5: begin
                if(out_wready)      nxt=SEND_6;
                else                nxt=SEND_5;
            end
            SEND_6: begin
                if(out_wready)      nxt=SEND_7;
                else                nxt=SEND_6;
            end
            SEND_7: begin
                if(out_wready)      nxt=SEND_8;
                else                nxt=SEND_7;
            end
            SEND_8: begin
                if(out_wready)      nxt=SEND_9;
                else                nxt=SEND_8;
            end
            SEND_9: begin
                if(out_wready)      nxt=SEND_10;
                else                nxt=SEND_9;
            end
            SEND_10: begin
                if(out_wready)      nxt=SEND_11;
                else                nxt=SEND_10;
            end
            SEND_11: begin
                if(out_wready)      nxt=SEND_12;
                else                nxt=SEND_11;
            end
            SEND_12: begin
                if(out_wready)      nxt=SEND_13;
                else                nxt=SEND_12;
            end
            SEND_13: begin
                if(out_wready)      nxt=SEND_14;
                else                nxt=SEND_13;
            end
            SEND_14: begin
                if(out_wready)      nxt=SEND_15;
                else                nxt=SEND_14;
            end
            SEND_15: begin
                if(out_wready)      nxt=_SEND;
                else                nxt=SEND_15;
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

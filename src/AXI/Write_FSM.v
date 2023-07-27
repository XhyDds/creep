module Write_FSM#(

)(
    input  clk,
    input  rstn, 

    output reg [3:0] crt,
    output reg [3:0] nxt
);
        parameter IDLE_L = 4'd0,PULL=4'd1,
            SEND_0=4'd2,SEND_1=4'd3,SEND_2=4'd4,SEND_3=4'd5,SEND_4=4'd6,SEND_5=4'd7,SEND_6=4'd8,SEND_7=4'd9,_SEND=4'd10;
    always @(posedge clk,negedge rstn) begin
        if (!rstn) begin
            crt<=IDLE_L;
        end
        else begin
            crt<=nxt;
        end
    end
    always @(*) begin
        case (crt)
            IDLE_L: begin
                if(dma_lock==0 && pointer!=0)      nxt=PULL;
                else                nxt=IDLE_L;
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
                if(out_wready)      nxt=_SEND;
                else                nxt=SEND_7;
            end
            _SEND: begin
                if(out_bvalid)      nxt=IDLE_L;
                else                nxt=_SEND;
            end
            default:                nxt=IDLE_L;
        endcase
    end
    //signal
endmodule
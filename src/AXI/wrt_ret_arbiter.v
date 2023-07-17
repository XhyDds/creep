/// 此模块负责仲裁读取的数据来自writebuf还是来自returnbuf(axi).
/// 先从writebuf读取，如果writebuf没有数据，再从returnbuf读取。

module wrt_ret_arbiter#(
    parameter offset_width = 2
)(
    input       clk,
    input       rstn,
    //l2cache
    input       l2cache_mem_req_r,
    output reg  mem_l2cache_addrOK_r,
    input       l2cache_mem_rdy,
    output reg  mem_l2cache_dataOK,
    output reg  [(1<<offset_width)*32-1:0]din_mem_l2cache,
    //writebuffer
    input       [(1<<offset_width)*32-1:0]query_data,
    input       query_ok,
    //returnbuffer
    output reg  arbiter_mem_req,
    input       mem_arbiter_addrOK,
    input       mem_arbiter_dataOK,
    input       [(1<<offset_width)*32-1:0]dout_mem_arbiter
);
    //state_machine
    parameter IDLE = 3'd0,WRT_AR = 3'd1,WRT_R=3'd2,RET_AR = 3'd3,RET_R = 3'd4;
    reg [2:0] crt,nxt;
    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            crt <= IDLE;
        end else begin
            crt <= nxt;
        end
    end
    always @(*) begin
        case (crt)
            IDLE: begin
                if(l2cache_mem_req_r) begin
                    if(query_ok)
                        nxt = WRT_AR;
                    else
                        nxt = RET_AR;
                end
                else    nxt = IDLE;
            end
            WRT_AR: begin
                nxt = WRT_R;
            end
            WRT_R: begin
                if(l2cache_mem_rdy) 
                        nxt = IDLE;
                else    nxt = WRT_R;
            end
            RET_AR: begin
                if(mem_arbiter_addrOK)
                        nxt = RET_R;
                else    nxt = RET_AR;
            end
            RET_R: begin
                if(l2cache_mem_rdy&&mem_arbiter_dataOK) 
                        nxt = IDLE;
                else    nxt = RET_R;
            end
            default:    nxt = IDLE;
        endcase
    end
    //signal
    always @(*) begin
        mem_l2cache_addrOK_r=0;
        mem_l2cache_dataOK=0;

        arbiter_mem_req=0;
        case (crt)
            IDLE: ;
            WRT_AR: begin
                mem_l2cache_addrOK_r=1;
            end
            WRT_R: begin
                mem_l2cache_dataOK=1;
            end
            RET_AR: begin
                arbiter_mem_req=1;
                mem_l2cache_addrOK_r=mem_arbiter_addrOK;
            end
            RET_R: begin
                mem_l2cache_dataOK=mem_arbiter_dataOK;
            end
            default: ;
        endcase
    end
    //data
    reg [(1<<offset_width)*32-1:0] _data;
    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            _data <= 0;
        end
        else begin
            case (crt)
                IDLE: begin
                    if(l2cache_mem_req_r) begin
                        if(query_ok)
                            _data <= query_data;
                        else _data <= 0;
                    end
                    else _data <= 0;
                end
                WRT_R: begin
                    if (nxt==IDLE) begin
                        _data <= 0;
                    end
                end
                default: _data <= 0;
            endcase
        end
    end
    always @(*) begin
        din_mem_l2cache=0;
        case (crt)
            IDLE: ;
            WRT_AR: begin
                din_mem_l2cache=0;
            end
            WRT_R: begin
                din_mem_l2cache=_data;
            end
            RET_AR: begin
                din_mem_l2cache=0;
            end
            RET_R: begin
                din_mem_l2cache=dout_mem_arbiter;
            end
            default: ;
        endcase
    end

endmodule

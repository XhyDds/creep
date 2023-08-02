module prefetching#(
    parameter ADDR_WIDTH    = 32,
              L2cache_width = 3
)(
    input        clk,
    input        rstn,
    //L2cache-port
    output reg   req_pref_l2cache,
    output reg   type_pref_l2cache,//指令或数据 0-指令 1-数据
    output reg   [31:0]addr_pref_l2cache,
    input        complete_l2cache_pref,
    input        hit_l2cache_pref,//预取请求的Hit
    input        miss_l2cache_pref//预取过程中来自L1访问的Miss 
);
    reg req_prefetching;
    reg [31:0] addr_prefetching;

    //statemachine
    reg [1:0] crt;
    reg [1:0] nxt;
    localparam IDLE = 2'd0, REQ=2'd1;
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
                if(req_prefetching)
                     nxt=REQ;
                else nxt=IDLE;
            end 
            REQ: begin
                if(complete_l2cache_pref) 
                     nxt=IDLE;
                else nxt=REQ;
            end
            default: nxt=IDLE;
        endcase
    end

    always @(*) begin
        req_pref_l2cache=0;
        case (crt)
            IDLE: begin
                req_pref_l2cache=0;
            end
            REQ:  begin
                req_pref_l2cache=1;
            end
            default: ;
        endcase
    end

    always @(posedge clk) begin
        if(!rstn) begin
            addr_pref_l2cache<=addr_prefetching;
        end
        else begin
            case (crt)
                IDLE: begin
                    if(nxt==REQ) 
                        addr_pref_l2cache<=addr_prefetching;
                    else
                        addr_pref_l2cache<=0;
                end
                REQ:  begin
                    if(nxt==IDLE) 
                        addr_pref_l2cache<=0;
                    else ;
                end
                default: ;
            endcase
        end
    end
endmodule
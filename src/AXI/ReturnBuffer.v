
//供l1使用，适用于icache和dcache
//l2也可使用，此时由于写buf的存在，交互对象为arbiter与axi
module ReturnBuffer #(
    parameter   offset_width=2
)(
    input               clk,
    input               rstn,

    //cache
    input               cache_mem_req,
    output reg          mem_cache_dataOK,
    output              [(1<<offset_width)*32-1:0]dout_mem_cache,
    //axi
    input               rready,   //r: arbiter->i:dataOK
    input[31:0]         rdata,
    `ifdef L2Cache
        input           cache_mem_rdy,
    `endif
    input               rlast
);
    localparam  WORD_NUM = (1 << offset_width)*32-1,              // words per block(set)
                WORD_SIZE = 2;                                  // word offset width


    reg [4:0]   state,next_state;
    localparam  IDLE = 5'b0,RECEIVE = 5'b1,SEND = 5'b10,OK=5'b11;

    always @(posedge clk) begin
        if(!rstn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    reg [WORD_NUM:0] _word;
    assign dout_mem_cache = _word;

    //状态机
    always @(*) begin
        case (state)
            IDLE: begin
                if(rready) begin
                    next_state = RECEIVE;
                end
                else begin
                    next_state = IDLE;
                end
            end
            RECEIVE: begin
                if(rready&&rlast) begin
                    next_state = SEND;
                end
                else begin
                    next_state = RECEIVE;
                end
            end
            SEND: begin
                `ifdef L2Cache
                    if(cache_mem_req&&cache_mem_rdy) begin
                        next_state = OK;
                    end
                    else if(cache_mem_rdy) begin
                        next_state = IDLE;
                    end
                    else begin
                        next_state = SEND;
                    end
                `endif
                `ifndef L2Cache
                    if(cache_mem_req) begin
                        next_state = OK;
                    end
                    else begin
                        next_state = IDLE;
                    end
                `endif
            end
            default:begin
                next_state = IDLE;
            end 
        endcase
    end

    always @(posedge clk) begin
        if(!rstn) begin
            _word<=0;
        end
        else begin 
            case (state)
                IDLE: begin
                    if(rready) begin
                        _word <= {rdata,_word[(1<<offset_width)*32-1:32]};
                    end
                    else begin
                        _word <= 0;
                    end
                end
                RECEIVE: begin
                    if(rready&&rlast) begin
                        _word <= {rdata,_word[(1<<offset_width)*32-1:32]};
                    end
                    else begin
                        if(rready) begin
                            _word <= {rdata,_word[(1<<offset_width)*32-1:32]};
                        end
                        else ;
                    end
                end
                SEND: begin
                    if(cache_mem_req) begin
                        _word<=0;
                    end
                    else ;
                end
                default:begin
                    _word<=0;
                end 
            endcase
        end
    end

    always @(*) begin
        mem_cache_dataOK=0;
        case (state)
            IDLE: ;
            RECEIVE: ;
            SEND: mem_cache_dataOK=1;
            default: ;
        endcase
    end
endmodule

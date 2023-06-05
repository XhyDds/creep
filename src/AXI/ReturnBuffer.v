
//供l1使用，适用于icache和dcache
module ReturnBuffer #(
    parameter   offset_width=2,
)(
    input               clk,
    input               rstn,

    //cache
    input               cache_mem_req,
    output reg          mem_cache_dataOK,
    output reg          [(1<<offset_width)*32-1:0]din_mem_cache,
    //arbiter 
    input reg           rready,   //r: arbiter->i:dataOK
    input[31:0]         rdata,
    input reg           rlast,
);
    localparam  WORD_NUM = 1 << WORD_OFFSET_WIDTH-1,              // words per block(set)
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

    always @(*) begin
        case (state)
            IDLE: begin
                if(rready) begin
                    next_state <= RECEIVE;

                    _word[31:0] <= rdata;
                end
                else begin
                    next_state <= IDLE;

                    _word <= 0;
                end
            end
            RECEIVE: begin
                if(rlast) begin
                    next_state <= SEND;

                    _word <= {_word[(1<<offset_width)*32-33:0],rdata};
                end
                else begin
                    next_state <= RECEIVE;

                    if(rready) begin
                        _word <= {_word[(1<<offset_width)*32-33:0],rdata};
                    end
                    else ;
                end
            end
            SEND: begin
                if(cache_mem_req) begin
                    next_state <= OK;

                    _word<=0;
                end
                else begin
                    next_state <= IDLE;
                end
            end
            default:begin
                next_state <= IDLE;

                _word<=0;
            end 
        endcase
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
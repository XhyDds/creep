/// 这里是用于L1Cache与L2Cache交互的转接桥
/// 分为两个版本，将用参数化的方式加以实现:
/// 版本1. 并行转串行
/// 版本2. 并行接受串行输出，但是与L2Cache耦合，请求与响应分离

`define VERSION1

`ifdef VERSION1
/// 不需要addrOK，因为没有请求握手
/// 不需要last，因为与l2之间直接传输（同理，不需要len，size直接传过去）
/// 不需要多个传输周期，因为一次传输且串行。
module arbiter #(
    parameter offset_width = 2;
)(
    input           clk,
    input           rstn,

    //from icache
    input           [31:0]addr_icache_mem,
    output reg      [32*(2<<offset_width)-1:0]dout_mem_icache,

    input           icache_mem_req,
    input           [1:0]icache_mem_size,
    output reg      mem_icache_dataOK,

    //from dcache
    input           [31:0]addr_dcache_mem,
    output reg      [32*(2<<offset_width)-1:0]dout_mem_dcache,
    input           [31:0]din_dcache_mem,

    input           dcache_mem_req,
    input           [1:0]dcache_mem_size,
    input           dcache_mem_wr,
    input           [3:0]dcache_mem_wstrb,
    output reg         mem_dcache_dataOK,

    //to l2cache
    output reg      [31:0]addr_l1cache_l2cache,
    output reg      [31:0]dout_l1cache_l2cache,
    input           [32*(2<<offset_width)-1:0]din_l2cache_l1cache,

    output reg      l1cache_l2cache_req,
    output reg      [1:0]l1cache_l2cache_size,
    output reg      l1cache_l2cache_wr,
    output reg      [3:0]l1cache_l2cache_wstrb,
    input           l2cache_l1cache_dataOK
);
    
/// 状态机
    localparam 
        IDLE    = 3'd0,
        I_R     = 3'd1,
        D_R     = 3'd2,
        D_W     = 3'd3;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge clk) begin
        if (!rstn) begin
            state<=IDLE;
        end
        else begin
            state<=next_state;
        end
    end

    always @(*) begin
        next_state=IDLE;
        case (state)
            IDLE: begin
                // 优先级：dcache写 > dcache读 > icache
                if (dcache_mem_req) begin
                    if(dcache_mem_wr)   next_state=D_W;//写
                    else                next_state=D_R;//读
                end
                else if (icache_mem_req)next_state=I_R;
                else                    next_state=IDLE;
            end
            I_R: begin
                if (mem_icache_dataOK)  next_state=IDLE;
                else                    next_state=I_R;
            end
            D_R: begin
                if (mem_dcache_dataOK)  next_state=IDLE;
                else                    next_state=D_R;
            end
            D_W: begin
                if (mem_dcache_dataOK)  next_state=IDLE;
                else                    next_state=D_W;
            end
            default: ;
        endcase
    end

/// 信号机
    always @(*) begin
        dout_mem_icache=0;
        mem_icache_dataOK=0;
        dout_mem_dcache=0;
        mem_dcache_dataOK=0;
        addr_l1cache_l2cache=0;
        dout_l1cache_l2cache=0;
        l1cache_l2cache_req=0;
        l1cache_l2cache_size=0;
        l1cache_l2cache_wr=0;
        l1cache_l2cache_wstrb=0;
        case (state)
            IDLE: begin
                if (dcache_mem_req) begin
                    if (dcache_mem_wr) begin
                        addr_l1cache_l2cache=addr_dcache_mem;
                        dout_l1cache_l2cache=din_dcache_mem;
                        l1cache_l2cache_req=1;
                        l1cache_l2cache_size=dcache_mem_size;
                        l1cache_l2cache_wr=1;
                        l1cache_l2cache_wstrb=dcache_mem_wstrb;
                    end
                    else begin
                        addr_l1cache_l2cache=addr_dcache_mem;
                        l1cache_l2cache_req=1;
                        l1cache_l2cache_size=dcache_mem_size;
                        l1cache_l2cache_wr=0;
                    end
                end
                else if (icache_mem_req) begin
                    addr_l1cache_l2cache=addr_icache_mem;
                    l1cache_l2cache_req=1;
                    l1cache_l2cache_size=icache_mem_size;
                    l1cache_l2cache_wr=0;
                end
            end
            I_R: begin
                dout_mem_icache=din_l2cache_l1cache;
                mem_icache_dataOK=l2cache_l1cache_dataOK;
            end
            D_R: begin
                dout_mem_dcache=din_l2cache_l1cache;
                mem_dcache_dataOK=l2cache_l1cache_dataOK;
            end
            D_W: begin
                mem_dcache_dataOK=l2cache_l1cache_dataOK;
            end
            default: ;
        endcase
    end
endmodule
`endif VERSION1
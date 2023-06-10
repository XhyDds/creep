/// 这里是用于L1Cache与L2Cache交互的转接桥
/// 分为两个版本，将用参数化的方式加以实现:
/// 版本1. 并行转串行
/// 版本2. 并行接受串行输出，但是与L2Cache耦合，请求与响应分离

`define VERSION1
//`define VERSION2

`ifdef VERSION1
/// 不需要addrOK，因为没有请求握手
/// 不需要last，因为与l2之间一次性传输（同理，不需要len，size直接传过去）
/// 不需要多个传输周期，因为一次传输且串行，只要单一状态即可。
module arbiter #(
    parameter offset_width = 2
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
`endif


`ifdef VERSION2
/// 请求与响应分离
/// 需要addrOK
/// 不需要last，因为与l2之间一次性传输（同理，不需要len，size直接传过去）
/// 需要多状态（主要是请求与响应要分离）
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

    output reg      icache_mem_addrOK,

    //from dcache
    input           [31:0]addr_dcache_mem,
    output reg      [32*(2<<offset_width)-1:0]dout_mem_dcache,
    input           [31:0]din_dcache_mem,

    input           dcache_mem_req,
    input           [1:0]dcache_mem_size,
    input           dcache_mem_wr,
    input           [3:0]dcache_mem_wstrb,
    output reg      mem_dcache_dataOK,

    output reg      dcache_mem_addrOK,

    //to l2cache
    output reg      [31:0]addr_l1cache_l2cache,
    output reg      [31:0]dout_l1cache_l2cache,
    input           [32*(2<<offset_width)-1:0]din_l2cache_l1cache,

    output reg      l1cache_l2cache_req,
    output reg      [1:0]l1cache_l2cache_size,
    output reg      l1cache_l2cache_wr,
    output reg      [3:0]l1cache_l2cache_wstrb,
    input           l2cache_l1cache_dataOK

    input           l2cache_l1cache_addrOK
);
//请求通道
    //请求状态机
    localparam 
        REQ_IDLE= 3'd0,
        I_AR    = 3'd1,
        D_AR    = 3'd2,
        D_W     = 3'd3,

    reg [2:0] req_state;
    reg [2:0] req_next_state;

    always @(posedge clk) begin
        if (!rstn) begin
            req_state<=IDLE;
        end
        else begin
            req_state<=req_next_state;
        end
    end

    always @(*) begin
        req_next_state=IDLE;
        case (req_state)
            IDLE: begin
                if(dcache_mem_req) begin
                    if(dcache_mem_wr)       req_next_state=D_W;
                    else                    req_next_state=D_AR;
                end
                else if(icache_mem_req)     req_next_state=I_AR;
                else                        req_next_state=IDLE;
            end 
            I_AR: begin
                if(l2cache_l1cache_addrOK)  req_next_state=IDLE;
                else                        req_next_state=I_AR;
            end
            D_AR: begin
                if(l2cache_l1cache_addrOK)  req_next_state=IDLE;
                else                        req_next_state=D_AR;
            end
            D_W: begin
                if(l2cache_l1cache_addrOK)  req_next_state=IDLE;
                else                        req_next_state=D_W;
            end
            default: ;
        endcase
    end
    //信号机

    reg [1:0] req_type;//0-ir,1-dr,2-dw
    localparam  
        TYPR_IR = 0,
        TYPE_DR = 1,
        TYPE_DW = 2;
    reg req_valid;

    always @(*) begin
        
    end

//响应通道
    //响应状态机
    localparam 
        RES_IDLE= 3'd0,
        I_R     = 3'd1,
        D_R     = 3'd2,
        D_B     = 3'd3,
    reg [2:0] res_state;
    reg [2:0] res_next_state;

    always @(posedge clk) begin
        if (!rstn) begin
            res_state<=IDLE;
        end
        else begin
            res_state<=res_next_state;
        end
    end
    always @(*) begin
        res_next_state=IDLE;
        case (res_state)
            IDLE: begin
                if(req_valid) begin
                    case (req_type)
                        TYPR_IR:    res_next_state=I_R;
                        TYPE_DR:    res_next_state=D_R;
                        TYPE_DW:    res_next_state=D_B;
                        default: ;
                    endcase
                end
                else begin
                    res_next_state=IDLE;
                end
            end 
            I_R: begin
                if(l2cache_l1cache_dataOK)  res_next_state=IDLE;
                else                        res_next_state=I_R;
            end
            D_R: begin
                if(l2cache_l1cache_dataOK)  res_next_state=IDLE;
                else                        res_next_state=D_R;
            end
            D_B: begin
                if(l2cache_l1cache_dataOK)  res_next_state=IDLE;
                else                        res_next_state=D_B;
            end
            default: ;
        endcase 
    end
    //信号机
    always @(*) begin
        
    end
endmodule
`endif
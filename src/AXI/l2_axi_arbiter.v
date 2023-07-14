
///这里是用于L1cache测试的arbiter，实现了读写并行，有以下几点说明：
///与正常版本不同，该版本需要L1cache适配以下设置：
///1. 搭载ReturnBuffer和WriteBuffer，设置size=2,len=3,配置last信号
///2. 取消addrOK的影响，写操作阻塞（没有写缓冲区）
///3. 目前并不需要WriteBuffer，因为一次最多写入一个byte。
module axi_arbiter(
    input               clk,
    input               rstn,
    // from l2cache
    input               [31:0]addr_l2cache_mem_r,
    input               [31:0]addr_l2cache_mem_w,
    output              [32*(1<<offset_width)-1:0]din_mem_l2cache,
    input               [32*(1<<offset_width)-1:0]dout_l2cache_mem,
    input               l2cache_mem_req_r,      //r
    input               l2cache_mem_req_w,      //
    input               l2cache_mem_rdy,        //
    input               [1:0]l2cache_mem_size,
    input               [3:0]l2cache_mem_wstrb,
    output              mem_l2cache_addrOK_r,
    output              mem_l2cache_addrOK_w,
    output              mem_l2cache_dataOK,
    // from icache
    input               i_rvalid,   //ar: i->arbiter:req
    output reg          i_rready,   //r: arbiter->i:dataOK
    input [31:0]        i_raddr,
    output[31:0]        i_rdata,
    output reg          i_rlast,
    input [2:0]         i_rsize,
    input [7:0]         i_rlen,
    // from dcache
    input               d_rvalid,   //ar: d->arbiter:req
    output reg          d_rready,   //r: arbiter->d:dataOK
    input [31:0]        d_raddr,
    output [31:0]       d_rdata,
    output reg          d_rlast,
    input [2:0]         d_rsize,
    input [7:0]         d_rlen,

    input               d_wvalid,   //aw: d->arbiter:req
    output reg          d_wready,   //w: arbiter->d:暂不关注
    input [31:0]        d_waddr,
    input [31:0]        d_wdata,
    input [3:0]         d_wstrb,
    input               d_wlast,
    input [2:0]         d_wsize,
    input [7:0]         d_wlen,

    output reg          d_bvalid,   //b: arbiter->d:dataOK
    input               d_bready,   //b: d->arbiter:req
    // from AXI 
    // AR
    output reg [31:0]   araddr,
    output reg          arvalid,    //ar: arbiter->axi
    input               arready,    //ar: axi->arbiter
    output reg [7:0]    arlen,
    output reg [2:0]    arsize,
    output [1:0]        arburst,

    // R
    input [31:0]        rdata,
    input [1:0]         rresp,
    input               rvalid,     //r: axi->arbiter
    output reg          rready,     //r: arbiter->axi
    input               rlast,

    // AW
    output [31:0]       awaddr,
    output reg          awvalid,    //aw: arbiter->axi
    input               awready,    //aw: axi->arbiter
    output [7:0]        awlen,
    output [2:0]        awsize,
    output [1:0]        awburst,

    // W
    output [31:0]       wdata,
    output [3:0]        wstrb,
    output reg          wvalid,     //w: arbiter->axi
    input               wready,     //w: axi->arbiter
    output reg          wlast,

    // B
    input [1:0]         bresp,
    input               bvalid,     //b: axi->arbiter
    output reg          bready      //b: arbiter->axi
);
    localparam 
        R_IDLE  = 3'd0,
        I_AR    = 3'd1,
        I_R     = 3'd2,
        D_AR    = 3'd3,
        D_R     = 3'd4;
    reg [2:0] r_crt, r_nxt;
    always @(posedge clk) begin
        if(!rstn) begin
            r_crt <= R_IDLE;
        end else begin
            r_crt <= r_nxt;
        end
    end
    always @(*) begin
        case(r_crt)
        R_IDLE: begin
            if(d_rvalid)            r_nxt = D_AR;   //优先Dcache
            else if(i_rvalid)       r_nxt = I_AR;
            else                    r_nxt = R_IDLE;
        end
        I_AR: begin
            if(arready)             r_nxt = I_R;
            else                    r_nxt = I_AR;
        end
        I_R: begin
            if(rvalid && rlast)     r_nxt = R_IDLE;
            else                    r_nxt = I_R;
        end
        D_AR: begin
            if(arready)             r_nxt = D_R;
            else                    r_nxt = D_AR;
        end
        D_R: begin
            if(rvalid && rlast)     r_nxt = R_IDLE;
            else                    r_nxt = D_R;
        end
        default :                   r_nxt = R_IDLE;    
        endcase
    end
    
    assign i_rdata = rdata;
    assign d_rdata = rdata;
    assign arburst = 2'b01;

    always @(*) begin
        i_rready    = 0;
        i_rlast     = 0;
        d_rready    = 0;
        d_rlast     = 0;
        arlen       = 0;
        arsize      = 0;
        arvalid     = 0;
        araddr      = 0;
        rready      = 0;
        case(r_crt) 
        I_AR: begin
            araddr      = i_raddr;
            arvalid     = i_rvalid;
            arlen       = i_rlen;
            arsize      = i_rsize;
        end
        I_R: begin
            araddr      = i_raddr;
            arlen       = i_rlen;
            arsize      = i_rsize;
            rready      = 1;
            i_rready    = rvalid;
            i_rlast     = rlast;
        end
        D_AR: begin
            araddr      = d_raddr;
            arvalid     = d_rvalid;
            arlen       = d_rlen;
            arsize      = d_rsize;
        end
        D_R: begin
            araddr      = d_raddr;
            rready      = 1;
            d_rready    = rvalid;
            d_rlast     = rlast;
        end
        default:;
        endcase
    end

    localparam 
        W_IDLE  = 3'd0,
        D_AW    = 3'd1,
        D_W     = 3'd2,
        D_B     = 3'd3;
    reg [2:0] w_crt, w_nxt;
    always @(posedge clk) begin
        if(!rstn) begin
            w_crt <= W_IDLE;
        end else begin
            w_crt <= w_nxt;
        end
    end
    always @(*) begin
        case(w_crt)
        W_IDLE: begin
            if(d_wvalid)            w_nxt = D_AW;
            else                    w_nxt = W_IDLE;
        end
        D_AW: begin
            if(awready)             w_nxt = D_W;
            else                    w_nxt = D_AW;
        end
        D_W: begin
            if(wready && wlast)     w_nxt = D_B;
            else                    w_nxt = D_W;
        end
        D_B: begin
            if(bvalid)              w_nxt = W_IDLE;
            else                    w_nxt = D_B;
        end
        default :                   w_nxt = W_IDLE;    
        endcase
    end
    assign awaddr   = d_waddr;
    assign awlen    = d_wlen;
    assign awsize   = d_wsize;
    assign awburst  = 2'b01;
    assign wdata    = d_wdata;
    assign wstrb    = d_wstrb;

    always @(*) begin
        d_wready    = 0;
        d_bvalid    = 0;
        bready      = 0;
        awvalid     = 0;
        wvalid      = 0;
        wlast       = 0;

        case(w_crt)
        D_AW: begin
            awvalid     = 1;
        end
        D_W: begin
            wvalid      = 1;
            wlast       = d_wlast;
            d_wready    = wready;
        end
        D_B: begin
            bready      = d_bready;
            d_bvalid    = bvalid;
        end
        default:;
        endcase
    end


endmodule
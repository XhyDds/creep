
///这里是用于L2cache与axi交互的arbiter，实现了读写通道并行，有以下几点说明：
///

module l2_axi_interface#(
    offset_width=2
)(
    input               clk,
    input               rstn,
    // from l2cache
    input               l2_rvalid,   //ar: l2->arbiter:req
    output reg          l2_raddrOK,   //arbiter->l2:addrOK
    output reg          l2_rready,   //r: arbiter->l2:dataOK
    input [31:0]        l2_raddr,
    output [31:0]       l2_rdata,    
    output reg          l2_rlast,     
    input  [7:0]        l2_rlen,
    input  [2:0]        l2_rsize,

    input               l2_wvalid,   //aw: l2->arbiter:req
    input               l2_wwvalid,
    output reg          l2_waddrOK,   //arbiter->l2:addrOK
    output reg          l2_wready,   //w: arbiter->l2:暂不关注
    input [31:0]        l2_waddr,
    input [31:0]        l2_wdata,
    input [3:0]         l2_wstrb,
    input               l2_wlast,
    input [7:0]         l2_wlen,
    input  [2:0]        l2_wsize,

    output reg          l2_bvalid,   //b: arbiter->d:dataOK
    input               l2_bready,   //b: d->arbiter:req

    // from AXI 
    // AR
    output reg [31:0]   araddr,
    output reg          arvalid,    //ar: arbiter->axi
    input               arready,    //ar: axi->arbiter
    output reg [7:0]    arlen,
    output reg [2:0]    arsize,
    output [1:0]        arburst,

    output   [ 3:0]     arid,
    output   [ 1:0]     arlock,
    output   [ 3:0]     arcache,
    output   [ 2:0]     arprot,
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

    output   [ 3:0]     awid,
    output   [ 1:0]     awlock,
    output   [ 3:0]     awcache,
    output   [ 2:0]     awprot,
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
    //信号位
    assign arid=0;
    assign arlock=0;
    assign arcache=0;
    assign arprot=0;

    assign awid=1;
    assign awlock=0;
    assign awcache=0;
    assign awprot=0;
    
    // assign  l2_rsize=3'd2;
    // assign  l2_rlen =8'd3;
    // assign  l2_wsize=3'd2;
    // assign  l2_wlen =8'd3;
    //读通道
    localparam 
        R_IDLE  = 2'd0,
        D_AR    = 2'd1,
        D_R     = 2'd2;
    reg [1:0] r_crt, r_nxt;
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
            if(l2_rvalid)           r_nxt = D_AR;   //优先Dcache
            else                    r_nxt = R_IDLE;
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
    
    assign l2_rdata = rdata;
    assign arburst  = 2'b01;

    always @(*) begin
        l2_rready   = 0;
        l2_rlast    = 0;
        arlen       = 0;
        arsize      = 0;
        arvalid     = 0;
        araddr      = 0;
        rready      = 0;
        l2_raddrOK  = 0;
        case(r_crt) 
        D_AR: begin
            araddr      = l2_raddr;
            arvalid     = l2_rvalid;
            arlen       = l2_rlen;
            arsize      = l2_rsize;
        end
        D_R: begin
            araddr      = l2_raddr;
            rready      = 1;
            l2_rready   = rvalid;
            l2_rlast    = rlast;
            l2_raddrOK  = 1;
        end
        default:;
        endcase
    end

    //写通道
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
            if(l2_wvalid)           w_nxt = D_AW;
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
    assign awaddr   = l2_waddr;
    assign awlen    = l2_wlen;
    assign awsize   = l2_wsize;
    assign awburst  = 2'b01;
    assign wdata    = l2_wdata;
    assign wstrb    = l2_wstrb;

    always @(*) begin
        l2_wready   = 0;
        l2_bvalid   = 0;
        bready      = 0;
        awvalid     = 0;
        wvalid      = 0;
        wlast       = 0;
        l2_waddrOK  = 0;

        case(w_crt)
        D_AW: begin
            awvalid     = 1;
        end
        D_W: begin
            wvalid      = l2_wwvalid;
            wlast       = l2_wlast;
            l2_wready   = wready;
            l2_waddrOK  = wready;
        end
        D_B: begin
            bready      = l2_bready;
            l2_bvalid   = bvalid;
        end
        default:;
        endcase
    end
endmodule

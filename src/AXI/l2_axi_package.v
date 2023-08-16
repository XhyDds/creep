/// 这里是l2_axi的接线预备
/// l2对axi的访存行为主要有以下几种：
/// 1.读操作：128位
/// 2.写操作时，先读内存：128位
/// 3.写脏时对内存写回：128位
/// 4. 一周期只会发送一次访存req

/// 尚未接入writebuffer
/// 拟：读数据时
///     先query writebuffer
///     若结果为未命中，询问axi；
///     否则，直接返回

///   ibar会flush，所以不用担心icache没有访问到正确数据

module l2_axi_package #(
    offset_width=2
)(
    input      clk,rstn,
    //l2 interface
    //r
    input      [31:0]addr_l2cache_mem_r,
    output     [32*(1<<offset_width)-1:0]din_mem_l2cache,
    input      l2cache_mem_req_r,
    output     mem_l2cache_addrOK_r,
    input      l2cache_mem_rdy,
    output     mem_l2cache_dataOK,
    //w
    input      [31:0]addr_l2cache_mem_w,
    input      [32*(1<<offset_width)-1:0]dout_l2cache_mem,
    input      l2cache_mem_req_w,
    output     mem_l2cache_addrOK_w, 
    //直接访存标志
    input      dma_sign,
    input      [3:0]l2cache_axi_wstrb,
    input    [2:0] l2cache_mem_size,

    //AXI interface 
    //read reqest
    output   [ 3:0] arid,
    output   [31:0] araddr,
    output   [ 7:0] arlen,
    output   [ 2:0] arsize,
    output   [ 1:0] arburst,
    output   [ 1:0] arlock,
    output   [ 3:0] arcache,
    output   [ 2:0] arprot,
    output          arvalid,
    input           arready,
    //read back
    input    [ 3:0] rid,
    input    [31:0] rdata,
    input    [ 1:0] rresp,
    input           rlast,
    input           rvalid,
    output          rready,
    //write request
    output   [ 3:0] awid,
    output   [31:0] awaddr,
    output   [ 7:0] awlen,
    output   [ 2:0] awsize,
    output   [ 1:0] awburst,
    output   [ 1:0] awlock,
    output   [ 3:0] awcache,
    output   [ 2:0] awprot,
    output          awvalid,
    input           awready,
    //write data
    output   [ 3:0] wid,
    output   [31:0] wdata,
    output   [ 3:0] wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    //write back
    input    [ 3:0] bid,
    input    [ 1:0] bresp,
    input           bvalid,
    output          bready
);
    wire [31:0]wrt_axi_waddr   ;
    wire [31:0]wrt_axi_wdata   ;
    wire wrt_axi_wvalid  ;
    wire wrt_axi_wwvalid ;
    wire axi_wrt_awready ;
    wire axi_wrt_wready  ;
    wire wrt_axi_wlast   ;
    wire axi_wrt_bvalid  ;
    wire wrt_axi_bready  ;

    wire [31:0]addr_arbiter_wrt_w;
    wire [(1<<offset_width)*32-1:0]dout_arbiter_wrt;
    wire arbiter_wrt_req_w;
    wire wrt_arbiter_addrOK_w;

    wire l2_rready;
    wire l2_rlast;
    wire [31:0] l2_rdata;

    wire l2_wvalid; 
    wire l2_wwvalid;
    wire l2_wready;
    wire l2_waddrOK;
    wire l2_wlast;
    wire l2_bvalid;
    wire l2_bready;
    wire [31:0] l2_waddr;
    wire [31:0] l2_wdata;

    wire arbiter_mem_req;
    wire mem_arbiter_dataOK;
    wire [(1<<offset_width)*32-1:0] din_mem_arbiter;

    wire [(1<<offset_width)*32-1:0] query_data;
    wire query_ok;
    wire cache_mem_rdy;
    wire mem_arbiter_addrOK;

    wire [3:0]l2_wstrb;
    wire [7:0]l2_rlen;
    wire [7:0]l2_wlen;
    wire [2:0]l2_rsize;
    wire [2:0]l2_wsize;

    wire [4:0]crt_w;
    wire [4:0]nxt_w;

    wire [31:0] pointer;

    ReturnBuffer#(
        .offset_width       (offset_width)
    )
    l2cache_returnbuf(
        .clk                (clk),
        .rstn               (rstn),
        .cache_mem_req      (arbiter_mem_req),
        .mem_cache_dataOK   (mem_arbiter_dataOK),
        .dout_mem_cache     (din_mem_arbiter),
        .rready             (l2_rready),
        .rdata              (l2_rdata),
        // `ifdef L2Cache
        .cache_mem_rdy      (cache_mem_rdy),
        // `endif
        .rlast              (l2_rlast)
        // .dma_sign           (dma_sign)
    );

    WriteBuffer#(
        .length         (5),
        .offset_width   (offset_width)
    )
    l2cache_writebuffer(
        .clk                (clk),
        .rstn               (rstn),

        .in_addr            (addr_arbiter_wrt_w),
        .in_data            (dout_arbiter_wrt),
        .in_valid           (l2cache_mem_req_w),
        .in_ready           (wrt_arbiter_addrOK_w),

        .out_addr           (wrt_axi_waddr),
        .out_data           (wrt_axi_wdata),
        .out_valid          (wrt_axi_wvalid),
        .out_wvalid         (wrt_axi_wwvalid),
        .out_awready        (axi_wrt_awready),
        .out_wready         (axi_wrt_wready),
        .out_last           (wrt_axi_wlast),
        .out_bvalid         (axi_wrt_bvalid),
        .out_bready         (wrt_axi_bready),

        .query_addr         (addr_l2cache_mem_r),
        .query_data         (query_data),
        .query_ok           (query_ok),

        .crt_pull           (crt_w),
        .nxt_pull           (nxt_w),
        .pointer            (pointer),
        .dma_sign           (dma_sign)
    );

    write_arbiter #(
        .offset_width       (offset_width)
    )
    u_write_arbiter(
        .clk                (clk),
        .rstn               (rstn),
        //l2cache_in
        .addr_l2cache_mem_w (addr_l2cache_mem_w),
        .dout_l2cache_mem   (dout_l2cache_mem),
        .l2cache_mem_req_w  (l2cache_mem_req_w),
        .mem_l2cache_addrOK_w(mem_l2cache_addrOK_w),
        .l2cache_mem_size(   l2cache_mem_size),
        //l2cache_out
        .l2_wstrb           (l2_wstrb),
        .l2_len             (l2_wlen),
        .l2_wsize            (l2_wsize),
        .l2_waddr           (l2_waddr),
        .l2_wdata           (l2_wdata),
        .l2_wvalid          (l2_wvalid),
        .l2_wwvalid         (l2_wwvalid),
        .l2_waddrOK         (l2_waddrOK),
        .l2_wready          (l2_wready),
        .l2_wlast           (l2_wlast),
        .l2_bvalid          (l2_bvalid),
        .l2_bready          (l2_bready),
        //wrt_in
        .addr_l2cache_wrt_w (addr_arbiter_wrt_w),
        .dout_l2cache_wrt   (dout_arbiter_wrt),
        .wrt_l2cache_addrOK_w(wrt_arbiter_addrOK_w),
        //wrt_out
        .wrt_axi_addr       (wrt_axi_waddr),
        .wrt_axi_data       (wrt_axi_wdata),
        .wrt_axi_valid      (wrt_axi_wvalid),
        .wrt_axi_wvalid     (wrt_axi_wwvalid),
        .axi_wrt_awready    (axi_wrt_awready),
        .axi_wrt_wready     (axi_wrt_wready),
        .wrt_axi_last       (wrt_axi_wlast),
        .axi_wrt_bvalid     (axi_wrt_bvalid),
        .wrt_axi_bready     (wrt_axi_bready),
        //直接访存
        .l2cache_axi_wstrb  (l2cache_axi_wstrb),
        .dma_sign           (dma_sign),
        
        .crt                (crt_w),
        .nxt                (nxt_w)
    );

    Write_FSM u_write_fsm(
        .clk                (clk),
        .rstn               (rstn),
        .l2cache_mem_req_w  (l2cache_mem_req_w),
        .dma_sign           (dma_sign),
        .pointer            (pointer),
        .l2_waddrOK         (l2_waddrOK),
        .l2_wready          (l2_wready),
        .l2_bvalid          (l2_bvalid),
        .out_awready        (axi_wrt_awready),
        .out_wready         (axi_wrt_wready),
        .out_bvalid         (axi_wrt_bvalid),

        .crt                (crt_w),
        .nxt                (nxt_w)
    );

    read_arbiter #(
        .offset_width       (offset_width)
    )
    l2_read_arbiter(
        .clk                (clk),
        .rstn               (rstn),

        .l2cache_mem_req_r  (l2cache_mem_req_r),
        .mem_l2cache_addrOK_r(mem_l2cache_addrOK_r),
        .l2cache_mem_rdy    (l2cache_mem_rdy),
        .mem_l2cache_dataOK (mem_l2cache_dataOK),
        .din_mem_l2cache    (din_mem_l2cache),
        .l2cache_mem_size   (l2cache_mem_size),

        .query_data         (query_data),
        .query_ok           (query_ok),

        .l2_rlen            (l2_rlen),
        .l2_rsize           (l2_rsize),
        .arbiter_mem_req    (arbiter_mem_req),
        .mem_arbiter_addrOK (mem_arbiter_addrOK),
        .mem_arbiter_dataOK (mem_arbiter_dataOK),
        .dout_mem_arbiter   (din_mem_arbiter),
        .cache_mem_rdy      (cache_mem_rdy),
        .dma_sign           (dma_sign)
    );

    l2_axi_interface u_axi_interface(
        //ports
        .clk      		( clk      		),
        .rstn     		( rstn     		),

        //l2cache
        .l2_rvalid 		( arbiter_mem_req ),//input
        .l2_raddrOK     ( mem_arbiter_addrOK),//output
        .l2_rready 		( l2_rready 		),//output reg
        .l2_raddr  		( addr_l2cache_mem_r  		),//input [31:0]
        .l2_rdata  		( l2_rdata  		),//output [31:0]
        .l2_rlast  		( l2_rlast	),//output reg
        .l2_rlen        (l2_rlen),
        .l2_rsize       (l2_rsize),

        .l2_wvalid 		( l2_wvalid         ),//input
        .l2_wwvalid     ( l2_wwvalid        ),//input
        .l2_waddrOK     ( l2_waddrOK        ),//output
        .l2_wready 		( l2_wready 		),//output reg
        .l2_waddr  		( l2_waddr  		),//input [31:0]
        .l2_wdata  		( l2_wdata  		),//input [31:0]
        .l2_wstrb  		( l2_wstrb   	    ),//input [3:0] 字节选通位
        .l2_wlast  		( l2_wlast  		),//input
        .l2_wlen        ( l2_wlen           ),
        .l2_wsize       ( l2_wsize          ),

        .l2_bvalid 		( l2_bvalid         ),//output reg
        .l2_bready 		( l2_bready 		),//input
        
        //AXI
        .araddr   		( araddr   		),
        .arvalid  		( arvalid  		),
        .arready  		( arready  		),
        .arlen    		( arlen    		),
        .arsize   		( arsize   		),
        .arburst  		( arburst  		),
        .arid           ( arid          ),
        .arlock         ( arlock        ),
        .arcache        ( arcache       ),
        .arprot         ( arprot        ),
        .rdata    		( rdata    		),
        .rresp    		( rresp    		),
        .rvalid   		( rvalid   		),
        .rready   		( rready   		),
        .rlast    		( rlast    		),
        .awaddr   		( awaddr   		),
        .awvalid  		( awvalid  		),
        .awready  		( awready  		),
        .awlen    		( awlen    		),
        .awsize   		( awsize   		),
        .awburst  		( awburst  		),
        .awid           ( awid          ),
        .awlock         ( awlock        ),
        .awcache        ( awcache       ),
        .awprot         ( awprot        ),
        .wdata    		( wdata    		),
        .wstrb    		( wstrb    		),
        .wvalid   		( wvalid   		),
        .wready   		( wready   		),
        .wlast    		( wlast    		),
        .wid            ( wid           ),
        .bresp    		( bresp    		),
        .bvalid   		( bvalid   		),
        .bready   		( bready   		)
    );

    wire allow;
    IO_mask r_mask(
    .addr(addr_l2cache_mem_r),
    .widthin(9'd128),
    .allow(allow)// 1:yes 0:no
    );
    wire addr_unvalid=~(allow&(~dma_sign)&(l2cache_mem_req_r|l2cache_mem_req_w));
endmodule

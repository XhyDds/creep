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
    input      [3:0]l2cache_mem_wstrb,//悬空

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
    wire l2_rready;
    wire l2_rlast;
    wire [31:0] l2_rdata;

    wire l2_wvalid; 
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
        .rlast              (l2_rlast)
    );

    WriteBuffer#(
        .length         (5),
        .offset_width   (offset_width)
    )
    l2cache_writebuffer(
        .clk                (clk),
        .rstn               (rstn),

        .in_addr            (addr_l2cache_mem_w),
        .in_data            (dout_l2cache_mem),
        .in_valid           (l2cache_mem_req_w),
        .in_ready           (mem_l2cache_addrOK_w),

        .out_addr           (l2_waddr),
        .out_data           (l2_wdata),
        .out_valid          (l2_wvalid),
        .out_awready        (l2_waddrOK),
        .out_wready         (l2_wready),
        .out_last           (l2_wlast),
        .out_bvalid         (l2_bvalid),
        .out_bready         (l2_bready),

        .query_addr         (addr_l2cache_mem_r),
        .query_data         (query_data),
        .query_ok           (query_ok)
    );

    wrt_ret_arbiter #(
        .offset_width       (offset_width)
    )
    l2_wrt_ret_arbiter(
        .clk                (clk),
        .rstn               (rstn),

        .l2cache_mem_req_r  (l2cache_mem_req_r),
        .mem_l2cache_addrOK_r(mem_l2cache_addrOK_r),
        .l2cache_mem_rdy    (l2cache_mem_rdy),
        .mem_l2cache_dataOK (mem_l2cache_dataOK),
        .din_mem_l2cache    (din_mem_l2cache),

        .query_data         (query_data),
        .query_ok           (query_ok),

        .arbiter_mem_req    (arbiter_mem_req),
        .mem_arbiter_addrOK (mem_arbiter_addrOK),
        .mem_arbiter_dataOK (mem_arbiter_dataOK),
        .dout_mem_arbiter   (din_mem_arbiter)
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

        .l2_wvalid 		( l2_wvalid         ),//input
        .l2_waddrOK     ( l2_waddrOK        ),//output
        .l2_wready 		( l2_wready 		),//output reg
        .l2_waddr  		( l2_waddr  		),//input [31:0]
        .l2_wdata  		( l2_wdata  		),//input [31:0]
        .l2_wstrb  		( 4'hF  		    ),//input [3:0] 字节选通位
        .l2_wlast  		( l2_wlast  		),//input

        .l2_bvalid 		( l2_bvalid         ),//output reg
        .l2_bready 		( l2_bready 		),//input
        
        //AXI
        .araddr   		( araddr   		),
        .arvalid  		( arvalid  		),
        .arready  		( arready  		),
        .arlen    		( arlen    		),
        .arsize   		( arsize   		),
        .arburst  		( arburst  		),
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
        .wdata    		( wdata    		),
        .wstrb    		( wstrb    		),
        .wvalid   		( wvalid   		),
        .wready   		( wready   		),
        .wlast    		( wlast    		),
        .bresp    		( bresp    		),
        .bvalid   		( bvalid   		),
        .bready   		( bready   		)
    );
endmodule

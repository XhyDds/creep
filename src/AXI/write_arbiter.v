module write_arbiter#(
    parameter   offset_width=2
)(
    input    clk,
    input    rstn,
    //l2cache_in
    input    [31:0] addr_l2cache_mem_w,
    input    [(1<<offset_width)*32-1:0]dout_l2cache_mem,
    input    l2cache_mem_req_w,
    output   reg  mem_l2cache_addrOK_w,
    input    [2:0] l2cache_mem_size,
    //l2cache_out
    output   reg  [3:0]l2_wstrb,
    output   reg  [7:0]l2_len,
    output   reg  [2:0]l2_wsize,

    output   reg  [31:0] l2_waddr,
    output   reg  [31:0] l2_wdata,
    output   reg  l2_wvalid,
    output   reg  l2_wwvalid,
    input    l2_waddrOK,
    input    l2_wready,
    output   reg  l2_wlast,
    input    l2_bvalid,
    output   reg  l2_bready,
    //wrt_in
    output   reg  [31:0] addr_l2cache_wrt_w,
    output   reg  [(1<<offset_width)*32-1:0]dout_l2cache_wrt,
    input    wrt_l2cache_addrOK_w,
    //wrt_out
    input    [31:0] wrt_axi_addr,
    input    [31:0] wrt_axi_data,
    input    wrt_axi_valid,
    input    wrt_axi_wvalid,
    output   reg axi_wrt_awready,
    output   reg axi_wrt_wready,
    input    wrt_axi_last,
    output   reg axi_wrt_bvalid,
    input    wrt_axi_bready,
    //直接访存
    input    [3:0]l2cache_axi_wstrb,
    input    dma_sign,
    //state_machine
    input    [4:0]crt,
    input    [4:0]nxt
);

    localparam IDLE = 5'd0,DMA_AW=5'd1 , DMA_W=5'd2 , DMA_R=5'd3;

    always @(*) begin
        mem_l2cache_addrOK_w=0;

        l2_wstrb=0;
        l2_len=0;
        l2_wsize=0;
        l2_waddr=0;
        l2_wdata=0;
        l2_wvalid=0;
        l2_wwvalid=0;
        l2_wlast=0;
        l2_bready=0;

        addr_l2cache_wrt_w=0;
        dout_l2cache_wrt=0;

        axi_wrt_awready=0;
        axi_wrt_wready=0;
        axi_wrt_bvalid=0;
        case (crt)
            IDLE: begin
                mem_l2cache_addrOK_w=wrt_l2cache_addrOK_w;
                addr_l2cache_wrt_w=addr_l2cache_mem_w;
                dout_l2cache_wrt=dout_l2cache_mem;

                l2_len=(1<<offset_width)-1;
                l2_wstrb=4'hF;
                l2_wsize=3'd2;

                l2_waddr=wrt_axi_addr;
                l2_wdata=wrt_axi_data;
                l2_wvalid=wrt_axi_valid;
                l2_wwvalid=wrt_axi_wvalid;
                l2_wlast=wrt_axi_last;
                l2_bready=wrt_axi_bready;

                axi_wrt_awready=l2_waddrOK;
                axi_wrt_wready=l2_wready;
                axi_wrt_bvalid=l2_bvalid;
            end
            DMA_AW: begin
                l2_wstrb=l2cache_axi_wstrb;
                l2_waddr=addr_l2cache_mem_w;
                l2_wdata=dout_l2cache_mem[31:0];
                l2_len=8'd0;
                l2_wsize=l2cache_mem_size;

                l2_wvalid=1;
            end
            DMA_W: begin
                l2_wstrb=l2cache_axi_wstrb;
                l2_waddr=addr_l2cache_mem_w;
                l2_wdata=dout_l2cache_mem[31:0];
                l2_len=8'd0;
                l2_wsize=l2cache_mem_size;

                l2_wvalid=1;
                l2_wwvalid=1;
                l2_wlast=1;
            end
            DMA_R: begin
                mem_l2cache_addrOK_w=l2_bvalid;
                l2_wstrb=l2cache_axi_wstrb;
                l2_waddr=addr_l2cache_mem_w;
                l2_wdata=dout_l2cache_mem[31:0];

                l2_len=8'd0;
                l2_wsize=l2cache_mem_size;
                l2_bready=1;

                //for 抢的周期(wrt与l2的交互)
                mem_l2cache_addrOK_w=wrt_l2cache_addrOK_w;
                addr_l2cache_wrt_w=addr_l2cache_mem_w;
                dout_l2cache_wrt=dout_l2cache_mem;
            end
            default: begin  //WRT_W
                mem_l2cache_addrOK_w=wrt_l2cache_addrOK_w;

                l2_len=(1<<offset_width)-1;
                l2_wstrb=4'hF;
                l2_wsize=3'd2;

                addr_l2cache_wrt_w=addr_l2cache_mem_w;
                dout_l2cache_wrt=dout_l2cache_mem;

                l2_waddr=wrt_axi_addr;
                l2_wdata=wrt_axi_data;
                l2_wvalid=wrt_axi_valid;
                l2_wwvalid=wrt_axi_wvalid;
                l2_wlast=wrt_axi_last;
                l2_bready=wrt_axi_bready;

                axi_wrt_awready=l2_waddrOK;
                axi_wrt_wready=l2_wready;
                axi_wrt_bvalid=l2_bvalid;
            end
        endcase
    end

    always @(posedge clk) begin
        if(!rstn) begin
            l2cache_axi_wstrb_<=0;
            addr_l2cache_mem_w_<=0;
            dout_l2cache_mem_<=0;
        end
        else if(crt==DMA_AW) begin
            l2cache_axi_wstrb_<=l2cache_axi_wstrb;
            addr_l2cache_mem_w_<=addr_l2cache_mem_w;
            dout_l2cache_mem_<=dout_l2cache_mem[31:0];
        end
    end
endmodule

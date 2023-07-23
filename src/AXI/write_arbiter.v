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
    //l2cache_out
    output   reg  [3:0]l2_wstrb,
    output   reg  [7:0]l2_len,

    output   reg  [31:0] l2_waddr,
    output   reg  [31:0] l2_wdata,
    output   reg  l2_wvalid,
    input    l2_waddrOK,
    input    l2_wready,
    output   reg  l2_wlast,
    input    l2_bvalid,
    output   reg  l2_bready,
    //wrt_in
    output   reg  [31:0] addr_l2cache_wrt_w,
    output   reg  [(1<<offset_width)*32-1:0]dout_l2cache_wrt,
    output   reg  l2cache_wrt_req_w,
    input    wrt_l2cache_addrOK_w,
    //wrt_out
    input    [31:0] wrt_axi_addr,
    input    [31:0] wrt_axi_data,
    input    wrt_axi_valid,
    output   axi_wrt_awready,
    output   axi_wrt_wready,
    input    wrt_axi_last,
    output   axi_wrt_bvalid,
    input    wrt_axi_bready,
    //直接访存
    input    [3:0]l2cache_axi_wstrb,
    input    dma_sign
);
    parameter IDLE = 3'd0,WRT_W = 3'd1,DMA_AW=3'd2 , DMA_W=3'd3 , DMA_R=3'd4;

    reg [2:0] crt,nxt;
    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            crt <= IDLE;
        end else begin
            crt <= nxt;
        end
    end
    always @(*) begin
        case(crt)
            IDLE: begin
                if(l2cache_mem_req_w) begin
                    if(dma_sign)
                                nxt = DMA_AW;
                    else
                                nxt = WRT_W;
                end
                else            nxt = IDLE;
            end
            WRT_W: begin
                if(wrt_l2cache_addrOK_w)   
                                nxt = IDLE;
                else            nxt = WRT_W;
            end
            DMA_W: begin
                if(l2_wready)   nxt = DMA_R;
                else            nxt = DMA_W;
            end
            DMA_R: begin
                if(l2_bvalid)   nxt = IDLE;
                else            nxt = DMA_R;
            end
            default:            nxt = IDLE;
        endcase
    end

    always @(*) begin
        mem_l2cache_addrOK_w=0;

        l2_wstrb=0;
        l2_len=0;
        l2_waddr=0;
        l2_wdata=0;
        l2_wvalid=0;
        l2_wlast=0;
        l2_bready=0;

        addr_l2cache_wrt_w=0;
        dout_l2cache_wrt=0;
        l2cache_wrt_req_w=0;

        axi_wrt_awready=0;
        axi_wrt_wready=0;
        axi_wrt_bvalid=0;

        case (crt)
            IDLE: begin
                l2_len=8'd3;
                l2_wstrb=4'hF;

                l2_waddr=wrt_axi_addr;
                l2_wdata=wrt_axi_data;
                l2_wvalid=wrt_axi_valid;
                l2_wlast=wrt_axi_last;
                l2_bready=wrt_axi_bready;
            end
            WRT_W: begin
                mem_l2cache_addrOK_w=wrt_l2cache_addrOK_w;

                l2_len=8'd3;
                l2_wstrb=4'hF;

                addr_l2cache_wrt_w=addr_l2cache_mem_w;
                dout_l2cache_wrt=dout_l2cache_mem;
                l2cache_wrt_req_w=l2cache_mem_req_w;

                l2_waddr=wrt_axi_addr;
                l2_wdata=wrt_axi_data;
                l2_wvalid=wrt_axi_valid;
                l2_wlast=wrt_axi_last;
                l2_bready=wrt_axi_bready;

                axi_wrt_awready=l2_waddrOK;
                axi_wrt_wready=l2_wready;
                axi_wrt_bvalid=l2_bvalid;

            end
            DMA_W: begin
                l2_wstrb=l2cache_axi_wstrb;
                l2_len=8'd0;
                l2_waddr=addr_l2cache_mem_w;
                l2_wdata=dout_l2cache_mem[31:0];
                l2_wvalid=1;
                l2_wlast=1;
            end
            DMA_R: begin
                mem_l2cache_addrOK_w=l2_bvalid;

                l2_wstrb=l2cache_axi_wstrb;
                l2_len=8'd0;
                l2_bready=1;
            end
            default: ;
        endcase
    end


endmodule
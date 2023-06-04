module (
    input               clk,
    input               rstn,

    // from icache
    input               i_rvalid,
    output reg          i_rready,
    input [31:0]        i_raddr,
    output[31:0]        i_rdata,
    // output reg          i_rlast,
    input [2:0]         i_rsize,
    // input [7:0]         i_rlen,

    // from dcache
    input               d_rvalid,
    output reg          d_rready,
    input [31:0]        d_raddr,
    output [31:0]       d_rdata,
    // output reg          d_rlast,
    input [2:0]         d_rsize,
    // input [7:0]         d_rlen,
    input               d_wvalid,
    output reg          d_wready,
    input [31:0]        d_waddr,
    input [31:0]        d_wdata,
    input [3:0]         d_wstrb,
    // input               d_wlast,
    input [2:0]         d_wsize,
    // input [7:0]         d_wlen,
    output reg          d_bvalid,
    input               d_bready,

    // from l2cache
    output reg [31:0]    l2_addr,
    output reg [31:0]    l2_din,    //要写入l2cache的数据
    input                l2_dout,   //来自l2cache的数据
    output reg [3:0]     l2_wstrb,
    output reg [2:0]     l2_size,
    output reg [2:0]     l2_wr,    //0-read 1-write

    output               l2_req,    //替换arvalid,awvalid,wvalid
    input                l2_addrOK, //替换rvalid,awready,wready
    input                l2_dataOK, //替换bvalid,rvalid

);
    localparam 
        IDLE  = 3'd0,
        //ir
        I_AR    = 3'd1,
        I_R     = 3'd2,
        //dr
        D_AR    = 3'd3,
        D_R     = 3'd4;
        //w
        // D_AW    = 3'd5,
        D_W     = 3'd5,
        D_B     = 3'd6;
    reg [2:0] crt, nxt;
    always @(posedge clk) begin
        if(!rstn) begin
            crt <= IDLE;
        end else begin
            crt <= nxt;
        end
    end
    always @(*) begin
        case(crt)
        IDLE: begin
            if(d_rvalid)            nxt = D_AR;   //优先Dcache
            else if(i_rvalid)       nxt = I_AR;
            else if(d_wvalid)       nxt = D_W;
            else                    nxt = IDLE;
        end
        I_AR: begin
            if(arready)             nxt = I_R;
            else                    nxt = I_AR;
        end
        I_R: begin
            // if(rvalid && rlast)     nxt = IDLE;
            if(rvalid)              nxt = IDLE;
            else                    nxt = I_R;
        end
        D_AR: begin
            if(arready)             nxt = D_R;
            else                    nxt = D_AR;
        end
        D_R: begin
            // if(rvalid && rlast)     nxt = IDLE;
            if(rvalid)              nxt = IDLE;
            else                    nxt = D_R;
        end
        D_W: begin
            // if(wready && wlast)     nxt = D_B;
            if(wready)              nxt = D_B;
            else                    nxt = D_W;
        end
        D_B: begin
            if(bvalid)              nxt = IDLE;
            else                    nxt = D_B;
        end
        default:                    nxt=IDLE;
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
        case(crt) 
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
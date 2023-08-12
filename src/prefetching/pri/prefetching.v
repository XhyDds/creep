///prefetching顶层模块
///负责与具体地预取模块交互，以及与L2cache交互
///预测上：接受预取模块的req与addr脉冲
`define TEST
module prefetching#(
    parameter ADDR_WIDTH    = 32,
              INST_WIDTH    = 30,
              L2cache_width = 3,
              HASH_WIDTH    = 10
)(
    input        clk,
    input        rstn,
    //inst-port
    input        [ADDR_WIDTH-1:0]pdc_pref_addr,
    //data-port
    input        [ADDR_WIDTH-1:0]dcache_pref_addr,
    input        [ADDR_WIDTH-1:0]dcache_pref_pc,
    input        dcache_pref_valid,
    //l2cache-(annealing)-port
    input        [ADDR_WIDTH-1:0]anneal_addr,
    input        [ADDR_WIDTH-1:0]anneal_pc,
    input        anneal_unhit,
    input        anneal_type,
    //L2cache-port
    output reg   req_pref_l2cache,
    output reg   type_pref_l2cache,//指令或数据 0-指令 1-数据
    output reg   [ADDR_WIDTH-1:0]addr_pref_l2cache,
    input        addrOK_l2cache_pref,
    input        complete_l2cache_pref,
    input        hit_l2cache_pref,//预取请求的Hit
    input        miss_l2cache_pref//预取过程中来自L1访问的Miss 
);

    localparam addr_width = ADDR_WIDTH-2-L2cache_width;
    
    reg req_pref;
    reg [addr_width-1:0] addr_pref;

    //statemachine
    reg [1:0] crt;
    reg [1:0] nxt;
    localparam IDLE = 2'd0, REQ=2'd1, WAIT=2'd2;
    always @(posedge clk)begin
        if (!rstn) begin
            crt<=IDLE;
        end
        else begin
            crt<=nxt;
        end
    end
    always @(*) begin
        case (crt)
            IDLE: begin
                if(req_pref)
                            nxt =   REQ;
                else        nxt =   IDLE;
            end
            REQ: begin
                if(addrOK_l2cache_pref)
                    if(complete_l2cache_pref)
                            nxt =   IDLE;
                    else    nxt =   WAIT;
                else        nxt =   REQ;
            end
            WAIT: begin
                if(complete_l2cache_pref)
                            nxt =   IDLE;
                else        nxt =   WAIT;
            end
            default:        nxt =   IDLE;
        endcase
    end

    always @(*) begin
        req_pref_l2cache=0;
        case (crt)
            IDLE: begin
                req_pref_l2cache=0;
            end
            REQ:  begin
                req_pref_l2cache=1;
            end
            WAIT: begin
                req_pref_l2cache=1;
            end
            default: ;
        endcase
    end

    reg type_pref_l2cache_;

    wire [1:0] pdch_i;
    wire [5:0] pdch_d;
    wire [INST_WIDTH-1:0] inst_d;
    wire [addr_width-1:0] naddr_i_h;
    wire [addr_width-1:0] naddr_d_h;

    reg  [2*addr_width+INST_WIDTH+7:0] hinfo_reg;
    wire [2*addr_width+INST_WIDTH+7:0] hinfo;

    assign hinfo={pdch_i,pdch_d,inst_d,naddr_i_h,naddr_d_h};

    wire [1:0] pdch_i_reg=hinfo_reg[2*addr_width+INST_WIDTH+7:2*addr_width+INST_WIDTH+6];
    wire [5:0] pdch_d_reg=hinfo_reg[2*addr_width+INST_WIDTH+5:2*addr_width+INST_WIDTH];
    wire [INST_WIDTH-1:0] inst_d_reg=hinfo_reg[2*addr_width+INST_WIDTH-1:2*addr_width];
    wire [addr_width-1:0] naddr_i_h_reg=hinfo_reg[2*addr_width-1:addr_width];
    wire [addr_width-1:0] naddr_d_h_reg=hinfo_reg[addr_width-1:0];

    always @(posedge clk) begin
        if(!rstn) begin
            addr_pref_l2cache<=0;
            type_pref_l2cache<=0;
            hinfo_reg<=0;
        end
        else begin
            case (crt)
                IDLE: begin
                    if(nxt==REQ) begin
                        addr_pref_l2cache<={addr_pref,{(2+L2cache_width){1'b0}}};
                        type_pref_l2cache<=type_pref_l2cache_;
                        hinfo_reg<=hinfo;
                    end
                    else begin
                        addr_pref_l2cache<=0;
                        type_pref_l2cache<=0;
                        hinfo_reg<=0;
                    end
                end
                REQ:  ;
                WAIT: ;
                default: ;
            endcase
        end
    end

    //预测单元
    wire [addr_width-1:0] naddr_inst;
    wire [addr_width-1:0] naddr_data;
    wire valid_inst;
    wire valid_data;
    wire req_inst;
    wire req_data;

    inst_pre#(
        .addr_width(addr_width),
        .HASH_WIDTH(HASH_WIDTH)
    )u_inst_pre(
        .clk(clk),
        .rstn(rstn),

        .addr(pdc_pref_addr[ADDR_WIDTH-1:2+L2cache_width]),
        .naddr_pdc(naddr_inst),
        .naddr_valid(valid_inst),
        .req(req_inst),
        .pdch(pdch_i),

        .addr_upt(addr_pref_l2cache[ADDR_WIDTH-1:2+L2cache_width]),
        .spare(~miss_l2cache_pref&~hit_l2cache_pref),
        .pdch_upt(pdch_i_reg),

        .update_en(complete_l2cache_pref&~complete_l2cache_pref),

        .anneal_addr(anneal_addr[ADDR_WIDTH-1:2+L2cache_width]),
        .anneal_pc(anneal_pc[ADDR_WIDTH-1:2+L2cache_width]),
        .anneal_unhit(anneal_unhit),
        .anneal_type(anneal_type)
    );

    data_pre#(
        .addr_width(addr_width),
        .INST_WIDTH(INST_WIDTH),
        .HASH_WIDTH(HASH_WIDTH)
    )u_data_pre(
        .clk(clk),
        .rstn(rstn),
        
        .inst_pc(dcache_pref_pc[INST_WIDTH-1:0]),
        .inst_valid(dcache_pref_valid),
        .addr(dcache_pref_addr[ADDR_WIDTH-1:2+L2cache_width]),
        .naddr_pdc(naddr_data),
        .naddr_valid(valid_data),
        .req(req_data),
        .pdch(pdch_d),

        .inst_pc_upt(inst_d_reg),
        .addr_upt(addr_pref_l2cache[ADDR_WIDTH-1:2+L2cache_width]),
        .naddr_upt(naddr_d_h_reg),
        .hit(hit_l2cache_pref),
        .spare(~miss_l2cache_pref&~hit_l2cache_pref),
        .choice(hit_l2cache_pref?(~pdch_d_reg[1]):pdch_d_reg[1]),
        .pdch_upt(pdch_d_reg),

        .update_en(complete_l2cache_pref&type_pref_l2cache),

        .anneal_addr(anneal_addr[ADDR_WIDTH-1:2+L2cache_width]),
        .anneal_pc(anneal_pc[INST_WIDTH-1:0]),
        .anneal_unhit(anneal_unhit),
        .anneal_type(anneal_type)
    );

    always @(*) begin
        addr_pref=0;
        req_pref=0;
        type_pref_l2cache_=0;
        if(valid_data&req_data) begin
            addr_pref=naddr_data;
            req_pref=1;
            type_pref_l2cache_=1;
        end
        if(valid_inst&req_inst) begin
            addr_pref=naddr_inst;
            req_pref=1;
            type_pref_l2cache_=0;
        end
        else ;
    end

    `ifdef TEST
    reg [31:0]  times_miss;
    reg [31:0]  times_hit;
    reg [31:0]  times_total;
    reg [31:0]  times_anneal;

    always @(posedge clk) begin
        if(!rstn) begin
            times_miss  <=0;
            times_hit   <=0;
            times_total <=0;
            times_anneal<=0;
        end
        else begin
            if(complete_l2cache_pref) begin
                times_total<=times_total+1;
                if(hit_l2cache_pref) begin
                    times_hit<=times_hit+1;
                end
                else begin
                    times_miss<=times_miss+1;
                end
            end
            if(anneal_unhit) begin
                times_anneal<=times_anneal+1;
            end
        end
    end
    `endif
endmodule
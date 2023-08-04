module inst_pre#(
    parameter addr_width = 32,
              HASH_WIDTH = 14
)(
    input         clk,
    input         rstn,
    //预测
    input [addr_width-1:0]  addr,
    output reg[addr_width-1:0]naddr_pdc,
    output reg              naddr_valid,
    output reg              req,
    output [1:0]            pdch,
    //更新
    input  [addr_width-1:0] addr_upt,
    input  [addr_width-1:0] naddr_upt,
    input                   spare,
    input  [1:0]            pdch_upt, //spare
    input                   update_en,
    //l2cache-(annealing)-port
    input        [addr_width-1:0]anneal_addr,
    input        [addr_width-1:0]anneal_pc,
    input        anneal_unhit,
    input        anneal_type
);

    reg  anneal_unhit_reg;
    reg  [addr_width-1:0]anneal_addr_reg;
    reg  [addr_width-1:0]anneal_pc_reg;

    reg [addr_width-1:0]ann_addr        ;
    reg [addr_width-1:0]ann_addr_upt    ;
    reg [1:0]           ann_spare_pdch  ;
    reg                 ann_spare       ;
    reg                 ann_update_en   ;

    wire [1:0] spare_pdch=pdch_upt[1:0];
    assign pdch=spare_pdc;

    wire [1:0] spare_upt;

    //预测下一条指令
    reg  [addr_width-1:0] paddr;
    wire [addr_width-1:0] naddr_pdc_inst;
    wire valid;
    wire [1:0] taken_pdc;
    wire [1:0] taken_upt;
    sp_bram#(
        .ADDR_WIDTH(HASH_WIDTH),
        .DATA_WIDTH(addr_width+1+2),
        .INIT_NUM(0)
    )u_inst(
        .clk(clk),
        .raddr(addr_hashed),
        .dout({naddr_pdc_inst,valid,taken_pdc}),
        .enb(1),
        .waddr(paddr_hashed),
        .din({taken_upt[1]?addr:paddr,1'b1,taken_upt}),
        .we((paddr!=addr))
    );
    always @(posedge clk) begin
        paddr<=addr;
    end
    //是否跳转
    transformer_2bit u_taken(
        .crt(taken_pdc),
        .nxt(taken_upt),
        .taken((addr!=(paddr+1))&valid)
    );

    //以inst_pc为索引，存储 空闲(spare)
    wire [1:0] spare_pdc;
    sp_bram#(
        .ADDR_WIDTH(HASH_WIDTH),
        .DATA_WIDTH(2),
        .INIT_NUM(2'b10)
    )u_cpt_spt(
        .clk(clk),
        .raddr(ann_addr_hashed),
        .dout(spare_pdc),
        .enb(1),
        .waddr(ann_addr_upt_hashed),
        .din(spare_upt),
        .we(ann_update_en)
    );
    transformer_2bit u_spare(
        .crt(ann_spare_pdch),
        .nxt(spare_upt),
        .taken(ann_spare)
    );

    always @(*) begin
        naddr_pdc=0;
        naddr_valid=0;
        req=0;
        if((addr!=paddr)) begin
            if(valid&spare_pdc[1]) 
                if(taken_pdc[1]) begin
                    naddr_pdc=naddr_pdc_inst;
                    naddr_valid=1;
                    req=1;
                end
                else begin
                    naddr_pdc=addr+1;
                    naddr_valid=1;
                    req=1;
                end
            else if(~valid)begin    //默认+1
                naddr_pdc=addr+1;
                naddr_valid=1;
                req=1;
            end
        end
    end

    //退火
    always @(posedge clk) begin
        anneal_unhit_reg<=anneal_unhit & ~anneal_type;
        anneal_pc_reg<=anneal_pc;
        anneal_addr_reg<=anneal_addr;
    end
    always @(*) begin
        ann_addr        =addr;
        ann_addr_upt    =addr_upt;
        ann_spare_pdch  =spare_pdch;
        ann_spare       =spare;
        ann_update_en   =update_en;

        if(anneal_unhit&~anneal_type) begin
            ann_addr        =anneal_addr;
        end
        else if(anneal_unhit_reg) begin
            ann_addr_upt    =anneal_addr_reg;
            ann_spare_pdch  =spare_pdc;
            ann_spare       =1;
            ann_update_en   =1;
        end
        else ;
    end

    wire [HASH_WIDTH-1:0] addr_hashed;
    wire [HASH_WIDTH-1:0] paddr_hashed;
    wire [HASH_WIDTH-1:0] ann_addr_hashed;
    wire [HASH_WIDTH-1:0] ann_addr_upt_hashed;

    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_addr_hash(
        .data_raw(addr),
        .data_hashed(addr_hashed)
    );
    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_paddr_hash(
        .data_raw(paddr),
        .data_hashed(paddr_hashed)
    );
    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_ann_addr_hash(
        .data_raw(ann_addr),
        .data_hashed(ann_addr_hashed)
    );
    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_ann_addr_upt_hash(
        .data_raw(ann_addr_upt),
        .data_hashed(ann_addr_upt_hashed)
    );

endmodule
module data_pre#(
    parameter addr_width = 27,
              INST_WIDTH = 30,
              HASH_WIDTH = 10
)(
    input         clk,
    input         rstn,
    //预测
    input  [INST_WIDTH-1:0] ip,
    output reg[addr_width-1:0]naddr_pdc,
    output reg              naddr_valid,
    output reg              req,
    output [5:0]            pdch,
    //更新
    input [INST_WIDTH-1:0]  inst_pc,
    input                   inst_valid,
    input [addr_width-1:0]  addr,
    input  [INST_WIDTH-1:0] inst_pc_upt,
    input  [addr_width-1:0] addr_upt,
    input  [addr_width-1:0] naddr_upt,
    input                   hit,        //i/d 共用
    input                   spare,
    input                   choice,
    input  [5:0]            pdch_upt, //{hit,spare,choice}
    input                   update_en,
    //l2cache-(annealing)-port
    input        [addr_width-1:0]anneal_addr,
    input        [INST_WIDTH-1:0]anneal_pc,
    input        anneal_unhit,
    input        anneal_type
);
    reg  anneal_unhit_reg;
    reg  [addr_width-1:0]anneal_addr_reg;
    reg  [INST_WIDTH-1:0]anneal_pc_reg;

    reg [INST_WIDTH-1:0]ann_inst_pc     ;
    reg [INST_WIDTH-1:0]ann_inst_pc_upt ;
    reg [addr_width-1:0]ann_addr        ;
    reg [addr_width-1:0]ann_addr_upt    ;
    wire[1:0]           ann_choice_upt  ;
    reg [1:0]           ann_choice_pdch ;
    reg                 ann_choice      ;
    reg [1:0]           ann_spare_pdch  ;
    reg                 ann_spare       ;
    reg [1:0]           ann_spare_upt   ;
    reg [1:0]           ann_hit_pdch    ;
    reg                 ann_hit         ;
    reg                 ann_update_en   ;

    wire [1:0] hit_pdch=pdch_upt[5:4];
    wire [1:0] spare_pdch=pdch_upt[3:2];
    wire [1:0] choice_pdch=pdch_upt[1:0];
    assign pdch={hit_pdc,spare_pdc,choice_pdc};

    wire [1:0] hit_upt;
    wire [1:0] spare_upt;
    reg [1:0] choice_upt;

    // 直接寻址
    wire [addr_width-1:0] naddr_pdc_dir;
    wire ip_kind;
    wire [INST_WIDTH-1:0] ip_;
    wire [HASH_WIDTH-1:0] ip_hashed;
    wire [INST_WIDTH-1:0] ip_reg;

    sp_bram#(
        .ADDR_WIDTH(HASH_WIDTH),
        .DATA_WIDTH(addr_width+INST_WIDTH+1),
        .INIT_NUM(0)
    )u_direct(
        .clk(clk),
        .raddr(ip_hashed),
        .dout({naddr_pdc_dir,ip_,ip_kind}),
        .enb(1),
        .waddr(inst_pc_hashed),
        .din({addr,inst_pc,inst_valid}),
        .we(1'b1)
    );

    wire valid_naddr_dir=ip_kind&(ip_==ip_reg);
    always @(posedge clk) begin
        ip_reg<=ip;
    end

    //hash
    single_hash#(
        .DATA_width(INST_WIDTH),
        .HASH_width(HASH_WIDTH)
    )u_ip(
        .data_raw(ip),
        .data_hashed(ip_hashed)
    ) ;

    // //数组型
    // //以inst_pc为索引，存储 上一次访存的地址+valid
    wire [addr_width-1:0] paddr_pdc_off;
    wire [addr_width-1:0] naddr_pdc_off;
    wire [INST_WIDTH-1:0] inst_pc_;
    wire offset_valid;
    // sp_bram#(
    //     .ADDR_WIDTH(HASH_WIDTH),
    //     .DATA_WIDTH(addr_width+1+INST_WIDTH),
    //     .INIT_NUM(0)
    // )u_offset(
    //     .clk(clk),
    //     .raddr(inst_pc_hashed),
    //     .dout({paddr_pdc_off,offset_valid,inst_pc_}),
    //     .enb(1),
    //     .waddr(inst_pc_hashed),
    //     .din({addr,1'b1,inst_pc}),
    //     .we(inst_valid)
    // );

    // assign naddr_pdc_off=addr+(addr-paddr_pdc_off);

    // //指针型
    // //以addr为索引，存储 访存的地址
    wire [addr_width-1:0] naddr_pdc_ptr;
    reg  [addr_width-1:0] paddr_pdc_ptr;
    wire ptr_valid;
    wire [addr_width-1:0] ptr_addr_;
    // sp_bram#(
    //     .ADDR_WIDTH(HASH_WIDTH),
    //     .DATA_WIDTH(addr_width+1+addr_width),
    //     .INIT_NUM(0)
    // )u_pointer(
    //     .clk(clk),
    //     .raddr(addr_hashed),
    //     .dout({naddr_pdc_ptr,ptr_valid,ptr_addr_}),
    //     .enb(1),
    //     .waddr(paddr_pdc_ptr_hashed),
    //     .din({addr,1'b1,paddr_pdc_ptr}),
    //     .we((paddr_pdc_ptr!=addr))
    // );
    // always @(posedge clk) begin
    //     paddr_pdc_ptr<=addr;
    // end

    //以inst_pc为索引，存储 数据类型(choice:0:数组,1:指针)+空闲(spare)
    wire [1:0] choice_pdc;
    wire [1:0] spare_pdc;

    sp_bram#(
        .ADDR_WIDTH(HASH_WIDTH),
        .DATA_WIDTH(4),
        .INIT_NUM(4'b0110)
    )u_cpt_spt(
        .clk(clk),
        .raddr(ann_inst_pc_hashed),
        .dout({choice_pdc,spare_pdc}),
        .enb(1),
        .waddr(ann_inst_pc_upt_hashed),
        .din({choice_upt,ann_spare_upt}),
        .we(ann_update_en)
    );

    transformer_2bit u_choice(
        .crt(ann_choice_pdch),
        .nxt(ann_choice_upt),
        .taken(ann_choice)
    );
    transformer_2bit u_spare(
        .crt(ann_spare_pdch),
        .nxt(spare_upt),
        .taken(ann_spare)
    );
    
    //以pc为索引，存储 有效(~hit)
    wire [1:0] hit_pdc;
    sp_bram#(
        .ADDR_WIDTH(HASH_WIDTH),
        .DATA_WIDTH(2),
        .INIT_NUM(2'b01)
    )u_hpt(
        .clk(clk),
        .raddr(ann_addr_hashed),
        .dout(hit_pdc),
        .enb(1),
        .waddr(ann_addr_upt_hashed),
        .din(hit_upt),
        .we(ann_update_en)
    );

    transformer_2bit u_hit(
        .crt(ann_hit_pdch),
        .nxt(hit_upt),
        .taken(ann_hit)
    );

    wire allow_ptr;
    wire allow_off;

    always @(*) begin
        naddr_pdc=0;
        naddr_valid=0;
        req=0;
        // if(anneal_unhit_reg) ;
        // else if(~hit_pdc[1]&spare_pdc[1]) ;
        //     if(choice_pdc[1]&ptr_valid&allow_ptr) begin
        //     if(choice_pdc[1]&ptr_valid&(addr==ptr_addr_)&allow_ptr) begin
        //         naddr_pdc=naddr_pdc_ptr;
        //         naddr_valid=1;
        //         req=1;
        //     end
        //     // else if(~choice_pdc[1]&offset_valid&allow_off) begin
        //     else if(~choice_pdc[1]&offset_valid&(inst_pc==inst_pc_)&allow_off) begin
        //         naddr_pdc=naddr_pdc_off;
        //         naddr_valid=1;
        //         req=1;
        //     end
        if(valid_naddr_dir) begin
            naddr_pdc=naddr_pdc_dir;
            naddr_valid=1;
            req=1;
        end
    end

    //退火
    always @(posedge clk) begin
        anneal_unhit_reg<=anneal_unhit&anneal_type;
        anneal_pc_reg<=anneal_pc;
        anneal_addr_reg<=anneal_addr;
    end
    always @(*) begin
        ann_inst_pc     =inst_pc;
        ann_inst_pc_upt =inst_pc_upt;
        ann_addr        =addr;
        ann_addr_upt    =addr_upt;
        choice_upt      =ann_choice_upt;
        ann_choice_pdch =choice_pdch;
        ann_choice      =choice;
        ann_spare_pdch  =spare_pdch;
        ann_spare       =spare;
        ann_spare_upt   =hit?spare_pdch:spare_upt;
        ann_hit_pdch    =hit_pdch;
        ann_hit         =hit;
        ann_update_en   =update_en;

        if(anneal_unhit&anneal_type) begin
            ann_inst_pc     =anneal_pc;
            ann_addr        =anneal_addr;
        end
        else if(anneal_unhit_reg) begin
            ann_inst_pc_upt =anneal_pc_reg;
            ann_addr_upt    =anneal_addr_reg;
            choice_upt      =choice_pdc;
            ann_choice_pdch =choice_pdc;
            ann_choice      =0;
            ann_spare_pdch  =spare_pdc;
            ann_spare       =1;
            ann_spare_upt   =spare_upt;
            ann_hit_pdch    =hit_pdc;
            ann_hit         =0;
            ann_update_en   =1;
        end
        else ;
    end

    //hash
    wire [HASH_WIDTH-1:0] inst_pc_hashed;
    wire [HASH_WIDTH-1:0] addr_hashed;
    wire [HASH_WIDTH-1:0] paddr_pdc_ptr_hashed;
    wire [HASH_WIDTH-1:0] ann_inst_pc_hashed;
    wire [HASH_WIDTH-1:0] ann_inst_pc_upt_hashed;
    wire [HASH_WIDTH-1:0] ann_addr_hashed;
    wire [HASH_WIDTH-1:0] ann_addr_upt_hashed;

    single_hash#(
        .DATA_width(INST_WIDTH),
        .HASH_width(HASH_WIDTH)
    )u_inst_pc_hashed(
        .data_raw(inst_pc),
        .data_hashed(inst_pc_hashed)
    );

    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_addr_hashed(
        .data_raw(addr),
        .data_hashed(addr_hashed)
    );

    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_paddr_pdc_ptr_hashed(
        .data_raw(paddr_pdc_ptr),
        .data_hashed(paddr_pdc_ptr_hashed)
    );

    single_hash#(
        .DATA_width(INST_WIDTH),
        .HASH_width(HASH_WIDTH)
    )u_ann_inst_pc_hashed(
        .data_raw(ann_inst_pc),
        .data_hashed(ann_inst_pc_hashed)
    );

    single_hash#(
        .DATA_width(INST_WIDTH),
        .HASH_width(HASH_WIDTH)
    )u_ann_inst_pc_upt_hashed(
        .data_raw(ann_inst_pc_upt),
        .data_hashed(ann_inst_pc_upt_hashed)
    );

    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_ann_addr_hashed(
        .data_raw(ann_addr),
        .data_hashed(ann_addr_hashed)
    );

    single_hash#(
        .DATA_width(addr_width),
        .HASH_width(HASH_WIDTH)
    )u_ann_addr_upt_hashed(
        .data_raw(ann_addr_upt),
        .data_hashed(ann_addr_upt_hashed)
    );

    //地址空洞
    IO_mask u_io_mask_ptr(
        .addr({naddr_pdc_ptr,5'b0}),
        .widthin(10'd32),
        .allow(allow_ptr)
    );   
    IO_mask u_io_mask_off(
        .addr({naddr_pdc_off,5'b0}),
        .widthin(10'd32),
        .allow(allow_off)
    );
endmodule
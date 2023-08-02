module data_pre#(
    parameter ADDR_WIDTH = 32,
              INST_WIDTH = 32
)(
    input         clk,
    input         rstn,
    //预测
    input [INST_WIDTH-1:0]  inst_pc,
    input                   inst_valid,
    input [ADDR_WIDTH-1:0]  addr,
    output reg[ADDR_WIDTH-1:0]naddr_pdc,
    output reg              naddr_valid,
    output reg              req,
    output [5:0]            pdch,
    //更新
    input  [INST_WIDTH-1:0] inst_pc_upt,
    input  [ADDR_WIDTH-1:0] addr_upt,
    input  [ADDR_WIDTH-1:0] naddr_upt,
    input                   hit,        //i/d 共用
    input                   spare,
    input                   choice,
    input  [5:0]            pdch_upt, //{hit,spare,choice}
    input                   update_en,
    //l2cache-(annealing)-port
    input        [ADDR_WIDTH-1:0]anneal_addr,
    input        [ADDR_WIDTH-1:0]anneal_pc,
    input        anneal_unhit,
    input        anneal_type
);
    reg  anneal_unhit_reg;
    reg  [ADDR_WIDTH-1:0]anneal_addr_reg;
    reg  [ADDR_WIDTH-1:0]anneal_pc_reg;

    reg [INST_WIDTH-1:0]ann_inst_pc     ;
    reg [INST_WIDTH-1:0]ann_inst_pc_upt ;
    reg [ADDR_WIDTH-1:0]ann_addr        ;
    reg [ADDR_WIDTH-1:0]ann_addr_upt    ;
    wire[1:0]           ann_choice_upt  ;
    reg [1:0]           ann_choice_pdch ;
    reg                 ann_choice      ;
    reg [1:0]           ann_spare_pdch  ;
    reg                 ann_spare       ;
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
    //数组型
    //以inst_pc为索引，存储 上一次访存的地址+valid
    wire [ADDR_WIDTH-1:0] paddr_pdc_off;
    wire [ADDR_WIDTH-1:0] naddr_pdc_off;
    wire offset_valid;
    sp_bram#(
        .ADDR_WIDTH(INST_WIDTH),
        .DATA_WIDTH(ADDR_WIDTH+1),
        .INIT_NUM(0)
    )u_offset(
        .clk(clk),
        .raddr(inst_pc),
        .dout({paddr_pdc_off,offset_valid}),
        .waddr(inst_pc),
        .din({addr,1'b1}),
        .we(inst_valid)
    );

    assign naddr_pdc_off=addr+(addr-paddr_pdc_off);

    //指针型
    //以addr为索引，存储 访存的地址
    wire [ADDR_WIDTH-1:0] naddr_pdc_ptr;
    reg  [ADDR_WIDTH-1:0] paddr_pdc_ptr;
    wire ptr_valid;
    sp_bram#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(ADDR_WIDTH+1),
        .INIT_NUM(0)
    )u_pointer(
        .clk(clk),
        .raddr(addr),
        .dout({naddr_pdc_ptr,ptr_valid}),
        .waddr(paddr_pdc_ptr),
        .din({addr,1'b1}),
        .we((paddr_pdc_ptr!=addr))
    );
    always @(posedge clk) begin
        paddr_pdc_ptr<=addr;
    end

    //以inst_pc为索引，存储 数据类型(choice:0:数组,1:指针)+空闲(spare)
    wire [1:0] choice_pdc;
    wire [1:0] spare_pdc;

    sp_bram#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(4),
        .INIT_NUM(4'b0110)
    )u_cpt_spt(
        .clk(clk),
        .raddr(ann_inst_pc),
        .dout({choice_pdc,spare_pdc}),
        .waddr(ann_inst_pc_upt),
        .din({choice_upt,spare_upt}),
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
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(2),
        .INIT_NUM(2'b01)
    )u_hpt(
        .clk(clk),
        .raddr(addr),
        .dout(hit_pdc),
        .waddr(ann_addr_upt),
        .din(hit_upt),
        .we(ann_update_en)
    );

    transformer_2bit u_hit(
        .crt(ann_hit_pdch),
        .nxt(hit_upt),
        .taken(ann_hit)
    );

    always @(*) begin
        naddr_pdc=0;
        naddr_valid=0;
        req=0;
        if(anneal_unhit_reg) ;
        else if(~hit_pdc[1]&spare_pdc[1]) 
            if(choice_pdc[1]&ptr_valid) begin
                naddr_pdc=naddr_pdc_ptr;
                naddr_valid=1;
                req=1;
            end
            else if(~choice_pdc[1]&offset_valid) begin
                naddr_pdc=naddr_pdc_off;
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
            ann_hit_pdch    =hit_pdc;
            ann_hit         =0;
            ann_update_en   =1;
        end
        else ;
    end
endmodule
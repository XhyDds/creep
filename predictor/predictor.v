`define TEST
module predictor #(
    parameter   k_width   = 12,
                h_width   = 8,
                bh_width  = 16,
                gh_width  = 32,
                stack_len = 16,
                queue_len = 16,
                ADDR_WIDTH= 30
)(
    input clk,
    input rstn,
    input update_en,
    input stall,
    //来自ex段
    input [ADDR_WIDTH-1:0]pc_ex,
    input [2:0]mis_pdc,         //2:npc 1:kind 0:taken
    input [ADDR_WIDTH-1:0]npc_ex,
    input [ADDR_WIDTH-1:0]ret_pc_ex,
    input [2:0]kind_ex,
    input taken_real,
    input [bh_width-1:0] bh_ex,
    input [1:0]choice_real,     //1:ras/btb  0:g/h
    input [1:0]choice_pdc_ex,
    input [7:0]out_pdch,
    input [2:0]kind_pdc_ex,
    input [11:0]tage_pdch_ex,

    //预测
    output [ADDR_WIDTH-1:0]npc_pdc,
    output [2:0]kind_pdc,
    output taken_pdc,
    output reg[bh_width-1:0] bh_pdc,//需要寄存
    output [1:0]choice_pdc,      //1:ras/btb  0:g/h
    output [7:0]pdch,
    output [11:0]tage_pdch,
    //当前
    input [ADDR_WIDTH-1:0]pc,
    output[ADDR_WIDTH-1:0]npc_test
);
    parameter   NOT_JUMP = 3'd0,
                DIRECT_JUMP = 3'd1,
                //
                RET = 3'd4,
                INDIRECT_JUMP = 3'd5,
                CALL = 3'd6,
                JUMP=3'd7;

    wire mis_pdc_npc   = mis_pdc[2];
    wire mis_pdc_kind  = mis_pdc[1];
    wire mis_pdc_taken = mis_pdc[0];

    wire choice_real_btb_ras=choice_real[1];
    wire choice_real_b_g    =choice_real[0];

    wire choice_pdc_b_g,choice_pdc_btb_ras;
    assign choice_pdc={choice_pdc_btb_ras,choice_pdc_b_g};

    wire [1:0]choice_pdch_ex_b_g    =out_pdch[1:0];
    wire [1:0]choice_pdch_ex_btb_ras=out_pdch[3:2];
    wire [1:0]taken_pdch_ex_b       =out_pdch[5:4];
    wire [1:0]taken_pdch_ex_g       =out_pdch[7:6];

    wire [1:0]choice_pdch_b_g    ;
    wire [1:0]choice_pdch_btb_ras;
    wire [1:0]taken_pdch_b       ;
    wire [1:0]taken_pdch_g       ;

    assign pdch={taken_pdch_g,taken_pdch_b,choice_pdch_btb_ras,choice_pdch_b_g};

    wire [gh_width-1:0] gh;
    wire [bh_width-1:0] bh_reg;
    wire [gh_width-1:0] gh_ex;
    reg [ADDR_WIDTH-1:0] pc_reg;
    reg [ADDR_WIDTH-1:0] pc_reg_reg;

    always @(posedge clk) begin
        if(!rstn) begin
            pc_reg<=30'h0700_0000;
            pc_reg_reg<=30'h0700_0000;
        end
        else if(~stall) begin
            pc_reg<=pc;
            pc_reg_reg<=pc_reg;
        end
    end

    //方向预测
    aim_predictor#(
        .h_width(h_width),
        .k_width(k_width),
        .bh_width(bh_width),
        .gh_width(gh_width),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_aim_predictor(
        .clk(clk),
        .stall(stall),
        .pc_ex(pc_ex),
        .gh_ex(gh_ex),
        .bh_ex(bh_ex),
        .kind_ex(kind_ex),
        .choice_real(choice_real_b_g),
        .taken_real(taken_real),
        .choice_pdch_ex(choice_pdch_ex_b_g),//b_g
        .taken_pdch_ex_b(taken_pdch_ex_b),
        .taken_pdch_ex_g(taken_pdch_ex_g),
        .kind_pdc(kind_pdc),
        .taken_pdc(taken_pdc),
        .choice_b_g(choice_pdc_b_g),
        .choice_pdch(choice_pdch_b_g),
        .taken_pdch_b(taken_pdch_b),
        .taken_pdch_g(taken_pdch_g),
        .gh(gh),
        .pc(pc),
        .pc_reg(pc_reg),
        .bh_reg(bh_reg),
        .update_en(update_en),

        .tage_pdch(tage_pdch),
        .tage_pdch_ex(tage_pdch_ex),
        .taken_pdc_ex(mis_pdc[0]?~taken_real:taken_real)
    );

    //类别预测
    kt#(
        .k_width(k_width),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_kt(
        .clk(clk),
        .pc(pc),
        .kind_pdc(kind_pdc),
        .stall(stall),
        .pc_update(pc_ex),
        .kind_real(kind_ex),
        .update_en(update_en)
    );

    //历史查取
    wire try_to_pdc=(kind_ex!=NOT_JUMP);

    // assign bh_pdc=bh_reg;
    always @(posedge clk) begin
        if(~stall) bh_pdc<=bh_reg;
    end

    bht#(
        .k_width(k_width),
        .bh_width(bh_width)
    )
    u_bht(
        .clk(clk),
        .stall(stall),
        .pc(pc),
        .bh_pdc(bh_reg),
        .bh_ex(bh_ex),
        .pc_update(pc_ex),
        .outcome_real(taken_real),
        .update_en(try_to_pdc&&update_en)
    );

    ghr#(
        .gh_width(gh_width),
        .queue_len(queue_len)
    )
    u_ghr(
        .clk(clk),
        .rstn(rstn),
        .stall(stall),
        .gh(gh),
        .gh_ex(gh_ex),
        .taken_pdc(taken_pdc),
        .taken_ex(taken_real),
        .mis_pdc(taken_pdch_ex_g[1]!=taken_real),
        .is_jump_pdc(kind_pdc!=NOT_JUMP),
        .is_jump_ex(kind_ex!=NOT_JUMP),
        .is_jump_pdc_ex(kind_pdc_ex!=NOT_JUMP),
        .update_en (update_en)
    );

    //地址预测
    npc_predictor#(
        .h_width(h_width),
        .stack_len(stack_len),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_npc_predictor(
        .clk(clk),
        .rstn(rstn),
        .stall(stall),
        .update_en(update_en),
        .taken_ex(taken_real),
        .npc_ex(npc_ex),
        .bh_ex(bh_ex),
        .ret_pc_ex(ret_pc_ex),
        .pc_ex(pc_ex),
        .kind_ex(kind_ex),
        .choice_real(choice_real_btb_ras),
        .choice_pdch_ex(choice_pdch_ex_btb_ras),//ras_btb
        .mis_pdc(mis_pdc_npc),
        .npc_pdc(npc_pdc),
        .kind_pdc(kind_pdc),
        .taken_pdc(taken_pdc),
        .choice_btb_ras(choice_pdc_btb_ras),
        .choice_pdch(choice_pdch_btb_ras),
        .bh_reg(bh_reg),
        .pc_reg(pc_reg),
        .pc_reg_reg(pc_reg_reg),
        .npc_test(npc_test)
    );


    `ifdef TEST
    reg [31:0] times_mis_npc    ;
    reg [31:0] times_mis_kind   ;
    reg [31:0] times_mis_taken  ;
    reg [31:0] times_total_npc  ;
    reg [31:0] times_total_kind ;
    reg [31:0] times_total_taken;

    reg [31:0] times_mis_bh     ;
    reg [31:0] times_mis_gh     ;
    reg [31:0] times_mis_btb    ;
    reg [31:0] times_mis_ras    ;

    always @(posedge clk) begin
        if(!rstn) begin
            times_mis_npc    <=0;
            times_mis_kind   <=0;
            times_mis_taken  <=0;
            times_total_npc  <=0;
            times_total_kind <=0;
            times_total_taken<=0;
            times_mis_bh     <=0;
            times_mis_gh     <=0;
            times_mis_btb    <=0;
            times_mis_ras    <=0;
        end
        else begin
            if(mis_pdc_npc&&update_en)  times_mis_npc    <=times_mis_npc    +1;
            if(mis_pdc_kind&&update_en) times_mis_kind   <=times_mis_kind   +1;
            if((kind_ex==DIRECT_JUMP)&&mis_pdc_taken&&update_en)
                                        times_mis_taken  <=times_mis_taken  +1;
            if(~mis_pdc_taken&&(kind_ex!=NOT_JUMP)&&update_en)
                                        times_total_npc  <=times_total_npc  +1;

                                        times_total_kind <=times_total_kind +1;
            if((kind_ex==DIRECT_JUMP)&&update_en)
                                        times_total_taken<=times_total_taken+1;

            if(mis_pdc_taken&&(kind_ex==DIRECT_JUMP)&&update_en) begin
                if(choice_real_b_g)     times_mis_gh     <=times_mis_gh     +1;
                else                    times_mis_bh     <=times_mis_bh     +1;
            end

            if(mis_pdc_npc&&(kind_ex==RET)&&update_en) begin
                if(choice_real_btb_ras) times_mis_ras    <=times_mis_ras    +1;
                else                    times_mis_btb    <=times_mis_btb    +1;
            end
        end
    end
    `endif

endmodule
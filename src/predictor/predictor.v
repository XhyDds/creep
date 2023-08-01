`define TEST
module predictor #(
    parameter   k_width   = 14,
                h_width   = 14,
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
    input [h_width-1:0] bh_ex,
    input [1:0]choice_real,     //1:btb/ras  0:g/h
    input [1:0]choice_pdc_ex,
    input [7:0]out_pdch,

    //预测
    output [ADDR_WIDTH-1:0]npc_pdc,
    output [2:0]kind_pdc,
    output taken_pdc,
    output [h_width-1:0] bh_pdc,
    output [1:0]choice_pdc,     //1:btb/ras  0:g/h
    output [7:0]pdch,
    //当前
    input [ADDR_WIDTH-1:0]pc,
    output[ADDR_WIDTH-1:0]npc_test
);
    parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,JUMP=3'd2,CALL = 3'd3,RET = 3'd4,INDIRECT_JUMP = 3'd5,OTHER_JUMP = 3'd6;

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

    //hash
    (* MAX_FANOUT = 3 *)wire [k_width-1:0] pc_hashed;
    (* MAX_FANOUT = 3 *)wire [h_width-1:0] pc_gh_hashed;
    (* MAX_FANOUT = 3 *)wire [h_width-1:0] pc_bh_hashed;

    wire [k_width-1:0] pc_ex_hashed;
    wire [h_width-1:0] pc_ex_gh_hashed;
    wire [h_width-1:0] pc_ex_bh_hashed;

    wire [h_width-1:0] gh;
    wire [h_width-1:0] bh;
    wire [h_width-1:0] gh_ex;

    (* MAX_FANOUT = 3 *)reg [k_width-1:0] pc_hashed_reg;
    reg [ADDR_WIDTH-1:0] pc_reg;

    always @(posedge clk) begin
        if(!rstn) begin
            pc_hashed_reg<=0;
            pc_reg<=0;
        end
        else begin
            pc_hashed_reg<=pc_hashed;
            pc_reg<=pc;
        end
    end

    single_hash#(
        .DATA_width(ADDR_WIDTH),
        .HASH_width(k_width)
    )
    single_hash_pc(
        .data_raw(pc),
        .data_hashed(pc_hashed)
    );

    single_hash#(
        .DATA_width(ADDR_WIDTH),
        .HASH_width(k_width)
    )
    single_hash_pc_ex(
        .data_raw(pc_ex),
        .data_hashed(pc_ex_hashed)
    );

    combine_hash#(
        .DATA1_width(k_width),
        .DATA2_width(h_width),
        .HASH_width(h_width)
    )
    combine_hash_pc_gh(
        .data1_raw(pc_hashed_reg),
        .data2_raw(gh),
        .data_hashed(pc_gh_hashed)
    );

    combine_hash#(
        .DATA1_width(k_width),
        .DATA2_width(h_width),
        .HASH_width(h_width)
    )
    combine_hash_pc_bh(
        .data1_raw(pc_hashed_reg),
        .data2_raw(bh),
        .data_hashed(pc_bh_hashed)
    );

    combine_hash#(
        .DATA1_width(k_width),
        .DATA2_width(h_width),
        .HASH_width(h_width)
    )
    combine_hash_pc_ex_gh(
        .data1_raw(pc_ex_hashed),
        .data2_raw(gh_ex),
        .data_hashed(pc_ex_gh_hashed)
    );

    combine_hash#(
        .DATA1_width(k_width),
        .DATA2_width(h_width),
        .HASH_width(h_width)
    )
    combine_hash_pc_ex_bh(
        .data1_raw(pc_ex_hashed),
        .data2_raw(bh_ex),
        .data_hashed(pc_ex_bh_hashed)
    );

    //方向预测
    aim_predictor#(
        .gh_width(k_width),
        .bh_width(h_width),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_aim_predictor(
        .clk(clk),
        .pc_ex(pc_ex),
        .pc_ex_gh_hashed(pc_ex_gh_hashed),
        .pc_ex_bh_hashed(pc_ex_bh_hashed),
        .pc_ex_hashed(pc_ex_hashed),
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
        .pc_gh_hashed(pc_gh_hashed),
        .pc_bh_hashed(pc_bh_hashed),
        .pc_hashed(pc_hashed),
        .pc(pc),
        .update_en(update_en)
    );

    //类别预测
    kt#(
        .k_width(k_width)
    )
    u_kt(
        .clk(clk),
        .hashed_pc(pc_hashed),
        .kind_pdc(kind_pdc),
        .hashed_pc_update(pc_ex_hashed),
        .kind_real(kind_ex),
        .update_en(update_en)
    );

    //历史查取
    wire try_to_pdc=(kind_ex!=NOT_JUMP);

    assign bh_pdc=bh;

    bht#(
        .k_width(k_width),
        .bh_width(h_width)
    )
    u_bht(
        .clk(clk),
        .hashed_pc(pc_hashed),
        .bh_pdc(bh),
        .hashed_pc_update(pc_ex_hashed),
        .bh_ex(bh_ex),
        .outcome_real(taken_real),
        .update_en(try_to_pdc&&update_en)
    );

    ghr#(
        .gh_width(h_width),
        .queue_len(queue_len)
    )
    u_ghr(
        .clk(clk),
        .rstn(rstn),
        .stall(stall),
        .gh(gh),
        .gh_ex(gh_ex),
        .taken_pdc(taken_pdc),
        .mis_pdc(mis_pdc_taken),
        .is_jump_pdc(kind_pdc!=NOT_JUMP),
        .is_jump_ex(kind_ex!=NOT_JUMP),
        .update_en (update_en)
    );

    //地址预测
    npc_predictor#(
        .gh_width(h_width),
        .stack_len(stack_len),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_npc_predictor(
        .clk(clk),
        .rstn(rstn),
        .update_en(update_en),
        .npc_ex(npc_ex),
        .ret_pc_ex(ret_pc_ex),
        .pc_ex_gh_hashed(pc_ex_gh_hashed),
        .pc_ex_bh_hashed(pc_ex_bh_hashed),
        .pc_ex_hashed(pc_ex_hashed),
        .kind_ex(kind_ex),
        .choice_real(choice_real_btb_ras),
        .choice_pdch_ex(choice_pdch_ex_btb_ras),//btb_ras
        .mis_pdc(mis_pdc_npc),
        .npc_pdc(npc_pdc),
        .kind_pdc(kind_pdc),
        .taken_pdc(taken_pdc),
        .choice_btb_ras(choice_pdc_btb_ras),
        .choice_pdch(choice_pdch_btb_ras),
        .pc_gh_hashed(pc_gh_hashed),
        .pc_bh_hashed(pc_bh_hashed),
        .pc_hashed_reg(pc_hashed_reg),
        .pc_reg(pc_reg),
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
            if(mis_pdc_npc&&update_en)             times_mis_npc    <=times_mis_npc    +1;
            if(mis_pdc_kind&&update_en)            times_mis_kind   <=times_mis_kind   +1;
            if(mis_pdc_taken&&update_en)           times_mis_taken  <=times_mis_taken  +1;

            if(~mis_pdc_taken&&kind_ex!=NOT_JUMP&&update_en)
                                        times_total_npc  <=times_total_npc  +1;
                                        times_total_kind <=times_total_kind +1;
            if(kind_ex==DIRECT_JUMP||kind_ex==OTHER_JUMP&&update_en) 
                                        times_total_taken<=times_total_taken+1;

            if(mis_pdc_taken&&(kind_ex==DIRECT_JUMP||kind_ex==OTHER_JUMP)&&update_en) begin
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

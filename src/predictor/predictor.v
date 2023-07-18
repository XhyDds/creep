module predictor #(
    parameter   k_width   = 14,
                h_width   = 14,
                stack_len = 16,
                queue_len = 16,
                ADDR_WIDTH= 30
)(
    input clk,
    input rstn,
    //来自ex段
    input [ADDR_WIDTH-1:0]pc_ex,
    input [2:0]mis_pdc,         //2:npc 1:kind 0:taken
    input [ADDR_WIDTH-1:0]npc_ex,
    input [2:0]kind_ex,
    input taken_real,
    input [1:0]choice_real,     //1:btb/ras  0:g/h

    //预测
    output [ADDR_WIDTH-1:0]npc_pdc,
    output [2:0]kind_pdc,
    output taken_pdc,
    //当前
    input [ADDR_WIDTH-1:0]pc
);
    parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,CALL = 3'd2,RET = 3'd3,INDIRECT_JUMP = 3'd4,OTHER_JUMP = 3'd5;

    wire mis_pdc_npc   = mis_pdc[2];
    wire mis_pdc_kind  = mis_pdc[1];
    wire mis_pdc_taken = mis_pdc[0];

    wire choice_real_btb_ras=choice_real[1];
    wire choice_real_b_g    =choice_real[0];

    //hash
    wire [k_width-1:0] pc_hashed;
    wire [h_width-1:0] pc_gh_hashed;
    wire [h_width-1:0] pc_bh_hashed;

    wire [k_width-1:0] pc_ex_hashed;
    wire [h_width-1:0] pc_ex_gh_hashed;
    wire [h_width-1:0] pc_ex_bh_hashed;

    wire [h_width-1:0] gh;
    wire [h_width-1:0] bh;
    wire [h_width-1:0] gh_ex;
    wire [h_width-1:0] bh_ex;

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
        .data1_raw(pc_hashed),
        .data2_raw(gh),
        .data_hashed(pc_gh_hashed)
    );

    combine_hash#(
        .DATA1_width(k_width),
        .DATA2_width(h_width),
        .HASH_width(h_width)
    )
    combine_hash_pc_bh(
        .data1_raw(pc_hashed),
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
        .kind_ex(kind_ex),
        .choice_real(choice_real_b_g),
        .taken_real(taken_real),
        .kind_pdc(kind_pdc),
        .taken_pdc(taken_pdc),
        .pc_gh_hashed(pc_gh_hashed),
        .pc_bh_hashed(pc_bh_hashed),
        .pc(pc)
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
        .update_en(1)
    );

    //历史查取
    wire try_to_pdc=(kind_ex!=NOT_JUMP);

    bht#(
        .k_width(k_width),
        .bh_width(h_width)
    )
    u_bht(
        .clk(clk),
        .hashed_pc(pc_hashed),
        .bh_pdc(bh),
        .hashed_pc_update(pc_ex_hashed),
        .outcome_real(taken_real),
        .update_en(try_to_pdc)
    );

    ghr#(
        .gh_width(h_width),
        .queue_len(queue_len)
    )
    u_ghr(
        .clk(clk),
        .rstn(rstn),
        .gh(gh),
        .taken_pdc(taken_pdc),
        .mis_pdc(mis_pdc_taken),
        .is_jump_pdc(kind_pdc!=NOT_JUMP),
        .is_jump_ex(kind_ex!=NOT_JUMP)
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
        .npc_ex(npc_ex),
        .pc_ex_gh_hashed(pc_ex_gh_hashed),
        .kind_ex(kind_ex),
        .choice_real(choice_real_btb_ras),
        .mis_pdc(mis_pdc_npc),
        .npc_pdc(npc_pdc),
        .kind_pdc(kind_pdc),
        .taken_pdc(taken_pdc),
        .pc_gh_hashed(pc_gh_hashed),
        .pc(pc)
    );


endmodule
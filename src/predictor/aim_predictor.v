module aim_predictor#(
    parameter   h_width   = 8,
                k_width   = 12,
                bh_width  = 32,
                ADDR_WIDTH = 30,
                gh_width = 32
)(
    input  clk,
    input  update_en,
    //ex
    input  [ADDR_WIDTH-1:0] pc_ex,
    input  [h_width-1:0] pc_ex_bh_hashed,
    input  [k_width-1:0] pc_ex_hashed,
    input  [gh_width-1:0] gh_ex,
    input  [2:0]kind_ex,
    input  choice_real,
    input  [1:0]choice_pdch_ex,
    input  taken_real,
    input  [1:0]taken_pdch_ex_b,
    input  [1:0]taken_pdch_ex_g,
    //预测
    input  [2:0]kind_pdc,
    output taken_pdc,
    output choice_b_g,    //0:b,1:g
    output [1:0]choice_pdch,
    output [1:0]taken_pdch_b,
    output [1:0]taken_pdch_g,
    //当前
    input  [h_width-1:0] pc_bh_hashed,
    input  [k_width-1:0] pc_hashed,
    input  [gh_width-1:0] gh,
    input  [ADDR_WIDTH-1:0] pc_reg,
    //tage
    output [11:0] tage_pdch,
    input [11:0] tage_pdch_ex,
    input taken_pdc_ex
);
    
    parameter   NOT_JUMP = 3'd0,
                DIRECT_JUMP = 3'd1,
                //
                RET = 3'd4,
                INDIRECT_JUMP = 3'd5,
                CALL = 3'd6,
                JUMP=3'd7;

    wire taken_b;
    wire taken_g;       

    wire try_to_pdc=(kind_ex==DIRECT_JUMP);

    bpht#(              //pc+bh
        .bh_width(h_width)
    )
    bpht_b(
        .clk(clk),
        .hashed_pc(pc_bh_hashed),
        .pc(pc_reg),
        .b_taken_pdc(taken_b),
        .taken_pdch_b(taken_pdch_b),
        .hashed_pc_update(pc_ex_bh_hashed),
        .b_taken_real(taken_real),
        .taken_pdch_ex_b(taken_pdch_ex_b),
        .update_en(try_to_pdc&&update_en),
        .pc_update(pc_ex)
    );

    wire taken_tage;

    tage #(
        .gh_width(gh_width),
        .ADDR_WIDTH(ADDR_WIDTH),
        .h_width(h_width),
        .DATA_WIDTH(27)
    )u_tage(
        .clk(clk),
        .update_en(try_to_pdc&&update_en),
        .pc_reg(pc_reg),
        .gh(gh),
        .taken_bh(taken_b),
        .pc_ex(pc_ex),
        .taken_pdc_ex(taken_pdc_ex),
        .taken_ex(taken_real),
        .gh_ex(gh_ex),
        .pdch_ex(tage_pdch_ex),
        .taken_pdc(taken_tage),
        .pdch(tage_pdch)
    );

    assign taken_pdc= kind_pdc[2]
                    | ( kind_pdc[0] & taken_tage );    
    // assign taken_pdc= kind_pdc[2]
    //                 | ( kind_pdc[0] & taken_b );
endmodule
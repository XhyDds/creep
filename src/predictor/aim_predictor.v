module aim_predictor#(
    parameter   gh_width   = 14,
                bh_width   = 14,
                ADDR_WIDTH = 29
)(
    input  clk,
    //ex
    input  [ADDR_WIDTH-1:0] pc_ex,
    input  [gh_width-1:0] pc_ex_gh_hashed,
    input  [bh_width-1:0] pc_ex_bh_hashed,
    input  [2:0]kind_ex,
    input  choice_real,
    input  taken_real,
    //预测
    input  [2:0]kind_pdc,
    output reg taken_pdc,
    output choice_b_g,    //0:b,1:g
    //当前
    input  [gh_width-1:0] pc_gh_hashed,
    input  [bh_width-1:0] pc_bh_hashed,
    input  [ADDR_WIDTH-1:0] pc
);
    parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,JUMP=3'd2,CALL = 3'd3,RET = 3'd4,INDIRECT_JUMP = 3'd5,OTHER_JUMP = 3'd6;

    wire taken_b;
    wire taken_g;       

    wire try_to_pdc=(kind_ex==DIRECT_JUMP||kind_ex==OTHER_JUMP);

    bpht#(
        .bh_width(bh_width)
    )
    bpht_b(
        .clk(clk),
        .hashed_pc(pc_bh_hashed),
        .b_taken_pdc(taken_b),
        .hashed_pc_update(pc_ex_bh_hashed),
        .b_taken_real(taken_real),
        .update_en(try_to_pdc)
    );

    gpht#(
        .gh_width(gh_width)
    )
    gpht_g(
        .clk(clk),
        .hashed_pc(pc_gh_hashed),
        .g_taken_pdc(taken_g),
        .hashed_pc_update(pc_ex_gh_hashed),
        .g_taken_real(taken_real),
        .update_en(try_to_pdc)
    );

    cpht#(
        .ch_width(gh_width)
    )
    cpht_b_g(
        .clk(clk),
        .hashed_pc(pc_gh_hashed),
        .choice_pdc(choice_b_g),
        .hashed_pc_update(pc_ex_gh_hashed),
        .choice_real(choice_real),
        .update_en(try_to_pdc)
    );

    always @(*) begin
        case (kind_pdc)
            NOT_JUMP:       taken_pdc=0;
            DIRECT_JUMP:    taken_pdc=choice_b_g?taken_g:taken_b; 
            JUMP:           taken_pdc=1;
            CALL:           taken_pdc=1;
            RET:            taken_pdc=1;
            INDIRECT_JUMP:  taken_pdc=1;
            OTHER_JUMP:     taken_pdc=choice_b_g?taken_g:taken_b;
            default:        taken_pdc=0;
        endcase
    end
endmodule

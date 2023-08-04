module aim_predictor#(
    parameter   h_width   = 8,
                k_width   = 12,
                ADDR_WIDTH = 30
)(
    input  clk,
    input  update_en,
    //ex
    input  [ADDR_WIDTH-1:0] pc_ex,
    // input  [h_width-1:0] pc_ex_gh_hashed,
    input  [h_width-1:0] pc_ex_bh_hashed,
    input  [k_width-1:0] pc_ex_hashed,
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
    // input  [h_width-1:0] pc_gh_hashed1,
    // input  [h_width-1:0] pc_gh_hashed2,
    input  [h_width-1:0] pc_bh_hashed,
    input  [k_width-1:0] pc_hashed,
    input  [ADDR_WIDTH-1:0] pc_reg
);
    // parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,JUMP=3'd2,CALL = 3'd3,RET = 3'd4,INDIRECT_JUMP = 3'd5,OTHER_JUMP = 3'd6;
    
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

    // gpht#(              //pc+gh
    //     .gh_width(h_width)
    // )
    // gpht_g(
    //     .clk(clk),
    //     .hashed_pc(pc_gh_hashed1),
    //     .pc(pc_reg),
    //     .g_taken_pdc(taken_g),
    //     .taken_pdch_g(taken_pdch_g),
    //     .hashed_pc_update(pc_ex_gh_hashed),
    //     .pc_update(pc_ex),
    //     .g_taken_real(taken_real),
    //     .taken_pdch_ex_g(taken_pdch_ex_g),
    //     .update_en(try_to_pdc&&update_en)
    // );

    // cpht#(              //pc
    //     .ch_width(h_width)
    // )
    // cpht_b_g(
    //     .clk(clk),
    //     .hashed_pc(pc_gh_hashed2),
    //     .choice_pdc(choice_b_g),
    //     .choice_pdch(choice_pdch),
    //     .hashed_pc_update(pc_ex_gh_hashed),
    //     .choice_real(choice_real),
    //     .choice_pdch_ex(choice_pdch_ex),
    //     .update_en(try_to_pdc&&update_en)
    // );

    // always @(*) begin
    //     case (kind_pdc)
    //         NOT_JUMP:       taken_pdc=0;
    //         JUMP:           taken_pdc=1;
    //         CALL:           taken_pdc=1;
    //         DIRECT_JUMP:    taken_pdc=(choice_b_g&taken_g)|(~choice_b_g&taken_b);
    //         RET:            taken_pdc=1;
    //         INDIRECT_JUMP:  taken_pdc=1;
    //         // OTHER_JUMP:     taken_pdc=choice_b_g?taken_g:taken_b;
    //         default:        taken_pdc=0;
    //     endcase
    // end

//     assign taken_pdc= ( kind_pdc[2] &  1)
//                     | (~kind_pdc[2] &  kind_pdc[0] & (choice_b_g&taken_g)|(~choice_b_g&taken_b) )
//                     | (~kind_pdc[2] & ~kind_pdc[0] & 0);

    // assign taken_pdc= kind_pdc[2]
    //                 | ( kind_pdc[0] & (choice_b_g&taken_g)|(~choice_b_g&taken_b) );

    assign taken_pdc= kind_pdc[2]
                    | ( kind_pdc[0] & taken_b );

        // assign taken_pdc= kind_pdc[2]
        //             | ( kind_pdc[0] & taken_g );
endmodule
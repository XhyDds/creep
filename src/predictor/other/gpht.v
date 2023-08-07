module gpht#(
    parameter gh_width = 14,
             ADDR_WIDTH = 30,
             h_width = 8
)(
    input clk,
    //query
    input [gh_width-1:0]gh,//hash(pc,gh)
    input [ADDR_WIDTH-1:0]pc,
    output g_taken_pdc,
    output [1:0]taken_pdch_g,
    //update
    input [gh_width-1:0]gh_update,
    input [ADDR_WIDTH-1:0]pc_update,
    input g_taken_real,
    input [1:0]taken_pdch_ex_g,
    input update_en
);
    wire [h_width-1:0]pc_gh_hashed;
    wire [h_width-1:0]pc_gh_hashed_upt;

    wire[1:0] _gph;
    wire[ADDR_WIDTH-1:0]_pc;
    assign g_taken_pdc=(_pc==pc)&_gph[1];
    assign taken_pdch_g=_gph;

    wire[1:0] _gph_old;
    wire[1:0] _gph_new;

    sp_bram#(
        .ADDR_WIDTH(h_width),
        .DATA_WIDTH(2+ADDR_WIDTH)
    )
    bpht_regs(
        .clk(clk),
        .raddr(pc_gh_hashed),
        .dout({_gph,_pc}),
        .enb(1),
        .waddr(pc_gh_hashed_upt),
        .din({_gph_new,pc_update}),
        .we(update_en)
    );
    //core
    transformer_2bit core(
        .crt(taken_pdch_ex_g),
        .nxt(_gph_new),
        .taken(g_taken_real)
    );

    //hash
    pc_gh_hash#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .gh_width(gh_width),
        .h_width(h_width)
    ) u_pc_gh_hashed(
        .pc(pc),
        .gh(gh),
        .pc_gh_hashed(pc_gh_hashed)
    );

    pc_gh_hash#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .gh_width(gh_width),
        .h_width(h_width)
    ) u_pc_gh_hashed_upt(
        .pc(pc_update),
        .gh(gh_update),
        .pc_gh_hashed(pc_gh_hashed_upt)
    );
    
endmodule
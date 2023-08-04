module gpht#(
    parameter gh_width = 14,
             ADDR_WIDTH = 30   
)(
    input clk,
    //query
    input [gh_width-1:0]hashed_pc,//hash(pc,gh)
    input [ADDR_WIDTH-1:0]pc,
    output g_taken_pdc,
    output [1:0]taken_pdch_g,
    //update
    input [gh_width-1:0]hashed_pc_update,
    input [ADDR_WIDTH-1:0]pc_update,
    input g_taken_real,
    input [1:0]taken_pdch_ex_g,
    input update_en
);
    wire[1:0] _gph;
    wire[ADDR_WIDTH-1:0]_pc;
    assign g_taken_pdc=(_pc==pc)&_gph[1];
    assign taken_pdch_g=_gph;

    wire[1:0] _gph_old;
    wire[1:0] _gph_new;

    sp_dram#(
        .ADDR_WIDTH(gh_width),
        .DATA_WIDTH(2+ADDR_WIDTH)
    )
    bpht_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout({_gph,_pc}),
        .waddr(hashed_pc_update),
        .din({_gph_new,pc_update}),
        .we(update_en)
    );

    transformer_2bit core(
        .crt(taken_pdch_ex_g),
        .nxt(_gph_new),
        .taken(g_taken_real)
    );
endmodule
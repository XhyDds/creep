module bpht#(
    parameter gh_width = 14
)(
    input clk,
    //query
    input [gh_width-1:0]hashed_pc,//hash(pc,gh)
    output g_taken_pdc,
    //update
    input [gh_width-1:0]hashed_pc_update,
    input g_taken_real
);
    wire[1:0] _gph;
    assign g_taken_pdc=_gph[1];

    wire[1:0] _gph_old;
    wire[1:0] _gph_new;

    wire update_en;
    assign update_en=1;//暂定如此，需要考虑stall等信号    //TOBE DONE

    dp_dram#(
        .ADDR_WIDTH(gh_width),
        .DATA_WIDTH(2)
    )
    bpht_regs(
        .clk(clk),
        .araddr(hashed_pc),
        .adout(_gph),
        .braddr(hashed_pc_update),
        .bdout(_gph_old),
        .waddr(hashed_pc_update),
        .din(_gph_new),
        .we(update_en)
    );

    transformer_2bit core(
        .crt(_gph_old),
        .nxt(_gph_new),
        .taken(g_taken_real)
    );
endmodule

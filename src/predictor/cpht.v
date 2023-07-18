module cpht#(
    parameter ch_width=14
)(
    input clk,
    //query
    input [ch_width-1:0]hashed_pc,//hash(pc,gh)
    output choice_pdc,
    //update
    input [ch_width-1:0]hashed_pc_update,
    input choice_real,
    input update_en
);
    wire[1:0] _cph;
    assign choice_pdc=_cph[1];

    wire[1:0] _cph_old;
    wire[1:0] _cph_new;

    dp_dram#(
        .ADDR_WIDTH(ch_width),
        .DATA_WIDTH(2)
    )
    cpht_regs(
        .clk(clk),
        .araddr(hashed_pc),
        .adout(_cph),
        .braddr(hashed_pc_update),
        .bdout(_cph_old),
        .waddr(hashed_pc_update),
        .din(_cph_new),
        .we(update_en)
    );

    transformer_2bit core(
        .crt(_cph_old),
        .nxt(_cph_new),
        .taken(choice_real)
    );
endmodule

module cpht#(
    parameter ch_width=16
)(
    input clk,
    //query
    input [ch_width-1:0]hashed_pc,//hash(pc,gh)
    output choice_pdc,
    //update
    input [ch_width-1:0]hashed_pc_update,
    input choice_real
);
    wire[1:0] _cph;
    assign choice_pdc=_cph[1];

    wire[1:0] _cph_old;
    wire[1:0] _cph_new;

    wire update_en;
    assign update_en=1;//暂定如此，需要考虑stall等信号    //TOBE DONE

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

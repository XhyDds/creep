module bpht#(
    parameter bh_width = 14
)(
    input clk,
    //query
    input [bh_width-1:0]hashed_pc,//hash(pc,bh)
    output b_taken_pdc,
    //update
    input [bh_width-1:0]hashed_pc_update,
    input b_taken_real,
    input update_en
);
    wire[1:0] _bph;
    assign b_taken_pdc=_bph[1];

    wire[1:0] _bph_old;
    wire[1:0] _bph_new;

    dp_dram#(
        .ADDR_WIDTH(bh_width),
        .DATA_WIDTH(2)
    )
    bpht_regs(
        .clk(clk),
        .araddr(hashed_pc),
        .adout(_bph),
        .braddr(hashed_pc_update),
        .bdout(_bph_old),
        .waddr(hashed_pc_update),
        .din(_bph_new),
        .we(update_en)
    );

    transformer_2bit core(
        .crt(_bph_old),
        .nxt(_bph_new),
        .taken(b_taken_real)
    );
endmodule
module bpht#(
    parameter bh_width = 14
)(
    input clk,
    //query
    input [bh_width-1:0]hashed_pc,//hash(pc,bh)
    output b_taken_pdc,
    output [1:0]taken_pdch_b,
    //update
    input [bh_width-1:0]hashed_pc_update,
    input b_taken_real,
    input [1:0]taken_pdch_ex_b,
    input update_en
);
    wire[1:0] _bph;
    assign b_taken_pdc=_bph[1];
    assign taken_pdch_b=_bph;

    wire[1:0] _bph_new;

    sp_dram#(
        .ADDR_WIDTH(bh_width),
        .DATA_WIDTH(2)
    )
    bpht_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout(_bph),
        .waddr(hashed_pc_update),
        .din(_bph_new),
        .we(update_en)
    );

    transformer_2bit core(
        .crt(taken_pdch_ex_b),
        .nxt(_bph_new),
        .taken(b_taken_real)
    );
endmodule

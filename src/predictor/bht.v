module bht#(
    parameter k_width = 14,
              bh_width = 14
)(
    input clk,
    //query
    input [k_width-1:0]hashed_pc,//hash(pc)
    output [bh_width-1:0]bh_pdc,
    //update
    input [k_width-1:0]hashed_pc_update,
    input outcome_real,
    input update_en
);
    wire[k_width-1:0] _bh_old;
    wire[k_width-1:0] _bh_new;

    assign _bh_new={_bh_old[bh_width-2:0],outcome_real};

    dp_dram#(
        .ADDR_WIDTH(k_width),
        .DATA_WIDTH(bh_width)
    )
    bht_regs(
        .clk(clk),
        .araddr(hashed_pc),
        .adout(bh_pdc),
        .braddr(hashed_pc_update),
        .bdout(_bh_old),
        .waddr(hashed_pc_update),
        .din(_bh_new),
        .we(update_en)
    );
endmodule

module bht#(
    parameter k_width = 14,
              bh_width = 14
)(
    input clk,
    input stall,
    //query
    input [k_width-1:0]hashed_pc,//hash(pc)
    output [bh_width-1:0]bh_pdc,
    //update
    input [k_width-1:0]hashed_pc_update,
    input outcome_real,
    input [bh_width-1:0]bh_ex,
    input update_en
);
    wire[k_width-1:0] _bh_new;

    assign _bh_new={bh_ex[bh_width-2:0],outcome_real};

    sp_bram#(
        .ADDR_WIDTH(k_width),
        .DATA_WIDTH(bh_width)
    )
    bht_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout(bh_pdc),
        .enb(~stall),
        .waddr(hashed_pc_update),
        .din(_bh_new),
        .we(update_en)
    );
endmodule
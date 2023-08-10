module bht#(
    parameter   ADDR_WIDTH = 30,
                k_width = 12,
                bh_width = 14
)(
    input clk,
    input stall,
    //query
    input [ADDR_WIDTH-1:0]pc,//hash(pc)
    output [bh_width-1:0]bh_pdc,
    //update
    input [ADDR_WIDTH-1:0]pc_update,
    input outcome_real,
    input [bh_width-1:0]bh_ex,
    input update_en
);
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0] pc_hashed;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0] pc_hashed_upt;


    sp_bram#(
        .ADDR_WIDTH(k_width),
        .DATA_WIDTH(bh_width)
    )
    bht_regs(
        .clk(clk),
        .raddr(pc_hashed),
        .dout(bh_pdc),
        // .enb(~stall),
        .enb(1),
        .waddr(pc_hashed_upt),
        .din({bh_ex[bh_width-2:0],outcome_real}),
        .we(update_en)
    );
    //hash
    pc_hash #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .k_width(k_width)
    )u_pc_hashed(
        .pc(pc),
        .pc_hashed(pc_hashed)
    );

    pc_hash #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .k_width(k_width)
    )u_pc_hashed_upt(
        .pc(pc_update),
        .pc_hashed(pc_hashed_upt)
    );
endmodule
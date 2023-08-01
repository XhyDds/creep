module btb#(
    parameter gh_width = 14,
              ADDR_WIDTH = 30
)(
    input clk,
    //query
    input [gh_width-1:0]hashed_pc,//hash(pc,gh)
    output [ADDR_WIDTH-1:0]npc_pdc,
    //update
    input [gh_width-1:0]hashed_pc_update,
    input [ADDR_WIDTH-1:0]npc_real,
    input update_en
);

    sp_dram#(
        .ADDR_WIDTH(gh_width),
        .DATA_WIDTH(ADDR_WIDTH),
        .INIT_NUM(30'h0700_0002)
    )
    btb_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout(npc_pdc),
        .waddr(hashed_pc_update),
        .din(npc_real),
        .we(update_en)
    );
endmodule
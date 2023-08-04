module btb#(
    parameter h_width = 8,
              k_width = 12,
              ADDR_WIDTH = 30
)(
    input clk,
    //query
    input [h_width-1:0]hashed_gh_pc,//hash(pc,gh)
    input [k_width-1:0]hashed_pc,//hash(pc)
    output [ADDR_WIDTH-1:0]npc_pdc,
    input [ADDR_WIDTH-1:0]pc_reg,
    //update
    input [h_width-1:0]hashed_gh_pc_update,
    input [k_width-1:0]hashed_pc_update,
    input [ADDR_WIDTH-1:0]npc_real,
    input update_en
);
    wire [k_width-1:0]hashed_pc_tag;
    wire [ADDR_WIDTH-1:0] npc_pdc_;

    assign npc_pdc = (hashed_pc_tag==hashed_pc)?npc_pdc_:(pc_reg[0]?(pc_reg+1):(pc_reg+2));

    sp_dram#(
        .ADDR_WIDTH(h_width),
        .DATA_WIDTH(ADDR_WIDTH+k_width),
        .INIT_NUM({30'h0700_0002,12'h000})
    )
    btb_regs(
        .clk(clk),
        .raddr(hashed_gh_pc),
        .dout({npc_pdc_,hashed_pc_tag}),
        .waddr(hashed_gh_pc_update),
        .din({npc_real,hashed_pc_update}),
        .we(update_en)
    );
endmodule
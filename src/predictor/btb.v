module btb#(
    parameter gh_width = 14,
              btb_width = 14
)(
    input clk,
    //query
    input [gh_width-1:0]hashed_pc,//hash(pc,gh)
    output [btb_width-1:0]npc_pdc,
    //update
    input [gh_width-1:0]hashed_pc_update,
    input [btb_width-1:0]npc_real
);

    wire update_en;
    assign update_en=1;//暂定如此，需要考虑stall等信号    //TOBE DONE

    sp_dram#(
        .ADDR_WIDTH(gh_width),
        .DATA_WIDTH(btb_width)
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
module kt#(
    parameter k_width = 14
)(
    input clk,
    //query
    input [k_width-1:0]hashed_pc,//hash(pc)（暂定：有考虑延迟因素）
    output[2:0]kind_pdc,
    //update
    input [k_width-1:0]hashed_pc_update,//ex段
    input [2:0]kind_real,
    input update_en
);
    parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,CALL = 3'd2,RET = 3'd3,INDIRECT_JUMP = 3'd4,OTHER_JUMP = 3'd5;

    sp_dram#(
        .ADDR_WIDTH(k_width),
        .DATA_WIDTH(3)
    )
    kt_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout(kind_pdc),
        .waddr(hashed_pc_update),
        .din(kind_real),
        .we(update_en)
    );
endmodule
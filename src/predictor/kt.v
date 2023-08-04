module kt#(
    parameter k_width = 12,
            ADDR_WIDTH=30
)(
    input clk,
    //query
    input [k_width-1:0]hashed_pc,//hash(pc)（暂定：有考虑延迟因素）
    input [ADDR_WIDTH-1:0]pc,
    output[2:0]kind_pdc,
    //update
    input [k_width-1:0]hashed_pc_update,//ex段
    input [ADDR_WIDTH-1:0]pc_ex,
    input [2:0]kind_real,
    input stall,
    input update_en
);
    parameter   NOT_JUMP = 3'd0,
                DIRECT_JUMP = 3'd1,
                //
                RET = 3'd4,
                INDIRECT_JUMP = 3'd5,
                CALL = 3'd6,
                JUMP=3'd7;
    wire [2:0] _kind_pdc;
    wire [12:0] _pc;

    assign kind_pdc=(_pc==pc[24:12])?_kind_pdc:3'b000;
    
    sp_bram#(
        .ADDR_WIDTH(k_width),
        .DATA_WIDTH(3+13)
    )
    kt_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout({_kind_pdc,_pc}),
        .enb(~stall),
        .waddr(hashed_pc_update),
        .din({kind_real,pc_ex[24:12]}),
        .we(update_en)
    );
endmodule
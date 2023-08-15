module kt#(
    parameter k_width = 12,
            ADDR_WIDTH=30
)(
    input clk,
    //query
    input [ADDR_WIDTH-1:0]pc,
    output reg[2:0]kind_pdc,
    //update
    input [ADDR_WIDTH-1:0]pc_update,//ex段
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
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0]hashed_pc;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0]hashed_pc_upt;

    wire [2:0] _kind_pdc;
    wire [12:0] _pc;

    wire [2:0]kind_pdc_=(_pc==pc[24:12])?_kind_pdc:3'b000;
    always @(posedge clk) begin
        if(~stall)
        kind_pdc<=kind_pdc_;
    end
    
    sp_bram#(
        .ADDR_WIDTH(k_width),
        .DATA_WIDTH(3+13)
    )
    kt_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout({_kind_pdc,_pc}),
        .enb(~stall),
        .waddr(hashed_pc_upt),
        .din({kind_real,pc_update[24:12]}),
        .we(update_en)
    );

    //hash
    pc_hash #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .k_width(k_width)
    )u_pc_hashed(
        .pc(pc),
        .pc_hashed(hashed_pc)
    );

    pc_hash #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .k_width(k_width)
    )u_pc_hashed_upt(
        .pc(pc_update),
        .pc_hashed(hashed_pc_upt)
    );

endmodule
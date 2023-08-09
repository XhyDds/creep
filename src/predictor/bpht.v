module bpht#(
    parameter bh_width = 16,
             ADDR_WIDTH = 30   ,
             h_width = 8
)(
    input clk,
    input stall,
    //query
    input [ADDR_WIDTH-1:0]pc,
    input [bh_width-1:0]bh,//hash(pc,bh)
    output b_taken_pdc,
    output [1:0]taken_pdch_b,
    //update
    input [ADDR_WIDTH-1:0]pc_update,
    input [bh_width-1:0]bh_update,
    input b_taken_real,
    input [1:0]taken_pdch_ex_b,
    input update_en
);
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [h_width-1:0] hashed_pc_bh;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [h_width-1:0] hashed_pc_bh_upt;
    wire[1:0] _bph;
    wire[ADDR_WIDTH-1:0]_pc;

    reg [ADDR_WIDTH-1:0] pc_reg;
    always @(posedge clk) begin
        if(~stall) pc_reg<=pc;
    end

    // assign b_taken_pdc=_bph[1];
    assign b_taken_pdc=(_pc==pc_reg)&_bph[1];
    assign taken_pdch_b=_bph;

    wire[1:0] _bph_new;

    sp_bram#(
        .ADDR_WIDTH(h_width),
        .DATA_WIDTH(2+ADDR_WIDTH)
    )
    bpht_regs(
        .clk(clk),
        .raddr(hashed_pc_bh),
        .dout({_bph,_pc}),
        .enb(~stall),
        .waddr(hashed_pc_bh_upt),
        .din({_bph_new,pc_update}),
        .we(update_en)
    );

    //core

    transformer_2bit core(
        .crt(taken_pdch_ex_b),
        .nxt(_bph_new),
        .taken(b_taken_real)
    );

    //hash
    pc_bh_hash#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .bh_width(bh_width),
        .h_width(h_width)
    ) u_pc_bh_hashed(
        .pc(pc),
        .bh(bh),
        .pc_bh_hashed(hashed_pc_bh)
    );
    pc_bh_hash#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .bh_width(bh_width),
        .h_width(h_width)
    ) u_pc_bh_hashed_upt(
        .pc(pc_update),
        .bh(bh_update),
        .pc_bh_hashed(hashed_pc_bh_upt)
    );
endmodule
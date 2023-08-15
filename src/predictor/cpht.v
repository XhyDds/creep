module cpht#(
    parameter k_width=12,
              ADDR_WIDTH=30
)(
    input clk,
    input stall,
    //query
    input [ADDR_WIDTH-1:0]pc,
    output choice_pdc,
    output [1:0]choice_pdch,
    //update
    input [ADDR_WIDTH-1:0]pc_update,
    input [1:0]choice_pdch_ex,
    input choice_real,
    input update_en
);
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0] hashed_pc;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0] hashed_pc_upt;

    wire[1:0] _cph;
    assign choice_pdc=_cph[1];

    wire[1:0] _cph_new;

    sp_bram#(
        .ADDR_WIDTH(k_width),
        .DATA_WIDTH(2)
    )
    cpht_regs(
        .clk(clk),
        .raddr(hashed_pc),
        .dout(_cph),
        .enb(~stall),
        .waddr(hashed_pc_upt),
        .din(_cph_new),
        .we(update_en)
    );
    //core
    transformer_2bit core(
        .crt(choice_pdch_ex),
        .nxt(_cph_new),
        .taken(choice_real)
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
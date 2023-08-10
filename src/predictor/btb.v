module btb#(
    parameter h_width = 8,
              k_width = 12,
              bh_width = 16,
              ADDR_WIDTH = 30
)(
    input clk,
    input stall,
    //query//hash(pc,gh)
    input [bh_width-1:0]bh,
    output [ADDR_WIDTH-1:0]npc_pdc,
    input [ADDR_WIDTH-1:0]pc,
    //update
    input [bh_width-1:0]bh_update,
    input [ADDR_WIDTH-1:0]pc_update,
    input [ADDR_WIDTH-1:0]npc_real,
    input update_en
);
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0]hashed_pc;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0]hashed_pc_tag;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [h_width-1:0]hashed_bh_pc;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0]hashed_pc_upt;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [h_width-1:0]hashed_bh_pc_upt;

    reg [ADDR_WIDTH-1:0] pc_reg;
    always @(posedge clk) begin
        if(~stall) pc_reg <= pc;
    end

    wire [ADDR_WIDTH-1:0] npc_pdc_;
    `ifndef DMA
    assign npc_pdc = (hashed_pc_tag==hashed_pc)?npc_pdc_:(pc_reg[0]?(pc_reg+1):(pc_reg+2));
    `endif
    `ifdef DMA
    assign npc_pdc = (hashed_pc_tag==hashed_pc)?npc_pdc_:(pc_reg+1);
    `endif


    sp_bram#(
        .ADDR_WIDTH(h_width),
        .DATA_WIDTH(ADDR_WIDTH+k_width),
        .INIT_NUM({30'h0700_0002,12'h000})
    )
    btb_regs(
        .clk(clk),
        .raddr(hashed_bh_pc),
        .dout({npc_pdc_,hashed_pc_tag}),
        .enb(~stall),
        .waddr(hashed_bh_pc_upt),
        .din({npc_real,hashed_pc_upt}),
        .we(update_en)
    );
    //hash
    pc_bh_hash #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .bh_width(bh_width),
        .h_width(h_width)
    )u_pc_bh_hashed(
        .pc(pc),
        .bh(bh),
        .pc_bh_hashed(hashed_bh_pc)
    );

    pc_bh_hash #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .bh_width(bh_width),
        .h_width(h_width)
    )u_pc_bh_hashed_upt(
        .pc(pc_update),
        .bh(bh_update),
        .pc_bh_hashed(hashed_bh_pc_upt)
    );

    pc_hash #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .k_width(k_width)
    )u_pc_hashed(
        .pc(pc_reg),
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
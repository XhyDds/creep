module bpht_cache#(
    parameter bh_width = 4,
             ADDR_WIDTH = 30   ,
             k_width = 12
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
    //declare
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0] hashed_pc;
    (* EQUIVALENT_REGISTER_REMOVAL="NO" ,MAX_FANOUT = 3 *)wire [k_width-1:0] hashed_pc_upt;

    //store


    //pdc

    //upt


    //hash
    pc_hash#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .k_width(k_width)
    ) u_pc_hashed(
        .pc(pc),
        .pc_hashed(hashed_pc)
    );
    pc_hash#(
        .ADDR_WIDTH(ADDR_WIDTH),
        .k_width(k_width)
    ) u_pc_hashed_upt(
        .pc(pc_update),
        .pc_hashed(hashed_pc_upt)
    );
endmodule

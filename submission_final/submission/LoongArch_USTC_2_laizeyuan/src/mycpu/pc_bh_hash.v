module pc_bh_hash#(
    parameter ADDR_WIDTH=30,   //pc
    parameter bh_width=16,   //bh
    parameter h_width=8
)(
    input [ADDR_WIDTH-1:0]      pc,
    input [bh_width-1:0]        bh,
    output[h_width-1:0]      pc_bh_hashed
);
    wire [h_width-1:0] bh_hashed={
        bh[0]^bh[15],
        bh[1]^bh[14],
        bh[2]^bh[13],
        bh[3]^bh[12],
        bh[4]^bh[11],
        bh[5]^bh[10],
        bh[6]^bh[9 ],
        bh[7]^bh[8 ]
    };
    wire [h_width-1:0] pc_hashed={
        pc[0]^pc[15]^pc[20]^pc[27]^pc[29],
        pc[1]^pc[14]^pc[21]^pc[26]^pc[28],
        pc[2]^pc[13]^pc[22]^pc[25],
        pc[3]^pc[12]^pc[23]^pc[24],
        pc[4]^pc[11]^pc[16],
        pc[5]^pc[10]^pc[17],
        pc[6]^pc[9 ]^pc[18],
        pc[7]^pc[8 ]^pc[19]
    };
    assign pc_bh_hashed=pc_hashed^bh_hashed;
endmodule
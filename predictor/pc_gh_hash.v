module pc_gh_hash#(
    parameter GH_width=36,   //gh
              ADDR_width=30,   //pc
              HASH_width=8
)(
    input [GH_width-1:0]     gh,
    input [ADDR_width-1:0]     pc,
    output[HASH_width-1:0]      hashed_8,
    output[HASH_width-1:0]      hashed_16,
    output[HASH_width-1:0]      hashed_32
);
    wire [HASH_width-1:0] gh_hashed_8=gh[7:0];
    wire [HASH_width-1:0] gh_hashed_16={
        gh[0]^gh[15],
        gh[1]^gh[14],
        gh[2]^gh[13],
        gh[3]^gh[12],
        gh[4]^gh[11],
        gh[5]^gh[10],
        gh[6]^gh[9],
        gh[7]^gh[8]
    };
    wire [HASH_width-1:0] gh_hashed_32={
        gh[0]^gh[15]^gh[16]^gh[31],
        gh[1]^gh[14]^gh[17]^gh[30],
        gh[2]^gh[13]^gh[18]^gh[29],
        gh[3]^gh[12]^gh[19]^gh[28],
        gh[4]^gh[11]^gh[20]^gh[27],
        gh[5]^gh[10]^gh[21]^gh[26],
        gh[6]^gh[9 ]^gh[22]^gh[25],
        gh[7]^gh[8 ]^gh[23]^gh[24]
    };
    wire [HASH_width-1:0] pc_hashed={
        pc[0]^pc[15]^pc[20]^pc[27]^pc[29],
        pc[1]^pc[14]^pc[21]^pc[26]^pc[28],
        pc[2]^pc[13]^pc[22]^pc[25],
        pc[3]^pc[12]^pc[23]^pc[24],
        pc[4]^pc[11]^pc[16],
        pc[5]^pc[10]^pc[17],
        pc[6]^pc[9 ]^pc[18],
        pc[7]^pc[8 ]^pc[19]
    };
    assign hashed_8=gh_hashed_8^pc_hashed;
    assign hashed_16=gh_hashed_16^pc_hashed;
    assign hashed_32=gh_hashed_32^pc_hashed;
endmodule
module pc_gh_hash#(
    parameter DATA1_width=12,
    parameter DATA2_width=32,   //bh
    parameter HASH_width=8
)(
    input [DATA1_width-1:0]     data1_raw,
    input [DATA2_width-1:0]     data2_raw,
    output[HASH_width-1:0]      data_hashed
);
    wire [HASH_width-1:0] data1_hashed={
        data1_raw[0]^data1_raw[11],
        data1_raw[1]^data1_raw[10],
        data1_raw[2]^data1_raw[9 ],
        data1_raw[3]^data1_raw[8 ],
        data1_raw[4],
        data1_raw[5],
        data1_raw[6],
        data1_raw[7]
    };
    // wire [HASH_width-1:0] data2_hashed={
    //     data2_raw[0]^data2_raw[15]^data2_raw[16]^data2_raw[31],
    //     data2_raw[1]^data2_raw[14]^data2_raw[17]^data2_raw[30],
    //     data2_raw[2]^data2_raw[13]^data2_raw[18]^data2_raw[29],
    //     data2_raw[3]^data2_raw[12]^data2_raw[19]^data2_raw[28],
    //     data2_raw[4]^data2_raw[11]^data2_raw[20]^data2_raw[27],
    //     data2_raw[5]^data2_raw[10]^data2_raw[21]^data2_raw[26],
    //     data2_raw[6]^data2_raw[9 ]^data2_raw[22]^data2_raw[25],
    //     data2_raw[7]^data2_raw[8 ]^data2_raw[23]^data2_raw[24]
    // };
    wire [HASH_width-1:0] data2_hashed={
        data2_raw[0]^data2_raw[15],
        data2_raw[1]^data2_raw[14],
        data2_raw[2]^data2_raw[13],
        data2_raw[3]^data2_raw[12],
        data2_raw[4]^data2_raw[11],
        data2_raw[5]^data2_raw[10],
        data2_raw[6]^data2_raw[9 ],
        data2_raw[7]^data2_raw[8 ]
    };
    assign data_hashed=data1_hashed&data2_hashed;
endmodule
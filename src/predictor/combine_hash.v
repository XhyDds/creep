//hash函数for双输入
module combine_hash#(
    parameter DATA1_width=32,
    parameter DATA2_width=14,   //暂定相同，为14
    parameter HASH_width=14
)(
    input [DATA1_width-1:0]     data1_raw,
    input [DATA2_width-1:0]     data2_raw,
    output[HASH_width-1:0]      data_hashed
);
    wire [DATA2_width-1:0] data1_hashed;

    assign data_hashed=data1_hashed^data2_raw;

    single_hash#(
        .DATA_width(DATA1_width),
        .HASH_width(DATA2_width)
    ) hash1(
        .data_raw(data1_raw),
        .data_hashed(data1_hashed)
    );
endmodule
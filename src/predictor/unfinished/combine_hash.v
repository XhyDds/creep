//hash函数for双输入
module combine_hash#(
    parameter DATA1_width=32,
    parameter DATA2_width=32,
    parameter HASH_width=32
)(
    input [DATA1_width-1:0]     data1_raw,
    input [DATA2_width-1:0]     data2_raw,
    output[HASH_width-1:0]      data_hashed
);
endmodule
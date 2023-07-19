//hash函数for单输入
module single_hash#(
    parameter DATA_width=29,
    parameter HASH_width=14 //暂定
) (
    input [DATA_width-1:0] data_raw,
    output[HASH_width-1:0] data_hashed
);
    wire [DATA_width-1:0]d=data_raw;
    
    assign data_hashed={d[0]^d[29]^d[28],
                        d[1]^d[27]^d[26],
                        d[2]^d[25],
                        d[3]^d[24],
                        d[4]^d[23],
                        d[5]^d[22],
                        d[6]^d[21],
                        d[7]^d[20],
                        d[8]^d[19],
                        d[9]^d[18],
                        d[10]^d[17],
                        d[11]^d[16],
                        d[12]^d[15],
                        d[13]^d[14]
                        };
endmodule

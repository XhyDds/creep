//hash函数for单输入
module single_hash#(
    parameter DATA_width=26,
    // parameter HASH_width=14 //暂定
    parameter HASH_width=10
) (
    input [DATA_width-1:0] data_raw,
    output[HASH_width-1:0] data_hashed
);
    wire [DATA_width-1:0]d=data_raw;
    
    // 10：
    assign data_hashed={d[0]^d[10]^d[20]^d[23],
                        d[1]^d[11]^d[21]^d[24],
                        d[2]^d[12]^d[22]^d[25],
                        d[3]^d[13],
                        d[4]^d[14],
                        d[5]^d[15],
                        d[6]^d[16],
                        d[7]^d[17],
                        d[8]^d[18],
                        d[9]^d[19]
                        };
endmodule

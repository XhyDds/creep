//hash函数for单输入
module pc_hash#(
    parameter ADDR_WIDTH=30,
    parameter k_width=12
) (
    input [ADDR_WIDTH-1:0] pc,
    output[k_width-1:0] pc_hashed
);
    wire [ADDR_WIDTH-1:0]d=pc;

    // 12:
    assign pc_hashed={  d[11]^d[12],
                        d[10]^d[13],
                        d[9 ]^d[14],
                        d[8 ]^d[15],
                        d[7 ]^d[16],
                        d[6 ]^d[17],
                        d[5 ]^d[18],
                        d[4 ]^d[19],
                        d[3 ]^d[20],
                        d[2 ]^d[21],
                        d[1 ]^d[22]^d[24]^d[25],
                        d[0 ]^d[23]^d[26]^d[27]^d[28]^d[29]
                        };
    // assign pc_hashed=d[k_width-1:0];
endmodule
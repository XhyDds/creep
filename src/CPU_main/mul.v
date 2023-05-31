module mul (
    input [31:0]rj,rk,ctr,
    output reg [31:0]mulresult
);
    wire [3:0]type=ctr[3:0];
    wire [4:0]subtype=ctr[11:7];
    wire [63:0]signedmulresult=$signed(rj)*$signed(rk);
    wire [63:0]unsignedmulresult=$unsigned(rj)*$unsigned(rk);
    always @(*) begin
        mulresult=0;
        if(type==2)
            case (subtype)
                0: mulresult=signedmulresult[31:0];
                1: mulresult=signedmulresult[63:32];
                2: mulresult=unsignedmulresult[63:32];
            endcase
    end
endmodule
module div (
    input [31:0]rj,rk,ctr,
    output reg [31:0]divresult
);
    wire [3:0]type=ctr[3:0];
    wire [4:0]subtype=ctr[11:7];
    always @(*) begin
        divresult=0;
        if(type==2)
            case (subtype)
                0: divresult=$signed(rj)/$signed(rk);
                1: divresult=$signed(rj)%$signed(rk);
                2: divresult=$unsigned(rj)/$unsigned(rk);
                3: divresult=$unsigned(rj)&$unsigned(rk);
            endcase
    end
endmodule
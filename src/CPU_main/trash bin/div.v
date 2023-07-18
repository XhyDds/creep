module div (
    input [31:0]rrj,rrk,ctr,
    output reg [31:0]divresult
);
    wire [3:0]type_=ctr[3:0];
    wire [4:0]subtype=ctr[11:7];
    always @(*) begin
        divresult=0;
        if(type_==2)
            case (subtype)
                0: divresult=$signed(rrj)/$signed(rrk);
                1: divresult=$signed(rrj)%$signed(rrk);
                2: divresult=$unsigned(rrj)/$unsigned(rrk);
                3: divresult=$unsigned(rrj)%$unsigned(rrk);
            endcase
    end
endmodule

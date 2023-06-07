module mul (
    input [31:0]rrj,rrk,ctr,
    input clk,rstn,
    output reg [31:0]mulresult_reg
);
    reg [31:0]mulresult;
    wire [3:0]type1=ctr[3:0];
    wire [4:0]subtype=ctr[11:7];
    wire [63:0]signedmulresult=$signed(rrj)*$signed(rrk);
    wire [63:0]unsignedmulresult=$unsigned(rrj)*$unsigned(rrk);
    always @(*) begin
        mulresult=0;
        if(type1==4)
            case (subtype)
                0: mulresult=signedmulresult[31:0];
                1: mulresult=signedmulresult[63:32];
                2: mulresult=unsignedmulresult[63:32];
            endcase
    end
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            mulresult_reg <= 0;
        end
        else begin
            mulresult_reg <= mulresult;
        end
    end
endmodule

module Random(
    input en, clk, rstn,
    input [31:0] seed1,
    output reg [31:0] randnum
    );
    always @(posedge clk) begin
        if(!rstn)   randnum <= 32'b0;
        else if(en) begin
          if(|randnum)  randnum <= {randnum[30:0], ((((randnum[31] ^ randnum[6]) ^ randnum[4]) ^ randnum[2]) ^ randnum[1]) ^ randnum[0]};
          else          randnum <= {seed1[31:1],1'b1};
        end
    end
endmodule

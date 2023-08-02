module Random(
    input en, clk, rstn,
    output reg [31:0] randnum
    );

    wire [31:0] seed;

    always @(posedge clk) begin
        if(!rstn)   randnum <= 32'b0;
        else if(en) begin
          if(|randnum)  randnum <= {randnum[30:0], ((((randnum[31] ^ randnum[6]) ^ randnum[4]) ^ randnum[2]) ^ randnum[1]) ^ randnum[0]};
          else          randnum <= seed;
        end
    end

    CNT #(
      .WIDTH(32),
      .RST_VLU (32'b0)
    )
    Counter_dut (
      .clk (clk),
      .rstn (rstn),
      .pe (1'b0),
      .ce (1'b1),
      .d (32'b0),
      .q (seed)
    );
  
endmodule

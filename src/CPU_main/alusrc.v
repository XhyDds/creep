module alusrc (
    input [31:0]a,b,
    input alusrc,
    output [31:0]alu
);
    assign alu=alusrc?a:b;
endmodule

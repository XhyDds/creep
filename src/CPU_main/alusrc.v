module alusrc (
    input [31:0]register,other,
    input [1:0]alusrc,
    output reg [31:0]alu
);
    always @(*) begin
        if(alusrc==1) alu=other;
        else if(alusrc==0) alu=register;
    end
endmodule

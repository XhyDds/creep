module alusrc (
    input [31:0]register0,register1,register2,register3,
    input [1:0]alusrc_,
    output reg [31:0]alu
);
    always @(*) begin
        case (alusrc_)
            0: alu=register0;
            1: alu=register1;
            2: alu=register2;
            3: alu=register3;
            default: alu=0;
        endcase
    end
endmodule

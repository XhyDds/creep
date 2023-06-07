module br (
    input [31:0]ctr,pc,imm,
    input zero,
    output reg ifbr,
    output reg [31:0]brresult
);
    wire [3:0]type1;
    assign type1 = ctr[3:0];
    wire [4:0]subtype;
    assign subtype = ctr[11:7];
    always @(*) begin
        ifbr=0;
        brresult=0;
        if(type1==1) begin
            brresult=pc+imm;
            case (subtype)//可以合并
                0: ifbr=1;
                1: ifbr=zero;
                2: ifbr=!zero;
                3: ifbr=zero;
                4: ifbr=!zero;
                5: ifbr=zero;
                6: ifbr=!zero;
            endcase
        end
        else if(type1==8) begin
            brresult=pc+imm;ifbr=1;
        end
    end
endmodule

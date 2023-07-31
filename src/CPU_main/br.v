module br (
    input [31:0]ctr,pc,imm,rrj,alu1,alu2,
    output reg ifbr,
    output reg [31:0]pc_br
);
    wire [3:0]type_ = ctr[3:0];
    wire [4:0]subtype = ctr[11:7];    
    wire [3:0]aluop = ctr[21:18];
    reg [31:0]aluresult;
    wire zero;
    always @(*) begin
        aluresult=0;
        if(type_==1)
        case (aluop)
            5:aluresult=alu1-alu2;
            9:aluresult=$signed(alu1)<$signed(alu2)?1:0;
            10:aluresult=alu1<alu2?1:0;
        endcase
    end
    assign zero=~|aluresult;

    always @(*) begin
        ifbr=0;
        pc_br=pc+imm;
        if(type_==1) begin
            case (subtype)//可以合并
                0: ifbr=1;
                1: ifbr=zero;
                2: ifbr=!zero;
                3: ifbr=!zero;
                4: ifbr=zero;
                5: ifbr=!zero;
                6: ifbr=zero;
            endcase
        end
        else if(type_==8) begin
            ifbr=1;
            if(~|subtype) pc_br=rrj+imm;
        end
    end
    
endmodule

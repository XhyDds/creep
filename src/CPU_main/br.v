module br (
    input [31:0]ctr,pc,imm,rrj,alu1,alu2,
    output reg ifbr,
    output reg [31:0]pc_br
);
    wire [3:0]type_ = ctr[3:0];
    wire [4:0]subtype = ctr[11:7];    
    always @(*) begin
        ifbr=0;
        pc_br=pc+imm;
        if(type_==1) begin
            case (subtype)//可以合并
                0: ifbr=1;
                1: ifbr=~|(alu1^alu2);
                2: ifbr=|(alu1^alu2);
                3: ifbr=$signed(alu1)<$signed(alu2);
                4: ifbr=~($signed(alu1)<$signed(alu2));
                5: ifbr=alu1<alu2;
                6: ifbr=~(alu1<alu2);
            endcase
        end
        else if(type_==8) begin
            ifbr=1;
            if(~|subtype) pc_br=rrj+imm;
        end
    end

endmodule

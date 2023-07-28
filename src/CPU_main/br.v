module br (
    input [31:0]ctr,pc,imm,rrj,
    input zero,stall,
    output reg ifbr,
    output reg [31:0]brresult
);
    wire [3:0]type_ = ctr[3:0];
    wire [4:0]subtype = ctr[11:7];
    reg ifbr_;
    always @(*) begin
        ifbr_=0;
        brresult=0;
        if(type_==1) begin
            brresult=pc+imm;
            case (subtype)//可以合并
                0: ifbr_=1;
                1: ifbr_=zero;
                2: ifbr_=!zero;
                3: ifbr_=!zero;
                4: ifbr_=zero;
                5: ifbr_=!zero;
                6: ifbr_=zero;
            endcase
        end
        else if(type_==8) 
            case (subtype)
                0: begin brresult=rrj+imm;ifbr_=1; end
                1: begin brresult=pc+imm;ifbr_=1; end
            endcase
    end
    always @(*) begin
        ifbr=stall?1'b0:ifbr_;
    end
endmodule

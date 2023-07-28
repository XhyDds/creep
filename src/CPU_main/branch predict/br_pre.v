module br_pre (
    input [31:0]ctr,pc,imm,rrj,npc,
    input zero,
    input [63:0]pre,
    output reg ifbr,flush_pre,
    output reg [31:0]brresult
);
    wire ifnpc_pdc=pre[35];
    wire iftaken_pdc=pre[32];
    wire [3:0]type_ = ctr[3:0];
    wire [4:0]subtype = ctr[11:7];
    reg ifbr_;
    reg [31:0]brresult_;
    always @(*) begin
        ifbr_=0;
        brresult_=0;
        if(type_==1) begin
            brresult_=pc+imm;
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
                0: begin brresult_=rrj+imm;ifbr_=1; end
                1: begin brresult_=pc+imm;ifbr_=1; end
            endcase
    end
    always @(*) begin
        ifbr=(npc!=(ifbr_?brresult_:{pc[31:3]+29'b1,3'b0})|((iftaken_pdc!=ifbr_)&ctr[30]))&ctr[31];
        brresult=ifbr_?brresult_:pc+4;
        flush_pre=~pc[3]&ifnpc_pdc&iftaken_pdc&ctr[30]&ctr[31];
    end
endmodule

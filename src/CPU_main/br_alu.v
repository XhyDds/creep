module br_alu (
    input [31:0]ctr,pc,imm,rrj,alu1,alu2,
<<<<<<< HEAD
    input [63:0]pre,
=======
    input [75:0]pre,
>>>>>>> 8b9b04c (tage)
    output reg flush_pre,ifbr_,
    output reg [31:0]brresult
);
    wire ifnpc_pdc=pre[34];
    wire iftaken_pdc=pre[33];
    wire iftwo=pre[38];
    wire [3:0]type_ = ctr[3:0];
    wire [4:0]subtype = ctr[11:7];

    always @(*) begin
        ifbr_=0;
        brresult=pc+imm;
        if(type_==1) begin
            case (subtype)//可以合并
                0: ifbr_=1;
                // 1: ifbr_=~|(alu1^alu2);
                // 2: ifbr_=|(alu1^alu2);
                1: ifbr_=alu1==alu2;
                2: ifbr_=alu1!=alu2;
                3: ifbr_=$signed(alu1)<$signed(alu2);
                4: ifbr_=~($signed(alu1)<$signed(alu2));
                5: ifbr_=alu1<alu2;
                6: ifbr_=~(alu1<alu2);
            endcase
        end
        else if(type_==8) begin
            ifbr_=1;
            if(~|subtype) brresult=rrj+imm;
        end
    end

    always @(*) begin
        flush_pre=iftwo&ifnpc_pdc&iftaken_pdc&ctr[30]&ctr[31];
    end
endmodule //br_alu

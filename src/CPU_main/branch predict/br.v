module br (
    input [31:0]ctr,pc,imm,rrj,npc,
    input zero,ifnpc_pdc,
    output reg ifbr,flush_pre,
    output reg [31:0]brresult
);
// `ifdef predictor
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
        // 第一 是否跳转
        // 第二 跳转是否等于npc
        // 第三?是否需要只刷一条
        // 第四 
        ifbr=(npc!=brresult)&ctr[31];
        brresult=ifbr_?brresult_:{pc[31:3]+29'b1,3'b0};
        flush_pre=(npc==brresult)&~pc[3]&ifnpc_pdc&ctr[31];
        // flush_pre=0;
        // ifbr=ifbr_;
        // brresult=brresult_;
    end
// `endif

// `ifndef predictor
//     wire [3:0]type_ = ctr[3:0];
//     wire [4:0]subtype = ctr[11:7];
//     always @(*) begin
//         ifbr=0;
//         brresult=0;
//         if(type_==1) begin
//             brresult=pc+imm;
//             case (subtype)//可以合并
//                 0: ifbr=1;
//                 1: ifbr=zero;
//                 2: ifbr=!zero;
//                 3: ifbr=!zero;
//                 4: ifbr=zero;
//                 5: ifbr=!zero;
//                 6: ifbr=zero;
//             endcase
//         end
//         else if(type_==8) 
//             case (subtype)
//                 0: begin brresult=rrj+imm;ifbr=1; end
//                 1: begin brresult=pc+imm;ifbr=1; end
//             endcase
//     end
// `endif
endmodule

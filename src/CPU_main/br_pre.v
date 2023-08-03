module br_pre (
    input [31:0]ctr,pc,brresult,npc,
    input [73:0]pre,
    input ifbr_,
    output reg ifbr,
    output reg [31:0]pc_br,
    output reg [31:0]pc_br_pdc
);
    wire iftaken_pdc=pre[33];
    wire iftwo=pre[38];
    always @(*) begin
        pc_br=ifbr_?brresult:pc+4;
        pc_br_pdc=ifbr_?brresult:(iftwo?pc+8:pc+4);
        ifbr=(npc!=(ifbr_?brresult:(iftwo?pc+8:pc+4))|((iftaken_pdc!=ifbr_)&ctr[30]))&ctr[31];
    end
endmodule

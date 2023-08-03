module br_pre (
    input [31:0]ctr,pc,brresult,npc,
    input [63:0]pre,
    input ifbr_,
    output reg ifbr,
    output reg [31:0]pc_br
);
    wire iftaken_pdc=pre[33];
    always @(*) begin
        pc_br=ifbr_?brresult:pc+4;
        ifbr=(npc!=(ifbr_?brresult:{pc[31:3]+29'b1,3'b0})|((iftaken_pdc!=ifbr_)&ctr[30]))&ctr[31];
    end
endmodule

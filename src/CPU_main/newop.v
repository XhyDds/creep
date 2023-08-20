module newop (
    input      clk,
    input      rstn,
    input      [31:0]rrd,rrj,ctr,
    input      [15:0]excp_arg,
    output     [31:0]result
);
    reg [5:0] num;wire [31:0]omask,mask,rrj_shift;
    wire [5:0] imma,immb,immc;
    
    rotl rotl_mask(.src(omask),.shift(immb[4:0]+1'b1),.result(mask));
    rotl rotl_rj(.src(rrj),.shift(imma[4:0]),.result(rrj_shift));
    assign result=rrj_shift&mask;
    assign immc={1'b0,excp_arg[4:0]};
    assign immb={1'b0,excp_arg[9:5]};
    assign imma={1'b0,excp_arg[14:10]};
    always@(*)
    begin
    if(immb>immc)
        num=immc+(6'd32-immb);
    else if(immb==immc)
        num=6'd0;
    else
        num=immc-immb;
    end
    assign omask=~((~0)<<num[4:0]);
    
endmodule //newop


module rotl(
    input[31:0] src ,
    input [4:0] shift,
    output [31:0] result
);

assign result=(src<<shift)|(src>>(6'd32-shift));

endmodule
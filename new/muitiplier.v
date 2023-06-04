module muitiplier(
    input clk,rstn,
    input pipeline_muitiplier_flush,
    input pipeline_muitiplier_stall,
    input [1:0]pipeline_muitiplier_mode,
    input [31:0] pipeline_muitiplier_din1,
    input [31:0] pipeline_muitiplier_din2,
    output [31:0] muitiplier_pipeline_dout
);
    localparam MULW=0,MULHW=1,MULHWU=2;
    wire stall,flush;wire [1:0] mode;wire [31:0] din1,din2;reg [31:0] dout;
    reg [63:0]result;reg [31:0] ac,ad,bc,bd,a_b,c_d,abs,cds;reg [1:0] mode_reg;
    assign stall=pipeline_muitiplier_stall,flush=pipeline_muitiplier_flush;
    assign mode=pipeline_muitiplier_mode,din1=pipeline_muitiplier_din1;
    assign din2=pipeline_muitiplier_din2,muitiplier_pipeline_dout=dout;
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn || flush)
        begin
        ac<=0;ad<=0;bc<=0;bd<=0;a_b<=0;c_d<=0;mode_reg<=0;
        end
    else if(!stall)
        begin
        ac<=din1[31:16]*din2[31:16];
        bd<=din1[15:0]*din2[15:0];
        ad<=din1[31:16]*din2[15:0];
        bc<=din1[15:0]*din2[31:16];
        a_b<=din1;
        c_d<=din2;
        mode_reg<=mode;
        end
    end
    always@(*)
    begin
    dout=0;
    //result={ac-abs-cds,32'b0}+{15'b0,{1'b0,ad}+{1'b0,bc},16'b0}+{32'b0,bd};
    //result={ac,32'b0}+{abs,32'b0}+{cds,32'b0}+{15'b0,{1'b0,ad}+{1'b0,bc},16'b0}+{32'b0,bd};
    result={ac,32'b0}+{15'b0,{1'b0,ad}+{1'b0,bc},16'b0}+{32'b0,bd};
    if(a_b[31]&&mode_reg==MULHW)
        abs=a_b;
    else
        abs=0;
    if(c_d[31]&&mode_reg==MULHW)
        cds=c_d;
    else
        cds=0;
    if(mode_reg==MULW)
        dout=result[31:0];
    else
        dout=result[63:32]-abs-cds;
    end
    
    
endmodule
`include "dispatcher.v"
`include "decoder.v"
`include "fetch_buffer.v"
`include "register_file.v"
`include "alu.v"

module cpu (
    input clk,rstn
);
    reg [31:0]npc;
    wire [1:0]pcsrc_exe1_wb;
    wire ifbr;
    reg [31:0]pc,ctr_id_reg_0,ctr_id_reg_1,ctr_reg_exe0_0,ctr_reg_exe0_1,ctr_exe0_exe1_0,ctr_exe0_exe1_1,ctr_exe1_wb_0,ctr_exe1_wb_1,pc_id_reg_0,pc_id_reg_1,pc_reg_exe0_0,pc_reg_exe0_1,result_exe0_exe1_0,result_exe0_exe1_1,result_exe1_wb_0,result_exe1_wb_1,wb_data,rrk_reg_exe0_0,rrj_reg_exe0_0,rrk_reg_exe0_1,rrj_reg_exe0_1;
    wire [31:0]rrk_reg_0,rrj_reg_0,rrk_reg_1,rrj_reg_1;
    reg [4:0]rk_id_reg_0,rj_id_reg_0,rk_id_reg_1,rj_id_reg_1;
    wire [4:0]rk_id_0,rj_id_0,rk_id_1,rj_id_1;
    
    always @(posedge clk,negedge rstn) begin
        if(!rstn) pc<=0;
        else pc<=npc;
    end

    always @(*) begin
        if(ifbr==1) npc=result_exe0_exe1_1;
        else npc=wb_data;
    end

    always @(posedge clk,negedge rstn) begin
        
    end

    dispatcher dispatcher (
        
    );

    decoder decoder1(

    );

    decoder decoder2(

    );

    fetch_buffer fetch_buffer(

    );

    register_file register_file(

    );

    alu alu1(
        
    );

    alu alu2(

    );



    // //IM
    // dist_mem_gen_0(.a(addr),.d(din),.dpra((pc-'h00003000)>>2),.clk(clk_ld),.we(we_im),.spo(dout_im),.dpo(irf));
    
    // //DM
    // wire [31:0]dpo1,spo1;
    // dist_mem_gen_1(.a(we_dm?addr:y>>2),.d(we_dm?din:mdw),.dpra(we_dm?y>>2:addr),.clk(clk_ld),.we(we_dm|ctrm[3]),.spo(spo1),.dpo(dpo1));
    // assign dout_dm=we_dm?spo1:dpo1;
    // assign readdata=ctrm[9]?(we_dm?dpo1:spo1):0;


endmodule
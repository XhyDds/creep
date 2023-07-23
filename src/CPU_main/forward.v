module forward (
    input[31:0]result_exe0_exe1_0,result_exe0_exe1_1,
    result_exe1_wb_0,result_exe1_wb_1,
    rrj_reg_exe0_0,rrj_reg_exe0_1,
    rrk_reg_exe0_0,rrk_reg_exe0_1,
    ctr_exe1_wb_0,ctr_exe1_wb_1,
    ctr_exe0_exe1_0,ctr_exe0_exe1_1,
    rrd_reg_exe0_0,rrd_reg_exe0_1,

    input[4:0]rd_exe0_exe1_0,rd_exe0_exe1_1,
    rd_exe1_wb_0,rd_exe1_wb_1,
    input [4:0]rj0,rj1,rk0,rk1,rd0,rd1,
    output reg [31:0]rrj0,rrj1,rrk0,rrk1,rrd0,rrd1
);
    wire ifw0_exe1_wb=ctr_exe1_wb_0[6];
    wire ifw1_exe1_wb=ctr_exe1_wb_1[6];
    wire ifw0_exe0_exe1=ctr_exe0_exe1_0[6];
    wire ifw1_exe0_exe1=ctr_exe0_exe1_1[6];
    always @(*) begin
        rrj0=rrj_reg_exe0_0;
        rrj1=rrj_reg_exe0_1;
        rrk0=rrk_reg_exe0_0;
        rrk1=rrk_reg_exe0_1;
        rrd0=rrd_reg_exe0_0;
        rrd1=rrd_reg_exe0_1;

        if(|rj0) if(rd_exe0_exe1_0==rj0&ifw0_exe0_exe1) rrj0=result_exe0_exe1_0;
        else if((rd_exe0_exe1_1==rj0)&ifw1_exe0_exe1) rrj0=result_exe0_exe1_1;
        else if(rd_exe1_wb_0==rj0&ifw0_exe1_wb) rrj0=result_exe1_wb_0;
        else if(rd_exe1_wb_1==rj0&ifw1_exe1_wb) rrj0=result_exe1_wb_1;

        if(|rk0) if(rd_exe0_exe1_0==rk0&ifw0_exe0_exe1) rrk0=result_exe0_exe1_0;
        else if(rd_exe0_exe1_1==rk0&ifw1_exe0_exe1) rrk0=result_exe0_exe1_1;
        else if(rd_exe1_wb_0==rk0&ifw0_exe1_wb) rrk0=result_exe1_wb_0;
        else if(rd_exe1_wb_1==rk0&ifw1_exe1_wb) rrk0=result_exe1_wb_1;

        if(|rj1) if(rd_exe0_exe1_0==rj1&ifw0_exe0_exe1) rrj1=result_exe0_exe1_0;
        else if(rd_exe0_exe1_1==rj1&ifw1_exe0_exe1) rrj1=result_exe0_exe1_1;
        else if(rd_exe1_wb_0==rj1&ifw0_exe1_wb) rrj1=result_exe1_wb_0;
        else if(rd_exe1_wb_1==rj1&ifw1_exe1_wb) rrj1=result_exe1_wb_1;

        if(|rk1) if(rd_exe0_exe1_0==rk1&ifw0_exe0_exe1) rrk1=result_exe0_exe1_0;
        else if(rd_exe0_exe1_1==rk1&ifw1_exe0_exe1) rrk1=result_exe0_exe1_1;
        else if(rd_exe1_wb_0==rk1&ifw0_exe1_wb) rrk1=result_exe1_wb_0;
        else if(rd_exe1_wb_1==rk1&ifw1_exe1_wb) rrk1=result_exe1_wb_1;

        if(|rd0) if(rd_exe0_exe1_0==rd0&ifw0_exe0_exe1) rrd0=result_exe0_exe1_0;
        else if(rd_exe0_exe1_1==rd0&ifw1_exe0_exe1) rrd0=result_exe0_exe1_1;
        else if(rd_exe1_wb_0==rd0&ifw0_exe1_wb) rrd0=result_exe1_wb_0;
        else if(rd_exe1_wb_1==rd0&ifw1_exe1_wb) rrd0=result_exe1_wb_1;

        if(|rd1) if(rd_exe0_exe1_0==rd1&ifw0_exe0_exe1) rrd1=result_exe0_exe1_0;
        else if(rd_exe0_exe1_1==rd1&ifw1_exe0_exe1) rrd1=result_exe0_exe1_1;
        else if(rd_exe1_wb_0==rd1&ifw0_exe1_wb) rrd1=result_exe1_wb_0;
        else if(rd_exe1_wb_1==rd1&ifw1_exe1_wb) rrd1=result_exe1_wb_1;
        
        // if(rx==rx_exe0_exe1&we_exe0_exe1&rx!=0) alu=rrd_exe0_exe1;
        // else if(rx==rx_exe1_wb&we_exe1_wb&rx!=0) alu=rrd_exe1_wb;
        // else alu=register;
    end
endmodule //forward

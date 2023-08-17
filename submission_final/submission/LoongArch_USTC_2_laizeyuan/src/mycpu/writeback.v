module writeback (
    input [31:0]result_exe1_wb_0,result_exe1_wb_1,ctr_exe1_wb_0,ctr_exe1_wb_1,
    input [4:0]rd_exe1_wb_0,rd_exe1_wb_1,
    output [31:0]wb_data0,wb_data1,
    output [4:0]wb_addr0,wb_addr1,
    output ifwb0,ifwb1
);
    // assign wb_addr0=ctr_exe1_wb_0[6]?rd_exe1_wb_0:0;
    // assign wb_data0=ctr_exe1_wb_0[6]?result_exe1_wb_0:0;
    // assign wb_addr1=ctr_exe1_wb_1[6]?rd_exe1_wb_1:0;
    // assign wb_data1=ctr_exe1_wb_1[6]?result_exe1_wb_1:0;
    assign wb_addr0=rd_exe1_wb_0;
    assign wb_data0=result_exe1_wb_0;
    assign wb_addr1=rd_exe1_wb_1;
    assign wb_data1=result_exe1_wb_1;
    assign ifwb0=ctr_exe1_wb_0[6];
    assign ifwb1=ctr_exe1_wb_1[6];
    // wire regwrite0=ctr_exe1_wb_0[6];
    // wire regwrite1=ctr_exe1_wb_1[6];
    // always @(*) begin
    //     wb_data0=0;
    //     wb_addr0=0;
    //     wb_data1=0;
    //     wb_addr1=0;
    //     if(regwrite0) begin
    //         wb_addr0=rd_exe1_wb_0;
    //         wb_data0=result_exe1_wb_0;
    //     end
    //     if(regwrite1) begin
    //         wb_addr1=rd_exe1_wb_1;
    //         wb_data1=result_exe1_wb_1;
    //     end
    // end
endmodule

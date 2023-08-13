module writeback (
    input [31:0]result0,result1,ctr0,ctr1,
    input [4:0]rd0,rd1,
    output [31:0]wb_data0,wb_data1,
    output [4:0]wb_addr0,wb_addr1,
    output ifwb0,ifwb1
);
    // assign wb_addr0=ctr0[6]?rd0:0;
    // assign wb_data0=ctr0[6]?result0:0;
    // assign wb_addr1=ctr1[6]?rd1:0;
    // assign wb_data1=ctr1[6]?result1:0;
    assign wb_addr0=rd0;
    assign wb_data0=result0;
    assign wb_addr1=rd1;
    assign wb_data1=result1;
    assign ifwb0=ctr0[6];
    assign ifwb1=ctr1[6];
    // wire regwrite0=ctr0[6];
    // wire regwrite1=ctr1[6];
    // always @(*) begin
    //     wb_data0=0;
    //     wb_addr0=0;
    //     wb_data1=0;
    //     wb_addr1=0;
    //     if(regwrite0) begin
    //         wb_addr0=rd0;
    //         wb_data0=result0;
    //     end
    //     if(regwrite1) begin
    //         wb_addr1=rd1;
    //         wb_data1=result1;
    //     end
    // end
endmodule

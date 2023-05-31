module register_file (
    input clk,ifwb0,ifwb1,
    input [31:0]wb_data0,wb_addr0,wb_data1,wb_addr1,
    input [4:0]rk0,rk1,rj0,rj1,rd0,rd1,
    output reg [31:0]rk00,rk11,rj00,rj11,rd00,rd11
);
    reg [31:0]rf[0:31];
    always @(posedge clk) begin:RF
    //能否保证wb_addr0!=wb_addr1？是否能通过综合？
        rk00=rf[rk0];
        rk11=rf[rk1];
        rj00=rf[rj0];
        rj11=rf[rj1];
        rd00=rf[rd0];
        rd11=rf[rd1];
        if(ifwb0) 
        begin 
            rf[wb_addr0]<=wb_data0;
            if(rk0==wb_addr0) rk00=wb_data0;
            if(rj0==wb_addr0) rj00=wb_data0;
            if(rd0==wb_addr0) rd00=wb_data0;
            if(rk1==wb_addr0) rk11=wb_data1;
            if(rj1==wb_addr0) rj11=wb_data0;
            if(rd1==wb_addr0) rd11=wb_data0;
        end
        if(ifwb1) 
        // if(wb_addr0!=wb_addr1) 
        begin 
            rf[wb_addr1]<=wb_data1;
            if(rk0==wb_addr1) rk00=wb_data0;
            if(rj0==wb_addr1) rj00=wb_data0;
            if(rd0==wb_addr1) rd00=wb_data0;
            if(rk1==wb_addr1) rk11=wb_data1;
            if(rj1==wb_addr1) rj11=wb_data0;
            if(rd1==wb_addr1) rd11=wb_data0;
        end
    end
endmodule
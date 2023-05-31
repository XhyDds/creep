module register_file (
    input clk,ifwb0,ifwb1,
    input [31:0]wb_data0,wb_addr0,wb_data1,wb_addr1,
    input [4:0]rk00,rk11,rj00,rj11,rd00,rd11,
    output reg [31:0]rrk0,rrk1,rrj0,rrj1,rrd0,rrd1
);
    reg [31:0]rf[0:31];
    always @(posedge clk) begin:RF
    //能否保证wb_addr0!=wb_addr1？是否能通过综合？
        rrk0=rf[rk00];
        rrk1=rf[rk11];
        rrj0=rf[rj00];
        rrj1=rf[rj11];
        rrd0=rf[rd00];
        rrd1=rf[rd11];
        if(ifwb0) 
            begin 
                rf[wb_addr0]<=wb_data0;
                if(rk00==wb_addr0) rrk0=wb_data0;
                if(rj00==wb_addr0) rrj0=wb_data0;
                if(rd00==wb_addr0) rrd0=wb_data0;
                if(rk11==wb_addr0) rrk1=wb_data1;
                if(rj11==wb_addr0) rrj1=wb_data0;
                if(rd11==wb_addr0) rrd1=wb_data0;
            end
        if(ifwb1) 
        // if(wb_addr0!=wb_addr1) 
            begin 
                rf[wb_addr1]<=wb_data1;
                if(rk00==wb_addr1) rrk0=wb_data0;
                if(rj00==wb_addr1) rrj0=wb_data0;
                if(rd00==wb_addr1) rrd0=wb_data0;
                if(rk11==wb_addr1) rrk1=wb_data1;
                if(rj11==wb_addr1) rrj1=wb_data0;
                if(rd11==wb_addr1) rrd1=wb_data0;
            end
    end
endmodule
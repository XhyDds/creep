module register_file (
    input clk,rstn,ifwb0,ifwb1,
    input [31:0]wb_data0,wb_data1,
    input [4:0]rk00,rk11,rj00,rj11,rd00,rd11,wb_addr0,wb_addr1,
    output reg [31:0]rrk0,rrk1,rrj0,rrj1,rrd0,rrd1
);
    reg [31:0]rf[0:31];
    always @(posedge clk,negedge rstn) begin:RF
    //能否保证wb_addr0!=wb_addr1？是否能通过综合？
        integer i;
        if (!rstn) begin
            for (i=0;i<32;i=i+1) begin
                rf[i]<=0;
            end
            rrk0<=0;rrk1<=0;rrj0<=0;rrj1<=0;rrd0<=0;rrd1<=0;
        end
        else begin
            if(ifwb0) rf[wb_addr0]<=wb_data0;
            if(ifwb1) begin
                if(wb_addr0!=wb_addr1) rf[wb_addr1]<=wb_data1;
            end
        end
    end
    always @(*) begin
        rrk0=rk00?((ifwb1&rk00==wb_addr1)?wb_data1:(rk00==wb_addr0)?wb_data0:rf[rk00]):0;
        rrk1=rk11?((ifwb1&rj00==wb_addr1)?wb_data1:(rj00==wb_addr0)?wb_data0:rf[rk11]):0;
        rrj0=rj00?((ifwb1&rd00==wb_addr1)?wb_data1:(rd00==wb_addr0)?wb_data0:rf[rj00]):0;
        rrj1=rj11?((ifwb1&rk11==wb_addr1)?wb_data1:(rk11==wb_addr0)?wb_data0:rf[rj11]):0;
        rrd0=rd00?((ifwb1&rj11==wb_addr1)?wb_data1:(rj11==wb_addr0)?wb_data0:rf[rd00]):0;
        rrd1=rd11?((ifwb1&rd11==wb_addr1)?wb_data1:(rd11==wb_addr0)?wb_data0:rf[rd11]):0;
        // if(ifwb0) 
        //     begin 
        //         if(rk00&rk00==wb_addr0) rrk0=wb_data0;
        //         if(rj00&rj00==wb_addr0) rrj0=wb_data0;
        //         if(rd00&rd00==wb_addr0) rrd0=wb_data0;
        //         if(rk11&rk11==wb_addr0) rrk1=wb_data0;
        //         if(rj11&rj11==wb_addr0) rrj1=wb_data0;
        //         if(rd11&rd11==wb_addr0) rrd1=wb_data0;
        //     end
        // if(ifwb1) 
        //     begin 
        //         if(rk00&rk00==wb_addr1) rrk0=wb_data1;
        //         if(rj00&rj00==wb_addr1) rrj0=wb_data1;
        //         if(rd00&rd00==wb_addr1) rrd0=wb_data1;
        //         if(rk11&rk11==wb_addr1) rrk1=wb_data1;
        //         if(rj11&rj11==wb_addr1) rrj1=wb_data1;
        //         if(rd11&rd11==wb_addr1) rrd1=wb_data1;
        //     end
    end
endmodule
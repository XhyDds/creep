module register_file (
    input clk,rstn,ifwb0,ifwb1,stall0,stall1,
    input [31:0]wb_data0,wb_data1,
    input [4:0]rk0,rk1,rj0,rj1,rd0,rd1,wb_addr0,wb_addr1,
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
        end
        else begin
            if(ifwb0&!stall0&|wb_addr0) rf[wb_addr0]<=wb_data0;
            if(ifwb1&!stall1&|wb_addr1) begin//禁止写r0
                if(wb_addr0!=wb_addr1) rf[wb_addr1]<=wb_data1;
            end
        end
    end
    always @(*) begin//r0读出为0
        rrk0=|rk0?((ifwb1&rk0==wb_addr1)?wb_data1:(ifwb0&rk0==wb_addr0)?wb_data0:rf[rk0]):0;
        rrk1=|rk1?((ifwb1&rj0==wb_addr1)?wb_data1:(ifwb0&rj0==wb_addr0)?wb_data0:rf[rk1]):0;
        rrj0=|rj0?((ifwb1&rd0==wb_addr1)?wb_data1:(ifwb0&rd0==wb_addr0)?wb_data0:rf[rj0]):0;
        rrj1=|rj1?((ifwb1&rk1==wb_addr1)?wb_data1:(ifwb0&rk1==wb_addr0)?wb_data0:rf[rj1]):0;
        rrd0=|rd0?((ifwb1&rj1==wb_addr1)?wb_data1:(ifwb0&rj1==wb_addr0)?wb_data0:rf[rd0]):0;
        rrd1=|rd1?((ifwb1&rd1==wb_addr1)?wb_data1:(ifwb0&rd1==wb_addr0)?wb_data0:rf[rd1]):0;
        // if(ifwb0) 
        //     begin 
        //         if(rk0&rk0==wb_addr0) rrk0=wb_data0;
        //         if(rj0&rj0==wb_addr0) rrj0=wb_data0;
        //         if(rd0&rd0==wb_addr0) rrd0=wb_data0;
        //         if(rk1&rk1==wb_addr0) rrk1=wb_data0;
        //         if(rj1&rj1==wb_addr0) rrj1=wb_data0;
        //         if(rd1&rd1==wb_addr0) rrd1=wb_data0;
        //     end
        // if(ifwb1) 
        //     begin 
        //         if(rk0&rk0==wb_addr1) rrk0=wb_data1;
        //         if(rj0&rj0==wb_addr1) rrj0=wb_data1;
        //         if(rd0&rd0==wb_addr1) rrd0=wb_data1;
        //         if(rk1&rk1==wb_addr1) rrk1=wb_data1;
        //         if(rj1&rj1==wb_addr1) rrj1=wb_data1;
        //         if(rd1&rd1==wb_addr1) rrd1=wb_data1;
        //     end
    end
endmodule

module register_file (
    input clk,rstn,ifwb0,ifwb1,stall0,stall1,infor_flag,
    input [31:0]wb_data0,wb_data1,
    input [4:0]rk0,rk1,rj0,rj1,rd0,rd1,wb_addr0,wb_addr1,reg_num,
    output reg [31:0]rrk0,rrk1,rrj0,rrj1,rrd0,rrd1,
    output [31:0] rf_rdata,reg0,reg1,reg2,reg3,reg4,reg5,reg6,reg7,reg8,reg9,reg10,reg11,reg12,reg13,reg14,reg15,reg16,reg17,reg18,reg19,reg20,reg21,reg22,reg23,reg24,reg25,reg26,reg27,reg28,reg29,reg30,reg31
);
    reg [31:0]rf[0:31];

    always @(posedge clk)begin:RF
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
                if(wb_addr0==wb_addr1 & (ifwb0&!stall0&|wb_addr0));
                else rf[wb_addr1]<=wb_data1;
            end
        end
    end

    always @(*) begin//r0读出为0
        rrk0=|rk0?((ifwb1&rk0==wb_addr1)?wb_data1:(ifwb0&rk0==wb_addr0)?wb_data0:rf[rk0]):0;
        rrk1=|rk1?((ifwb1&rk1==wb_addr1)?wb_data1:(ifwb0&rk1==wb_addr0)?wb_data0:rf[rk1]):0;

        rrj0=|rj0?((ifwb1&rj0==wb_addr1)?wb_data1:(ifwb0&rj0==wb_addr0)?wb_data0:rf[rj0]):0;
        rrj1=|rj1?((ifwb1&rj1==wb_addr1)?wb_data1:(ifwb0&rj1==wb_addr0)?wb_data0:rf[rj1]):0;

        rrd0=|rd0?((ifwb1&rd0==wb_addr1)?wb_data1:(ifwb0&rd0==wb_addr0)?wb_data0:rf[rd0]):0;
        rrd1=|rd1?((ifwb1&rd1==wb_addr1)?wb_data1:(ifwb0&rd1==wb_addr0)?wb_data0:rf[rd1]):0;
    end

    assign rf_rdata=rf[reg_num];
    assign reg0=rf[0];
    assign reg1=rf[1];
    assign reg2=rf[2];
    assign reg3=rf[3];
    assign reg4=rf[4];
    assign reg5=rf[5];
    assign reg6=rf[6];
    assign reg7=rf[7];
    assign reg8=rf[8];
    assign reg9=rf[9];
    assign reg10=rf[10];
    assign reg11=rf[11];
    assign reg12=rf[12];
    assign reg13=rf[13];
    assign reg14=rf[14];
    assign reg15=rf[15];
    assign reg16=rf[16];
    assign reg17=rf[17];
    assign reg18=rf[18];
    assign reg19=rf[19];
    assign reg20=rf[20];
    assign reg21=rf[21];
    assign reg22=rf[22];
    assign reg23=rf[23];
    assign reg24=rf[24];
    assign reg25=rf[25];
    assign reg26=rf[26];
    assign reg27=rf[27];
    assign reg28=rf[28];
    assign reg29=rf[29];
    assign reg30=rf[30];
    assign reg31=rf[31];
endmodule

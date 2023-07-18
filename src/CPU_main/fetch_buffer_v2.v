module fetch_buffer_v2 (
    input [31:0]pc,
    input clk,rstn,flush,stall,
    input if0,if1,icache_valid,
    input [63:0]irin,
    input flag,
    //flag==1表示2个有效，flag==0表示1个有效
    //[0:31]为pc小，0-后一条指令（[63:32]）无效 1-有效
    output [31:0]ir0,ir1,pc0,pc1,
    output stall_fetch_buffer,valid0,valid1
);
    reg [31:0]buffer[0:15];//15为0，14最新，0最旧，是否会溢出？
    reg [31:0]bufferpc[0:15];
    reg valid[0:15];
    reg [3:0]pointer;//0~15
    wire [31:0]ir[0:1];
    assign ir[0]=irin[31:0];
    assign ir[1]=irin[63:32];
    assign ir0=buffer[pointer==15?pointer:pointer+1];
    assign ir1=buffer[pointer];
    assign pc0=bufferpc[pointer==15?pointer:pointer+1];
    assign pc1=bufferpc[pointer];
    assign stall_fetch_buffer=(pointer<=1);
    assign valid0=valid[pointer==15?pointer:pointer+1];
    assign valid1=valid[pointer];
    wire [3:0]flag4p=icache_valid?(flag?4'b0010:4'b0001):4'b0000;
    wire [3:0]flag4=icache_valid?(flag?4'b0001:4'b0000):4'b1111;
    wire [3:0]flag4m=icache_valid?(flag?4'b0000:4'b1111):4'b1110;

    always @(posedge clk,negedge rstn) begin:fetch_buffer
        integer i;
        if(!rstn|flush) 
            begin
                pointer<=15;
                for (i=0;i<16;i=i+1) begin
                        buffer[i]<=0;
                        bufferpc[i]<=0;
                        valid[i]<=0;
                end
            end
        else if(!stall)
            begin
                if(icache_valid)
                    if (flag) 
                        begin
                            buffer[1]<=buffer[3];
                            bufferpc[1]<=bufferpc[3];
                            valid[1]<=valid[3];
                            buffer[2]<=buffer[4];
                            bufferpc[2]<=bufferpc[4];
                            valid[2]<=valid[4];
                            buffer[3]<=buffer[5];
                            bufferpc[3]<=bufferpc[5];
                            valid[3]<=valid[5];
                            buffer[4]<=buffer[6];
                            bufferpc[4]<=bufferpc[6];
                            valid[4]<=valid[6];
                            buffer[5]<=buffer[7];
                            bufferpc[5]<=bufferpc[7];
                            valid[5]<=valid[7];
                            buffer[6]<=buffer[8];
                            bufferpc[6]<=bufferpc[8];
                            valid[6]<=valid[8];
                            buffer[7]<=buffer[9];
                            bufferpc[7]<=bufferpc[9];
                            valid[7]<=valid[9];
                            buffer[8]<=buffer[10];
                            bufferpc[8]<=bufferpc[10];
                            valid[8]<=valid[10];
                            buffer[9]<=buffer[11];
                            bufferpc[9]<=bufferpc[11];
                            valid[9]<=valid[11];
                            buffer[10]<=buffer[12];
                            bufferpc[10]<=bufferpc[12];
                            valid[10]<=valid[12];
                            buffer[11]<=buffer[13];
                            bufferpc[11]<=bufferpc[13];
                            valid[11]<=valid[13];
                            buffer[12]<=buffer[14];
                            bufferpc[12]<=bufferpc[14];
                            valid[12]<=valid[14];
                            buffer[13]<=ir[0];
                            bufferpc[13]<=pc;
                            valid[13]<=1;
                            buffer[14]<=ir[1];
                            bufferpc[14]<=pc+4;
                            valid[14]<=1;
                        end
                    else 
                        begin
                            buffer[1]<=buffer[2];
                            bufferpc[1]<=bufferpc[2];
                            valid[1]<=valid[2];
                            buffer[2]<=buffer[3];
                            bufferpc[2]<=bufferpc[3];
                            valid[2]<=valid[3];
                            buffer[3]<=buffer[4];
                            bufferpc[3]<=bufferpc[4];
                            valid[3]<=valid[4];
                            buffer[4]<=buffer[5];
                            bufferpc[4]<=bufferpc[5];
                            valid[4]<=valid[5];
                            buffer[5]<=buffer[6];
                            bufferpc[5]<=bufferpc[6];
                            valid[5]<=valid[6];
                            buffer[6]<=buffer[7];
                            bufferpc[6]<=bufferpc[7];
                            valid[6]<=valid[7];
                            buffer[7]<=buffer[8];
                            bufferpc[7]<=bufferpc[8];
                            valid[7]<=valid[8];
                            buffer[8]<=buffer[9];
                            bufferpc[8]<=bufferpc[9];
                            valid[8]<=valid[9];
                            buffer[9]<=buffer[10];
                            bufferpc[9]<=bufferpc[10];
                            valid[9]<=valid[10];
                            buffer[10]<=buffer[11];
                            bufferpc[10]<=bufferpc[11];
                            valid[10]<=valid[11];
                            buffer[11]<=buffer[12];
                            bufferpc[11]<=bufferpc[12];
                            valid[11]<=valid[12];
                            buffer[12]<=buffer[13];
                            bufferpc[12]<=bufferpc[13];
                            valid[12]<=valid[13];
                            buffer[14]<=ir[0];
                            bufferpc[14]<=pc;
                            valid[14]<=1;
                        end
                if(if1)
                    if(if0) pointer<=(pointer==14|pointer==15)?(15-flag4p):(pointer-flag4m);//取两个
                    else pointer<=(pointer==15)?(15-flag4p):(pointer-flag4);//取一个
                else
                    pointer<=pointer-flag4p;
                //有下面走，上面不走的情况吗？
            end
    end
endmodule

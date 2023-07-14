module fetch_buffer_v2 (
    input [31:0]pc,
    input clk,rstn,flush,stall,
    input if0,if1,icache_valid,
    input [63:0]irin,
    input flag,
    //flag==1表示2个有效，flag==0表示1个有效
    //[0:31]为pc小，0-后一条指令（[63:32]）无效 1-有效
    output [31:0]ir0,ir1,pc0,pc1,
    output stall_fetch_buffer
);
    reg [31:0]buffer[0:15];//15为0，14最新，0最旧，是否会溢出？
    reg [31:0]bufferpc[0:15];
    reg [3:0]pointer;//0~15
    wire [31:0]ir[0:1];
    assign ir[0]=irin[31:0];
    assign ir[1]=irin[63:32];
    assign ir0=buffer[pointer==15?pointer:pointer+1];
    assign ir1=buffer[pointer];
    assign pc0=bufferpc[pointer==15?pointer:pointer+1];
    assign pc1=bufferpc[pointer];
    assign stall_fetch_buffer=(pointer<=1);
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
                end
            end
        else if(!stall)
            begin
                if(icache_valid)
                    if (flag) 
                        begin
                            buffer[1]<=buffer[3];
                            bufferpc[1]<=bufferpc[3];
                            buffer[2]<=buffer[4];
                            bufferpc[2]<=bufferpc[4];
                            buffer[3]<=buffer[3+2];
                            bufferpc[3]<=bufferpc[3+2];
                            buffer[4]<=buffer[4+2];
                            bufferpc[4]<=bufferpc[4+2];
                            buffer[5]<=buffer[5+2];
                            bufferpc[5]<=bufferpc[5+2];
                            buffer[6]<=buffer[6+2];
                            bufferpc[6]<=bufferpc[6+2];
                            buffer[7]<=buffer[7+2];
                            bufferpc[7]<=bufferpc[7+2];
                            buffer[8]<=buffer[8+2];
                            bufferpc[8]<=bufferpc[8+2];
                            buffer[9]<=buffer[9+2];
                            bufferpc[9]<=bufferpc[9+2];
                            buffer[10]<=buffer[10+2];
                            bufferpc[10]<=bufferpc[10+2];
                            buffer[11]<=buffer[11+2];
                            bufferpc[11]<=bufferpc[11+2];
                            buffer[12]<=buffer[12+2];
                            bufferpc[12]<=bufferpc[12+2];
                            buffer[13]<=ir[0];
                            bufferpc[13]<=pc;
                            buffer[14]<=ir[1];
                            bufferpc[14]<=pc+4;
                        end
                    else 
                        begin
                            buffer[1]<=buffer[3];
                            bufferpc[1]<=bufferpc[3];
                            buffer[2]<=buffer[4];
                            bufferpc[2]<=bufferpc[4];
                            buffer[3]<=buffer[3+1];
                            bufferpc[3]<=bufferpc[3+1];
                            buffer[4]<=buffer[4+1];
                            bufferpc[4]<=bufferpc[4+1];
                            buffer[5]<=buffer[5+1];
                            bufferpc[5]<=bufferpc[5+1];
                            buffer[6]<=buffer[6+1];
                            bufferpc[6]<=bufferpc[6+1];
                            buffer[7]<=buffer[7+1];
                            bufferpc[7]<=bufferpc[7+1];
                            buffer[8]<=buffer[8+1];
                            bufferpc[8]<=bufferpc[8+1];
                            buffer[9]<=buffer[9+1];
                            bufferpc[9]<=bufferpc[9+1];
                            buffer[10]<=buffer[10+1];
                            bufferpc[10]<=bufferpc[10+1];
                            buffer[11]<=buffer[11+1];
                            bufferpc[11]<=bufferpc[11+1];
                            buffer[12]<=buffer[12+1];
                            bufferpc[12]<=bufferpc[12+1];
                            buffer[14]<=ir[0];
                            bufferpc[14]<=pc;
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

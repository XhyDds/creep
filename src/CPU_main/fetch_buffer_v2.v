module fetch_buffer_v2 (
    input [31:0]pc,
    input clk,rstn,flush,stall,
    input if0,if1,icache_valid,
    input [63:0]irin,
    input flag,//flag==1表示2个有效，flag==0表示1个有效
    output [31:0]ir0,ir1,pc0,pc1,
    output stall_fetch_buffer
);
    reg [31:0]buffer[0:15];//15为0，14最新，0最旧，是否会溢出？
    reg [31:0]bufferpc[0:15];
    reg [3:0]pointer;//0~15
    // reg icache_valid=1;
    wire [31:0]ir[0:1];
    assign ir[1]=irin[31:0];
    assign ir[0]=irin[63:32];
    assign ir0=buffer[pointer];
    assign ir1=buffer[pointer==15?pointer:pointer+1];
    assign pc0=bufferpc[pointer];
    assign pc1=bufferpc[pointer==15?pointer:pointer+1];
    assign stall_fetch_buffer=(pointer<=1);
    wire [3:0]flag4p=flag?4'b0010:4'b0001;
    wire [3:0]flag4=flag?4'b0001:4'b0000;
    wire [3:0]flag4m=flag?4'b0000:4'b1111;

    always @(posedge clk) begin
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
                            for (i=0;i<13;i=i+1) begin
                                buffer[i]<=buffer[i+2];
                                bufferpc[i]<=bufferpc[i+2];
                            end
                            buffer[13]<=ir[0];
                            bufferpc[13]<=pc;
                            buffer[14]<=ir[1];
                            bufferpc[14]<=pc+4;
                        end
                    else 
                        begin
                            for (i=0;i<14;i=i+1) begin
                                buffer[i]<=buffer[i+1];
                                bufferpc[i]<=bufferpc[i+1];
                            end
                            buffer[14]<=ir[0];
                            bufferpc[14]<=pc;
                        end
                if(if1) 
                    if(if0) pointer<=((pointer==14&~flag)|pointer==15)?15:(pointer-flag4m);
                    else pointer<=(pointer==15)?15:(pointer-flag4);
                else
                    pointer<=pointer-flag4p;
                //有下面走，上面不走的情况吗？
            end
    end
endmodule

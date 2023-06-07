module fetch_buffer (
    input [31:0]pc,
    input clk,rstn,flush,stall,
    input if0,if1,icache_valid,
    input [63:0]irin,
    input flag,//flag==1表示2个有效，==0表示1个有效
    output [31:0]ir0,ir1,pc0,pc1,
    output stall_fetch_buffer
);
    //是否需要改用循环队列？head+tail。for循环赋值对性能影响大吗？
    reg [31:0]buffer[0:15];//是否会溢出？
    reg [31:0]bufferpc[0:15];
    reg [4:0]pointer;//0~31
    // reg icache_valid=1;
    wire [31:0]ir[0:1];
    assign ir0=buffer[1];
    assign ir1=buffer[0];
    assign ir[1]=irin[31:0];
    assign ir[0]=irin[63:32];
    assign pc0=bufferpc[1];
    assign pc1=bufferpc[0];
    assign stall_fetch_buffer=(pointer>=15);
    // reg [127:0]ir_reg;
    // assign ir[2]=irin[95:64];
    // assign ir[3]=irin[127:96];
    // assign icache_valid=(ir_reg!=irin);
    // always @(posedge clk,negedge rstn) begin
    //     if(!rstn) ir_reg<=0;
    //     else ir_reg<=irin;
    // end
    always @(posedge clk,negedge rstn) begin:fetch_buffer
        integer i;
        if(!rstn|flush) 
            begin
                pointer<=0;
                for (i=0;i<16;i=i+1) begin
                        buffer[i]<=0;
                        bufferpc[i]<=0;
                end
            end
        else if(!stall)
            case ({if0,if1,icache_valid})//if1是优先级高的通道，即pc小的一侧
            //是否会出现if0&!if1的情况？
                'b000: ;
                'b001: begin 
                    pointer<=pointer+flag+1;
                    for (i=0;i<flag+1;i=i+1)begin
                        buffer[pointer+i]<=ir[i];
                        bufferpc[pointer+i]<=pc+(i<<2);
                    end
                end
                'b010: begin 
                    if(pointer>0) begin
                        pointer<=pointer-1;
                        for (i=0;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        buffer[pointer-1]<=0;
                        bufferpc[pointer-1]<=0;
                    end
                end
                'b011: begin 
                    if(pointer>0) begin
                        pointer<=pointer+flag;
                        for (i=0;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer-1+i]<=ir[i];
                            bufferpc[pointer-1+i]<=pc+(i<<2);
                        end
                    end
                    else begin
                        pointer<=pointer+flag+1;
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer+i]<=ir[i];
                            bufferpc[pointer+i]<=pc+(i<<2);
                        end
                    end
                end
                'b100: begin 
                    if(pointer>1) begin
                        pointer<=pointer-1;
                        for (i=1;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        buffer[pointer-1]<=0;
                        bufferpc[pointer-1]<=0;
                    end
                end
                'b101: begin 
                    if(pointer>1) begin
                        pointer<=pointer+flag;
                        for (i=1;i<pointer-1;i=i+1)begin
                            buffer[i]<=buffer[i+1];
                            bufferpc[i]<=bufferpc[i+1];
                        end
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer-1+i]<=ir[i];
                            bufferpc[pointer-1+i]<=pc+(i<<2);
                        end
                    end
                    else begin
                        pointer<=pointer+flag+1;
                        for (i=0;i<flag+1;i=i+1)begin
                            buffer[pointer+i]<=ir[i];
                            bufferpc[pointer+i]<=pc+(i<<2);
                        end
                    end
                end
                'b110: begin 
                    if(pointer>1) begin
                        pointer<=pointer-2;
                        for (i=0;i<pointer-2;i=i+1)begin
                            buffer[i]<=buffer[i+2];
                            bufferpc[i]<=bufferpc[i+2];
                        end
                        buffer[pointer-1]<=0;
                        buffer[pointer-2]<=0;
                        bufferpc[pointer-1]<=0;
                        bufferpc[pointer-2]<=0;
                    end
                    else if(pointer==1) begin
                        pointer<=pointer-1;
                        // for (i=0;i<pointer-1;i=i+1)begin
                        //     buffer[i]<=buffer[i+1];
                        // end
                        buffer[0]<=0;
                        bufferpc[0]<=0;
                    end
                end
                'b111: begin 
                    if(pointer>1) begin
                        pointer<=pointer+flag-1;
                        for (i=0;i<pointer-2;i=i+1)begin
                            buffer[i]<=buffer[i+2];
                            bufferpc[i]<=bufferpc[i+2];
                        end
                        if(flag) 
                            begin
                                buffer[pointer-2]<=ir[0];
                                bufferpc[pointer-2]<=pc;
                                buffer[pointer-1]<=ir[1];
                                bufferpc[pointer-1]<=pc+4;
                            end
                        else 
                            begin
                                buffer[pointer-2]<=ir[0];
                                bufferpc[pointer-2]<=pc;
                                buffer[pointer-1]<=0;
                                bufferpc[pointer-1]<=0;
                            end
                    end
                    else begin
                        pointer<=pointer+flag+1;
                        if(flag) 
                            begin
                                buffer[0]<=ir[0];
                                bufferpc[0]<=pc;
                                buffer[1]<=ir[1];
                                bufferpc[1]<=pc+4;
                            end
                        else 
                            begin
                                buffer[0]<=ir[0];
                                bufferpc[0]<=pc;
                                buffer[1]<=0;
                                bufferpc[1]<=0;
                            end
                    end
                end
                default: ;
            endcase
    end

endmodule
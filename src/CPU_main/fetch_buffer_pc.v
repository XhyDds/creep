module fetch_buffer_pc (
    input [31:0]pc,
    input clk,rstn,flush,stall,
    input if0,if1,icache_valid,
    input [63:0]irin,
    input flag,//flag==1表示2个有效，==0表示1个有效
    output [31:0]ir0,ir1,pc0,pc1,
    output stall_fetch_buffer
);
    reg [31:0]buffer[0:15];
    reg [31:0]bufferpc[0:15];
    reg [3:0]top;
    reg [3:0]bottom;
    // reg icache_valid=1;
    wire [31:0]ir[0:1];
    assign ir0=buffer[1];
    assign ir1=buffer[0];
    assign ir[1]=irin[31:0];
    assign ir[0]=irin[63:32];
    assign pc0=bufferpc[1];
    assign pc1=bufferpc[0];
endmodule
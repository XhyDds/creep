module IO_mask(
    input [31:0] addr,
    input [9:0] widthin,
    output allow// 1:yes 0:no

);
    localparam N=3;
    reg [31:0] base[0:N-1];reg [31:0]top[0:N-1];
    wire [N-1:0] allow_c;
    assign allow=&allow_c;
    initial
    begin
    base[0]=32'h1faf_0000;
    top[0]=32'h1fb0_0000;
    base[1]=32'hbfaf_0000;
    top[1]=32'hbfb0_0000;
    base[2]=32'ha000_0000;
    top[2]=32'hc000_0000;
    end
    genvar i;
    generate
    for(i=0;i<N;i=i+1)
    begin: gen_allow
    assign allow_c[i]=(addr+{22'b0,widthin}<base[i]) || (addr>=top[i]);
    end
    endgenerate
endmodule

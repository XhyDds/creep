module IO_mask(
    input [31:0] addr,
    input [9:0] widthin,
    output allow// 1:yes 0:no

);
    localparam N=2;
    reg [31:0] base[0:N-1];reg [5:0]width[0:N-1];
    wire [N-1:0] allow_c;
    assign allow=&allow_c;
    initial
    begin
    base[0]<=32'h1faf_0000;
    width[0]<=6'd16;
    base[1]<=32'hbfaf_0000;
    width[1]<=6'd16;
    end
    genvar i;
    generate
    for(i=0;i<N;i=i+1)
    begin: gen_allow
    assign allow_c[i]=(addr+{22'b0,widthin}<base[i]) || (addr>=base[i]+(1<<width[i]));
    end
    endgenerate
endmodule

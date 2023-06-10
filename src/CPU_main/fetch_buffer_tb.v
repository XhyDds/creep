module tb_fetch_buffer;

// fetch_buffer Parameters
parameter PERIOD  = 0.5;


// fetch_buffer Inputs
reg   [31:0]  pc                           = 0 ;
reg   clk                                  = 0 ;
reg   rstn                                 = 0 ;
reg   if0                                  = 0 ;
reg   if1                                  = 0 ;
reg   [63:0]  irin                         = 0 ;
reg   flag                                 = 0 ;

// fetch_buffer Outputs
wire  [31:0]  ir0                          ;
wire  [31:0]  ir1                          ;
wire  [31:0]  pc0                          ;
wire  [31:0]  pc1                          ;

initial
begin
    forever #PERIOD  clk=~clk;
end

initial
begin
    #(PERIOD*2) rstn  =  1;
end

fetch_buffer  u_fetch_buffer (
    .pc                      ( pc    [31:0] ),
    .clk                     ( clk          ),
    .rstn                    ( rstn         ),
    .if0                     ( if0          ),
    .if1                     ( if1          ),
    .irin                    ( irin  [63:0] ),
    .flag                    ( flag         ),

    .ir0                     ( ir0   [31:0] ),
    .ir1                     ( ir1   [31:0] ),
    .pc0                     ( pc0   [31:0] ),
    .pc1                     ( pc1   [31:0] )
);

initial
begin
    rstn=1;pc=0;if0=0;if1=0;irin=0;flag=0;
    #0.1 rstn=0;
    #0.1 rstn=1;
    #0.3 irin=64'h1111111122222222;flag=1;if0=1;if1=1;pc='h11111111;
    #1 irin=64'h3333333344444444;flag=0;if0=0;if1=1;pc='h33333333;
    #1 irin=64'h5555555566666666;flag=0;if0=0;if1=0;pc='h55555555;
    #1 irin=64'h7777777788888888;flag=1;if0=1;if1=0;pc='h77777777;
    #1 irin=64'h1111111122222222;flag=1;if0=1;if1=1;pc='h11111111;
    #1 irin=64'h3333333344444444;flag=0;if0=0;if1=1;pc='h33333333;
    #1 irin=64'h5555555566666666;flag=0;if0=0;if1=0;pc='h55555555;
    #1 irin=64'h7777777788888888;flag=1;if0=1;if1=0;pc='h77777777;
    #1 irin=64'hFFFFFFFFFFFFFFFF;pc=0;flag=0;if0=1;if1=1;
    #1 irin=64'hFFFFFFFFFFFFFFFF;pc=0;flag=0;if0=1;if1=1;
    #1 irin=64'hFFFFFFFFFFFFFFFF;pc=0;flag=0;if0=1;if1=1;
    #1 irin=64'hFFFFFFFFFFFFFFFF;pc=0;flag=0;if0=1;if1=1;
    #1 irin=64'hFFFFFFFFFFFFFFFF;pc=0;flag=0;if0=1;if1=1;
    #1 irin=64'hFFFFFFFFFFFFFFFF;pc=0;flag=0;if0=1;if1=1;
    #1 irin=64'hFFFFFFFFFFFFFFFF;pc=0;flag=0;if0=1;if1=1;
    #1
    $finish;
end

endmodule
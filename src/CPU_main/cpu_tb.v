module tb_cpu;

// cpu Parameters
parameter PERIOD  = 0.5;


// cpu Inputs
reg   clk                                  = 1 ;
reg   rstn                                 = 0 ;

// cpu Outputs
wire  [15:0]  LED                          ;

initial
begin
    forever #PERIOD  clk=~clk;
end

initial
begin
    #(PERIOD*2) rstn  =  1;
end

cpu  u_cpu (
    .clk                     ( clk          ),
    .rstn                    ( rstn         ),
    .LED                     ( LED          )
);

initial
begin
    rstn=1;
    #0.1 rstn=0;
    #20
    $finish;
end

endmodule
module newop (
    input      clk,
    input      rstn,
    input      [31:0]rrd,rrk,ctr,
    output     [31:0]result,
    output     ifwrite,
    output     stall,
);
    assign result=0;
    assign ifwrite=0;
    assign stall=0;
endmodule //newop

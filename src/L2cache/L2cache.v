`timescale 1ns / 1ps

module L2cache#(
    parameter   index_width=4,
                offset_width=2,
                L1offset_width=2,
                way=2
)(
    input       clk,rstn,

    //Icache port
    input       [31:0]addr_icache_l2cache,
    output      [32*(1<<L1offset_width)-1:0]dout_l2cache_icache,
    input       icache_l2cache_req,
    output      l2cache_icache_addrOK,
    output      l2cache_icache_dataOK,

    //Dcache port
    input       [31:0]addr_dcache_l2cache,
    input       [31:0]data_l2cache_dcache,
    output      [32*(1<<L1offset_width)-1:0]dout_l2cache_dcache,
    input       dcache_l2cache_req,
    input       dcache_l2cache_wr,
    output      l2cache_dcache_addrOK,
    output      l2cache_dcache_dataOK,

    //mem port
    output      [31:0]addr_l2cache_mem,
    input       [32*(1<<L1offset_width)-1:0]din_mem_l2cache,



)

endmodule

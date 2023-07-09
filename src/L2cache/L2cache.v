`timescale 1ns / 1ps

module L2cache#(
    parameter   index_width=8,
                offset_width=4,
                L1offset_width=2,
                way=4
)(
    //四路 写回写分配
    input       clk,rstn,

    //Icache port
    input       [31:0]addr_icache_l2cache,
    output      [32*(1<<L1offset_width)-1:0]dout_l2cache_icache,
    input       icache_l2cache_req,
    output      l2cache_icache_addrOK,
    output      l2cache_icache_dataOK,

    //Dcache port
    input       [31:0]addr_dcache_l2cache,
    input       [31:0]data_l2cache_dcache,//L1写直达
    output      [32*(1<<L1offset_width)-1:0]dout_l2cache_dcache,
    input       dcache_l2cache_req,
    input       dcache_l2cache_wr,  //0-read 1-write
    output      l2cache_dcache_addrOK,
    output      l2cache_dcache_dataOK,

    //mem port(AXI bridge)
    output      [31:0]addr_l2cache_mem,
    input       [32*(1<<offset_width)-1:0]din_mem_l2cache,
    output      [32*(1<<offset_width)-1:0]dout_l2cache_mem,
    output      l2cache_mem_req,
    output      l2cache_mem_wr,//0-read 1-write
    input       mem_l2cache_addrOK, 
    input       mem_l2cache_dataOK
    
);

endmodule

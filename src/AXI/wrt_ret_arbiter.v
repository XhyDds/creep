/// 此模块负责仲裁读取的数据来自writebuf还是来自returnbuf(axi).
/// 先从writebuf读取，如果writebuf没有数据，再从returnbuf读取。

module wrt_ret_arbiter#(
    parameter offset_width = 2
)(
    input       clk,
    input       rstn,
    //l2cache
    input       l2cache_mem_req_r,
    output      mem_l2cache_addrOK_r,
    input       l2cache_mem_rdy,
    output      mem_l2cache_dataOK,
    output      din_mem_l2cache,
    //writebuffer
    input       [(1<<offset_width)*32-1:0]query_data,
    input       query_ok,
    //returnbuffer
    input       arbiter_mem_req,
    input       mem_arbiter_addrOK,
    output reg  mem_arbiter_dataOK,
    output      [(1<<offset_width)*32-1:0]dout_mem_arbiter
);
endmodule
module prefetching#(
    parameter ADDR_WIDTH    = 32,
              L2cache_width = 3
)(
    output       req_pref_l2cache,
    output       type_pref_l2cache,//指令或数据 0-指令 1-数据
    output       [31:0]addr_pref_l2cache,
    input        complete_l2cache_pref,
    input        hit_l2cache_pref,//预取请求的Hit
    input        miss_l2cache_pref//预取过程中来自L1访问的Miss 
);
endmodule
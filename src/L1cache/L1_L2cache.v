// `define MMU
module L1_L2cache#(
    parameter   I_index_width=8,
                D_index_width=8,
                L2_index_width=7,
                L1_offset_width=2,
                L2_offset_width=3
)
(
    input       clk,rstn,

    //Icache-pipeline port
    input       [31:0]addr_pipeline_icache,
    input       [31:0]paddr_pipeline_icache,
    output      [63:0]dout_icache_pipeline,//双发射 [31:0]是给定地址处的指令
    output      [31:0]pc_icache_pipeline,
    output      flag_icache_pipeline,//0-后一条指令（[63:32]）无效 1-有效
    input       SUC_pipeline_icache,

    input       pipeline_icache_valid,
    output      icache_pipeline_ready,

    input       [31:0]pipeline_icache_opcode,//cache操作
    input       pipeline_icache_opflag,//0-正常访存 1-cache操作    
    input       [31:0]pipeline_icache_ctrl,//stall flush branch ...
    output      icache_pipeline_stall,//stall form icache     不知道可不可以用ready代替，先留着    

    //Dcache-pipeline port
    input       [31:0]addr_pipeline_dcache,
    input       [31:0]paddr_pipeline_dcache,
    input       [31:0]din_pipeline_dcache,
    input       [31:0]pcin_pipeline_dcache,
    output      [31:0]dout_dcache_pipeline,
    input       type_pipeline_dcache,//0-read 1-write
    input       SUC_pipeline_dcache,

    input       pipeline_dcache_valid,
    output      dcache_pipeline_ready,
    
    input       [3:0]pipeline_dcache_wstrb,//字节处理位
    input       [1:0]pipeline_dcache_size,
    input       [31:0]pipeline_dcache_opcode,//cache操作
    input       pipeline_dcache_opflag,//0-正常访存 1-cache操作    
    input       [31:0]pipeline_dcache_ctrl,//stall flush branch ...
    output      dcache_pipeline_stall,//stall form dcache     不知道可不可以用ready代替，先留着

    //L2-pipeline port
    input       [31:0]addr_pipeline_l2cache,
    input       pipeline_l2cache_opflag,
    input       [31:0]pipeline_l2cache_opcode,

    //L2-Mem port
    output      [31:0]addr_l2cache_mem_r,
    output      [31:0]addr_l2cache_mem_w,
    input       [32*(1<<L2_offset_width)-1:0]din_mem_l2cache,
    output      [32*(1<<L2_offset_width)-1:0]dout_l2cache_mem,
    output      l2cache_mem_req_r,
    output      l2cache_mem_req_w,
    output      l2cache_mem_rdy,
    output      l2cache_mem_SUC,
    output      [3:0]l2cache_mem_wstrb,
    output      [1:0]l2cache_mem_size,
    input       mem_l2cache_addrOK_r,
    input       mem_l2cache_addrOK_w, 
    input       mem_l2cache_dataOK
     );

wire [31:0]addr_icache_mem;
wire [32*(1<<L1_offset_width)-1:0]din_mem_icache;
wire icache_mem_req;
wire icache_mem_SUC;
wire [1:0]icache_mem_size;
wire mem_icache_addrOK;
wire mem_icache_dataOK;

Icache #(
    .index_width(I_index_width),
    .offset_width(L1_offset_width)
)
Icache(
    .clk(clk),
    .rstn(rstn),

    .addr_pipeline_icache(addr_pipeline_icache),
    .paddr_pipeline_icache(paddr_pipeline_icache),
    .dout_icache_pipeline(dout_icache_pipeline),
    .pc_icache_pipeline(pc_icache_pipeline),
    .flag_icache_pipeline(flag_icache_pipeline),
    .SUC_pipeline_icache(SUC_pipeline_icache),

    .pipeline_icache_valid(pipeline_icache_valid),
    .icache_pipeline_ready(icache_pipeline_ready),

    .pipeline_icache_opcode(pipeline_icache_opcode),
    .pipeline_icache_opflag(pipeline_icache_opflag),
    .pipeline_icache_ctrl(pipeline_icache_ctrl),
    .icache_pipeline_stall(icache_pipeline_stall),

    .addr_icache_mem(addr_icache_mem),
    .din_mem_icache(din_mem_icache),

    .icache_mem_req(icache_mem_req),
    .icache_mem_SUC(icache_mem_SUC),
    .icache_mem_size(icache_mem_size),
    .mem_icache_addrOK(mem_icache_addrOK),
    .mem_icache_dataOK(mem_icache_dataOK)
    );

wire [31:0]addr_dcache_mem;
wire [31:0]dout_dcache_mem;
wire [32*(1<<L1_offset_width)-1:0]din_mem_dcache;
wire dcache_mem_req;
wire dcache_mem_SUC;
wire dcache_mem_wr;
wire [1:0]dcache_mem_size;
wire [3:0]dcache_mem_wstrb;
wire mem_dcache_addrOK;
wire mem_dcache_dataOK;

Dcache #(
    .index_width(D_index_width),
    .offset_width(L1_offset_width)
)
Dcache(
    .clk(clk),
    .rstn(rstn),

    .addr_pipeline_dcache(addr_pipeline_dcache),
    .paddr_pipeline_dcache(paddr_pipeline_dcache),
    .din_pipeline_dcache(din_pipeline_dcache),
    .pcin_pipeline_dcache(pcin_pipeline_dcache),
    .dout_dcache_pipeline(dout_dcache_pipeline),
    .type_pipeline_dcache(type_pipeline_dcache),
    .SUC_pipeline_dcache(SUC_pipeline_dcache),

    .pipeline_dcache_valid(pipeline_dcache_valid),
    .dcache_pipeline_ready(dcache_pipeline_ready),

    .pipeline_dcache_wstrb(pipeline_dcache_wstrb),
    .pipeline_dcache_opcode(pipeline_dcache_opcode),
    .pipeline_dcache_opflag(pipeline_dcache_opflag),
    .pipeline_dcache_ctrl(pipeline_dcache_ctrl),
    .dcache_pipeline_stall(dcache_pipeline_stall),

    .addr_dcache_mem(addr_dcache_mem),
    .dout_dcache_mem(dout_dcache_mem),
    .din_mem_dcache(din_mem_dcache),

    .dcache_mem_req(dcache_mem_req),
    .dcache_mem_wr(dcache_mem_wr),
    .dcache_mem_SUC(dcache_mem_SUC),
    .dcache_mem_size(dcache_mem_size),
    .dcache_mem_wstrb(dcache_mem_wstrb),
    .mem_dcache_addrOK(mem_dcache_addrOK),
    .mem_dcache_dataOK(mem_dcache_dataOK)

);

//Icache
wire [31:0]addr_icache_l2cache;
wire [32*(1<<L1_offset_width)-1:0]dout_l2cache_icache;
wire icache_l2cache_req;
wire l2cache_icache_addrOK;
wire l2cache_icache_dataOK;
wire icache_l2cache_SUC;

assign addr_icache_l2cache = addr_icache_mem;
assign din_mem_icache = dout_l2cache_icache;
assign icache_l2cache_req = icache_mem_req;
assign mem_icache_addrOK = l2cache_icache_addrOK;
assign mem_icache_dataOK = l2cache_icache_dataOK;
assign icache_l2cache_SUC = icache_mem_SUC;

//Dcache
wire [31:0]addr_dcache_l2cache;
wire [31:0]din_dcache_l2cache;
wire [32*(1<<L1_offset_width)-1:0]dout_l2cache_dcache;
wire dcache_l2cache_req;
wire dcache_l2cache_wr;
wire [3:0]dcache_l2cache_wstrb;
wire l2cache_dcache_addrOK;
wire l2cache_dcache_dataOK;
wire dcache_l2cache_SUC;
wire dcache_l2cache_size;

assign addr_dcache_l2cache = addr_dcache_mem;
assign din_dcache_l2cache = dout_dcache_mem;
assign din_mem_dcache = dout_l2cache_dcache;
assign dcache_l2cache_req = dcache_mem_req;
assign dcache_l2cache_wr = dcache_mem_wr;
assign dcache_l2cache_wstrb = dcache_mem_wstrb;
assign mem_dcache_addrOK = l2cache_dcache_addrOK;
assign mem_dcache_dataOK = l2cache_dcache_dataOK;
assign dcache_l2cache_SUC = dcache_mem_SUC;
assign dcache_l2cache_size = dcache_mem_size;

L2cache #(
    .index_width(L2_index_width),
    .offset_width(L2_offset_width),
    .L1_offset_width(L1_offset_width)
)
L2cache(
    .clk(clk),
    .rstn(rstn),

    .pipeline_l2cache_opflag(pipeline_l2cache_opflag),
    .pipeline_l2cache_opcode(pipeline_l2cache_opcode),
    .addr_pipeline_l2cache(addr_pipeline_l2cache),

    .addr_icache_l2cache(addr_icache_l2cache),
    .dout_l2cache_icache(dout_l2cache_icache),
    .icache_l2cache_req(icache_l2cache_req),
    .icache_l2cache_SUC(icache_l2cache_SUC),
    .l2cache_icache_addrOK(l2cache_icache_addrOK),
    .l2cache_icache_dataOK(l2cache_icache_dataOK),
    
    .addr_dcache_l2cache(addr_dcache_l2cache),
    .din_dcache_l2cache(din_dcache_l2cache),
    .dout_l2cache_dcache(dout_l2cache_dcache),
    .dcache_l2cache_req(dcache_l2cache_req),
    .dcache_l2cache_wr(dcache_l2cache_wr),
    .dcache_l2cache_SUC(dcache_l2cache_SUC),
    .dcache_l2cache_wstrb(dcache_l2cache_wstrb),
    .dcache_l2cache_size(dcache_l2cache_size),
    .l2cache_dcache_addrOK(l2cache_dcache_addrOK),
    .l2cache_dcache_dataOK(l2cache_dcache_dataOK),

    .addr_l2cache_mem_r(addr_l2cache_mem_r),
    .addr_l2cache_mem_w(addr_l2cache_mem_w),
    .din_mem_l2cache(din_mem_l2cache),
    .dout_l2cache_mem(dout_l2cache_mem),
    .l2cache_mem_req_r(l2cache_mem_req_r),
    .l2cache_mem_req_w(l2cache_mem_req_w),
    .l2cache_mem_rdy(l2cache_mem_rdy),
    .l2cache_mem_SUC(l2cache_mem_SUC),
    .l2cache_mem_wstrb(l2cache_mem_wstrb),
    .l2cache_mem_size(l2cache_mem_size),
    .mem_l2cache_addrOK_r(mem_l2cache_addrOK_r),
    .mem_l2cache_addrOK_w(mem_l2cache_addrOK_w),
    .mem_l2cache_dataOK(mem_l2cache_dataOK)

);

endmodule

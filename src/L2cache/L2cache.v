`timescale 1ns / 1ps

module L2cache#(
    parameter   index_width=2,
                offset_width=3,
                L1_offset_width=2,//两者相等
                way=4
)
(
    //四路 写回写分配
    //Icache可见前两路 Dcache可见后两路 PLRU公用
    input       clk,rstn,
    
    //op port
    input       pipeline_l2cache_opflag,
    input       [31:0]pipeline_l2cache_opcode,
    input       [31:0]addr_pipeline_l2cache,
    output      ack_op,

    //Icache port
    input       [31:0]addr_icache_l2cache,
    output      [32*(1<<L1_offset_width)-1:0]dout_l2cache_icache,
    input       icache_l2cache_req,
    input       icache_l2cache_SUC,
    output      l2cache_icache_addrOK,
    output      l2cache_icache_dataOK,

    //Dcache port
    input       [31:0]addr_dcache_l2cache,
    input       [31:0]din_dcache_l2cache,//L1写直达
    output      [32*(1<<L1_offset_width)-1:0]dout_l2cache_dcache,
    input       dcache_l2cache_req,
    input       dcache_l2cache_SUC,
    input       dcache_l2cache_wr,  //0-read 1-write
    input       [3:0]dcache_l2cache_wstrb,
    input       [1:0]dcache_l2cache_size,
    output      l2cache_dcache_addrOK,
    output      l2cache_dcache_dataOK,

    //mem port(AXI bridge)
    output      [31:0]addr_l2cache_mem_r,
    output      [31:0]addr_l2cache_mem_w,
    input       [32*(1<<offset_width)-1:0]din_mem_l2cache,
    output      [32*(1<<offset_width)-1:0]dout_l2cache_mem,
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

//仲裁逻辑：Dcache优先
wire [31:0]addr_l1cache_l2cache;
wire [31:0]din_l1cache_l2cache;
reg [32*(1<<L1_offset_width)-1:0]dout_l2cache_l1cache;
wire [3:0]l1cache_l2cache_wstrb;
reg [1:0]l1cache_l2cache_size;
reg [1:0]from;//0-No 1-I 2-Dr 3-Dw
reg l1cache_l2cache_SUC;
always @(*) begin
    l1cache_l2cache_SUC = 0;
    if(dcache_l2cache_req)begin
        if(!dcache_l2cache_wr)from = 2'd2;
        else from = 2'd3;
        l1cache_l2cache_SUC = dcache_l2cache_SUC;
        l1cache_l2cache_size = dcache_l2cache_size;
    end
    else if(icache_l2cache_req)begin
        from = 2'd1;
        l1cache_l2cache_SUC = icache_l2cache_SUC;
        l1cache_l2cache_size = 2'd2;
    end
    else from = 2'd0;
end
assign addr_l1cache_l2cache = from[1] ? addr_dcache_l2cache : addr_icache_l2cache;
assign din_l1cache_l2cache = din_dcache_l2cache;
assign dout_l2cache_icache = dout_l2cache_l1cache;
assign dout_l2cache_dcache = dout_l2cache_l1cache;
assign l1cache_l2cache_wstrb = dcache_l2cache_wstrb;

wire [offset_width-1:0]offset;
wire [index_width-1:0]index;
wire [32-offset_width-index_width-2-1:0]tag;
assign offset = addr_l1cache_l2cache[offset_width+1:2];
assign index = addr_l1cache_l2cache[offset_width+index_width+1:offset_width+2];
assign tag = addr_l1cache_l2cache[31:offset_width+index_width+2];

//request buffer
wire [31:0]rbuf_addr,rbuf_data,rbuf_opcode,rbuf_opaddr;
wire [3:0]rbuf_wstrb;
wire [1:0]rbuf_from;
wire [1:0]rbuf_size;
wire rbuf_opflag,rbuf_we,rbuf_SUC;

wire [offset_width-1:0]rbuf_offset;
wire [index_width-1:0]rbuf_index;
wire [32-offset_width-index_width-2-1:0]rbuf_tag;

assign rbuf_offset = rbuf_addr[offset_width+1:2];
assign rbuf_index = rbuf_addr[offset_width+index_width+1:offset_width+2];
assign rbuf_tag = rbuf_addr[31:offset_width+index_width+2];

L2cache_rbuf L2cache_rbuf(
    .clk(clk),.rstn(rstn),
    .rbuf_we(rbuf_we),

    .addr(addr_l1cache_l2cache),
    .rbuf_addr(rbuf_addr),

    .data(din_l1cache_l2cache),
    .rbuf_data(rbuf_data),

    .opcode(pipeline_l2cache_opcode),
    .rbuf_opcode(rbuf_opcode),

    .opflag(pipeline_l2cache_opflag),
    .rbuf_opflag(rbuf_opflag),
    
    .from(from),
    .rbuf_from(rbuf_from),
        
    .wstrb(l1cache_l2cache_wstrb),
    .rbuf_wstrb(rbuf_wstrb),

    .size(l1cache_l2cache_size),
    .rbuf_size(rbuf_size),

    .SUC(l1cache_l2cache_SUC),
    .rbuf_SUC(rbuf_SUC),

    .opaddr(addr_pipeline_l2cache),
    .rbuf_opaddr(rbuf_opaddr)
);

//PLRU
wire [way-1:0]use1;
wire [way-1:0]valid;
wire [1:0]way_sel_d;
wire way_sel_i;
L2cache_replace #(
    .way(way),
    .addr_width(index_width)
)
L2cache_replace(
    .clk(clk),
    .use1(use1),
    .valid(valid),
    .addr(rbuf_index),
    .way_sel_d(way_sel_d),
    .way_sel_i(way_sel_i)
);

//Data
wire [way-1:0]Data_we;
wire [(1<<offset_width)*32-1:0]data0,data1,data2,data3;
wire Data_replace;
wire Data_writeback;
L2cache_Data #(
    .way(way),
    .addr_width(index_width),
    .offset_width(offset_width),
    .data_width((1<<offset_width)*32)
)
L2cache_Data(
    .clk(clk),
    
    .Data_addr_read(Data_writeback ? rbuf_index : index),
    .Data_dout0(data0),
    .Data_dout1(data1),
    .Data_dout2(data2),
    .Data_dout3(data3),

    .Data_din_write(din_mem_l2cache),//一整行
    .Data_din_write_32(rbuf_data),
    .Data_addr_write(rbuf_index),
    .Data_offset(rbuf_offset),
    .Data_choose_byte(rbuf_wstrb),
    .Data_we(Data_we),
    .Data_replace(Data_replace)
);

//Tag
wire [way-1:0]TagV_we,hit,TagV_unvalid;
wire [1:0]TagV_way_select;
wire [2:0]TagV_init;
wire [32-2-index_width-offset_width-1:0]TagV_dout;
assign TagV_we = Data_we;
L2cache_TagV #(
    .way(way),
    .addr_width(index_width),
    .data_width(32-2-index_width-offset_width)
)
L2cache_TagV(
    .clk(clk),

    .TagV_addr_read(Data_writeback ? rbuf_index : index),
    .TagV_din_compare(rbuf_tag),
    .hit(hit),
    .valid(valid),
    .TagV_way_select(TagV_way_select),
    .TagV_dout(TagV_dout),
    
    .TagV_init(TagV_init),
    .TagV_din_write(rbuf_tag),
    .TagV_addr_write(rbuf_index),
    .TagV_unvalid(TagV_unvalid),
    .TagV_we(TagV_we)
);

//Dirtytable
wire Dirty,Dirtytable_set0,Dirtytable_set1;
wire [1:0]Dirtytable_way_select;
L2cache_Dirtytable #(
    .addr_width(index_width)
)
L2cache_Dirtytable(
    .clk(clk),
    
    .Dirtytable_addr(rbuf_index),
    .Dirtytable_way_select(Dirtytable_way_select),
    .Dirtytable_set0(Dirtytable_set0),
    .Dirtytable_set1(Dirtytable_set1),
    .Dirty(Dirty)
);

//data choose
wire [1:0]choose_way;
wire choose_return;
reg [32*(1<<offset_width)-1:0]line;
always @(*) begin
    if(choose_return)line = din_mem_l2cache;
    else begin
        case (choose_way)
            2'd0: line = data0;
            2'd1: line = data1;
            2'd2: line = data2;
            2'd3: line = data3;
            default: line = 64'h1234ABCD;
        endcase
    end
end
wire choose_word = rbuf_offset[offset_width -1 : L1_offset_width];
always @(*) begin
    if(rbuf_SUC)dout_l2cache_l1cache = line[127:0];//TLB时还要注意
    else begin
        case (choose_word)
            1'd0: dout_l2cache_l1cache = line[127:0];
            1'd1: dout_l2cache_l1cache = line[255:128];
            default: dout_l2cache_l1cache = line;
        endcase
    end
end
//Mem
assign addr_l2cache_mem_r = rbuf_SUC ? rbuf_addr : {rbuf_addr[31:offset_width+2],{(offset_width+2){1'b0}}};//对齐
assign addr_l2cache_mem_w = rbuf_SUC ? rbuf_addr : {TagV_dout,rbuf_index,{(offset_width+2){1'b0}}};
assign dout_l2cache_mem = rbuf_SUC ? rbuf_data : line;//
assign l2cache_mem_SUC = rbuf_SUC;
assign l2cache_mem_wstrb = rbuf_wstrb;
assign l2cache_mem_size = rbuf_size;

//FSM
L2cache_FSMmain #(
    .way(way),
    .index_width(index_width),
    .offset_width(offset_width)
)
L2cache_FSMmain(
    .clk(clk),.rstn(rstn),

    //req for L1(pipe)
    .from(from),
    .pipeline_l2cache_opflag(pipeline_l2cache_opflag),
    .ack_op(ack_op),
    .l2cache_icache_addrOK(l2cache_icache_addrOK),
    .l2cache_icache_dataOK(l2cache_icache_dataOK),
    .l2cache_dcache_addrOK(l2cache_dcache_addrOK),
    .l2cache_dcache_dataOK(l2cache_dcache_dataOK),

    //req for Mem
    .l2cache_mem_req_w(l2cache_mem_req_w),
    .l2cache_mem_req_r(l2cache_mem_req_r),
    .l2cache_mem_rdy(l2cache_mem_rdy),
    .mem_l2cache_addrOK_r(mem_l2cache_addrOK_r),
    .mem_l2cache_addrOK_w(mem_l2cache_addrOK_w),
    .mem_l2cache_dataOK(mem_l2cache_dataOK),

    //request buffer
    .FSM_rbuf_we(rbuf_we),
    .FSM_rbuf_from(rbuf_from),
    .FSM_rbuf_opcode(rbuf_opcode),
    .FSM_rbuf_SUC(rbuf_SUC),
    .FSM_rbuf_opaddr(rbuf_opaddr),
    .FSM_rbuf_opflag(rbuf_opflag),

    .FSM_SUC(l1cache_l2cache_SUC),
    .FSM_dSUC(dcache_l2cache_SUC),
    .FSM_dcache_req(dcache_l2cache_req),
    .FSM_dcache_wr(dcache_l2cache_wr),
    .FSM_icache_req(icache_l2cache_req),

    //PLRU
    .FSM_use(use1),
    .FSM_way_sel_d(way_sel_d),
    .FSM_way_sel_i(way_sel_i),

    //Data and TagV
    .FSM_hit(hit),
    .FSM_Data_we(Data_we),
    .FSM_Data_replace(Data_replace),//为1时替换整行，否则对word操作
    .FSM_TagV_way_select(TagV_way_select),
    .FSM_Data_writeback(Data_writeback),
    .FSM_TagV_unvalid(TagV_unvalid),
    .FSM_TagV_init(TagV_init),

    //Dirtytable
    .FSM_Dirtytable_way_select(Dirtytable_way_select),
    .FSM_Dirtytable_set0(Dirtytable_set0),
    .FSM_Dirtytable_set1(Dirtytable_set1),
    .FSM_Dirty(Dirty),

    //Data Choose
    .FSM_choose_way(choose_way),
    .FSM_choose_return(choose_return)
    
);
endmodule

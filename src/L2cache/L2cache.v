`timescale 1ns / 1ps

module L2cache#(
    parameter   index_width=2,
                offset_width=3,
                L1_offset_width=2,//两者相等
                way=8
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
    input       icache_l2cache_flush,
    input       icache_l2cache_SUC,
    output      l2cache_icache_addrOK,
    output      l2cache_icache_dataOK,

    //Dcache port
    input       [31:0]addr_dcache_l2cache,
    input       [31:0]pc_dcache_l2cache,
    input       [31:0]din_dcache_l2cache,//L1写直达
    output      [32*(1<<L1_offset_width)-1:0]dout_l2cache_dcache,
    input       dcache_l2cache_req,
    input       dcache_l2cache_SUC,
    input       dcache_l2cache_wr,  //0-read 1-write
    input       [3:0]dcache_l2cache_wstrb,
    input       [1:0]dcache_l2cache_size,
    output      l2cache_dcache_addrOK,
    output      l2cache_dcache_dataOK,

    //L2-prefetch port
    input       req_pref_l2cache,
    input       type_pref_l2cache,
    input       [31:0]addr_pref_l2cache,
    output      hit_l2cache_pref,//
    output      miss_l2cache_pref,
    output      addrOK_l2cache_pref,
    output      complete_l2cache_pref,
    output      missvalid_l2cacahe_pref,//valid
    output      [31:0]misspc_l2cache_pref,
    output      [31:0]missaddr_l2cache_pref,
    output      misstype_l2cache_pref_paddr,//0-I 1-D

    input       [2:0]num_pref_l2cache,//预取类型
    output      [2:0]num_l2cache_pref,
    output      hitnum_l2cache_pref,

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
reg [31:0]addr_l1cache_l2cache;
wire addr_choose_pref;
wire [31:0]din_l1cache_l2cache;
reg [31:0]pc_l1cache_l2cache;
reg [32*(1<<L1_offset_width)-1:0]dout_l2cache_l1cache;
wire [3:0]l1cache_l2cache_wstrb;
reg [1:0]l1cache_l2cache_size;
reg [1:0]from;//0-No 1-I 2-Dr 3-Dw
reg l1cache_l2cache_SUC;
always @(*) begin
    l1cache_l2cache_SUC = 0;
    l1cache_l2cache_size = 2'd0;
    from = 2'd0;
    addr_l1cache_l2cache = 0;
    pc_l1cache_l2cache = 0;
    if(pipeline_l2cache_opflag)begin
        addr_l1cache_l2cache = addr_pipeline_l2cache;
    end
    else if(dcache_l2cache_req)begin
        pc_l1cache_l2cache = pc_dcache_l2cache;
        if(!dcache_l2cache_wr)from = 2'd2;
        else from = 2'd3;
        l1cache_l2cache_SUC = dcache_l2cache_SUC;
        l1cache_l2cache_size = dcache_l2cache_size;
        addr_l1cache_l2cache = addr_dcache_l2cache;
    end
    else if(icache_l2cache_req)begin
        pc_l1cache_l2cache = addr_icache_l2cache;
        from = 2'd1;
        l1cache_l2cache_SUC = icache_l2cache_SUC;
        l1cache_l2cache_size = 2'd2;
        addr_l1cache_l2cache = addr_icache_l2cache;
    end
    else if(req_pref_l2cache)begin
        l1cache_l2cache_SUC = 0;
        addr_l1cache_l2cache = addr_pref_l2cache;
        l1cache_l2cache_size = 2'd2;
    end
end
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
wire [31:0]rbuf_addr,rbuf_pc,rbuf_data,rbuf_opcode,rbuf_opaddr;
wire [3:0]rbuf_wstrb;
wire [1:0]rbuf_from,rbuf_from_pref;
wire [1:0]rbuf_size;
wire rbuf_opflag,rbuf_we,rbuf_SUC,rbuf_pref_type;

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

    .SUC(l1cache_l2cache_SUC && |from),//
    .rbuf_SUC(rbuf_SUC),

    .opaddr(addr_pipeline_l2cache),
    .rbuf_opaddr(rbuf_opaddr),

    .pref_type(type_pref_l2cache),
    .rbuf_pref_type(rbuf_pref_type),

    .pc(pc_l1cache_l2cache),
    .rbuf_pc(rbuf_pc)
);

//pref buffer
wire inpref;
wire [31:0]data_pref,addr_pref;
wire [3:0]wstrb_pref;
wire [1:0]from_pref;
wire SUC_pref;
wire [offset_width-1:0]offset_pref;
wire [index_width-1:0]index_pref;
wire [32-offset_width-index_width-2-1:0]tag_pref;
assign offset_pref = addr_pref[offset_width+1:2];
assign index_pref = addr_pref[offset_width+index_width+1:offset_width+2];
assign tag_pref = addr_pref[31:offset_width+index_width+2];
reg tt;
always @(posedge clk) begin//间隔访问
    if(!rstn)tt <= 0;
    else tt <= ~tt;
end
wire we_wbaddr;
reg [32:0]wbaddr;//写回地址
always @(posedge clk) begin
    if(we_wbaddr)wbaddr <= {1'b0,addr_l2cache_mem_w};
end
reg [1:0]from_tt;
always @(*) begin
    if(dcache_l2cache_req)begin
        if(!dcache_l2cache_wr)from_tt = 2'd2;
        else if(wbaddr<={1'b0,addr_dcache_l2cache} && wbaddr+33'd32>{1'b0,addr_dcache_l2cache})from_tt = 2'd0;//拒绝写
        else from_tt = 2'd3;
    end
    else if(icache_l2cache_req)begin
        from_tt = 2'd1;
    end
    else from_tt = 2'd0;
end
L2cache_pref_reqbuf L2cache_pref_reqbuf(
    .clk(clk),
    .rstn(rstn),

    .data_l1(din_l1cache_l2cache),
    .addr_l1(dcache_l2cache_req ? addr_dcache_l2cache : (icache_l2cache_req ? addr_icache_l2cache : 0)),
    .from({from_tt[1]&tt,from_tt[0]&tt}),
    .wstrb_l1(dcache_l2cache_wstrb),
    .SUC(l1cache_l2cache_SUC),

    .data_l1_pref(data_pref),
    .addr_l1_pref(addr_pref),
    .from_pref(from_pref),
    .wstrb_pref(wstrb_pref),
    .SUC_pref(SUC_pref)
);

//PLRU
wire [way-1:0]use1;
wire [way-1:0]valid;
wire [2:0]way_sel_d;
wire [1:0]way_sel_i;
L2cache_replace #(
    .way(way),
    .addr_width(index_width)
)
L2cache_replace(
    .clk(clk),.rstn(rstn),
    .use1(use1),
    .valid(valid),
    .addr(rbuf_index),
    .way_sel_d(way_sel_d),
    .way_sel_i(way_sel_i)
);

//Data
wire [way-1:0]Data_we;
wire [(1<<offset_width)*32-1:0]data0,data1,data2,data3,data4,data5,data6,data7;
wire Data_replace;
wire Data_writeback;
reg Data_replace_reg;//延迟
reg [way-1:0]Data_we_reg;
reg [32*(1<<offset_width)-1:0]din_reg;
L2cache_Data #(
    .way(way),
    .addr_width(index_width),
    .offset_width(offset_width),
    .data_width((1<<offset_width)*32)
)
L2cache_Data(
    .clk(clk),
    
    .Data_addr_read(Data_writeback ? rbuf_index : index),//pref不用改
    .Data_dout0(data0),
    .Data_dout1(data1),
    .Data_dout2(data2),
    .Data_dout3(data3),
    .Data_dout4(data4),
    .Data_dout5(data5),
    .Data_dout6(data6),
    .Data_dout7(data7),

    .Data_din_write(din_reg),//一整行
    .Data_din_write_32(inpref ? data_pref : rbuf_data),
    .Data_addr_write(inpref ? index_pref : rbuf_index),
    .Data_offset(inpref ? offset_pref : rbuf_offset),
    .Data_choose_byte(inpref ? wstrb_pref : rbuf_wstrb),
    .Data_we(Data_replace_reg ? Data_we_reg : Data_we),
    .Data_replace(Data_replace_reg)
    // .Data_we(Data_we),
    // .Data_replace(Data_replace)
);
always @(posedge clk) begin
    din_reg <= din_mem_l2cache;
    Data_replace_reg <= Data_replace;
    Data_we_reg <= Data_we;
end

//Tag
wire [way-1:0]TagV_we,hit,TagV_unvalid;
wire [2:0]TagV_way_select;
wire [3:0]TagV_init;
wire [32-2-index_width-offset_width-1:0]TagV_dout;
assign TagV_we = Data_we;
L2cache_TagV #(
    .way(way),
    .addr_width(index_width),
    .data_width(32-2-index_width-offset_width)
)
L2cache_TagV(
    .clk(clk),.rstn(rstn),

    .TagV_addr_read(Data_writeback ? rbuf_index : index),
    // .TagV_din_compare(inpref ? tag_pref : rbuf_tag),
    .TagV_din_compare(tag),
    .hit(hit),
    .valid(valid),
    .TagV_way_select(TagV_way_select),
    .TagV_dout(TagV_dout),
    
    .TagV_init(TagV_init),
    .TagV_din_write(inpref ? tag_pref : rbuf_tag),
    .TagV_addr_write(inpref ? index_pref : rbuf_index),
    .TagV_unvalid(TagV_unvalid),
    .TagV_we(TagV_we)

);

//prefnum table
wire num_clear;
assign hitnum_l2cache_pref = num_clear;
wire [way-1:0]num_we;
L2cache_prefnum #(//预取类型
    .addr_width(index_width),
    .data_width(3),
    .way(way)
)
L2cache_prefnum(
    .clk(clk),.rstn(rstn),
    .num_addr_read(index),
    .num_addr_write(inpref ? index_pref : rbuf_index),
    .num_din(num_pref_l2cache),
    .num_dout(num_l2cache_pref),
    .hit(hit),
    .num_we(num_we),
    .clear(num_clear)
);

//Dirtytable
wire Dirty,Dirtytable_set0,Dirtytable_set1;
wire [2:0]Dirtytable_way_select;
L2cache_Dirtytable #(
    .addr_width(index_width)
)
L2cache_Dirtytable(
    .clk(clk),.rstn(rstn),
    
    // .valid(valid),
    .Dirtytable_addr(rbuf_index),
    .Dirtytable_addrw(inpref ? index_pref : rbuf_index),
    .Dirtytable_way_select(Dirtytable_way_select),
    .Dirtytable_set0(Dirtytable_set0),
    .Dirtytable_set1(Dirtytable_set1),
    .Dirty(Dirty)
);

//data choose
wire [2:0]choose_way;
wire choose_return;
reg [32*(1<<offset_width)-1:0]line;
always @(*) begin
    if(choose_return)line = din_mem_l2cache;
    else begin
        case (choose_way)
            3'd0: line = data0;
            3'd1: line = data1;
            3'd2: line = data2;
            3'd3: line = data3;
            3'd4: line = data4;
            3'd5: line = data5;
            3'd6: line = data6;
            3'd7: line = data7;
            default: line = 64'h1234ABCD;
        endcase
    end
end
// wire [offset_width -1 : L1_offset_width]choose_word = inpref ? offset_pref[offset_width -1 : L1_offset_width] : rbuf_offset[offset_width -1 : L1_offset_width];
always @(*) begin
    if(rbuf_SUC)dout_l2cache_l1cache = line[255:0];//TLB时还要注意
    else begin
        dout_l2cache_l1cache = line;
        // case (choose_word)
        //     // 'd0: dout_l2cache_l1cache = line[255:0];
        //     // 'd1: dout_l2cache_l1cache = line[511:256];
        //     // 'd2: dout_l2cache_l1cache = line[383:256];
        //     // 'd3: dout_l2cache_l1cache = line[511:384];
        //     default: dout_l2cache_l1cache = line;
        // endcase
    end
end
//Mem
assign addr_l2cache_mem_r = rbuf_SUC ? rbuf_addr : {rbuf_addr[31:offset_width+2],{(offset_width+2){1'b0}}};//对齐
assign addr_l2cache_mem_w = rbuf_SUC ? rbuf_addr : {TagV_dout,rbuf_index,{(offset_width+2){1'b0}}};
assign dout_l2cache_mem = rbuf_SUC ? {{(32*(1<<offset_width) - 32){1'b0}},rbuf_data} : line;//
assign l2cache_mem_SUC = rbuf_SUC;
assign l2cache_mem_wstrb = rbuf_wstrb;
assign l2cache_mem_size = rbuf_size;

//prefetch
assign misspc_l2cache_pref = rbuf_pc;
assign missaddr_l2cache_pref = rbuf_addr;
assign misstype_l2cache_pref_paddr = ~(rbuf_from == 2'd1);

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
    .icache_l2cache_flush(icache_l2cache_flush),
    .l2cache_dcache_addrOK(l2cache_dcache_addrOK),
    .l2cache_dcache_dataOK(l2cache_dcache_dataOK),

    //req for Mem
    .l2cache_mem_req_w(l2cache_mem_req_w),
    .l2cache_mem_req_r(l2cache_mem_req_r),
    .l2cache_mem_rdy(l2cache_mem_rdy),
    .mem_l2cache_addrOK_r(mem_l2cache_addrOK_r),
    .mem_l2cache_addrOK_w(mem_l2cache_addrOK_w),
    .mem_l2cache_dataOK(mem_l2cache_dataOK),

    //prefetch
    .req_pref_l2cache(req_pref_l2cache),
    .hit_l2cache_pref(hit_l2cache_pref),
    .miss_l2cache_pref(miss_l2cache_pref),
    .addrOK_l2cache_pref(addrOK_l2cache_pref),
    .complete_l2cache_pref(complete_l2cache_pref),
    .missvalid(missvalid_l2cacahe_pref),

    .we_wbaddr(we_wbaddr),
    .num_clear(num_clear),
    .num_we(num_we),

    //request buffer
    .FSM_rbuf_we(rbuf_we),
    .FSM_rbuf_from(rbuf_from),
    .FSM_rbuf_opcode(rbuf_opcode),
    .FSM_rbuf_SUC(rbuf_SUC),
    .FSM_rbuf_opaddr(rbuf_opaddr),
    .FSM_rbuf_opflag(rbuf_opflag),
    .FSM_rbuf_pref_type(rbuf_pref_type),

    //pref req buf
    .FSM_from_pref(from_pref),
    .FSM_SUC_pref(SUC_pref),

    //req
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
    .FSM_inpref(inpref),
    .FSM_choose_way(choose_way),
    .FSM_choose_return(choose_return)
    
);
endmodule

`timescale 1ns / 1ps

module L2cache#(
    parameter   index_width=8,
                offset_width=2,
                L1offset_width=2,//两者相等
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

    //op port
    input       l2cache_opflag;
    input       [31:0]l2cache_opcode;
    //Dcache port
    input       [31:0]addr_dcache_l2cache,
    input       [31:0]din_dcache_l2cache,//L1写直达
    output      [32*(1<<L1offset_width)-1:0]dout_l2cache_dcache,
    input       dcache_l2cache_req,
    input       dcache_l2cache_wr,  //0-read 1-write
    input       [3:0]dcache_l2cache_wstrb,
    output      l2cache_dcache_addrOK,
    output      l2cache_dcache_dataOK,

    //mem port(AXI bridge)
    output      [31:0]addr_l2cache_mem,
    input       [32*(1<<offset_width)-1:0]din_mem_l2cache,
    output      [32*(1<<offset_width)-1:0]dout_l2cache_mem,
    output      l2cache_mem_req,
    output      l2cache_mem_wr,//0-read 1-write
    output      [1:0]l2cache_mem_size,
    output      [3:0]l2cache_mem_wstrb,
    input       mem_l2cache_addrOK, 
    input       mem_l2cache_dataOK
);
assign l2cache_mem_size = 2'd2;

//仲裁逻辑：Dcache优先
wire [31:0]addr_l1cache_l2cache;
wire [31:0]din_l1cache_l2cache;
reg [32*(1<<L1offset_width)-1:0]dout_l2cache_l1cache;
wire [3:0]l1cache_l2cache_wstrb;
reg [1:0]from;//0-No 1-I 2-Dr 3-Dw
always @(*) begin
    if(dcache_l2cache_req)begin
        if(!dcache_l2cache_wr)from = 2'd2;
        else from = 2'd3;
    end
    else if(icache_l2cache_req)from = 2'd1;
    else from = 2'd0;
end
assign addr_l1cache_l2cache = form[1] ? addr_dcache_l2cache : addr_icache_l2cache;
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
wire [31:0]rbuf_addr,rbuf_data,rbuf_opcode;
wire [3:0]rbuf_wstrb;
wire [1:0]rbuf_from;
wire rbuf_opflag,rbuf_we;

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

    .opcode(l2cache_opcode),
    .rbuf_opcode(rbuf_opcode),

    .opflag(l2cache_opflag),
    .rbuf_opflag(rbuf_opflag),
    
    .from(from),
    .rbuf_from(rbuf_from),
        
    .wstrb(l1cache_l2cache_wstrb),
    .rbuf_wstrb(rbuf_wstrb)
);

//PLRU
wire use0,use1,use2,use3;
wire [1:0]way_sel_lru;

L2cache_lru L2cache_lru(
    .clk(clk),
    .use0(use0),.use1(use1),.use2(use2),.use3(use3),
    .addr(rbuf_index),
    .way_sel(way_sel_lru)
);
defparam Dcache_lru.addr_width = index_width;
defparam Dcache_lru.way = way;

//Data
wire [way-1:0]Data_we;
wire [(2<<index_width)*32-1:0]data0,data1,data2,data3;
wire Data_replace;
L2cache_Data L2cache_Data(
    .clk(clk),
    
    .Data_addr_read(index),
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
defparam Dcache_Data.addr_width = index_width;
defparam Dcache_Data.data_width = (2<<index_width)*32;//单个line的长度
defparam Dcache_Data.offset_width = offset_width;
defparam Dcache_Data.way = way;

//Tag
wire [way-1:0]TagV_we,hit;
L2cache_TagV L2cache_TagV(
    .clk(clk),

    .TagV_addr_read(index),
    .TagV_din_compare(rbuf_tag),
    .hit(hit),
    
    .TagV_din_write(rbuf_tag),
    .TagV_addr_write(rbuf_index),
    .TagV_we(TagV_we)
);
defparam Dcache_TagV.addr_width = index_width;
defparam Dcache_TagV.data_width = 32-2-index_width-offset_width;
defparam Dcache_TagV.way = way;

//Dirtytable
wire Dirty,Dirtytable_set0,Dirtytable_set1;
wire [1:0]Dirtytable_way_select;
L2cache_Dirtytable L2cache_Dirtytable(
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
always @(*) begin
    if(choose_return)dout_l2cache_l1cache = din_mem_l2cache;
    else begin
        case (choose_way)
            2'd0: dout_l2cache_l1cache = data0;
            2'd1: dout_l2cache_l1cache = data1;
            2'd2: dout_l2cache_l1cache = data2;
            2'd3: dout_l2cache_l1cache = data3;
            default: dout_l2cache_l1cache = 64'h1234ABCD;
        endcase
    end
end

//Mem
assign addr_l2cache_mem = rbuf_addr;
assign dout_l2cache_mem = rbuf_data;//????

//FSM
L2cache_FSMmain L2cache_FSMmain(
    .clk(clk),.rstn(rstn)
);

endmodule
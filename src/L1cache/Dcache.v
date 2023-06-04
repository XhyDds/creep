`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 19:06:47
// Design Name: 
// Module Name: Dcache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Dcache#(
    parameter   index_width=4,
                offset_width=2,
                way=2
)
//写直达 非写分配 暂定延迟一周期出
//读 无论byte还是字都返回一个字，外部解决存入一个byte
//写 根据外部生成的wstrb决定 一个字则生成4'b1111，单byte存入则生成一位的1即可，并且传入的byte放在字对应的八位处，以字传入
//也支持同时修改多个byte
(  
    input       clk,rstn,
    output      [31:0]test1,test2,test3,

    //pipeline port
    input       [31:0]addr_pipeline_dcache,
    input       [31:0]din_pipeline_dcache,
    output      [31:0]dout_dcache_pipeline,
    input       type_pipeline_dcache,//0-read 1-write

    input       pipeline_dcache_vaild,
    output      dcache_pipeline_ready,
    
    input       [3:0]pipeline_dcache_wstrb,//字节处理位
    input       [31:0]pipeline_dcache_opcode,//cache操作
    input       pipeline_dcache_opflag,//0-正常访存 1-cache操作    
    input       [31:0]pipeline_dcache_ctrl,//stall flush branch ...
    output      dcache_pipeline_stall,//stall from dcache     不知道可不可以用ready代替，先留着

    //mem port
    output      [31:0]addr_dcache_mem,
    output      [31:0]dout_dcache_mem,
    input       [32*(2<<offset_width)-1:0]din_mem_dcache,

    output      dcache_mem_req,
    output      dcache_mem_wr,//0-read 1-write
    output      [1:0]dcache_mem_size,//0-1byte  1-2b    2-4b
    output      [3:0]dcache_mem_wstrb,//字节写使能
    input       mem_dcache_addrOK,
    input       mem_dcache_dataOK
    );
assign test1=0;
assign test2=0;
assign test3=0;

wire [offset_width-1:0]offset;
wire [index_width-1:0]index;
wire [32-offset_width-index_width-2-1:0]tag;
assign offset = addr_pipeline_dcache[offset_width+1:2];
assign index = addr_pipeline_dcache[offset_width+index_width+1:offset_width+2];
assign tag = addr_pipeline_dcache[31:offset_width+index_width+2];

//rquest buffer
wire [31:0]rbuf_addr,rbuf_data,rbuf_opcode;
wire rbuf_opflag,rbuf_type,rbuf_we;
wire [3:0]rbuf_wstrb;
wire [offset_width-1:0]rbuf_offset;
wire [index_width-1:0]rbuf_index;
wire [32-offset_width-index_width-2-1:0]rbuf_tag;
assign rbuf_offset = rbuf_addr[offset_width+1:2];
assign rbuf_index = rbuf_addr[offset_width+index_width+1:offset_width+2];
assign rbuf_tag = rbuf_addr[31:offset_width+index_width+2];
wire fStall_outside=pipeline_dcache_ctrl[0];//dcache好像不需要stall？？

Dcache_rbuf Dcache_rbuf(
    .clk(clk),.rstn(rstn),
    .rbuf_we(rbuf_we),//dcache好像不需要stall？？

    .addr(addr_pipeline_dcache),
    .rbuf_addr(rbuf_addr),

    .data(din_pipeline_dcache),
    .rbuf_data(rbuf_data),

    .opcode(pipeline_dcache_opcode),
    .rbuf_opcode(rbuf_opcode),

    .opflag(pipeline_dcache_opflag),
    .rbuf_opflag(rbuf_opflag),
    
    .type(type_pipeline_dcache),
    .rbuf_type(rbuf_type),
        
    .wstrb(pipeline_dcache_wstrb),
    .rbuf_wstrb(rbuf_wstrb)
);

//LRU
wire use0,use1;
wire way_sel_lru;

Dcache_lru Dcache_lru(
    .clk(clk),
    .use0(use0),.use1(use1),
    .addr(rbuf_index),
    .way_sel(way_sel_lru)
);
defparam Dcache_lru.addr_width = index_width;
defparam Dcache_lru.way = way;

//Data
wire [way-1:0]Data_we;
wire [(2<<index_width)*32-1:0]data0,data1;
wire Data_replace;
Dcache_Data Dcache_Data(
    .clk(clk),
    
    .Data_addr_read(index),
    .Data_dout0(data0),
    .Data_dout1(data1),

    .Data_din_write(din_mem_dcache),//一整行
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
wire [way-1:0]Tag_we,hit;
Dcache_TagV Dcache_TagV(
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

//data choose
//不需要stall所以不需要锁存？？
wire choose_way,choose_return;
wire [offset_width-1:0]choose_word;
reg [31:0]data_out;
reg [32*(2<<offset_width)-1:0]data_line;
assign dout_dcache_pipeline = data_out;
always @(*) begin
    if (choose_return) data_line = din_mem_dcache;
    else begin
        if (!choose_way) data_line = data0;
        else data_line = data1;
    end
end
always @(*) begin
    case (choose_word[1:0])
        2'b00: data_out = data_line[31:0];
        2'b01: data_out = data_line[63:32];
        2'b10: data_out = data_line[95:64];
        2'b11: data_out = data_line[127:96];
        default: data_out = 32'h1234ABCD;
    endcase
end

//Mem
assign addr_dcache_mem = rbuf_addr;
assign dout_dcache_mem = rbuf_data;


//FSM
Dcache_FSMmain Dcache_FSMmain1(

    .clk(clk),.rstn(rstn),

    //pipeline  dcache
    .pipeline_dcache_vaild(pipeline_dcache_vaild),
    .dcache_pipeline_ready(dcache_pipeline_ready),
    .pipeline_dcache_wstrb(pipeline_dcache_wstrb),
    .pipeline_dcache_opcode(pipeline_dcache_opcode),
    .pipeline_dcache_opflag(pipeline_dcache_opflag),
    .pipeline_dcache_ctrl(pipeline_dcache_ctrl),
    .dcache_pipeline_stall(dcache_pipeline_stall),

    //dcache  mem
    .dcache_mem_req(dcache_mem_req),
    .dcache_mem_wr(dcache_mem_wr),
    .dcache_mem_size(dcache_mem_size),
    .dcache_mem_wstrb(dcache_mem_wstrb),
    .mem_dcache_addrOK(mem_dcache_addrOK),
    .mem_dcache_dataOK(mem_dcache_dataOK),

    //request buffer
    .FSM_rbuf_we(rbuf_we),
    .FSM_rbuf_opcode(rbuf_opcode),
    .FSM_rbuf_opflag(rbuf_opflag),
    .FSM_rbuf_addr(rbuf_addr),
    .FSM_rbuf_type(rbuf_type),
    .FSM_rbuf_wstrb(rbuf_wstrb),
    
    //lru
    .FSM_use0(use0),
    .FSM_use1(use1),
    .FSM_wal_sel_lru(way_sel_lru),

    //Data and TagV
    .FSM_hit(hit),
    .FSM_Data_we(Data_we),
    .FSM_Data_replace(Data_replace),//为1时替换整行，否则对word操作
    .FSM_TagV_we(Tag_we),

    //data choose
    .FSM_choose_way(choose_way),
    .FSM_choose_return(choose_return),
    .FSM_choose_word(choose_word)
);
defparam Dcache_FSMmain1.index_width = index_width;
defparam Dcache_FSMmain1.offset_width = offset_width;
defparam Dcache_FSMmain1.way = way;
endmodule
//锁存出去的data，上一个周期有stall则发上一个周期锁存的data
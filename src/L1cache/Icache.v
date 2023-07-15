`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 20:48:18
// Design Name: 
// Module Name: Icache
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

// 6.4 Icache待完成任务：
// 1.tag的有效位
// 2.对于flush响应  外部寄存器flush优先级最高
module Icache#(
    parameter   index_width=4,
                offset_width=2,
                way=2
)
//写直达 非写分配 暂定延迟一周期出
(  
    input       clk,rstn,
    output      [31:0]test1,test2,test3,

    //pipeline port
    input       [31:0]addr_pipeline_icache,
    output      [63:0]dout_icache_pipeline,//双发射 [31:0]是给定地址处的指令
    output      [31:0]pc_icache_pipeline,
    output      flag_icache_pipeline,//0-后一条指令（[63:32]）无效 1-有效

    input       pipeline_icache_valid,
    output      icache_pipeline_ready,
    
    input       [31:0]pipeline_icache_opcode,//cache操作
    input       pipeline_icache_opflag,//0-正常访存 1-cache操作    
    input       [31:0]pipeline_icache_ctrl,//stall flush branch ...
    output      icache_pipeline_stall,//stall form icache     不知道可不可以用ready代替，先留着

    //mem prot
    output      [31:0]addr_icache_mem,
    input       [32*(1<<offset_width)-1:0]din_mem_icache,

    output      icache_mem_req,
    output      [1:0]icache_mem_size,//0-1byte  1-2b    2-4b
    input       mem_icache_addrOK,
    input       mem_icache_dataOK
    );
assign test1=0;
assign test2=0;
assign test3=0;

wire [offset_width-1:0]offset;
wire [index_width-1:0]index;
wire [32-offset_width-index_width-2-1:0]tag;
assign offset = addr_pipeline_icache[offset_width+1:2];
assign index = addr_pipeline_icache[offset_width+index_width+1:offset_width+2];
assign tag = addr_pipeline_icache[31:offset_width+index_width+2];

//rquest buffer
wire [31:0]rbuf_addr,rbuf_opcode;
wire rbuf_opflag,rbuf_we,rbuf_stall;
wire [offset_width-1:0]rbuf_offset;
wire [index_width-1:0]rbuf_index;
wire [32-offset_width-index_width-2-1:0]rbuf_tag;
assign rbuf_offset = rbuf_addr[offset_width+1:2];
assign rbuf_index = rbuf_addr[offset_width+index_width+1:offset_width+2];
assign rbuf_tag = rbuf_addr[31:offset_width+index_width+2];
assign rbuf_stall = pipeline_icache_ctrl[0];//icache需要stall

Icache_rbuf Icache_rbuf(
    .clk(clk),.rstn(rstn),
    .rbuf_we(rbuf_we),
    .rbuf_stall(rbuf_stall),

    .addr(addr_pipeline_icache),
    .rbuf_addr(rbuf_addr),

    .opcode(pipeline_icache_opcode),
    .rbuf_opcode(rbuf_opcode),

    .opflag(pipeline_icache_opflag),
    .rbuf_opflag(rbuf_opflag)
);
assign pc_icache_pipeline = rbuf_addr;

//LRU
wire use0,use1;
wire way_sel_lru;

Icache_lru Icache_lru(
    .clk(clk),.rstn(rstn),
    .use0(use0),.use1(use1),
    .addr(rbuf_index),
    .way_sel(way_sel_lru)
);
defparam Icache_lru.addr_width = index_width;
defparam Icache_lru.way = way;

//Data
wire [way-1:0]Data_we;
wire [(1<<offset_width)*32-1:0]data0,data1;
Icache_Data Icache_Data(
    .clk(clk),
    
    .Data_addr_read(index),
    .Data_dout0(data0),
    .Data_dout1(data1),

    .Data_din_write(din_mem_icache),//一整行
    .Data_addr_write(rbuf_index),
    .Data_we(Data_we)
);
defparam Icache_Data.addr_width = index_width;
defparam Icache_Data.data_width = (1<<offset_width)*32;//单个line的长度
defparam Icache_Data.offset_width = offset_width;
defparam Icache_Data.way = way;

//Tag
wire [way-1:0]TagV_we,hit;
Icache_TagV Icache_TagV(
    .clk(clk),.rstn(rstn),

    .TagV_addr_read(index),
    .TagV_din_compare(rbuf_tag),
    .hit(hit),
    
    .TagV_din_write(rbuf_tag),
    .TagV_addr_write(rbuf_index),
    .TagV_we(TagV_we)
);
defparam Icache_TagV.addr_width = index_width;
defparam Icache_TagV.data_width = 32-2-index_width-offset_width;
defparam Icache_TagV.way = way;

//data choose
//需要stall所以需要锁存
wire choose_way,choose_return;
wire [offset_width-1:0]choose_word;
reg [63:0]data_out;
reg data_flag;
reg [32*(1<<offset_width)-1:0]data_line;
wire send_nop;

always @(*) begin
    if (choose_return) data_line = din_mem_icache;
    else begin
        if (!choose_way) data_line = data0;
        else data_line = data1;
    end
end
always @(*) begin
    case (choose_word[1:0])
        2'b00:begin
            data_out = data_line[63:0];
            data_flag=1;
        end
        2'b01:begin
            data_out = {32'h1234ABCD,data_line[63:32]};
            data_flag=0;
        end
        2'b10:begin
            data_out = data_line[127:64];
            data_flag=1;
        end
        2'b11:begin
            data_out = {32'h1234ABCD,data_line[127:96]};
            data_flag=0;
        end
        default: data_out = 64'h1234ABCD1234ABCD;
    endcase
end
//理论输出
wire [63:0]dout1 = send_nop ? 64'h1234ABCD00000000 : data_out;
wire flag1 = send_nop ? 1'b0 : data_flag;
//锁存
reg choose_stall;
reg [63:0]data_out_reg;
reg data_flag_reg;
always @(posedge clk) begin
    data_out_reg <= dout_icache_pipeline;
    data_flag_reg <= flag_icache_pipeline;
    choose_stall <= rbuf_stall & icache_pipeline_ready;
end
assign dout_icache_pipeline = (choose_stall) ? data_out_reg : dout1;
assign flag_icache_pipeline = (choose_stall) ? data_flag_reg : flag1;

//Mem
wire [1+offset_width:0]temp;
assign temp=0;
assign addr_icache_mem = {rbuf_addr[31:2+offset_width],temp};

//FSM
Icache_FSMmain Icache_FSMmain(

    .clk(clk),.rstn(rstn),

    //pipeline  icache
    .pipeline_icache_valid(pipeline_icache_valid),
    .icache_pipeline_ready1(icache_pipeline_ready),
    .pipeline_icache_opcode(pipeline_icache_opcode),
    .pipeline_icache_opflag(pipeline_icache_opflag),
    .pipeline_icache_ctrl(pipeline_icache_ctrl),
    .icache_pipeline_stall(icache_pipeline_stall),

    //icache  mem
    .icache_mem_req(icache_mem_req),
    .icache_mem_size(icache_mem_size),
    .mem_icache_addrOK(mem_icache_addrOK),
    .mem_icache_dataOK(mem_icache_dataOK),

    //request buffer
    .FSM_rbuf_we(rbuf_we),
    .FSM_rbuf_opcode(rbuf_opcode),
    .FSM_rbuf_opflag(rbuf_opflag),
    .FSM_rbuf_addr(rbuf_addr),
    
    //lru
    .FSM_use0(use0),
    .FSM_use1(use1),
    .FSM_wal_sel_lru(way_sel_lru),

    //Data and TagV
    .FSM_hit(hit),
    .FSM_Data_we(Data_we),
    .FSM_TagV_we(TagV_we),

    //data choose
    // .FSM_choose_stall(choose_stall),
    .FSM_choose_way(choose_way),
    .FSM_choose_return(choose_return),
    .FSM_choose_word(choose_word),
    .FSM_send_nop(send_nop)
);
defparam Icache_FSMmain.index_width = index_width;
defparam Icache_FSMmain.offset_width = offset_width;
defparam Icache_FSMmain.way = way;
endmodule


`define MMU
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


//6.4 Tag会有bug valid写的行为不对 并且可以考虑offset=0

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

    //pipeline port
    input       [31:0]addr_pipeline_dcache,
    input       [31:0]paddr_pipeline_dcache,//物理地址
    input       [31:0]din_pipeline_dcache,
    input       [31:0]pcin_pipeline_dcache,
    output      [31:0]dout_dcache_pipeline,
    input       type_pipeline_dcache,//0-read 1-write
    input       SUC_pipeline_dcache,
    input       [1:0]pipeline_dcache_size,

    input       pipeline_dcache_valid,
    output      dcache_pipeline_ready,
    
    input       [3:0]pipeline_dcache_wstrb,//字节处理位
    input       [31:0]pipeline_dcache_opcode,//cache操作
    input       pipeline_dcache_opflag,//0-正常访存 1-cache操作  
    output      dcache_pipeline_doneop, 
    output      ack_op, 
    input       [31:0]pipeline_dcache_ctrl,//stall flush branch ...
    output      dcache_pipeline_stall,//stall form dcache     不知道可不可以用ready代替，先留着

    //mem prot
    output      [31:0]addr_dcache_mem,
    output      [31:0]pc_dcache_mem,
    output      [31:0]dout_dcache_mem,
    input       [32*(1<<offset_width)-1:0]din_mem_dcache,

    output      dcache_mem_req,
    output      dcache_mem_wr,//0-read 1-write
    output      dcache_mem_SUC,
    output      [1:0]dcache_mem_size,//0-1byte  1-2b    2-4b
    output      [3:0]dcache_mem_wstrb,//字节写使能
    input       mem_dcache_addrOK,
    input       mem_dcache_dataOK
    );

wire [offset_width-1:0]offset;
wire [index_width-1:0]index;
wire [index_width-1:0]index1;
wire [32-offset_width-index_width-2-1:0]tag;
assign offset = addr_pipeline_dcache[offset_width+1:2];
assign index = addr_pipeline_dcache[offset_width+index_width+1:offset_width+2];
assign index1 = tag[index_width-1:0];
assign tag = addr_pipeline_dcache[31:offset_width+index_width+2];

wire [offset_width-1:0]poffset;
wire [index_width-1:0]pindex;
wire [32-offset_width-index_width-2-1:0]ptag;
assign poffset = paddr_pipeline_dcache[offset_width+1:2];
assign pindex = paddr_pipeline_dcache[offset_width+index_width+1:offset_width+2];
assign ptag = paddr_pipeline_dcache[31:offset_width+index_width+2];

//rquest buffer
wire [31:0]rbuf_addr,rbuf_data,rbuf_opcode,rbuf_pc,rbuf_paddr;
wire rbuf_opflag,rbuf_type,rbuf_we,rbuf_SUC;
wire [1:0]rbuf_size;
wire [3:0]rbuf_wstrb;
wire [offset_width-1:0]rbuf_offset;
wire [index_width-1:0]rbuf_index;
wire [index_width-1:0]rbuf_index1;
wire [32-offset_width-index_width-2-1:0]rbuf_tag;
assign rbuf_offset = rbuf_addr[offset_width+1:2];
assign rbuf_index = rbuf_addr[offset_width+index_width+1:offset_width+2];
assign rbuf_index1 = rbuf_tag[index_width-1:0];
assign rbuf_tag = rbuf_addr[31:offset_width+index_width+2];

wire rbuf_stall = pipeline_dcache_ctrl[0];
Dcache_rbuf Dcache_rbuf(
    .clk(clk),.rstn(rstn),
    .rbuf_we(rbuf_we & ~rbuf_stall),// & ~rbuf_stall

    .pc(pcin_pipeline_dcache),
    .rbuf_pc(rbuf_pc),

    .addr(addr_pipeline_dcache),
    .rbuf_addr(rbuf_addr),

    .data(din_pipeline_dcache),
    .rbuf_data(rbuf_data),

    .opcode(pipeline_dcache_opcode),
    .rbuf_opcode(rbuf_opcode),

    .opflag(pipeline_dcache_opflag),
    .rbuf_opflag(rbuf_opflag),
    
    .type1(type_pipeline_dcache),
    .rbuf_type(rbuf_type),
        
    .wstrb(pipeline_dcache_wstrb),
    .rbuf_wstrb(rbuf_wstrb),

    .SUC(SUC_pipeline_dcache),
    .rbuf_SUC(rbuf_SUC),

    .paddr(paddr_pipeline_dcache),
    .rbuf_paddr(rbuf_paddr),

    .size(pipeline_dcache_size),
    .rbuf_size(rbuf_size)
);

//LRU
wire use0,use1;
wire way_sel_lru;

Dcache_lru #(
    .addr_width(index_width),
    .way(way)
)
Dcache_lru(
    .clk(clk),.rstn(rstn),
    .use0(use0),.use1(use1),
    .addr(rbuf_index ),//^ rbuf_index1
    .way_sel(way_sel_lru)
);

//Data
wire [way-1:0]Data_we;
wire [(1<<offset_width)*32-1:0]data0,data1;
wire Data_replace;
reg [32*(1<<offset_width)-1:0]din_reg;
Dcache_Data #(
    .addr_width(index_width),
    .data_width((1<<offset_width)*32),
    .offset_width(offset_width),
    .way(way)
)
Dcache_Data(
    .clk(clk),.rstn(rstn),
    
    .Data_addr_read(index ),//^ index1
    .Data_dout0(data0),
    .Data_dout1(data1),

    .Data_din_write(din_reg),//一整行 
    .Data_din_write_32(rbuf_data),
    .Data_addr_write(rbuf_index ),//^ rbuf_index1
    .Data_offset(rbuf_offset),
    .Data_choose_byte(rbuf_wstrb),
    .Data_we(Data_we),
    .Data_replace(Data_replace)
);

//Tag
wire [way-1:0]TagV_we,hit,TagV_unvalid;
wire [1:0]TagV_init;
Dcache_TagV #(
    .addr_width(index_width),
    .data_width(32-2-index_width-offset_width),
    .way(way)
)
Dcache_TagV(
    .clk(clk),.rstn(rstn),

    .TagV_addr_read(index ),//^ index1
    // .TagV_din_compare(tag),
    .TagV_din_compare(ptag),
    .hit(hit),
    
    .TagV_init(TagV_init),
    // .TagV_din_write(rbuf_tag),
    .TagV_din_write(ptag),
    .TagV_addr_write(rbuf_index ),//^ rbuf_index1
    .TagV_unvalid(TagV_unvalid),
    .TagV_we(TagV_we)
);

//data choose
//不需要stall所以不需要锁存？？
wire choose_way,choose_return;
wire [offset_width-1:0]choose_word = rbuf_addr[2+offset_width-1:2];
reg [31:0]data_out,data_out_reg,data_return;
reg choose_return_reg;
reg [32*(1<<offset_width)-1:0]data_line;
always @(*) begin
    if (!choose_way) data_line = data0;
    else data_line = data1;
end
always @(posedge clk) begin
    if(!rstn)begin
        din_reg <= 0;
        data_out_reg <= 0;
        choose_return_reg <= 0;
    end
    else begin
        din_reg <= din_mem_dcache;
        choose_return_reg <= choose_return;
        data_out_reg <= data_return;
    end
end
always @(*) begin
    if(rbuf_SUC)data_return = din_mem_dcache[31:0];
    else begin
        case (choose_word)
            'd0: data_return = din_mem_dcache[31:0];
            'd1: data_return = din_mem_dcache[63:32];
            'd2: data_return = din_mem_dcache[95:64];
            'd3: data_return = din_mem_dcache[127:96];
            'd4: data_return = din_mem_dcache[159:128];
            'd5: data_return = din_mem_dcache[191:160];
            'd6: data_return = din_mem_dcache[223:192];
            'd7: data_return = din_mem_dcache[255:224];
            default: data_return = 32'h1234ABCD;
        endcase
    end
end
always @(*) begin
    case (choose_word)
        'd0: data_out = data_line[31:0];
        'd1: data_out = data_line[63:32];
        'd2: data_out = data_line[95:64];
        'd3: data_out = data_line[127:96];
        'd4: data_out = data_line[159:128];
        'd5: data_out = data_line[191:160];
        'd6: data_out = data_line[223:192];
        'd7: data_out = data_line[255:224];
        default: data_out = 0;
    endcase
end

wire [31:0]dout_dcache_pipeline1;
assign dout_dcache_pipeline1 = choose_return_reg ? data_out_reg : data_out;
reg choose_stall;
reg [31:0]data_out_reg_stall;
always @(posedge clk) begin
    if(!rstn)begin
        choose_stall <= 0;
        data_out_reg_stall <= 0;
    end
    else begin
        choose_stall <= rbuf_stall & dcache_pipeline_ready;
        data_out_reg_stall <= dout_dcache_pipeline;
    end
end
assign dout_dcache_pipeline = choose_stall ? data_out_reg_stall : dout_dcache_pipeline1;

//Mem
wire [1+offset_width:0]temp;
assign temp=0;
assign dout_dcache_mem = rbuf_data;
assign dcache_mem_SUC = rbuf_SUC;
`ifdef MMU
assign addr_dcache_mem = rbuf_SUC ? rbuf_paddr : (dcache_mem_wr ? rbuf_paddr:{rbuf_paddr[31:2+offset_width],temp});
`else 
assign addr_dcache_mem = rbuf_SUC ? rbuf_addr :(dcache_mem_wr ? rbuf_addr:{rbuf_addr[31:2+offset_width],temp});
`endif
assign dcache_mem_size = rbuf_size;
assign dcache_mem_wstrb = rbuf_wstrb;
assign pc_dcache_mem = rbuf_pc;

//FSM
Dcache_FSMmain #(
    .offset_width(offset_width),
    .index_width(index_width),
    .way(way))
Dcache_FSMmain1(

    .clk(clk),.rstn(rstn),

    //pipeline  dcache
    .pipeline_dcache_valid(pipeline_dcache_valid),
    .dcache_pipeline_ready(dcache_pipeline_ready),
    .pipeline_dcache_wstrb(pipeline_dcache_wstrb),
    .pipeline_dcache_opcode(pipeline_dcache_opcode),
    .pipeline_dcache_opflag(pipeline_dcache_opflag),
    .dcache_pipeline_doneop(dcache_pipeline_doneop),
    .ack_op(ack_op),
    .pipeline_dcache_ctrl(pipeline_dcache_ctrl),
    .dcache_pipeline_stall(dcache_pipeline_stall),

    //dcache  mem
    .dcache_mem_req(dcache_mem_req),
    .dcache_mem_wr(dcache_mem_wr),
    .mem_dcache_addrOK(mem_dcache_addrOK),
    .mem_dcache_dataOK(mem_dcache_dataOK),

    //request buffer
    .FSM_rbuf_we(rbuf_we),
    .FSM_rbuf_opcode(rbuf_opcode),
    .FSM_rbuf_opflag(rbuf_opflag),
    .FSM_rbuf_addr(rbuf_addr),
    .FSM_rbuf_type(rbuf_type),
    .FSM_rbuf_wstrb(rbuf_wstrb),
    .FSM_rbuf_SUC(rbuf_SUC),

    //lru
    .FSM_use0(use0),
    .FSM_use1(use1),
    .FSM_wal_sel_lru(way_sel_lru),

    //Data and TagV
    .FSM_hit(hit),
    .FSM_Data_we(Data_we),
    .FSM_Data_replace(Data_replace),//为1时替换整行，否则对word操作
    .FSM_TagV_we(TagV_we),
    .FSM_TagV_unvalid(TagV_unvalid),
    .FSM_TagV_init(TagV_init),

    //data choose
    .FSM_choose_way(choose_way),
    .FSM_choose_return(choose_return)
);
endmodule
//锁存出去的data，上一个周期有stall则发上一个周期锁存的data
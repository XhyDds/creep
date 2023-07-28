`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 20:17:30
// Design Name: 
// Module Name: L2cache_FSMmain
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

//写回写分配
module L2cache_FSMmain#(
    parameter   index_width=8,
                offset_width=2,
                way=4
)
(
    input clk,rstn,

    //上下游信号
    input       [1:0]from,
    input       pipeline_l2cache_opflag,
    output reg  l2cache_icache_addrOK,
    output reg  l2cache_icache_dataOK,
    output reg  l2cache_dcache_addrOK,
    output reg  l2cache_dcache_dataOK,

    output reg  l2cache_mem_req_w,
    output reg  l2cache_mem_req_r,
    output reg  l2cache_mem_rdy,//准备接收读数据
    input       mem_l2cache_addrOK_w,
    input       mem_l2cache_addrOK_r,
    input       mem_l2cache_dataOK,

    //模块间信号

    //reqbuf
    output reg  FSM_rbuf_we,
    input       [1:0]FSM_rbuf_from,
    input       [31:0]FSM_rbuf_opcode,
    input       [31:0]FSM_rbuf_opaddr,
    input       FSM_rbuf_SUC,
    input       FSM_SUC,
    input       FSM_rbuf_opflag,
    
    //PLRU
    output reg  [way-1:0]FSM_use,
    input       [1:0]FSM_way_sel_d,
    input       FSM_way_sel_i,

    //Data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output reg  [way-1:0]FSM_TagV_unvalid,
    output reg  FSM_Data_replace,
    output reg  [1:0]FSM_TagV_way_select,
    output reg  FSM_Data_writeback,
    output reg  [2:0]FSM_TagV_init,

    //Dirtytable
    input       FSM_Dirty,
    output reg  [1:0]FSM_Dirtytable_way_select,
    output reg  FSM_Dirtytable_set1,FSM_Dirtytable_set0,

    //Data Choose
    output reg  [1:0]FSM_choose_way,
    output reg  FSM_choose_return
    );
wire opflag;
assign opflag=pipeline_l2cache_opflag;
reg [4:0]state;
reg [4:0]next_state;
localparam Idle=5'd0,Lookup=5'd1,Operation=5'd2,send=5'd3,replace1=5'd4,replace2=5'd5,replace_write=5'd6;
localparam checkDirty=5'd7,writeback=5'd8,SUC_w=5'd9,checkDirty1=5'd10;
always @(posedge clk,negedge rstn) begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    next_state = Idle; 
    case (state)
        Idle:begin
            if(opflag)next_state = Operation;
            else if(from)next_state = Lookup;
            else next_state = Idle;
        end 
        Lookup:begin
            if(FSM_rbuf_SUC)begin
                if(FSM_rbuf_from == 2'b11)next_state = SUC_w;
                else next_state = replace1;
            end
            else begin
                if(((!FSM_hit[0])&&(!FSM_hit[1])&&(!FSM_hit[2])&&(!FSM_hit[3])))begin
                    next_state = checkDirty;
                end
                else begin//Hit流水化
                    // if(opflag)next_state = Operation;
                    if(from)next_state = Lookup;
                    else next_state = Idle;
                end
            end
        end
        SUC_w:begin
            if(!mem_l2cache_addrOK_w)next_state = SUC_w;
            else next_state = Idle;
        end
        checkDirty:begin
            // if(FSM_Dirty)next_state = writeback;
            // else begin
            //     if(!FSM_rbuf_opflag)next_state = replace1;
            //     else next_state = Idle;
            // end
            next_state = checkDirty1;
        end
        checkDirty1:begin
            if(FSM_Dirty)next_state = writeback;
            else begin
                if(!FSM_rbuf_opflag)next_state = replace1;
                else next_state = Idle;
            end
        end
        writeback:begin
            if(!mem_l2cache_addrOK_w)next_state = writeback;
            else begin
                if(!FSM_rbuf_opflag)next_state = replace1;
                else next_state = Idle;//只需要完成脏块写回
            end
        end
        replace1:begin
            if(mem_l2cache_addrOK_r|mem_l2cache_dataOK)next_state = replace2;
            else next_state = replace1;
        end
        replace2:begin
            if(mem_l2cache_dataOK)begin
                if(FSM_rbuf_from != 2'b11 || FSM_rbuf_SUC)begin//强序读和正常读
                    next_state = Idle;
                end
                else begin
                    next_state = replace_write;
                end
            end
            else next_state = replace2;
        end
        replace_write:begin
            next_state = Idle;
        end
        Operation:begin
            if(FSM_rbuf_opcode[4:3] == 2'd0)begin//Tag、valid置零
                next_state = Idle;
            end
            else if(FSM_rbuf_opcode[4:3] == 2'd1)begin//valid置零并写回
                next_state = checkDirty;
            end
            else if(FSM_rbuf_opcode[4:3] == 2'd2)begin//先命中，其他同二
                if((!FSM_hit[0])&&(!FSM_hit[1])&&(!FSM_hit[2])&&(!FSM_hit[3]))next_state = Idle;
                else next_state = checkDirty;
            end
        end
    endcase
end
reg [1:0]FSM_way_sel_d_reg;
always @(posedge clk) begin
    FSM_way_sel_d_reg <= FSM_way_sel_d;
end
reg hit_record_we;
reg [1:0]hit_record;
always @(posedge clk) begin
    if(hit_record_we)begin
        if(FSM_hit[0])hit_record <= 2'b00;
        else if(FSM_hit[1])hit_record <= 2'b01;
        else if(FSM_hit[2])hit_record <= 2'b10;
        else if(FSM_hit[3])hit_record <= 2'b11;
        else hit_record <= 2'b00;
    end
end
always @(*) begin
    l2cache_icache_addrOK = 0;
    l2cache_icache_dataOK = 0;
    l2cache_dcache_addrOK = 0;
    l2cache_dcache_dataOK = 0;
    l2cache_mem_req_w = 0;
    l2cache_mem_req_r = 0;
    l2cache_mem_rdy = 0;
    FSM_TagV_way_select = 0;
    FSM_rbuf_we = 0;
    FSM_use = 0;
    FSM_Data_we = 0;
    FSM_Data_replace = 0;
    FSM_Data_writeback = 0;
    FSM_Dirtytable_way_select = 0;
    FSM_Dirtytable_set0 = 0;
    FSM_Dirtytable_set1 = 0;
    FSM_choose_way = 0;
    FSM_choose_return = 0;
    FSM_TagV_init = 0;
    hit_record_we = 0;
    FSM_TagV_unvalid = 0;
    case (state)//如果强序，如果脏了先不处理，直接置无效
        Idle:begin
            FSM_rbuf_we = 1;
            if(from[1])begin
                if(~from[0])l2cache_dcache_addrOK = 1;
                else l2cache_dcache_addrOK = ~ FSM_SUC;//强序写时先不发addrOK
            end
            else if(from == 2'b01)begin
                l2cache_icache_addrOK = 1;
            end
        end
        Operation:begin
            if(FSM_rbuf_opcode[4:3] == 2'd0)begin//Tag、valid置零
                FSM_TagV_init = {1'b1,FSM_rbuf_opaddr[1:0]};
            end
            else if(FSM_rbuf_opcode[4:3] == 2'd1)begin
                if(FSM_rbuf_opaddr[1:0] == 2'd0)FSM_TagV_unvalid = 4'b0001;
                else if(FSM_rbuf_opaddr[1:0] == 2'd1)FSM_TagV_unvalid = 4'b0010;
                else if(FSM_rbuf_opaddr[1:0] == 2'd2)FSM_TagV_unvalid = 4'b0100;
                else FSM_TagV_unvalid = 4'b1000;
            end
            else if(FSM_rbuf_opcode[4:3] == 2'd2)begin
                hit_record_we = 1;
                if(FSM_hit[0])FSM_TagV_unvalid = 4'b0001;
                else if(FSM_hit[1])FSM_TagV_unvalid = 4'b0010;
                else if(FSM_hit[2])FSM_TagV_unvalid = 4'b0100;
                else if(FSM_hit[3])FSM_TagV_unvalid = 4'b1000;
                else FSM_TagV_unvalid = 4'b0000;
            end
        end
        SUC_w:begin
            l2cache_mem_req_w = 1;
            if(next_state == Idle)l2cache_dcache_addrOK = 1;//实际写入后发addrOK
        end
        Lookup:begin
            if(FSM_hit[0] || FSM_hit[1] || FSM_hit[2] || FSM_hit[3])begin
                if(FSM_rbuf_from == 2'b01 || FSM_rbuf_from == 2'b10)begin//读命中
                    if(FSM_hit[0])begin
                        FSM_use[0] = 1;
                        FSM_choose_way = 2'd0;
                    end
                    else if(FSM_hit[1])begin
                        FSM_use[1] = 1;
                        FSM_choose_way = 2'd1;
                    end
                    else if(FSM_hit[2])begin
                        FSM_use[2] = 1;
                        FSM_choose_way = 2'd2;
                    end
                    else if(FSM_hit[3])begin
                        FSM_use[3] = 1;
                        FSM_choose_way = 2'd3;
                    end
                    if(FSM_rbuf_from[1])l2cache_dcache_dataOK =1;
                    else l2cache_icache_dataOK = 1;
                end
                else begin//写命中
                    if(FSM_hit[0])begin
                        FSM_use[0] = 1;
                        FSM_Data_we[0] = 1;
                        FSM_Dirtytable_way_select = 2'd0;
                        FSM_Dirtytable_set1 = 1;
                    end
                    else if(FSM_hit[1])begin
                        FSM_use[1] = 1;
                        FSM_Data_we[1] = 1;
                        FSM_Dirtytable_way_select = 2'd1;
                        FSM_Dirtytable_set1 = 1;
                    end
                    else if(FSM_hit[2])begin
                        FSM_use[2] = 1;
                        FSM_Data_we[2] = 1;
                        FSM_Dirtytable_way_select = 2'd2;
                        FSM_Dirtytable_set1 = 1;
                    end
                    else if(FSM_hit[3])begin
                        FSM_use[3] = 1;
                        FSM_Data_we[3] = 1;
                        FSM_Dirtytable_way_select = 2'd3;
                        FSM_Dirtytable_set1 = 1;
                    end
                end
                if(next_state == Lookup)begin
                    if(from[1])begin
                        if(~from[0])l2cache_dcache_addrOK = 1;
                        else l2cache_dcache_addrOK = ~ FSM_SUC;//强序写时先不发addrOK
                        FSM_rbuf_we = 1;
                    end
                    else if(from == 2'b01)begin
                        l2cache_icache_addrOK = 1;
                        FSM_rbuf_we = 1;
                    end
                end
            end
        end
        checkDirty:begin
            if(!FSM_rbuf_opflag)begin
                if(FSM_rbuf_from == 2'b01)FSM_Dirtytable_way_select = {1'b0,FSM_way_sel_i};
                else FSM_Dirtytable_way_select = FSM_way_sel_d;
            end
            else begin
                if(FSM_rbuf_opcode[4:3] == 2'd1)FSM_Dirtytable_way_select = FSM_rbuf_opaddr[1:0];
                else if(FSM_rbuf_opcode[4:3] == 2'd2)FSM_Dirtytable_way_select = hit_record;
            end
            // if(FSM_Dirty)FSM_Data_writeback = 1;
        end
        checkDirty1:begin
            if(FSM_Dirty)FSM_Data_writeback = 1;
        end
        writeback:begin
            // l2cache_mem_req_r = 1;   //串行并行
            if(next_state == writeback)FSM_Data_writeback = 1;//用rbuf_index读tag
            else FSM_Data_writeback = 0;
            l2cache_mem_req_w = 1;
            if(!FSM_rbuf_opflag)begin
                if(FSM_rbuf_from == 2'b01)begin
                    FSM_choose_way = {1'b0,FSM_way_sel_i};//选择写数据
                    FSM_TagV_way_select = {1'b0,FSM_way_sel_i};//选择写地址
                end
                else begin
                    FSM_choose_way = FSM_way_sel_d;
                    FSM_TagV_way_select = FSM_way_sel_d;
                end
            end
            else begin
                if(FSM_rbuf_opcode[4:3] == 2'd1)begin
                    FSM_choose_way = FSM_rbuf_opaddr[1:0];
                    FSM_TagV_way_select = FSM_rbuf_opaddr[1:0];
                end
                else if(FSM_rbuf_opcode[4:3] == 2'd2)begin
                    FSM_choose_way = hit_record;
                    FSM_TagV_way_select = hit_record;
                end
            end
        end
        replace1:begin
            l2cache_mem_req_r = 1;
        end
        replace2:begin
            l2cache_mem_rdy = 1;
            if(mem_l2cache_dataOK)begin             
                FSM_choose_return = 1;
                if(!FSM_rbuf_SUC)begin
                    FSM_Data_replace = 1;//写一个块
                    if(FSM_rbuf_from == 2'b01)begin//i-r
                        FSM_rbuf_we = 1;
                        l2cache_icache_dataOK = 1;
                        FSM_use[{1'b0,FSM_way_sel_i}] = 1;
                        FSM_Data_we[{1'b0,FSM_way_sel_i}] = 1;
                        FSM_Dirtytable_way_select = {1'b0,FSM_way_sel_i};
                        FSM_Dirtytable_set0 = 1;
                    end
                    else if(FSM_rbuf_from == 2'b10)begin//d-r
                        FSM_rbuf_we = 1;
                        l2cache_dcache_dataOK = 1;
                        FSM_use[FSM_way_sel_d] = 1;
                        FSM_Data_we[FSM_way_sel_d] = 1;
                        FSM_Dirtytable_way_select = FSM_way_sel_d;
                        FSM_Dirtytable_set0 = 1;
                    end
                    else begin//d-w
                        // FSM_use[FSM_way_sel_d] = 1;//还不能发use给lru单元
                        FSM_Data_we[FSM_way_sel_d] = 1;
                    end 
                end
                else begin
                    if(FSM_rbuf_from == 2'b01)begin
                        FSM_rbuf_we = 1;
                        l2cache_icache_dataOK = 1;
                    end
                    else if(FSM_rbuf_from == 2'b10)begin
                        FSM_rbuf_we = 1;
                        l2cache_dcache_dataOK = 1;
                    end
                end
            end
        end
        replace_write:begin//写一个字  用上一个周期的FSM_way_sel_d  上一次写会改变vaild
            if(next_state != Idle)FSM_rbuf_we = 1;
            FSM_Data_we[FSM_way_sel_d_reg] = 1;
            FSM_use[FSM_way_sel_d_reg] = 1;
            FSM_Dirtytable_way_select = FSM_way_sel_d_reg;
            FSM_Dirtytable_set1 = 1;
        end
        default:begin
            
        end
    endcase
end
endmodule
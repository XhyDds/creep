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
                way=8
)
(
    input clk,rstn,

    //上下游信号
    input       [1:0]from,
    input       pipeline_l2cache_opflag,
    output reg  ack_op,
    output reg  l2cache_icache_addrOK,
    output reg  l2cache_icache_dataOK,
    input       icache_l2cache_flush,
    output reg  l2cache_dcache_addrOK,
    output reg  l2cache_dcache_dataOK,

    output reg  l2cache_mem_req_w,
    output reg  l2cache_mem_req_r,
    output reg  l2cache_mem_rdy,//准备接收读数据
    input       mem_l2cache_addrOK_w,
    input       mem_l2cache_addrOK_r,
    input       mem_l2cache_dataOK,

    //L2-prefetch port
    input       req_pref_l2cache,
    output reg  hit_l2cache_pref,
    output reg  miss_l2cache_pref,
    output reg  addrOK_l2cache_pref,
    output reg  complete_l2cache_pref,
    output reg  missvalid,

    //模块间信号

    //reqbuf
    output reg  FSM_rbuf_we,
    input       [1:0]FSM_rbuf_from,
    input       [31:0]FSM_rbuf_opcode,
    input       [31:0]FSM_rbuf_opaddr,
    input       FSM_rbuf_SUC,
    input       FSM_rbuf_opflag,
    input       [1:0]FSM_from_pref,
    input       FSM_rbuf_pref_type,
    input       FSM_SUC_pref,

    input       FSM_SUC,
    input       FSM_dSUC,
    input       FSM_dcache_req,
    input       FSM_dcache_wr,
    input       FSM_icache_req,

    output reg  we_wbaddr,
    
    //PLRU
    output reg  [way-1:0]FSM_use,
    input       [2:0]FSM_way_sel_d,
    input       [1:0]FSM_way_sel_i,

    //Data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output reg  [way-1:0]FSM_TagV_unvalid,
    output reg  FSM_Data_replace,
    output reg  [2:0]FSM_TagV_way_select,
    output reg  FSM_Data_writeback,
    output reg  [3:0]FSM_TagV_init,

    //Dirtytable
    input       FSM_Dirty,
    output reg  [2:0]FSM_Dirtytable_way_select,
    output reg  FSM_Dirtytable_set1,FSM_Dirtytable_set0,

    //Data Choose
    output reg  FSM_inpref,
    output reg  [2:0]FSM_choose_way,
    output reg  FSM_choose_return
    );
wire opflag=pipeline_l2cache_opflag;
wire Hit = |FSM_hit;
reg [4:0]state;
reg [4:0]next_state;
reg flush;
always @(posedge clk) begin
    flush <= icache_l2cache_flush;//迟一个周期撤销
end
reg FSM_rbuf_prefetch;
reg inpref,outpref;
always @(posedge clk) begin
    if(inpref)FSM_rbuf_prefetch <= 1;
    else if(outpref)FSM_rbuf_prefetch <= 0;
end
localparam Idle=5'd0,Lookup=5'd1,Operation=5'd2,send=5'd3,replace1=5'd4,replace2=5'd5,replace_write=5'd6;
localparam checkDirty=5'd7,writeback=5'd8,SUC_w=5'd9,checkDirty1=5'd10,SUC_w1=5'd11;
localparam prefetch_check=5'd12,prefetch_wait=5'd13,prefetch_wait_miss=5'd14;
localparam replace_write1=5'd15;
always @(posedge clk)begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    next_state = 0; 
    case (state)
        Idle:begin
            if(opflag)next_state = Operation;
            else if(from)next_state = Lookup;
            else if(req_pref_l2cache)next_state = prefetch_check;
            else next_state = Idle;
        end 
        prefetch_check:begin
            if(Hit)next_state = Idle;
            else next_state = checkDirty;
        end
        prefetch_wait:begin
            if(mem_l2cache_dataOK)next_state = Idle;
            else if((~Hit&&FSM_from_pref) || FSM_SUC_pref)next_state = prefetch_wait_miss;
            else next_state = prefetch_wait;
        end
        prefetch_wait_miss:begin
            if(mem_l2cache_dataOK)next_state = Idle;
            else next_state = prefetch_wait_miss;
        end
        Lookup:begin
            if(flush && FSM_rbuf_from == 2'b01)next_state = Idle;
            else if(FSM_rbuf_SUC)begin
                if(FSM_rbuf_from == 2'b11)next_state = SUC_w;
                else next_state = replace1;
            end
            else begin
                if(~Hit)next_state = checkDirty;
                else begin
                    next_state = Idle;
                end
            end
        end
        SUC_w:begin
            if(!mem_l2cache_addrOK_w)next_state = SUC_w;
            else next_state = SUC_w1;
        end
        SUC_w1:begin
            next_state = Idle;
        end
        checkDirty:begin
            next_state = checkDirty1;
        end
        checkDirty1:begin
            // if(FSM_rbuf_prefetch)begin
            //     if(FSM_Dirty)next_state = Idle;//拒绝
            //     else next_state = prefetch_wait;
            // end
            // else begin//
                if(FSM_Dirty)begin
                    next_state = writeback;
                end
                else begin
                    if(FSM_rbuf_prefetch)next_state = prefetch_wait;
                    else if(!FSM_rbuf_opflag)next_state = replace1;
                    else next_state = Idle;
                end
            // end
        end
        writeback:begin
            if(!mem_l2cache_addrOK_w)next_state = writeback;
            else begin
                if(FSM_rbuf_prefetch)next_state = prefetch_wait;
                else if(!FSM_rbuf_opflag)next_state = replace1;
                else next_state = Idle;//只需要完成脏块写回
            end
        end
        replace1:begin
            // if(FSM_rbuf_prefetch)next_state = prefetch_wait;
            if(mem_l2cache_addrOK_r)next_state = replace2;
            else next_state = replace1;
        end
        replace2:begin
            if(mem_l2cache_dataOK)begin
                if(FSM_rbuf_from != 2'b11 || FSM_rbuf_SUC)begin//强序读和正常读
                    next_state = Idle;
                end
                else begin//非强序写
                    next_state = replace_write1;
                end
            end
            else next_state = replace2;
        end
        replace_write1:begin
            next_state = replace_write;
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
                if(~Hit)next_state = Idle;
                else next_state = checkDirty;
            end
        end
        default:next_state = Idle;
    endcase
end
reg [2:0]sel;
reg we_sel;
always @(posedge clk) begin
    if(we_sel)begin
        sel <= FSM_Dirtytable_way_select;
    end
end
reg hit_record_we;
reg [2:0]hit_record;
reg [2:0]hit_pos;
always @(*) begin
    if(FSM_hit[0])hit_pos = 3'd0;
    else if(FSM_hit[1])hit_pos = 3'd1;
    else if(FSM_hit[2])hit_pos = 3'd2;
    else if(FSM_hit[3])hit_pos = 3'd3;
    else if(FSM_hit[4])hit_pos = 3'd4;
    else if(FSM_hit[5])hit_pos = 3'd5;
    else if(FSM_hit[6])hit_pos = 3'd6;
    else if(FSM_hit[7])hit_pos = 3'd7;
    else hit_pos = 3'd0;
end
always @(posedge clk) begin
    if(hit_record_we)begin
        hit_record <= hit_pos;
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
    ack_op = 0;
    hit_l2cache_pref = 0;
    complete_l2cache_pref = 0;
    addrOK_l2cache_pref = 0;
    FSM_inpref = 0;
    miss_l2cache_pref = 0;
    we_sel = 0;
    inpref = 0;
    outpref = 0;
    missvalid = 0;
    we_wbaddr = 0;
    case (state)//如果强序，如果脏了先不处理，直接置无效
        Idle:begin
            FSM_rbuf_we = 1;
            if(FSM_dcache_req)begin
                if(!FSM_dcache_wr)l2cache_dcache_addrOK = 1;//读请求
                else l2cache_dcache_addrOK = ~ FSM_dSUC;//强序写时先不发addrOK
            end
            else if(FSM_icache_req)begin
                l2cache_icache_addrOK = 1;
            end
        end
        Operation:begin
            ack_op = 1;
            if(FSM_rbuf_opcode[4:3] == 2'd0)begin//Tag、valid置零
                FSM_TagV_init = {1'b1,FSM_rbuf_opaddr[2:0]};
            end
            else if(FSM_rbuf_opcode[4:3] == 2'd1)begin
                if(FSM_rbuf_opaddr[2:0] == 3'd0)FSM_TagV_unvalid = 8'b00000001;
                else if(FSM_rbuf_opaddr[2:0] == 3'd1)FSM_TagV_unvalid = 8'b00000010;
                else if(FSM_rbuf_opaddr[2:0] == 3'd2)FSM_TagV_unvalid = 8'b00000100;
                else if(FSM_rbuf_opaddr[2:0] == 3'd3)FSM_TagV_unvalid = 8'b00001000;
                else if(FSM_rbuf_opaddr[2:0] == 3'd4)FSM_TagV_unvalid = 8'b00010000;
                else if(FSM_rbuf_opaddr[2:0] == 3'd5)FSM_TagV_unvalid = 8'b00100000;
                else if(FSM_rbuf_opaddr[2:0] == 3'd6)FSM_TagV_unvalid = 8'b01000000;
                else if(FSM_rbuf_opaddr[2:0] == 3'd7)FSM_TagV_unvalid = 8'b10000000;
            end
            else if(FSM_rbuf_opcode[4:3] == 2'd2)begin
                hit_record_we = 1;
                if(FSM_hit[0])FSM_TagV_unvalid = 8'b00000001;
                else if(FSM_hit[1])FSM_TagV_unvalid = 8'b00000010;
                else if(FSM_hit[2])FSM_TagV_unvalid = 8'b00000100;
                else if(FSM_hit[3])FSM_TagV_unvalid = 8'b00001000;
                else if(FSM_hit[4])FSM_TagV_unvalid = 8'b00010000;
                else if(FSM_hit[5])FSM_TagV_unvalid = 8'b00100000;
                else if(FSM_hit[6])FSM_TagV_unvalid = 8'b01000000;
                else if(FSM_hit[7])FSM_TagV_unvalid = 8'b10000000;
            end
        end
        prefetch_check:begin
            addrOK_l2cache_pref = 1;
            if(Hit)begin
                hit_l2cache_pref = 1;
                complete_l2cache_pref = 1;
            end
            else begin
                inpref = 1;
            end
        end
        prefetch_wait:begin//wait and req for l1
            l2cache_mem_req_r = 1;
            l2cache_mem_rdy = 1;
            if(mem_l2cache_dataOK)begin
                complete_l2cache_pref = 1;
                outpref = 1;
                miss_l2cache_pref = 0;
                FSM_Data_replace = 1;
                FSM_use[sel] = 1;
                FSM_Data_we[sel] = 1;
                FSM_Dirtytable_way_select = sel;
                FSM_Dirtytable_set0 = 1;
            end
            else begin//req for L1
                FSM_inpref = 1;
                if(Hit && ! FSM_SUC_pref)begin
                    if(FSM_from_pref == 2'b01 || FSM_from_pref == 2'b10)begin
                        FSM_choose_way = hit_pos;
                        if(FSM_from_pref[1])l2cache_dcache_dataOK =1;
                        else l2cache_icache_dataOK = 1;
                    end
                    else if(FSM_from_pref == 2'b11)begin
                        l2cache_dcache_addrOK = 1;
                        FSM_Dirtytable_set1 = 1;
                        FSM_use[hit_pos] = 1;
                        FSM_Data_we[hit_pos] = 1;
                        FSM_Dirtytable_way_select = hit_pos;
                    end
                end
            end
        end
        prefetch_wait_miss:begin
            l2cache_mem_req_r = 1;
            l2cache_mem_rdy = 1;
            if(mem_l2cache_dataOK)begin
                outpref = 1;
                complete_l2cache_pref = 1;
                miss_l2cache_pref = 1;
                FSM_Data_replace = 1;
                FSM_use[sel] = 1;
                FSM_Data_we[sel] = 1;
                FSM_Dirtytable_way_select = sel;
                FSM_Dirtytable_set0 = 1;
            end
        end
        SUC_w:begin
            l2cache_mem_req_w = 1;
        end
        SUC_w1:begin
            l2cache_dcache_addrOK = 1;//实际写入后发addrOK
        end
        Lookup:begin
            missvalid = ~Hit;
            if(!(FSM_rbuf_from == 2'b01 && flush) && !FSM_rbuf_SUC)begin
            if(Hit)begin
                if(FSM_rbuf_from == 2'b01 || FSM_rbuf_from == 2'b10)begin//读命中
                    FSM_use[hit_pos] = 1;
                    FSM_choose_way = hit_pos;
                    if(FSM_rbuf_from[1])l2cache_dcache_dataOK =1;
                    else l2cache_icache_dataOK = 1;
                end
                else begin//写命中
                    FSM_Dirtytable_set1 = 1;
                    FSM_use[hit_pos] = 1;
                    FSM_Data_we[hit_pos] = 1;
                    FSM_Dirtytable_way_select = hit_pos;
                end
            end
            end
        end
        checkDirty:begin
            we_sel = 1;//记录这个周期的wal_sel
            if(!FSM_rbuf_opflag)begin
                if(~FSM_rbuf_prefetch)begin
                    if(FSM_rbuf_from == 2'b01)FSM_Dirtytable_way_select = {1'b0,FSM_way_sel_i};
                    else FSM_Dirtytable_way_select = FSM_way_sel_d;
                end
                else begin
                    if(~FSM_rbuf_pref_type)FSM_Dirtytable_way_select = {1'b0,FSM_way_sel_i};
                    else FSM_Dirtytable_way_select = FSM_way_sel_d;
                end
            end
            else begin
                if(FSM_rbuf_opcode[4:3] == 2'd1)FSM_Dirtytable_way_select = FSM_rbuf_opaddr[2:0];
                else if(FSM_rbuf_opcode[4:3] == 2'd2)FSM_Dirtytable_way_select = hit_record;
            end
        end
        checkDirty1:begin
            if(FSM_Dirty)begin
                FSM_Data_writeback = 1;
            end
        end
        writeback:begin
            if(next_state == writeback)FSM_Data_writeback = 1;//用rbuf_index读tag
            l2cache_mem_req_w = 1;
            FSM_choose_way = sel;
            FSM_TagV_way_select = sel;
            we_wbaddr = 1;
            // if(sel == 3'd0)FSM_TagV_unvalid = 8'b00000001;
            // else if(sel == 3'd1)FSM_TagV_unvalid = 8'b00000010;
            // else if(sel == 3'd2)FSM_TagV_unvalid = 8'b00000100;
            // else if(sel == 3'd3)FSM_TagV_unvalid = 8'b00001000;
            // else if(sel == 3'd4)FSM_TagV_unvalid = 8'b00010000;
            // else if(sel == 3'd5)FSM_TagV_unvalid = 8'b00100000;
            // else if(sel == 3'd6)FSM_TagV_unvalid = 8'b01000000;
            // else if(sel == 3'd7)FSM_TagV_unvalid = 8'b10000000;
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
                    FSM_use[sel] = 1;
                    FSM_Data_we[sel] = 1;
                    FSM_Dirtytable_way_select = sel;
                    if(FSM_rbuf_from == 2'b01)begin//i-r
                        l2cache_icache_dataOK = 1;
                        FSM_Dirtytable_set0 = 1;
                    end
                    else if(FSM_rbuf_from == 2'b10)begin//d-r
                        l2cache_dcache_dataOK = 1;
                        FSM_Dirtytable_set0 = 1;
                    end
                    else begin//d-w
                        FSM_Dirtytable_set1 = 1;
                    end 
                end
                else begin
                    if(FSM_rbuf_from == 2'b01)l2cache_icache_dataOK = 1;
                    else if(FSM_rbuf_from == 2'b10)l2cache_dcache_dataOK = 1;
                end
            end
        end
        replace_write1:begin
            
        end
        replace_write:begin
            FSM_Data_we[sel] = 1;
            FSM_use[sel] = 1;
        end
        default:;
    endcase
end
endmodule

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
    input       l2cache_opflag,
    output reg  l2cache_icache_addrOK,
    output reg  l2cache_icache_dataOK,
    output reg  l2cache_dcache_addrOK,
    output reg  l2cache_dcache_dataOK,

    output reg  l2cache_mem_req,
    output reg  l2cache_mem_wr,
    input       mem_l2cache_addrOK,
    input       mem_l2cache_dataOK,

    //模块间信号

    //reqbuf
    output reg  FSM_rbuf_we,
    input       [1:0]FSM_rbuf_from,
    input       [31:0]FSM_rbuf_opcode,
    
    //PLRU
    output reg  FSM_use0,FSM_use1,FSM_use2,FSM_use3,
    input       [1:0]FSM_wal_sel_lru,

    //Data TagV
    input       [way-1:0]FSM_hit,
    output reg  [way-1:0]FSM_Data_we,
    output reg  FSM_Data_replace,

    //Dirtytable
    input       FSM_Dirty,
    output reg  [1:0]FSM_Dirtytable_way_select,
    output reg  FSM_Dirtytable_set1,FSM_Dirtytable_set0,

    //Data Choose
    output reg  FSM_choose_way,
    output reg  FSM_choose_return
    );
wire hit0,hit1,hit2,hit3;
assign hit0=FSM_hit[0];
assign hit1=FSM_hit[1];
assign hit2=FSM_hit[2];
assign hit3=FSM_hit[3];
wire opflag;
assign opflag=l2cache_opflag;

reg [4:0]state;
reg [4:0]next_state;
localparam Idle=5'd0,Lookup=5'd1,Operation=5'd2,send=5'd3,replace1=5'd4,replace2=5'd5;
always @(posedge clk,negedge rstn) begin
    if(!rstn)state<=0;
    else state<=next_state;
end
always @(*) begin
    case (state)
        Idle:begin
            if(opflag)next_state = Operation;
            else if(!from)next_state = Lookup;
            else next_state = Idle;
        end 
        Lookup:begin
            if((!hit0)&&(!hit1)&&(!hit2)&&(!hit3))begin
                next_state = replace1;
            end
            else begin
                if(opflag)next_state = Operation;
                else if(!from)next_state = Lookup;
                else next_state = Idle;
            end
        end
        Replace1:begin
            if(!)
        end
        default: 
    endcase
end
endmodule

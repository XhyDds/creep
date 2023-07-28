//尚未完成
module ex_buffer#(
    parameter length = 4
            // ,DATA_WIDTH=98
)(
    input clk,
    input rstn,
    input flag, //0:两条指令输入  1:一条指令输入
    input stall,
    // input  [DATA_WIDTH-1:0] in_data_0,
    input        in_taken_pdc_0,   //优先
    input [2:0]  in_kind_pdc_0 ,
    input [29:0] in_npc_pdc_0  ,
    input [1:0]  in_choice_pdc_0,
    input        in_taken_ex_0 ,
    input [2:0]  in_kind_ex_0  ,
    input [29:0] in_npc_ex_0   ,
    input [29:0] in_pc_ex_0    ,
    // input  [DATA_WIDTH-1:0] in_data_1,
    input        in_taken_pdc_1,
    input [2:0]  in_kind_pdc_1 ,
    input [29:0] in_npc_pdc_1  ,
    input [1:0]  in_choice_pdc_1,
    input        in_taken_ex_1 ,
    input [2:0]  in_kind_ex_1  ,
    input [29:0] in_npc_ex_1   ,
    input [29:0] in_pc_ex_1    ,
    // output [DATA_WIDTH-1:0] out_data,
    output reg          out_taken_pdc ,
    output reg   [2:0]  out_kind_pdc  ,
    output reg   [29:0] out_npc_pdc   ,
    output reg          out_taken_ex  ,
    output reg   [2:0]  out_kind_ex   ,
    output reg   [29:0] out_npc_ex    ,
    output reg   [29:0] out_pc_ex     ,
    output reg   [1:0]  out_choice_pdc,

    output reg   update_en
);
    localparam NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,CALL = 3'd2,RET = 3'd3,INDIRECT_JUMP = 3'd4,OTHER_JUMP = 3'd5;

    wire [99:0] in_data_0={in_choice_pdc_0,in_pc_ex_0,in_npc_ex_0,in_kind_ex_0,in_taken_ex_0,in_npc_pdc_0,in_kind_pdc_0,in_taken_pdc_0};
    wire [99:0] in_data_1={in_choice_pdc_1,in_pc_ex_1,in_npc_ex_1,in_kind_ex_1,in_taken_ex_1,in_npc_pdc_1,in_kind_pdc_1,in_taken_pdc_1};

    reg [99:0] out_data_0;
    reg [99:0] out_data_1;

    wire        out_taken_pdc_0;
    wire [2:0]  out_kind_pdc_0 ;
    wire [29:0] out_npc_pdc_0  ;
    wire        out_taken_ex_0 ;
    wire [2:0]  out_kind_ex_0  ;
    wire [29:0] out_npc_ex_0   ;
    wire [29:0] out_pc_ex_0    ;
    wire [1:0]  out_choice_pdc_0;

    wire        out_taken_pdc_1;
    wire [2:0]  out_kind_pdc_1 ;
    wire [29:0] out_npc_pdc_1  ;
    wire        out_taken_ex_1 ;
    wire [2:0]  out_kind_ex_1  ;
    wire [29:0] out_npc_ex_1   ;
    wire [29:0] out_pc_ex_1    ;
    wire [1:0]  out_choice_pdc_1;

    wire pack_size=out_pc_ex_0[0];

    assign out_taken_pdc_0=out_data_0[0]    ;
    assign out_kind_pdc_0 =out_data_0[3:1]  ;
    assign out_npc_pdc_0  =out_data_0[33:4] ;
    assign out_taken_ex_0 =out_data_0[34]   ;
    assign out_kind_ex_0  =out_data_0[37:35];
    assign out_npc_ex_0   =out_data_0[67:38];
    assign out_pc_ex_0    =out_data_0[97:68];
    assign out_choice_pdc_0=out_data_0[99:98];


    assign out_taken_pdc_1=out_data_1[0]    ;
    assign out_kind_pdc_1 =out_data_1[3:1]  ;
    assign out_npc_pdc_1  =out_data_1[33:4] ;
    assign out_taken_ex_1 =out_data_1[34]   ;
    assign out_kind_ex_1  =out_data_1[37:35];
    assign out_npc_ex_1   =out_data_1[67:38];
    assign out_pc_ex_1    =out_data_1[97:68];
    assign out_choice_pdc_1=out_data_1[99:98];

    reg [99:0] buffer_data[0:length-1];

    reg [31:0] pointer;
    reg empty;

    always @(posedge clk)begin
        if(!rstn) begin
            pointer<=0;
            empty<=1;

            buffer_data[0]<=0;
            buffer_data[1]<=0;
            buffer_data[2]<=0;
            buffer_data[3]<=0;
        end
        else begin
            //empty
            if(pointer==0&&empty==1) begin
                empty<=1;
                pointer<=0;
            end
            else if(pointer==0&&empty==0) begin
                pointer<=0;
                if(pack_size)       empty<=1;
                else                empty<=0;
            end
            else begin
                if(pointer==32'd2 && pack_size==0)
                                    empty<=1;  
                else                empty<=0;

                if(pack_size==0)    pointer<=pointer-2;
                else if(pack_size)  pointer<=pointer-1;
            end

            //buffer_data
            if(stall) ;
            else if(flag) begin//默认不会满
                buffer_data[0]<=in_data_0;
                buffer_data[1]<=buffer_data[0];
                buffer_data[2]<=buffer_data[1];
                buffer_data[3]<=buffer_data[2];
            end
            else begin
                buffer_data[0]<=in_data_1;
                buffer_data[1]<=in_data_0;
                buffer_data[2]<=buffer_data[1];
                buffer_data[3]<=buffer_data[2];
            end
        end
    end

    always @(*) begin
        out_data_0=0;
        out_data_1=0;
        update_en=0;
        if(pointer==0&&empty==1) ;
        else if(pointer==0&&empty==0) begin
            out_data_0=buffer_data[pointer];
            out_data_1=0;
            if(pack_size) update_en=1;
        end
        else begin
            out_data_0=buffer_data[pointer];
            out_data_1=buffer_data[pointer-1];
            update_en=1;
        end

        out_taken_pdc=0;
        out_kind_pdc =0;
        out_npc_pdc  =0;
        out_choice_pdc=0;
        out_taken_ex =0;
        out_kind_ex  =0;
        out_npc_ex   =0;
        out_pc_ex    =0;

        if(pack_size) begin
            out_taken_pdc=out_taken_pdc_0;
            out_kind_pdc =out_kind_pdc_0 ;
            out_npc_pdc  =out_npc_pdc_0  ;
            out_choice_pdc=out_choice_pdc_0;
            out_taken_ex =out_taken_ex_0 ;
            out_kind_ex  =out_kind_ex_0  ;
            out_npc_ex   =out_npc_ex_0   ;
            out_pc_ex    =out_pc_ex_0    ;
        end
        else begin
            out_taken_pdc =out_taken_pdc_0;
            out_kind_pdc  =out_kind_pdc_0 ;
            out_npc_pdc   =out_npc_pdc_0  ;
            out_choice_pdc=out_choice_pdc_0;
            out_pc_ex     =out_pc_ex_0    ;

            out_taken_ex  =out_taken_ex_0||out_taken_ex_1;
            //kind
            if(out_kind_ex_0==DIRECT_JUMP||out_kind_ex_1==DIRECT_JUMP) begin
                out_kind_ex=DIRECT_JUMP;
            end
            else if(out_kind_ex_0==CALL||out_kind_ex_1==CALL) begin
                out_kind_ex=CALL;
            end
            else if(out_kind_ex_0==RET||out_kind_ex_1==RET) begin
                out_kind_ex=RET;
            end
            else if(out_kind_ex_0==INDIRECT_JUMP||out_kind_ex_1==INDIRECT_JUMP) begin
                out_kind_ex=INDIRECT_JUMP;
            end
            else if(out_kind_ex_0==OTHER_JUMP||out_kind_ex_1==OTHER_JUMP) begin
                out_kind_ex=OTHER_JUMP;
            end
            else begin
                out_kind_ex=NOT_JUMP;
            end
            //npc
            if(out_taken_ex_0) out_npc_ex=out_npc_ex_0;
            else out_npc_ex=out_npc_ex_1;
        end
    end
endmodule

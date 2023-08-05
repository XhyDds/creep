//尚未完成
module ex_buffer#(
    parameter length = 6,
            bh_width=14
            // ,DATA_WIDTH=99
)(
    input clk,
    input rstn,
    input [1:0]flag, //0:一条指令输入  1:两条指令输入
    input stall,
    // input  [DATA_WIDTH-1:0] in_data_0,
    input        in_taken_pdc_0,   //上路
    input [2:0]  in_kind_pdc_0 ,
    input [29:0] in_npc_pdc_0  ,
    input [1:0]  in_choice_pdc_0,
    input [bh_width-1:0] in_bh_pdc_0   ,
    input        in_taken_ex_0 ,
    input [2:0]  in_kind_ex_0  ,
    input [29:0] in_npc_ex_0   ,
    input [29:0] in_pc_ex_0    ,
    input        in_pack_size_0,    //0:1条 1:2条
    input        in_flush_pre_0,
    input [7:0]  in_pdch_0     ,
    input [11:0] in_tage_pdch_0,

    // input  [DATA_WIDTH-1:0] in_data_1,
    input        in_taken_pdc_1,    //下路
    input [2:0]  in_kind_pdc_1 ,
    input [29:0] in_npc_pdc_1  ,
    input [1:0]  in_choice_pdc_1,
    input [bh_width-1:0] in_bh_pdc_1,
    input        in_taken_ex_1 ,
    input [2:0]  in_kind_ex_1  ,
    input [29:0] in_npc_ex_1   ,
    input [29:0] in_pc_ex_1    ,
    input        in_pack_size_1,
    input        in_flush_pre_1,
    input [7:0]  in_pdch_1,
    input [11:0] in_tage_pdch_1,

    // output [DATA_WIDTH-1:0] out_data,
    output reg          out_taken_pdc ,
    output reg   [2:0]  out_kind_pdc  ,
    output reg   [29:0] out_npc_pdc   ,
    output reg   [bh_width-1:0] out_bh_pdc    ,
    output reg          out_taken_ex  ,
    output reg   [2:0]  out_kind_ex   ,
    output reg   [29:0] out_npc_ex    ,
    output reg   [29:0] out_pc_ex     ,
    output reg   [1:0]  out_choice_pdc,
    output reg   [7:0]  out_pdch      ,
    output reg   [11:0] out_tage_pdch ,

    output reg   [29:0] ret_pc_ex,

    output reg   update_en
);
    parameter   NOT_JUMP = 3'd0,
                DIRECT_JUMP = 3'd1,
                //
                RET = 3'd4,
                INDIRECT_JUMP = 3'd5,
                CALL = 3'd6,
                JUMP=3'd7;

    wire [121+bh_width:0] in_data_0={in_bh_pdc_0,in_tage_pdch_0,in_pdch_0,in_flush_pre_0,in_pack_size_0,in_choice_pdc_0,in_pc_ex_0,in_npc_ex_0,in_kind_ex_0,in_taken_ex_0,in_npc_pdc_0,in_kind_pdc_0,in_taken_pdc_0};
    wire [121+bh_width:0] in_data_1={in_bh_pdc_1,in_tage_pdch_1,in_pdch_1,in_flush_pre_1,in_pack_size_1,in_choice_pdc_1,in_pc_ex_1,in_npc_ex_1,in_kind_ex_1,in_taken_ex_1,in_npc_pdc_1,in_kind_pdc_1,in_taken_pdc_1};

    reg [121+bh_width:0] out_data_0;     //优先
    reg [121+bh_width:0] out_data_1;

    wire        out_taken_pdc_0;
    wire [2:0]  out_kind_pdc_0 ;
    wire [29:0] out_npc_pdc_0  ;
    wire [bh_width-1:0] out_bh_pdc_0   ;
    wire        out_taken_ex_0 ;
    wire [2:0]  out_kind_ex_0  ;
    wire [29:0] out_npc_ex_0   ;
    wire [29:0] out_pc_ex_0    ;
    wire [1:0]  out_choice_pdc_0;
    wire        out_pack_size_0;
    wire        out_flush_pre_0;
    wire [7:0]  out_pdch_0;
    wire [11:0] out_tage_pdch_0;

    wire        out_taken_pdc_1;
    wire [2:0]  out_kind_pdc_1 ;
    wire [29:0] out_npc_pdc_1  ;
    wire [bh_width-1:0] out_bh_pdc_1   ;
    wire        out_taken_ex_1 ;
    wire [2:0]  out_kind_ex_1  ;
    wire [29:0] out_npc_ex_1   ;
    wire [29:0] out_pc_ex_1    ;
    wire [1:0]  out_choice_pdc_1;
    wire        out_pack_size_1;
    wire        out_flush_pre_1;
    wire [7:0]  out_pdch_1;
    wire [11:0] out_tage_pdch_1;

    wire pack_size=(~out_pack_size_0)|out_flush_pre_0; //后一条指令被刷掉:0:两条 1:一条

    reg [29:0] ret_pc_ex_;
    always @(*) begin
        if(out_kind_ex_0!=CALL && out_kind_ex_1==CALL && pack_size==0) ret_pc_ex_=out_pc_ex_1+1;
        else ret_pc_ex_=out_pc_ex_0+1;
    end

    assign out_taken_pdc_0=out_data_0[0]    ;
    assign out_kind_pdc_0 =out_data_0[3:1]  ;
    assign out_npc_pdc_0  =out_data_0[33:4] ;
    assign out_taken_ex_0 =out_data_0[34]   ;
    assign out_kind_ex_0  =out_data_0[37:35];
    assign out_npc_ex_0   =out_data_0[67:38];
    assign out_pc_ex_0    =out_data_0[97:68];
    assign out_choice_pdc_0=out_data_0[99:98];
    assign out_pack_size_0=out_data_0[100]  ;
    assign out_flush_pre_0=out_data_0[101]  ;
    assign out_pdch_0     =out_data_0[109:102];
    assign out_tage_pdch_0=out_data_0[121:110];
    assign out_bh_pdc_0   =out_data_0[121+bh_width:122];


    assign out_taken_pdc_1=out_data_1[0]    ;
    assign out_kind_pdc_1 =out_data_1[3:1]  ;
    assign out_npc_pdc_1  =out_data_1[33:4] ;
    assign out_taken_ex_1 =out_data_1[34]   ;
    assign out_kind_ex_1  =out_data_1[37:35];
    assign out_npc_ex_1   =out_data_1[67:38];
    assign out_pc_ex_1    =out_data_1[97:68];
    assign out_choice_pdc_1=out_data_1[99:98];
    assign out_pack_size_1=out_data_1[100]  ;
    assign out_flush_pre_1=out_data_1[101]  ;
    assign out_pdch_1     =out_data_1[109:102];
    assign out_tage_pdch_1=out_data_1[121:110];
    assign out_bh_pdc_1   =out_data_1[121+bh_width:122];


    reg [121+bh_width:0] buffer_data[0:length-1];

    reg [31:0] pointer;

    reg        update_en_     ;
    reg        out_taken_pdc_ ;
    reg [2:0]  out_kind_pdc_  ;
    reg [29:0] out_npc_pdc_   ;
    reg [bh_width-1:0] out_bh_pdc_;
    reg        out_taken_ex_  ;
    reg [2:0]  out_kind_ex_   ;
    reg [29:0] out_npc_ex_    ;
    reg [29:0] out_pc_ex_     ;
    reg [1:0]  out_choice_pdc_;
    reg [7:0]  out_pdch_;
    reg [11:0] out_tage_pdch_;

    reg [1:0] pointer_minus;
    reg [1:0] pointer_plus;

    always @(*) begin
        pointer_minus=0;
        if(pointer==0) ;
        else if(pointer==1) begin
            if(pack_size) pointer_minus=2'd1;
            else          pointer_minus=0;
        end
        else begin
            if(pack_size) pointer_minus=2'd1;
            else          pointer_minus=2'd2;
        end

        pointer_plus=0;
        if(stall) ;
        else if(flag!=2'b11) begin//默认不会满
            pointer_plus=2'd1;
        end
        else begin
            pointer_plus=2'd2;
        end
    end

    always @(posedge clk) begin
        if(!rstn) pointer<=0;
        else begin
            if(pointer_minus==2'd0&&pointer_plus==2'd0)      pointer<=pointer;
            else if(pointer_minus==2'd0&&pointer_plus==2'd1) pointer<=pointer+32'd1;
            else if(pointer_minus==2'd0&&pointer_plus==2'd2) pointer<=pointer+32'd2;
            else if(pointer_minus==2'd1&&pointer_plus==2'd0) pointer<=pointer-32'd1;
            else if(pointer_minus==2'd1&&pointer_plus==2'd1) pointer<=pointer;
            else if(pointer_minus==2'd1&&pointer_plus==2'd2) pointer<=pointer+32'd1;
            else if(pointer_minus==2'd2&&pointer_plus==2'd0) pointer<=pointer-32'd2;
            else if(pointer_minus==2'd2&&pointer_plus==2'd1) pointer<=pointer-32'd1;
            else if(pointer_minus==2'd2&&pointer_plus==2'd2) pointer<=pointer;
            else                                             pointer<=pointer;
        end
    end

    always @(posedge clk)begin
        if(!rstn) begin
            // buffer_data[0]<=0;
            buffer_data[1]<=0;
            buffer_data[2]<=0;
            buffer_data[3]<=0;
            buffer_data[4]<=0;
            buffer_data[5]<=0;
        end
        else begin
            //buffer_data
            if(stall) ;
            else if(flag==2'b01) begin//默认不会满
                // buffer_data[0]<=0;
                buffer_data[1]<=in_data_1;
                buffer_data[2]<=buffer_data[1];
                buffer_data[3]<=buffer_data[2];
                buffer_data[4]<=buffer_data[3];
                buffer_data[5]<=buffer_data[4];
            end
            else if(flag==2'b10) begin//默认不会满
                // buffer_data[0]<=0;
                buffer_data[1]<=in_data_0;
                buffer_data[2]<=buffer_data[1];
                buffer_data[3]<=buffer_data[2];
                buffer_data[4]<=buffer_data[3];
                buffer_data[5]<=buffer_data[4];
            end
            else begin
                // buffer_data[0]<=0;
                buffer_data[1]<=in_data_0;
                buffer_data[2]<=in_data_1;
                buffer_data[3]<=buffer_data[1];
                buffer_data[4]<=buffer_data[2];
                buffer_data[5]<=buffer_data[3];
            end
        end
    end

    always @(*) begin
        out_data_0=0;
        out_data_1=0;
        update_en_=0;
        if(pointer==0) ;
        else if(pointer==1) begin
            out_data_0=buffer_data[pointer];
            out_data_1=0;
            if(pack_size) update_en_=1;
        end
        else begin
            out_data_0=buffer_data[pointer];
            out_data_1=buffer_data[pointer-1];
            update_en_ =1;
        end

        out_taken_pdc_ =0;
        out_kind_pdc_  =0;
        out_npc_pdc_   =0;
        out_bh_pdc_    =0;
        out_choice_pdc_=0;
        out_taken_ex_  =0;
        out_kind_ex_   =0;
        out_npc_ex_    =0;
        out_pc_ex_     =0;
        out_pdch_      =0;
        out_tage_pdch_ =out_tage_pdch_0;

        if(pack_size) begin
            out_taken_pdc_ =out_taken_pdc_0;
            out_kind_pdc_  =out_kind_pdc_0 ;
            out_npc_pdc_   =out_npc_pdc_0  ;
            out_choice_pdc_=out_choice_pdc_0;
            out_bh_pdc_    =out_bh_pdc_0   ;
            out_taken_ex_  =out_taken_ex_0 ;
            out_kind_ex_   =out_kind_ex_0  ;
            out_npc_ex_    =out_npc_ex_0   ;
            out_pc_ex_     =out_pc_ex_0    ;
            out_pdch_      =out_pdch_0     ;
        end
        else begin
            out_taken_pdc_ =out_taken_pdc_0;
            out_kind_pdc_  =out_kind_pdc_0 ;
            out_npc_pdc_   =out_npc_pdc_0  ;
            out_choice_pdc_=out_choice_pdc_0;
            out_bh_pdc_    =out_bh_pdc_0   ;
            out_pc_ex_     =out_pc_ex_0    ;
            out_pdch_      =out_pdch_0     ;

            out_taken_ex_  =out_taken_ex_0||out_taken_ex_1;
            //kind
            if(out_kind_ex_0==DIRECT_JUMP||out_kind_ex_1==DIRECT_JUMP) begin
                out_kind_ex_=DIRECT_JUMP;
            end
            else if(out_kind_ex_0==CALL||out_kind_ex_1==CALL) begin
                out_kind_ex_=CALL;
            end
            else if(out_kind_ex_0==RET||out_kind_ex_1==RET) begin
                out_kind_ex_=RET;
            end
            else if(out_kind_ex_0==INDIRECT_JUMP||out_kind_ex_1==INDIRECT_JUMP) begin
                out_kind_ex_=INDIRECT_JUMP;
            end
            else begin
                out_kind_ex_=NOT_JUMP;
            end
            //npc
            if(out_taken_ex_0) out_npc_ex_=out_npc_ex_0;
            else out_npc_ex_=out_npc_ex_1;
        end
    end

    //寄存，截断传播
    always @(posedge clk) begin
        if(!rstn)begin
            update_en     <=0;
            out_taken_pdc <=0;
            out_kind_pdc  <=0;
            out_npc_pdc   <=0;
            out_taken_ex  <=0;
            out_kind_ex   <=0;
            out_npc_ex    <=0;
            out_pc_ex     <=0;
            out_choice_pdc<=0;
            ret_pc_ex     <=0;
            out_pdch      <=0;
            out_tage_pdch <=0;
        end
        else begin
            update_en     <=update_en_     ;
            out_taken_pdc <=out_taken_pdc_ ;
            out_kind_pdc  <=out_kind_pdc_  ;
            out_npc_pdc   <=out_npc_pdc_   ;
            out_bh_pdc    <=out_bh_pdc_    ;
            out_taken_ex  <=out_taken_ex_  ;
            out_kind_ex   <=out_kind_ex_   ;
            out_npc_ex    <=out_npc_ex_    ;
            out_pc_ex     <=out_pc_ex_     ;
            out_choice_pdc<=out_choice_pdc_;
            ret_pc_ex     <=ret_pc_ex_     ;
            out_pdch      <=out_pdch_      ;
            out_tage_pdch <=out_tage_pdch_ ;
        end
    end
    
endmodule
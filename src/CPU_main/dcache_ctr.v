module dcache_ctr (
    input        [31:0]rrj_reg_exe0_1,imm_reg_exe0_1,ctr_reg_exe0_1,rd_reg_exe0_1,
    // output  ALE,
    output  reg  [31:0]addr_pipeline_dcache,
    output  reg  [31:0]din_pipeline_dcache,
    output  reg  type_pipeline_dcache,//0-read 1-write
    output  reg  pipeline_dcache_vaild,
    output  reg  [3:0]pipeline_dcache_wstrb,//字节处理位
    output  reg  [31:0]pipeline_dcache_opcode,//cache操作//?????
    output  reg  pipeline_dcache_opflag,//0-正常访存 1-cache操作    
    output  reg  [31:0]pipeline_dcache_ctrl//stall flush branch ...//?????
);
    wire [3:0]type=ctr_reg_exe0_1[3:0];
    wire [4:0]subtype=ctr_reg_exe0_1[11:7];
    always @(*) begin
        addr_pipeline_dcache=rrj_reg_exe0_1+imm_reg_exe0_1;
        din_pipeline_dcache=0;
        type_pipeline_dcache=0;
        pipeline_dcache_vaild=0;
        pipeline_dcache_wstrb=0;
        pipeline_dcache_opcode=0;
        pipeline_dcache_opflag=0;
        pipeline_dcache_ctrl=0;
        if(type==5)
            case (subtype)//for dcache, 0~2:load, 3~5:store, 6~7:load, 8:ibar
                0: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        00:pipeline_dcache_wstrb='b0001;
                        01:pipeline_dcache_wstrb='b0010;
                        10:pipeline_dcache_wstrb='b0100;
                        11:pipeline_dcache_wstrb='b1000;
                    endcase
                end
                1: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        00:begin pipeline_dcache_wstrb='b0011; end
                        10:begin pipeline_dcache_wstrb='b1100; end
                    endcase
                end
                2: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=0;
                    pipeline_dcache_wstrb='b1111;
                end
                3: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=1;
                    din_pipeline_dcache=rd_reg_exe0_1[7:0];
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        00:pipeline_dcache_wstrb='b0001;
                        01:pipeline_dcache_wstrb='b0010;
                        10:pipeline_dcache_wstrb='b0100;
                        11:pipeline_dcache_wstrb='b1000;
                    endcase
                end
                4: 
                begin 
                    type_pipeline_dcache=1;
                    pipeline_dcache_vaild=1;
                    din_pipeline_dcache=rd_reg_exe0_1[15:0]; 
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        00:begin pipeline_dcache_wstrb='b0011; end
                        10:begin pipeline_dcache_wstrb='b1100; end
                    endcase
                end
                5: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=1;
                    din_pipeline_dcache=rd_reg_exe0_1; pipeline_dcache_wstrb='b1111;
                end
                6: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        00:pipeline_dcache_wstrb='b0001;
                        01:pipeline_dcache_wstrb='b0010;
                        10:pipeline_dcache_wstrb='b0100;
                        11:pipeline_dcache_wstrb='b1000;
                    endcase 
                    end
                7: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=0;
                    case (addr_pipeline_dcache[1:0])//小尾端？
                        00:begin pipeline_dcache_wstrb='b0011; end
                        10:begin pipeline_dcache_wstrb='b1100; end
                    endcase 
                end
                8: begin pipeline_dcache_vaild=1;pipeline_dcache_opflag=1;/*pipeline_dcache_opcode=?;*/ end
            endcase
        else if(type==6)
            case (subtype)//fot yuanzi, 0:load, 1:store
                0: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=0;
                    pipeline_dcache_wstrb='b1111; 
                end
                1: 
                begin 
                    pipeline_dcache_vaild=1;
                    type_pipeline_dcache=1;
                    din_pipeline_dcache=rd_reg_exe0_1; pipeline_dcache_wstrb='b1111; 
                end
            endcase
    end
endmodule
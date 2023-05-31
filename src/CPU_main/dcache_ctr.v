module dcache_ctr (
    input        [31:0]rj,rk,ctr,
    output  reg  [31:0]addr_pipeline_dcache,
    output  reg  [31:0]din_pipeline_dcache,
    output  reg  type_pipeline_dcache,//0-read 1-write
    output  reg  pipeline_dcache_vaild,
    output  reg  [3:0]pipeline_dcache_wstrb,//字节处理位
    output  reg  [31:0]pipeline_dcache_opcode,//cache操作
    output  reg  pipeline_dcache_opflag,//0-正常访存 1-cache操作    
    output  reg  [31:0]pipeline_dcache_ctrl//stall flush branch ...
);
    wire [3:0]type=ctr[3:0];
    wire [4:0]subtype=ctr[11:7];
    always @(*) begin
        addr_pipeline_dcache=0;
        din_pipeline_dcache=0;
        type_pipeline_dcache=0;
        pipeline_dcache_vaild=0;
        pipeline_dcache_wstrb=0;
        pipeline_dcache_opcode=0;
        pipeline_dcache_opflag=0;
        pipeline_dcache_ctrl=0;
        if(type==2)
            case (subtype)//for dcache, 0~2:load, 3~5:store, 6~7:load, 8:ibar
                0: ;
                1: ;
                2: ;
                3: ;
                4: ;
                5: ;
                6: ;
                7: ;
                8: ;
            endcase
    end
endmodule
module dcache_extend (
    input [31:0]ctr_exe0_exe1_1,dout_dcache_pipeline,din_pipeline_dcache,
    input [1:0]addr_pipeline_dcache,
    output reg [31:0]dout_dcache_pipeline_extend
);
    wire [3:0]type_=ctr_exe0_exe1_1[3:0];
    wire [4:0]subtype=ctr_exe0_exe1_1[11:7];
    wire [15:0]dout16=addr_pipeline_dcache[1]?dout_dcache_pipeline[31:16]:dout_dcache_pipeline[15:0];
    reg [7:0]dout8;
    always @(*) begin
        dout8=0;
        case (addr_pipeline_dcache)
            'b11: dout8=dout_dcache_pipeline[31:24];
            'b10: dout8=dout_dcache_pipeline[23:16];
            'b01: dout8=dout_dcache_pipeline[15:8];
            'b00: dout8=dout_dcache_pipeline[7:0];
        endcase
    end

    always @(*) begin
        dout_dcache_pipeline_extend=0;
        if(type_==5)
            case (subtype)
            //LD
                0: dout_dcache_pipeline_extend={{24{dout8[7]}},dout8};
                1: dout_dcache_pipeline_extend={{16{dout16[15]}},dout16};
                2: dout_dcache_pipeline_extend=dout_dcache_pipeline;
            //ST
                3: dout_dcache_pipeline_extend=din_pipeline_dcache;
                4: dout_dcache_pipeline_extend=din_pipeline_dcache;
                5: dout_dcache_pipeline_extend=din_pipeline_dcache;
            //LD
                6: dout_dcache_pipeline_extend={24'b0,dout8};
                7: dout_dcache_pipeline_extend={16'b0,dout16};
            endcase
        else if(type_==6)
            case (subtype)
                0: dout_dcache_pipeline_extend={{16{dout16[15]}},dout16};
                1: dout_dcache_pipeline_extend=din_pipeline_dcache;
            endcase
    end
endmodule //dcache_extend

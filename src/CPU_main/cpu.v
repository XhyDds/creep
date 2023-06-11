module cpu (
    input clk,rstn,
    // input  [7:0] intrpt,
    output [15:0]LED
);
    assign LED=0;
    reg [31:0]pc,npc,
    ctr_id_reg_0,ctr_id_reg_1,ctr_reg_exe0_1_ALE,
    ctr_reg_exe0_0,ctr_reg_exe0_1,
    ctr_exe0_exe1_0,ctr_exe0_exe1_1,
    ctr_exe1_wb_0,ctr_exe1_wb_1,
    pc_id_reg_0,pc_id_reg_1,
    // pc_fifo_id,
    pc_if1_fifo,
    pc_if0_if1,
    pc_reg_exe0_0,pc_reg_exe0_1,
    aluresult_exe0_exe1_0,aluresult_exe0_exe1_1,
    result_exe1_wb_0,result_exe1_wb_1,
    rrk_reg_exe0_0,rrj_reg_exe0_0,
    rrk_reg_exe0_1,rrj_reg_exe0_1,
    rrd_reg_exe0_0,rrd_reg_exe0_1,
    imm_reg_exe0_0,imm_reg_exe0_1,
    imm_id_reg_0,imm_id_reg_1;

    reg [15:0]excp_arg_reg_exe0_1,excp_arg_reg_exe0_1_excp,
    excp_arg_id_reg_0,excp_arg_id_reg_1;
    // excp_arg_reg_exe0_0,

    reg [63:0]ir_if1_fifo;
    reg [4:0]rd_exe1_wb_0,rd_exe1_wb_1,
    rk_reg_exe0_0,rk_reg_exe0_1,
    rj_reg_exe0_0,rj_reg_exe0_1,
    rd_reg_exe0_0,rd_reg_exe0_1,
    rd_id_reg_0,rd_id_reg_1,
    rk_id_reg_0,rk_id_reg_1,
    rj_id_reg_0,rj_id_reg_1,
    rd_exe0_exe1_0,rd_exe0_exe1_1;
    reg icache_valid_if1_fifo,flag_if1_fifo;
    
    //PRIV
    wire ifbr_priv=0,llbit=0;
    wire [1:0]PLV=0;
    wire [31:0]priv_pc;
    wire [31:0]privresult1=0;
    wire flush_priv=0,stall_priv=0;
    // wire stall_priv_break=0;

    wire ifbr0,ifbr1,ifibar0,ifibar1;
    wire stall_div0,stall_div1,stall_fetch_buffer;
    wire stall_dcache=0,stall_icache=0;//dcache_valid-ready?
    wire flush_if0_if1,flush_if1_fifo,flush_fifo_id,flush_id_reg0,flush_id_reg1,flush_reg_exe0_0,flush_reg_exe0_1,flush_exe0_exe1_0,flush_exe0_exe1_1,flush_exe1_wb_0,flush_exe1_wb_1;
    wire stall_pc,stall_if0_if1,stall_if1_fifo,stall_fifo_id,stall_id_reg0,stall_id_reg1,stall_reg_exe0_0,stall_reg_exe0_1,stall_exe0_exe1_0,stall_exe0_exe1_1,stall_exe1_wb_0,stall_exe1_wb_1,stall_to_icache,stall_to_dcache;

    assign flush_if0_if1 =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_if1_fifo =     flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_fifo_id =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_id_reg0 =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_id_reg1 =      flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_reg_exe0_0 =   flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_reg_exe0_1 =   flush_priv|ifibar1|ifibar0|ifbr1|ifbr0;
    assign flush_exe0_exe1_0 =  flush_priv|ifibar1|ifbr1;
    assign flush_exe0_exe1_1 =  0;
    assign flush_exe1_wb_0 =    0;
    assign flush_exe1_wb_1 =    0;

    assign stall_pc =           stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache|stall_icache;
    assign stall_if0_if1 =      stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache|stall_icache;
    assign stall_to_icache =    stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache;//暂时不死锁
    assign stall_if1_fifo =     stall_fetch_buffer|stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_fifo_id =      stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_id_reg0 =      stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_id_reg1 =      stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_reg_exe0_0 =   stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_reg_exe0_1 =   stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_exe0_exe1_0 =  stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_exe0_exe1_1 =  stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_to_dcache =    stall_priv|stall_div0|stall_div1;//暂时不死锁
    assign stall_exe1_wb_0 =    stall_priv|stall_div0|stall_div1|stall_dcache;
    assign stall_exe1_wb_1 =    stall_priv|stall_div0|stall_div1|stall_dcache;

    // //ICache
    // wire [31:0]	test1_icache;
    // wire [31:0]	test2_icache;
    // wire [31:0]	test3_icache;

    // wire [63:0]	dout_icache_pipeline;
    // wire 	flag_icache_pipeline;
    // wire 	icache_pipeline_ready;

    // wire [31:0]	addr_icache_mem;
    // wire 	icache_mem_req;
    // wire [1:0]	icache_mem_size;

    // Icache #(
    //     .index_width  		( 4 		),
    //     .offset_width 		( 2 		),
    //     .way          		( 2 		))
    // u_Icache(
    //     //ports
    //     .clk                    		( clk                    		),
    //     .rstn                   		( rstn                   		),
    //     .test1                  		( test1_icache           		),
    //     .test2                  		( test2_icache           		),
    //     .test3                  		( test3_icache           		),

    //     // .ifibar(ifibar0|ifibar1),
    //     .addr_pipeline_icache   		( |pc[1:0]?0:pc   		),
    //     .dout_icache_pipeline   		( dout_icache_pipeline   		),//
    //     .flag_icache_pipeline   		( flag_icache_pipeline   		),//
    //     .pipeline_icache_vaild  		( 1  		),
    //     .icache_pipeline_ready  		( icache_pipeline_ready  		),//
    //     .pipeline_icache_opcode 		( 0 		),
    //     .pipeline_icache_opflag 		( 0 		),
    //     .pipeline_icache_ctrl           ( {30'b0,flush_if0_if1,stall_to_icache} ),
    //     .icache_pipeline_stall  		( stall_icache  		),//

    //     .addr_icache_mem        		( addr_icache_mem        		),
    //     .din_mem_icache         		( din_mem_icache         		),
    //     .icache_mem_req         		( icache_mem_req         		),
    //     .icache_mem_size        		( icache_mem_size        		),
    //     .mem_icache_addrOK      		( mem_icache_addrOK      		),
    //     .mem_icache_dataOK      		( mem_icache_dataOK      		)
    // );

    wire [63:0]	dout_icache_pipeline;
    wire 	flag_icache_pipeline,icache_pipeline_ready;

    icache_testonly u_icache_testonly(
        //ports
        .flush(flush_if0_if1),
        .stall(stall_if0_if1),
        .icache_valid_reg(icache_pipeline_ready),
        .clk      		( clk      		),
        .rstn     		( rstn     		),
        .pc       		( |pc[1:0]?0:pc  ),
        .ir_reg   		( dout_icache_pipeline   		    ),
        .flag_reg 		( flag_icache_pipeline 		    )
    );

    wire [31:0]	pc0;
    wire [31:0]	pc1;
    wire [31:0]	ir0;
    wire [31:0]	ir1;
    wire 	if0;
    wire 	if1;

    fetch_buffer u_fetch_buffer(
        //ports
        .pc(pc_if1_fifo),
        .flush(flush_if0_if1),
        .stall(stall_if0_if1),
        .icache_valid   (icache_valid_if1_fifo),
        .clk     		( clk     		),
        .rstn    		( rstn    		),
        .if0     		( if0     		),
        .if1     		( if1     		),
        .irin    		( ir_if1_fifo   ),
        .flag    		( flag_if1_fifo ),
        .ir0 		    ( ir0 	    	),
        .ir1 		    ( ir1 	    	),
        .pc0            ( pc0           ),
        .pc1            ( pc1           ),
        .stall_fetch_buffer(stall_fetch_buffer)
    );

    wire [31:0]	control0;
    wire [4:0]	rk0;
    wire [4:0]	rj0;
    wire [4:0]	rd0;
    wire [31:0]	imm0;
    wire [15:0]	excp_arg0;

    decoder u_decoder0(
        //ports
        // .PLV            ( PLV               ),
        .pc             ( pc0               ),
        .ir       		( ir0 	    	    ),
        .control  		( control0  		),
        .rk       		( rk0       		),
        .rj       		( rj0       		),
        .rd       		( rd0       		),
        .imm      		( imm0      		),
        .excp_arg 		( excp_arg0 		)
    );

    wire [31:0]	control1;
    wire [4:0]	rk1;
    wire [4:0]	rj1;
    wire [4:0]	rd1;
    wire [31:0]	imm1;
    wire [15:0]	excp_arg1;

    decoder u_decoder1(
        //ports
        // .PLV            ( PLV               ),
        .pc             ( pc1               ),
        .ir       		( ir1        	    ),
        .control  		( control1  		),
        .rk       		( rk1       		),
        .rj       		( rj1       		),
        .rd       		( rd1       		),
        .imm      		( imm1      		),
        .excp_arg 		( excp_arg1 		)
    );

    wire [4:0]	rk00;
    wire [4:0]	rk11;
    wire [4:0]	rj00;
    wire [4:0]	rj11;
    wire [4:0]	rd00;
    wire [4:0]	rd11;
    wire [31:0]	imm00;
    wire [31:0]	imm11;
    wire [31:0]	control00;
    wire [31:0]	control11;
    wire [15:0]	excp_arg00;
    wire [15:0]	excp_arg11;
    wire [32:1]pc00;
    wire [32:1]pc11;

    dispatcher u_dispatcher(
        //ports
        .clk     		    ( clk     		),
        .rstn    		    ( rstn    		),
        .flush(flush_fifo_id),
        .stall(stall_fifo_id),
        .pc0(pc0),
        .pc1(pc1),
        .imm0       		( imm0       		),
        .imm1       		( imm1       		),
        .control0   		( control0   		),
        .control1   		( control1   		),
        .rk0        		( rk0        		),
        .rk1        		( rk1        		),
        .rj0        		( rj0        		),
        .rj1        		( rj1        		),
        .rd0        		( rd0        		),
        .rd1        		( rd1        		),
        .excp_arg0  		( excp_arg0  		),
        .excp_arg1  		( excp_arg1  		),
        .rk00       		( rk00       		),
        .rk11       		( rk11       		),
        .rj00       		( rj00       		),
        .rj11       		( rj11       		),
        .rd00       		( rd00       		),
        .rd11       		( rd11       		),
        .imm00      		( imm00      		),
        .imm11      		( imm11      		),
        .pc00(pc00),
        .pc11(pc11),
        .control00  		( control00  		),
        .control11  		( control11  		),
        .excp_arg00 		( excp_arg00 		),
        .excp_arg11 		( excp_arg11 		),
        .if0        		( if0        		),
        .if1        		( if1        		)
    );

    wire [31:0]	rrk0_rf;
    wire [31:0]	rrk1_rf;
    wire [31:0]	rrj0_rf;
    wire [31:0]	rrj1_rf;
    wire [31:0]	rrd0_rf;
    wire [31:0]	rrd1_rf;
    wire [31:0]	wb_data0;
    wire [31:0]	wb_data1;
    wire [4:0]	wb_addr0;
    wire [4:0]	wb_addr1;
    wire ifwb0,ifwb1;

    register_file u_register_file(
        //ports
        .stall0(stall_exe1_wb_0),
        .stall1(stall_exe1_wb_1),
        .clk      		( clk      		),
        .rstn      		( rstn      		),
        .ifwb0    		( ifwb0    		),
        .ifwb1    		( ifwb1    		),
        .wb_data0 		( wb_data0 		),
        .wb_addr0 		( wb_addr0 		),
        .wb_data1 		( wb_data1 		),
        .wb_addr1 		( wb_addr1 		),
        .rk0     		( rk_id_reg_0     		),
        .rk1     		( rk_id_reg_1     		),
        .rj0     		( rj_id_reg_0     		),
        .rj1     		( rj_id_reg_1     		),
        .rd0     		( rd_id_reg_0     		),
        .rd1     		( rd_id_reg_1     		),
        .rrk0     		( rrk0_rf     		),
        .rrk1     		( rrk1_rf     		),
        .rrj0     		( rrj0_rf     		),
        .rrj1     		( rrj1_rf     		),
        .rrd0     		( rrd0_rf     		),
        .rrd1     		( rrd1_rf     		)
    );

    wire [31:0]	rrj0_forward;
    wire [31:0]	rrj1_forward;
    wire [31:0]	rrk0_forward;
    wire [31:0]	rrk1_forward;
    wire [31:0]	rrd0_forward;
    wire [31:0]	rrd1_forward;

    forward u_forward(
        //ports
        .ctr_exe1_wb_0(ctr_exe1_wb_0),
        .ctr_exe1_wb_1(ctr_exe1_wb_1),
        .ctr_exe0_exe1_0(ctr_exe0_exe1_0),
        .ctr_exe0_exe1_1(ctr_exe0_exe1_1),
        .aluresult_exe0_exe1_0 		( aluresult_exe0_exe1_0 		),
        .aluresult_exe0_exe1_1 		( aluresult_exe0_exe1_1 		),
        .result_exe1_wb_0      		( result_exe1_wb_0      		),
        .result_exe1_wb_1      		( result_exe1_wb_1      		),
        .rrj_reg_exe0_0        		( rrj_reg_exe0_0        		),
        .rrj_reg_exe0_1        		( rrj_reg_exe0_1        		),
        .rrk_reg_exe0_0        		( rrk_reg_exe0_0        		),
        .rrk_reg_exe0_1        		( rrk_reg_exe0_1        		),
        .rd_exe0_exe1_0        		( rd_exe0_exe1_0        		),
        .rd_exe0_exe1_1        		( rd_exe0_exe1_1        		),
        .rrd_reg_exe0_0        		( rrd_reg_exe0_0        		),
        .rrd_reg_exe0_1        		( rrd_reg_exe0_1        		),
        .rd_exe1_wb_0          		( rd_exe1_wb_0          		),
        .rd_exe1_wb_1          		( rd_exe1_wb_1          		),
        .rj0                   		( rj_reg_exe0_0               		),
        .rj1                   		( rj_reg_exe0_1               		),
        .rk0                   		( rk_reg_exe0_0               		),
        .rk1                   		( rk_reg_exe0_1               		),
        .rd0(rd_reg_exe0_0),
        .rd1(rd_reg_exe0_1),
        .rrj0                  		( rrj0_forward                  ),
        .rrj1                  		( rrj1_forward                  ),
        .rrk0                  		( rrk0_forward                  ),
        .rrk1                  		( rrk1_forward                  ),
        .rrd0(rrd0_forward),
        .rrd1(rrd1_forward)
    );

    wire [31:0]	alu1_0;

    alusrc u_alusrc1_0(
        //ports
        .register0 		( rrj0_forward 		),
        .register2 		( 0 		),
        .register3 		( 0 		),
        .register1    	( pc_reg_exe0_0    		),
        .alusrc_   		( ctr_reg_exe0_0[15:14]   		),
        .alu      		( alu1_0      		)
    );

    wire [31:0]	alu2_0;

    alusrc u_alusrc2_0(
        //ports
        .register0 		( rrk0_forward 		),
        .register2 		( rrd0_forward 		),
        .register3 		( 4 		),
        .register1    	( imm_reg_exe0_0    		),
        .alusrc_   		( ctr_reg_exe0_0[13:12]   		),
        .alu      		( alu2_0      		)
    );

    wire [31:0]	alu1_1;

    alusrc u_alusrc1_1(
        //ports
        .register0 		( rrj1_forward 		),
        .register2 		( 0 		),
        .register3 		( 0 		),
        .register1    	( pc_reg_exe0_1    		),
        .alusrc_   		( ctr_reg_exe0_1_ALE[15:14]   		),
        .alu      		( alu1_1      		)
    );

    wire [31:0]	alu2_1;

    alusrc u_alusrc2_1(
        //ports
        .register0 		( rrk1_forward 		),
        .register2 		( rrd1_forward 		),
        .register3 		( 4 		),
        .register1    	( imm_reg_exe0_1    		),
        .alusrc_   		( ctr_reg_exe0_1_ALE[13:12]   		),
        .alu      		( alu2_1      		)
    );

    wire [31:0]	aluresult0;
    wire 	zero0;

    alu u_alu0(
        //ports
        .alu1      		( alu1_0      		),
        .alu2      		( alu2_0      		),
        .ctr       		( ctr_reg_exe0_0       		),
        .aluresult 		( aluresult0		),
        .zero      		( zero0     		)
    );

    wire [31:0]	aluresult1;
    wire 	zero1;

    alu u_alu1(
        //ports
        .alu1      		( alu1_1      		),
        .alu2      		( alu2_1      		),
        .ctr       		( ctr_reg_exe0_1_ALE       		),
        .aluresult 		( aluresult1		),
        .zero      		( zero1     		)
    );

    wire [31:0]	mulresult0;

    muitiplier u_muitiplier0(
        //ports
        .clk                         		( clk                         		),
        .rstn                        		( rstn                        		),
        .pipeline_muitiplier_flush   		( flush_exe0_exe1_0   		),
        .pipeline_muitiplier_stall   		( stall_exe0_exe1_0   		),
        // .pipeline_muitiplier_type 		    ( ctr_reg_exe0_0[3:0] 		),
        .pipeline_muitiplier_subtype 		( ctr_reg_exe0_0[11:7] 		),
        .pipeline_muitiplier_din1    		( rrj0_forward    		),
        .pipeline_muitiplier_din2    		( rrk0_forward    		),
        .muitiplier_pipeline_dout    		( mulresult0    		)
    );

    wire [31:0]	mulresult1;

    muitiplier u_muitiplier1(
        //ports
        .clk                         		( clk                         		),
        .rstn                        		( rstn                        		),
        .pipeline_muitiplier_flush   		( flush_exe0_exe1_1   		),
        .pipeline_muitiplier_stall   		( stall_exe0_exe1_1   		),
        // .pipeline_muitiplier_type 		    ( ctr_reg_exe0_1_ALE[3:0] 		),
        .pipeline_muitiplier_subtype 		( ctr_reg_exe0_1_ALE[11:7] 		),
        .pipeline_muitiplier_din1    		( rrj1_forward    		),
        .pipeline_muitiplier_din2    		( rrk1_forward    		),
        .muitiplier_pipeline_dout    		( mulresult1    		)
    );

    wire [31:0]	divresult0;

    divider #(
        .WIDTH 		( 32 		))
    u_divider0(
        //ports
        .clk                      		( clk                      		),
        .rstn                     		( rstn                     		),
        .pipeline_divider_type    		( ctr_reg_exe0_0[3:0]    		),
        .pipeline_divider_subtype 		( ctr_reg_exe0_0[11:7] 		),
        .pipeline_divider_stall   		( stall_exe0_exe1_0   		),
        .pipeline_divider_flush   		( flush_exe0_exe1_0   		),
        .pipeline_divider_din1    		( rrj0_forward    		),
        .pipeline_divider_din2    		( rrk0_forward    		),
        .divider_pipeline_stall   		( stall_div0   		),
        .divider_pipeline_dout    		( divresult0    		)
    );

    wire [31:0]	divresult1;
    
    divider #(
        .WIDTH 		( 32 		))
    u_divider1(
        //ports
        .clk                      		( clk                      		),
        .rstn                     		( rstn                     		),
        .pipeline_divider_type    		( ctr_reg_exe0_1_ALE[3:0]    		),
        .pipeline_divider_subtype 		( ctr_reg_exe0_1_ALE[11:7] 		),
        .pipeline_divider_stall   		( stall_exe0_exe1_1   		),
        .pipeline_divider_flush   		( flush_exe0_exe1_1   		),
        .pipeline_divider_din1    		( rrj1_forward    		),
        .pipeline_divider_din2    		( rrk1_forward    		),
        .divider_pipeline_stall   		( stall_div1   		),
        .divider_pipeline_dout    		( divresult1    		)
    );

    ibar u_ibar0(
        //ports
        .ctr        	( ctr_reg_exe0_0        		),
        .ifibar 		( ifibar0 		)
    );

    ibar u_ibar1(
        //ports
        .ctr        	( ctr_reg_exe0_1_ALE        		),
        .ifibar 		( ifibar1 		)
    );

    wire [31:0]	brresult0;

    br u_br0(
        //ports
        .ctr      		( ctr_reg_exe0_0      		),
        .pc       		( pc_reg_exe0_0       		),
        .imm      		( imm_reg_exe0_0      		),
        .zero     		( zero0     		),
        .ifbr     		( ifbr0    		),
        .brresult 		( brresult0 	)
    );

    wire [31:0]	brresult1;

    br u_br1(
        //ports
        .ctr      		( ctr_reg_exe0_1_ALE      		),
        .pc       		( pc_reg_exe0_1       		),
        .imm      		( imm_reg_exe0_1      		),
        .zero     		( zero1     		),
        .ifbr     		( ifbr1    		),
        .brresult 		( brresult1		)
    );

    // wire [31:0]	addr_pipeline_dcache;
    // wire [31:0]	din_pipeline_dcache;
    // wire 	type_pipeline_dcache;
    // wire 	pipeline_dcache_vaild;
    // wire [3:0]	pipeline_dcache_wstrb;
    // wire [31:0]	pipeline_dcache_opcode;
    // wire 	pipeline_dcache_opflag;

    // dcache_ctr u_dcache_ctr(
    //     //ports
    //     .excp_arg_reg_exe0_1_excp       ( excp_arg_reg_exe0_1_excp      ),
    //     .rrj1_forward         		    ( rrj1_forward         		    ),
    //     .imm_reg_exe0_1         		( imm_reg_exe0_1         		),
    //     .ctr_reg_exe0_1         		( ctr_reg_exe0_1         		),
    //     .rd_reg_exe0_1          		( rd_reg_exe0_1          		),
    //     .addr_pipeline_dcache   		( addr_pipeline_dcache   		),
    //     .din_pipeline_dcache    		( din_pipeline_dcache    		),
    //     .type_pipeline_dcache   		( type_pipeline_dcache   		),
    //     .pipeline_dcache_vaild  		( pipeline_dcache_vaild  		),
    //     .pipeline_dcache_wstrb  		( pipeline_dcache_wstrb  		),
    //     .pipeline_dcache_opcode 		( pipeline_dcache_opcode 		),
    //     .pipeline_dcache_opflag 		( pipeline_dcache_opflag 		)
    // );

    // wire [31:0]	test1_dcache;
    // wire [31:0]	test2_dcache;
    // wire [31:0]	test3_dcache;

    // wire [31:0]	dout_dcache_pipeline;
    // wire 	dcache_pipeline_ready;//无用？
    // // wire 	dcache_pipeline_stall;

    // wire [31:0]	addr_dcache_mem;
    // wire [31:0]	dout_dcache_mem;
    // wire 	dcache_mem_req;
    // wire 	dcache_mem_wr;
    // wire [1:0]	dcache_mem_size;
    // wire [3:0]	dcache_mem_wstrb;

    // Dcache #(
    //     .index_width  		( 4 		),
    //     .offset_width 		( 2 		),
    //     .way          		( 2 		))
    // u_Dcache(
    //     //ports
    //     .clk                    		( clk                    		),
    //     .rstn                   		( rstn                   		),
    //     .test1                  		( test1_dcache           		),
    //     .test2                  		( test2_dcache           		),
    //     .test3                  		( test3_dcache           		),

    //     .addr_pipeline_dcache   		( addr_pipeline_dcache          ),
    //     .din_pipeline_dcache    		( din_pipeline_dcache    		),
    //     .dout_dcache_pipeline   		( dout_dcache_pipeline   		),
    //     .type_pipeline_dcache   		( type_pipeline_dcache   		),
    //     .pipeline_dcache_vaild  		( pipeline_dcache_vaild  		),
    //     .dcache_pipeline_ready  		( dcache_pipeline_ready  		),
    //     .pipeline_dcache_wstrb  		( pipeline_dcache_wstrb  		),
    //     .pipeline_dcache_opcode 		( pipeline_dcache_opcode 		),
    //     .pipeline_dcache_opflag 		( pipeline_dcache_opflag 		),
    //     .pipeline_dcache_ctrl   		( {30'b0,flush_exe0_exe1,stall_to_dcache}),
    //     .dcache_pipeline_stall  		( stall_dcache  		        ),

    //     .addr_dcache_mem        		( addr_dcache_mem        		),
    //     .dout_dcache_mem        		( dout_dcache_mem        		),
    //     .din_mem_dcache         		( din_mem_dcache         		),
    //     .dcache_mem_req         		( dcache_mem_req         		),
    //     .dcache_mem_wr          		( dcache_mem_wr          		),
    //     .dcache_mem_size        		( dcache_mem_size        		),
    //     .dcache_mem_wstrb       		( dcache_mem_wstrb       		),
    //     .mem_dcache_addrOK      		( mem_dcache_addrOK      		),
    //     .mem_dcache_dataOK      		( mem_dcache_dataOK      		)
    // );

    wire [31:0]	dout_dcache_pipeline;

    dcache_testonly u_dcache_testonly(
        //ports
        .clk      		( clk      		),
        .rstn     		( rstn     		),
        .addr     		( rrj1_forward+imm_reg_exe0_1 ),
        .data_reg 		( dout_dcache_pipeline  )
    );

    writeback u_writeback(
        //ports
        .ifwb0    		( ifwb0    		),
        .ifwb1    		( ifwb1    		),
        .result_exe1_wb_0 		( result_exe1_wb_0 		),
        .result_exe1_wb_1 		( result_exe1_wb_1 		),
        .ctr_exe1_wb_0    		( ctr_exe1_wb_0    		),
        .ctr_exe1_wb_1    		( ctr_exe1_wb_1    		),
        .rd_exe1_wb_0     		( rd_exe1_wb_0     		),
        .rd_exe1_wb_1     		( rd_exe1_wb_1     		),
        .wb_data0         		( wb_data0         		),
        .wb_data1         		( wb_data1         		),
        .wb_addr0         		( wb_addr0         		),
        .wb_addr1         		( wb_addr1         		)
    );

    //PC
    always @(*) begin
        if(ifbr_priv) npc=priv_pc;
        else if(ifbr1) npc=brresult1;
        else if(ifbr0) npc=brresult0;
        else if(pc[2]) npc=pc+4;
        else npc=pc+8;
        //0000 0004 0008 000C 0010
        //0000 0100 1000 1100 10000
    end    
    always @(posedge clk,negedge rstn) begin
        if(!rstn) pc<=0;
        else if(!stall_pc) pc<=npc;
    end

    //IF0-IF1
    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_if0_if1) begin
            pc_if0_if1<=0;
        end
        else if(!stall_if0_if1)begin
            pc_if0_if1<=pc;
        end
    end

    //IF1-FIFO
    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_if1_fifo) begin
            pc_if1_fifo<=0;ir_if1_fifo<=0;icache_valid_if1_fifo<=0;flag_if1_fifo<=0;
        end
        else if(!stall_if1_fifo)begin
            pc_if1_fifo<=pc_if0_if1;
            ir_if1_fifo<=dout_icache_pipeline;
            icache_valid_if1_fifo<=icache_pipeline_ready;
            flag_if1_fifo<=flag_icache_pipeline;
        end
    end

    //FIFO-ID
    //即fetch_buffer

    //ID-REG
    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_id_reg0) begin
            ctr_id_reg_0 <= 0;
            excp_arg_id_reg_0<=0;
            imm_id_reg_0<=0;
            rk_id_reg_0<=0;
            rj_id_reg_0<=0;
            rd_id_reg_0<=0;
            pc_id_reg_0<=0;
        end
        else if(!stall_id_reg0)begin
            ctr_id_reg_0 <= control00;
            excp_arg_id_reg_0<=excp_arg00;
            imm_id_reg_0<=imm00;
            rk_id_reg_0<=rk00;
            rj_id_reg_0<=rj00;
            rd_id_reg_0<=rd00;
            pc_id_reg_0<=pc00;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_id_reg1) begin
            ctr_id_reg_1 <= 0;
            excp_arg_id_reg_1<=0;
            imm_id_reg_1<=0;
            rk_id_reg_1<=0;
            rj_id_reg_1<=0;
            rd_id_reg_1<=0;
            pc_id_reg_1<=0;
        end
        else if(!stall_id_reg1)begin
            ctr_id_reg_1 <= control11;
            excp_arg_id_reg_1<=excp_arg11;
            imm_id_reg_1<=imm11;
            rk_id_reg_1<=rk11;
            rj_id_reg_1<=rj11;
            rd_id_reg_1<=rd11;
            pc_id_reg_1<=pc11;
        end
    end

    //REG-EXE0
    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_reg_exe0_0) begin
            ctr_reg_exe0_0 <= 0;
            // excp_arg_reg_exe0_0<=0;
            imm_reg_exe0_0<=0;
            rk_reg_exe0_0<=0;
            rj_reg_exe0_0<=0;
            rd_reg_exe0_0<=0;
            rrk_reg_exe0_0<=0;
            rrj_reg_exe0_0<=0;
            rrd_reg_exe0_0<=0;
            pc_reg_exe0_0<=0;
        end
        else if(!stall_reg_exe0_0)begin
            ctr_reg_exe0_0 <= ctr_id_reg_0;
            // excp_arg_reg_exe0_0<=excp_arg_id_reg_0;
            imm_reg_exe0_0<=imm_id_reg_0;
            rrk_reg_exe0_0<=rrk0_rf;
            rrj_reg_exe0_0<=rrj0_rf;
            rrd_reg_exe0_0<=rrd0_rf;
            rk_reg_exe0_0<=rk_id_reg_0;
            rj_reg_exe0_0<=rj_id_reg_0;
            rd_reg_exe0_0<=rd_id_reg_0;
            pc_reg_exe0_0<=pc_id_reg_0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_reg_exe0_1) begin
            ctr_reg_exe0_1 <= 0;
            excp_arg_reg_exe0_1<=0;
            imm_reg_exe0_1<=0;
            rk_reg_exe0_1<=0;
            rj_reg_exe0_1<=0;
            rd_reg_exe0_1<=0;
            rrk_reg_exe0_1<=0;
            rrj_reg_exe0_1<=0;
            rrd_reg_exe0_1<=0;
            pc_reg_exe0_1<=0;
        end
        else if(!stall_reg_exe0_1)begin
            ctr_reg_exe0_1 <= ctr_id_reg_1;
            excp_arg_reg_exe0_1<=excp_arg_id_reg_1;
            imm_reg_exe0_1<=imm_id_reg_1;
            rrk_reg_exe0_1<=rrk1_rf;
            rrj_reg_exe0_1<=rrj1_rf;
            rrd_reg_exe0_1<=rrd1_rf;
            rk_reg_exe0_1<=rk_id_reg_1;
            rj_reg_exe0_1<=rj_id_reg_1;
            rd_reg_exe0_1<=rd_id_reg_1;
            pc_reg_exe0_1<=pc_id_reg_1;
        end
    end

    //EXE0-EXE1
    localparam liwai = 32'd3,excp_argALE='b001001,excp_argIPE='b0_001110;
    wire [1:0]addr_2=rrj1_forward[1:0]+imm_reg_exe0_1[1:0];

    always @(*) begin//检测访存地址是否对齐，特权指令是否内核态，否则将访存指令变为例外指令
        ctr_reg_exe0_1_ALE=ctr_reg_exe0_1;
        excp_arg_reg_exe0_1_excp=excp_arg_reg_exe0_1;
        if(ctr_reg_exe0_1[23]&(|PLV)) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argIPE; end
        else if(ctr_reg_exe0_1[3:0]==5)
            case (ctr_reg_exe0_1[11:7])
                1: if(addr_2[0]  ) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                2: if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                4: if(addr_2[0]  ) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                5: if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                7: if(addr_2[0]  ) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
            endcase
        else if(ctr_reg_exe0_1[3:0]==6)
            case (ctr_id_reg_1[11:7])//fot yuanzi, 0:load, 1:store
                0: if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                1: if(llbit) if(|addr_2[1:0]) begin ctr_reg_exe0_1_ALE=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
            endcase
    end
    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_exe0_exe1_0) begin
            ctr_exe0_exe1_0 <= 0;
            rd_exe0_exe1_0 <= 0;
            aluresult_exe0_exe1_0 <= 0;
        end
        else if(!stall_exe0_exe1_0)begin
            ctr_exe0_exe1_0 <= ctr_reg_exe0_0;
            rd_exe0_exe1_0 <= rd_reg_exe0_0;
            aluresult_exe0_exe1_0 <= aluresult0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_exe0_exe1_1) begin
            ctr_exe0_exe1_1 <= 0;
            rd_exe0_exe1_1<=0;
            aluresult_exe0_exe1_1<=0;
        end
        else if(!stall_exe0_exe1_1)begin
            ctr_exe0_exe1_1 <= ctr_reg_exe0_1_ALE;
            rd_exe0_exe1_1<=rd_reg_exe0_1;
            aluresult_exe0_exe1_1<=aluresult1;
        end
    end

    //EXE1-WB
    reg [31:0]result0,result1;
    always @(*) begin//0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:priv+dcache, 7:RDCNT, 8:alu+br
        result0=0;
        result1=0;
        case (ctr_exe0_exe1_0[3:0])
            0: result0=aluresult_exe0_exe1_0;
            1: ;
            2: result0=divresult0;
            4: result0=mulresult0;
            8: result0=aluresult_exe0_exe1_0;
        endcase
        case (ctr_exe0_exe1_1[3:0])
            0: result1=aluresult_exe0_exe1_1;
            1: ;
            2: result1=divresult1;
            3: result1=privresult1;
            4: result1=mulresult1;
            5: result1=dout_dcache_pipeline;
            6: result1=dout_dcache_pipeline;
            7: ;
            8: result1=aluresult_exe0_exe1_1;
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_exe1_wb_0) begin
            ctr_exe1_wb_0 <= 0;
            ctr_exe1_wb_1 <= 0;
            rd_exe1_wb_0<=0;
            rd_exe1_wb_1<=0;
            result_exe1_wb_0<=0;
            result_exe1_wb_1<=0;
        end
        else if(!stall_exe1_wb_0)begin
            ctr_exe1_wb_0 <= ctr_exe0_exe1_0;
            ctr_exe1_wb_1 <= ctr_exe0_exe1_1;
            rd_exe1_wb_0<=rd_exe0_exe1_0;
            rd_exe1_wb_1<=rd_exe0_exe1_1;
            result_exe1_wb_0<=result0;
            result_exe1_wb_1<=result1;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn|flush_exe1_wb_1) begin
            ctr_exe1_wb_0 <= 0;
            ctr_exe1_wb_1 <= 0;
            rd_exe1_wb_0<=0;
            rd_exe1_wb_1<=0;
            result_exe1_wb_0<=0;
            result_exe1_wb_1<=0;
        end
        else if(!stall_exe1_wb_1)begin
            ctr_exe1_wb_0 <= ctr_exe0_exe1_0;
            ctr_exe1_wb_1 <= ctr_exe0_exe1_1;
            rd_exe1_wb_0<=rd_exe0_exe1_0;
            rd_exe1_wb_1<=rd_exe0_exe1_1;
            result_exe1_wb_0<=result0;
            result_exe1_wb_1<=result1;
        end
    end
endmodule

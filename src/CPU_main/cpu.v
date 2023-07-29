`define predictor
//`define DMA
//module mycpu_top(
module core_top(
    input           aclk,
    input           aresetn,
    input    [ 7:0] intrpt, 

    //AXI interface 
    //read reqest
    output   [ 3:0] arid,
    output   [31:0] araddr,
    output   [ 7:0] arlen,
    output   [ 2:0] arsize,
    output   [ 1:0] arburst,
    output   [ 1:0] arlock,
    output   [ 3:0] arcache,
    output   [ 2:0] arprot,
    output          arvalid,
    input           arready,
    //read back
    input    [ 3:0] rid,
    input    [31:0] rdata,
    input    [ 1:0] rresp,
    input           rlast,
    input           rvalid,
    output          rready,
    //write request
    output   [ 3:0] awid,
    output   [31:0] awaddr,
    output   [ 7:0] awlen,
    output   [ 2:0] awsize,
    output   [ 1:0] awburst,
    output   [ 1:0] awlock,
    output   [ 3:0] awcache,
    output   [ 2:0] awprot,
    output          awvalid,
    input           awready,
    //write data
    output   [ 3:0] wid,
    output   [31:0] wdata,
    output   [ 3:0] wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    //write back
    input    [ 3:0] bid,
    input    [ 1:0] bresp,
    input           bvalid,
    output          bready,

    //debug
    input           break_point,
    input           infor_flag,
    input    [ 4:0] reg_num,
    output          ws_valid,
    output   [31:0] rf_rdata,
     
    output   [31:0] debug0_wb_pc,
    output   [ 3:0] debug0_wb_rf_wen,
    output   [ 4:0] debug0_wb_rf_wnum,
    output   [31:0] debug0_wb_rf_wdata,
    output   [31:0] debug0_wb_inst,
    output          debug0_stall_exe1_wb,
         
    output   [31:0] debug1_wb_pc,
    output   [ 3:0] debug1_wb_rf_wen,
    output   [ 4:0] debug1_wb_rf_wnum,
    output   [31:0] debug1_wb_rf_wdata,
    output   [31:0] debug1_wb_inst,
    output          debug1_stall_exe1_wb
);
    wire clk=aclk;
    wire rstn=aresetn;
    parameter offset_width = 3;

    reg [31:0]pc,npc,
    ctr_id_reg_0,       ctr_id_reg_1,       
    ctr_reg_exe0_0,     ctr_reg_exe0_1,     ctr_reg_exe0_1_excp,
    ctr_exe0_exe1_0,    ctr_exe0_exe1_1,
    ctr_exe1_wb_0,      ctr_exe1_wb_1,
    pc_id_reg_0,        pc_id_reg_1,        pc_if1_fifo,        pc_if0_if1,
    pc_reg_exe0_0,      pc_reg_exe0_1,      pc_exe0_exe1_0,     pc_exe0_exe1_1,
    pc_exe1_wb_0,       pc_exe1_wb_1,
    npc_if1_fifo,
    npc_id_reg_0,       npc_id_reg_1,
    npc_reg_exe0_0,     npc_reg_exe0_1,
    result_exe0_exe1_0, result_exe0_exe1_1,
    result_exe1_wb_0,   result_exe1_wb_1,
    rrk_reg_exe0_0,     rrj_reg_exe0_0,
    rrk_reg_exe0_1,     rrj_reg_exe0_1,
    rrd_reg_exe0_0,     rrd_reg_exe0_1,
    imm_reg_exe0_0,     imm_reg_exe0_1,
    imm_id_reg_0,       imm_id_reg_1,
    ir_id_reg_0,        ir_id_reg_1,
    ir_reg_exe0_0,      ir_reg_exe0_1,
    ir_exe0_exe1_0,     ir_exe0_exe1_1,
    ir_exe1_wb_0,       ir_exe1_wb_1,
    addr_pipeline_dcache_exe0_exe1,
    din_pipeline_dcache_exe0_exe1,          din_pipeline_dcache_exe1_wb,
    vaddr_exe1_wb,      paddr_exe1_wb,
    vaddr_exe0_exe1,    paddr_exe0_exe1;

    reg ir_valid_id_reg_0,ir_valid_id_reg_1,ir_valid_reg_exe0_0,ir_valid_reg_exe0_1,ir_valid_exe0_exe1_0,ir_valid_exe0_exe1_1,ir_valid_exe1_wb_0,ir_valid_exe1_wb_1,icache_valid_if1_fifo,flag_if1_fifo,LLbit_exe0_exe1;

    reg [1:0]PLV_if0_if1,PLV_if1_fifo;
    
    reg [15:0]excp_arg_reg_exe0_1,excp_arg_reg_exe0_1_excp,excp_arg_id_reg_1;
    reg [15:0]MMU_pipeline_excp_arg0_if1_fifo;

    reg [63:0]ir_if1_fifo;

    reg [63:0]pre_mmu_if0,pre_if0_if1,pre_if1_fifo,pre_id_reg_0,pre_id_reg_1,pre_reg_exe0_0,pre_reg_exe0_1;

    reg [4:0]rd_exe1_wb_0,rd_exe1_wb_1,
    rk_reg_exe0_0,rk_reg_exe0_1,
    rj_reg_exe0_0,rj_reg_exe0_1,
    rd_reg_exe0_0,rd_reg_exe0_1,
    rd_id_reg_0,rd_id_reg_1,
    rk_id_reg_0,rk_id_reg_1,
    rj_id_reg_0,rj_id_reg_1,
    rd_exe0_exe1_0,rd_exe0_exe1_1;

    localparam TLB_n=5,TLB_PALEN=32;

    reg [TLB_n-1:0] rand_index_exe0_exe1,rand_index_exe1_wb;

    reg [63:0]countresult_exe1_wb_0,countresult_exe1_wb_1,countresult_exe0_exe1_0,countresult_exe0_exe1_1;

    //PRIV
    wire LLbit;
    wire [1:0]PLV;
    wire [31:0]pc_priv;
    wire [31:0]privresult;
    wire ifpriv,excp_flush;
    wire ifidle;
    wire [15:0]MMU_pipeline_excp_arg1;

    wire ifbr0,ifbr1,ifcacop_ibar;
    wire ifmmu_excp=MMU_pipeline_excp_arg1[15];
    wire stall_div0,stall_div1,stall_fetch_buffer;
    wire stall_dcache,stall_icache;
    wire flush_if0_if1,flush_if1_fifo,flush_fifo_id,flush_id_reg0,flush_id_reg1,flush_reg_exe0_0,flush_reg_exe0_1,flush_exe0_exe1_0,flush_exe0_exe1_1,flush_exe1_wb_0,flush_exe1_wb_1,flushup,flushdown;
    wire stall_pc,stall_if0_if1,stall_if1_fifo,stall_fifo_id,stall_id_reg0,stall_id_reg1,stall_reg_exe0_0,stall_reg_exe0_1,stall_exe0_exe1_0,stall_exe0_exe1_1,stall_exe1_wb_0,stall_exe1_wb_1,stall_to_icache,stall_to_dcache,flush_pre0,flush_pre1;

    assign flushup=flush_pre1&ctr_reg_exe0_0[31];
    assign flushdown=flush_pre1&ctr_id_reg_1[31];
    assign flush_if0_if1 =      ifpriv|ifbr1|ifbr0|ifcacop_ibar|ifmmu_excp|ifidle;
    assign flush_if1_fifo =     ifpriv|ifbr1|ifbr0|ifcacop_ibar|ifmmu_excp|ifidle;
    assign flush_fifo_id =      ifpriv|ifbr1|ifbr0|ifcacop_ibar|ifmmu_excp|ifidle;
    assign flush_id_reg0 =      ifpriv|ifbr1|ifbr0|ifcacop_ibar|ifmmu_excp|ifidle;
    assign flush_id_reg1 =      ifpriv|ifbr1|ifbr0|ifcacop_ibar|ifmmu_excp|ifidle;
    assign flush_reg_exe0_0 =   ifpriv|ifbr1|ifbr0|ifcacop_ibar|ifmmu_excp|ifidle;
    assign flush_reg_exe0_1 =   ifpriv|ifbr1|ifbr0|ifcacop_ibar|ifmmu_excp|ifidle|flushdown;
    assign flush_exe0_exe1_0 =  ifpriv|ifbr1|ifcacop_ibar|ifmmu_excp|ifidle|flushup;
    assign flush_exe0_exe1_1 =  ifmmu_excp|excp_flush;
    assign flush_exe1_wb_0 =    ifmmu_excp|excp_flush;
    assign flush_exe1_wb_1 =    ifmmu_excp|excp_flush;

    assign stall_pc =           break_point|stall_fetch_buffer|stall_div1|stall_dcache|stall_icache;
    assign stall_if0_if1 =      break_point|stall_fetch_buffer|stall_div1|stall_dcache|stall_icache;
    assign stall_to_icache =    break_point|stall_fetch_buffer|stall_div1|stall_dcache;
    assign stall_if1_fifo =     break_point|stall_fetch_buffer|stall_div1|stall_dcache;
    assign stall_fifo_id =      break_point|stall_div1|stall_dcache;
    assign stall_id_reg0 =      break_point|stall_div1|stall_dcache;
    assign stall_id_reg1 =      break_point|stall_div1|stall_dcache;
    assign stall_reg_exe0_0 =   break_point|stall_div1|stall_dcache;
    assign stall_reg_exe0_1 =   break_point|stall_div1|stall_dcache;
    assign stall_exe0_exe1_0 =  break_point|stall_div1|stall_dcache;
    assign stall_exe0_exe1_1 =  break_point|stall_div1|stall_dcache;
    assign stall_to_dcache =    break_point|stall_div1;
    assign stall_exe1_wb_0 =    break_point|stall_div1|stall_dcache;
    assign stall_exe1_wb_1 =    break_point|stall_div1|stall_dcache;

    //ICache Return Buffer
    wire        mem_icache_addrOK;
    wire        mem_icache_dataOK;
    wire 	    icache_mem_req;
    wire [32*(1<<offset_width)-1:0]     din_mem_icache;
    wire    i_rready;
    wire    [31:0] i_rdata;
    wire    i_rlast;

    //ICache
    wire [63:0]	dout_icache_pipeline;
    wire 	    flag_icache_pipeline;
    wire        icache_pipeline_ready;

    wire [31:0]	addr_icache_mem;
    wire [1:0]	icache_mem_size;

    wire [31:0]	MMU_pipeline_PADDR0;
    wire [31:0] pc_icache_pipeline;

    wire    [31:0]	pc0;
    wire    [31:0]	pc1;
    wire    [31:0]	ir0;
    wire    [31:0]	ir1;
    wire 	if0;
    wire 	if1;
    wire    ir_valid0;
    wire    ir_valid1;
    wire    [1:0]   PLV0;
    wire    [1:0]   PLV1;
    wire    [63:0]  pre0;
    wire    [63:0]  pre1;
    wire    [15:0]  excp_arg0_mmu;
    wire    [15:0]  excp_arg1_mmu;
    wire    [31:0]  npc0;
    wire    [31:0]  npc1;
    
    fetch_buffer_v2 u_fetch_buffer(
        //ports
        .pc             ( pc_if1_fifo   ),
        .flush          ( flush_fifo_id ),
        .stall          ( stall_fifo_id ),
        .icache_valid   ( icache_valid_if1_fifo),
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
        .valid0         ( ir_valid0     ),
        .valid1         ( ir_valid1     ),
        .stall_fetch_buffer(stall_fetch_buffer),
        .plv            ( PLV_if1_fifo  ),
        .plv0           ( PLV0          ),
        .plv1           ( PLV1          ),
        .pre            ( pre_if1_fifo  ),
        .pre0           ( pre0          ),
        .pre1           ( pre1          ),
        .excp_arg       ( MMU_pipeline_excp_arg0_if1_fifo),
        .excp_arg0      ( excp_arg0_mmu ),
        .excp_arg1      ( excp_arg1_mmu ),
        .npc            ( npc_if1_fifo  ),
        .npc0           ( npc0          ),
        .npc1           ( npc1          )
    );

    wire [31:0]	control0;
    wire [4:0]	rk0;
    wire [4:0]	rj0;
    wire [4:0]	rd0;
    wire [31:0]	imm0;
    wire [15:0]	excp_arg0;

    decoder u_decoder0(
        //ports
        .PLV            ( PLV0              ),
        .pc             ( pc0               ),
        .ir       		( ir0 	    	    ),
        .control  		( control0  		),
        .rk       		( rk0       		),
        .rj       		( rj0       		),
        .rd       		( rd0       		),
        .imm      		( imm0      		),
        .excp_arg 		( excp_arg0 		),
        .valid          ( ir_valid0         ),
        .excp_arg_in    ( excp_arg0_mmu     )
    );

    wire [31:0]	control1;
    wire [4:0]	rk1;
    wire [4:0]	rj1;
    wire [4:0]	rd1;
    wire [31:0]	imm1;
    wire [15:0]	excp_arg1;

    decoder u_decoder1(
        //ports
        .PLV            ( PLV1              ),
        .pc             ( pc1               ),
        .ir       		( ir1        	    ),
        .control  		( control1  		),
        .rk       		( rk1       		),
        .rj       		( rj1       		),
        .rd       		( rd1       		),
        .imm      		( imm1      		),
        .excp_arg 		( excp_arg1 		),
        .valid          ( ir_valid1         ),
        .excp_arg_in    ( excp_arg1_mmu     )
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
    wire [31:0] pc00;
    wire [31:0] pc11;
    wire [31:0] ir00;
    wire [31:0] ir11;
    wire ir_valid00;
    wire ir_valid11;
    wire [63:0]pre00;
    wire [63:0]pre11;
    wire [31:0]npc00;
    wire [31:0]npc11;

    dispatcher u_dispatcher(
        //ports
        .clk     		    ( clk     		    ),
        .rstn    		    ( rstn    		    ),
        .flush              ( flush_fifo_id     ),
        .stall              ( stall_fifo_id     ),
        .pc0                ( pc0               ),
        .pc1                ( pc1               ),
        .ir0                ( ir0               ),
        .ir1                ( ir1               ),
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
        .pc00               ( pc00              ),
        .pc11               ( pc11              ),
        .ir00               ( ir00              ),
        .ir11               ( ir11              ),
        .control00  		( control00  		),
        .control11  		( control11  		),
        .excp_arg00 		( excp_arg00 		),
        .excp_arg11 		( excp_arg11 		),
        .if0        		( if0        		),
        .if1        		( if1        		),
        .valid0     		( ir_valid0	        ),
        .valid1     		( ir_valid1	        ),
        .valid00     		( ir_valid00	    ),
        .valid11     		( ir_valid11	    ),
        .pre0               ( pre0              ),
        .pre1               ( pre1              ),
        .pre00              ( pre00             ),
        .pre11              ( pre11             ),
        .npc0               ( npc0              ),
        .npc1               ( npc1              ),
        .npc00              ( npc00             ),
        .npc11              ( npc11             )
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
    wire [31:0] regs[31:0];

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
        .rrd1     		( rrd1_rf     		),
        .rf_rdata       ( rf_rdata     		),
        .reg_num        ( reg_num     		),
        .infor_flag     ( infor_flag     		),
        .reg0          (regs[0]    ),
        .reg1           (regs[1]    ),
        .reg2           (regs[2]    ),
        .reg3           (regs[3]    ),
        .reg4           (regs[4]    ),
        .reg5           (regs[5]    ),
        .reg6           (regs[6]    ),
        .reg7           (regs[7]    ),
        .reg8           (regs[8]    ),
        .reg9           (regs[9]    ),
        .reg10          (regs[10]   ),
        .reg11          (regs[11]   ),
        .reg12          (regs[12]   ),
        .reg13          (regs[13]   ),
        .reg14          (regs[14]   ),
        .reg15          (regs[15]   ),
        .reg16          (regs[16]   ),
        .reg17          (regs[17]   ),
        .reg18          (regs[18]   ),
        .reg19          (regs[19]   ),
        .reg20          (regs[20]   ),
        .reg21          (regs[21]   ),
        .reg22          (regs[22]   ),
        .reg23          (regs[23]   ),
        .reg24          (regs[24]   ),
        .reg25          (regs[25]   ),
        .reg26          (regs[26]   ),
        .reg27          (regs[27]   ),
        .reg28          (regs[28]   ),
        .reg29          (regs[29]   ),
        .reg30          (regs[30]   ),
        .reg31          (regs[31]   )
    );

    wire [31:0]	rrj0_forward;
    wire [31:0]	rrj1_forward;
    wire [31:0]	rrk0_forward;
    wire [31:0]	rrk1_forward;
    wire [31:0]	rrd0_forward;
    wire [31:0]	rrd1_forward;

    wire [31:0]	dcacheresult;

    forward u_forward(
        //ports
        .ctr_exe1_wb_0(ctr_exe1_wb_0),
        .ctr_exe1_wb_1(ctr_exe1_wb_1),
        .ctr_exe0_exe1_0(ctr_exe0_exe1_0),
        .ctr_exe0_exe1_1(ctr_exe0_exe1_1),
        .result_exe0_exe1_0 		( result_exe0_exe1_0 		),
        .result_exe0_exe1_1 		( result_exe0_exe1_1 		),
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
        .rj0                   		( rj_reg_exe0_0               	),
        .rj1                   		( rj_reg_exe0_1               	),
        .rk0                   		( rk_reg_exe0_0               	),
        .rk1                   		( rk_reg_exe0_1               	),
        .rd0                        ( rd_reg_exe0_0                 ),
        .rd1                        ( rd_reg_exe0_1                 ),
        .rrj0                  		( rrj0_forward                  ),
        .rrj1                  		( rrj1_forward                  ),
        .rrk0                  		( rrk0_forward                  ),
        .rrk1                  		( rrk1_forward                  ),
        .rrd0                       ( rrd0_forward                  ),
        .rrd1                       ( rrd1_forward                  )
    );

    wire [31:0]	alu1_0;

    alusrc u_alusrc1_0(
        //ports
        .register0 		( rrj0_forward 		),
        .register1    	( pc_reg_exe0_0    		),
        .register2 		( 0 		),
        .register3 		( 0 		),
        .alusrc_   		( ctr_reg_exe0_0[15:14]   		),
        .alu      		( alu1_0      		)
    );

    wire [31:0]	alu2_0;

    alusrc u_alusrc2_0(
        //ports
        .register0 		( rrk0_forward 		),
        .register1    	( imm_reg_exe0_0    		),
        .register2 		( rrd0_forward 		),
        .register3 		( 4 		),
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
        .alusrc_   		( ctr_reg_exe0_1_excp[15:14]   		),
        .alu      		( alu1_1      		)
    );

    wire [31:0]	alu2_1;

    alusrc u_alusrc2_1(
        //ports
        .register0 		( rrk1_forward 		),
        .register2 		( rrd1_forward 		),
        .register3 		( 4 		),
        .register1    	( imm_reg_exe0_1    		),
        .alusrc_   		( ctr_reg_exe0_1_excp[13:12]   		),
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
        .ctr       		( ctr_reg_exe0_1_excp       		),
        .aluresult 		( aluresult1		),
        .zero      		( zero1     		)
    );

    wire [31:0] countresult0;
    wire [31:0] countresult1;
    wire [63:0] countresult;

    counter u_counter(
        //ports
        .clk  		    ( clk  		),
        .rstn 		    ( rstn 		),
        .ctr0  		    ( ctr_reg_exe0_0  	),
        .countresult0 	( countresult0		),
        .ctr1  		    ( ctr_reg_exe0_1_excp),
        .countresult1 	( countresult1		),
        .countresult    ( countresult		)
    );

    wire [31:0]	mulresult0;

    muitiplier u_muitiplier0(
        //ports
        .clk                         		( clk                       ),
        .rstn                        		( rstn                      ),
        .pipeline_muitiplier_flush   		( flush_exe0_exe1_0   		),
        .pipeline_muitiplier_stall   		( stall_exe0_exe1_0   		),
        // .pipeline_muitiplier_type 	    ( ctr_reg_exe0_0[3:0] 		),
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
        // .pipeline_muitiplier_type 		    ( ctr_reg_exe0_1_excp[3:0] 		),
        .pipeline_muitiplier_subtype 		( ctr_reg_exe0_1_excp[11:7] 		),
        .pipeline_muitiplier_din1    		( rrj1_forward    		),
        .pipeline_muitiplier_din2    		( rrk1_forward    		),
        .muitiplier_pipeline_dout    		( mulresult1    		)
    );

    wire [31:0] divresult0;

    divider #(
        .WIDTH 		( 32 		))
    u_divider0(
        //ports
        .clk                      		( clk                      		),
        .rstn                     		( rstn                     		),
        .pipeline_divider_type    		( ctr_reg_exe0_0[3:0]    		),
        .pipeline_divider_subtype 		( ctr_reg_exe0_0[11:7] 		),
        .pipeline_divider_stall1   		( stall_exe0_exe1_0   		),
        .pipeline_divider_flush1   		( flush_exe0_exe1_0   		),
        .pipeline_divider_stall2   		( stall_exe1_wb_0   		),
        .pipeline_divider_flush2   		( flush_exe1_wb_0   		),
        .pipeline_divider_din1    		( rrj0_forward    		),
        .pipeline_divider_din2    		( rrk0_forward    		),
        .divider_pipeline_stall   		( stall_div0   		),
        .divider_pipeline_dout    		( divresult0    		)
    );

    wire [31:0] divresult1;

    divider #(
        .WIDTH 		( 32 		))
    u_divider1(
        //ports
        .clk                      		( clk                      		),
        .rstn                     		( rstn                     		),
        .pipeline_divider_type    		( ctr_reg_exe0_1_excp[3:0]    		),
        .pipeline_divider_subtype 		( ctr_reg_exe0_1_excp[11:7] 		),
        .pipeline_divider_stall1   		( stall_exe0_exe1_1   		),
        .pipeline_divider_flush1   		( flush_exe0_exe1_1   		),
        .pipeline_divider_stall2   		( stall_exe1_wb_1   		),
        .pipeline_divider_flush2   		( flush_exe1_wb_1   		),
        .pipeline_divider_din1    		( rrj1_forward    		),
        .pipeline_divider_din2    		( rrk1_forward    		),
        .divider_pipeline_stall   		( stall_div1   		),
        .divider_pipeline_dout    		( divresult1    		)
    );

    // ibar u_ibar0(
    //     //ports
    //     .ctr        	( ctr_reg_exe0_0        		),
    //     .ifibar 		( ifibar0 		)
    // );

    // ibar u_ibar1(
    //     //ports
    //     .ctr        	( ctr_reg_exe0_1_excp        		),
    //     .ifibar 		( ifibar1 		)
    // );
`ifdef predictor
    wire [31:0]	pc_br0;
    wire ifbr_0;
    wire [31:0] brresult_0;

    br_pre u_br0(
        //ports
        .ctr      		( ctr_reg_exe0_0    ),
        .pc       		( pc_reg_exe0_0     ),
        .npc            ( npc_reg_exe0_0    ),
        .imm      		( imm_reg_exe0_0    ),
        .zero     		( zero0     		),
        .ifbr     		( ifbr0    		    ),
        .ifbr_          ( ifbr_0            ),
        .brresult 		( pc_br0 	        ),
        .brresult_      ( brresult_0        ),
        .rrj            ( rrj0_forward      ),
        .pre            ( pre_reg_exe0_0    ),
        .flush_pre      ( flush_pre0        ),
        .stall          ( stall_reg_exe0_0  )
    );

    wire [31:0]	pc_br1;
    wire ifbr_1;
    wire [31:0]brresult_1;

    br_pre u_br1(
        //ports
        .ctr      		( ctr_reg_exe0_1_excp),
        .pc       		( pc_reg_exe0_1      ),
        .npc            ( npc_reg_exe0_1     ),
        .imm      		( imm_reg_exe0_1     ),
        .zero     		( zero1     		 ),
        .ifbr     		( ifbr1    		     ),
        .ifbr_          ( ifbr_1             ),
        .brresult 		( pc_br1		     ),
        .brresult_      ( brresult_1         ),
        .rrj            ( rrj1_forward       ),
        .pre            ( pre_reg_exe0_1     ),
        .flush_pre      ( flush_pre1         ),
        .stall          ( stall_reg_exe0_1  )
    );
`endif
`ifndef predictor
    wire [31:0]	pc_br0;

    br u_br0(
        //ports
        .ctr      		( ctr_reg_exe0_0    ),
        .pc       		( pc_reg_exe0_0     ),
        .imm      		( imm_reg_exe0_0    ),
        .zero     		( zero0     		),
        .ifbr     		( ifbr0    		    ),
        .brresult 		( pc_br0 	        ),
        .rrj            ( rrj0_forward      ),
        .stall          ( stall_reg_exe0_0  )
    );

    wire [31:0]	pc_br1;

    br u_br1(
        //ports
        .ctr      		( ctr_reg_exe0_1_excp),
        .pc       		( pc_reg_exe0_1      ),
        .imm      		( imm_reg_exe0_1     ),
        .zero     		( zero1     		 ),
        .ifbr     		( ifbr1    		     ),
        .brresult 		( pc_br1		     ),
        .rrj            ( rrj1_forward       ),
        .stall          ( stall_reg_exe0_1   )
    );
`endif

    wire [31:0]	addr_pipeline_dcache;
    wire [31:0]	din_pipeline_dcache;
    wire 	type_pipeline_dcache;
    wire 	pipeline_dcache_valid;
    wire [3:0]	pipeline_dcache_wstrb;
    wire [31:0]	pipeline_cache_opcode;
    wire    pipeline_l2cache_opflag;
    wire    pipeline_dcache_opflag;
    wire    pipeline_icache_opflag;
    wire    pipeline_MMU_valid;

    cache_ctr u_cache_ctr(
        //ports
        .stall                          ( stall_exe0_exe1_1             ),
        .excp_arg                       ( excp_arg_reg_exe0_1_excp      ),
        .rrj                 		    ( rrj1_forward         		    ),
        .imm                     		( imm_reg_exe0_1         		),
        .ctr                     		( ctr_reg_exe0_1_excp         	),
        .rrd                  		    ( rrd1_forward          		),
        .addr_pipeline_dcache   		( addr_pipeline_dcache   		),
        .din_pipeline_dcache    		( din_pipeline_dcache    		),
        .type_pipeline_dcache   		( type_pipeline_dcache   		),
        .pipeline_dcache_valid  		( pipeline_dcache_valid  		),
        .pipeline_MMU_valid             ( pipeline_MMU_valid            ),
        .pipeline_dcache_wstrb  		( pipeline_dcache_wstrb  		),
        .pipeline_cache_opcode 		    ( pipeline_cache_opcode 		),
        .ifcacop_ibar                   ( ifcacop_ibar                  ),
        .pipeline_l2cache_opflag        ( pipeline_l2cache_opflag       ),
        .pipeline_dcache_opflag         ( pipeline_dcache_opflag        ),
        .pipeline_icache_opflag         ( pipeline_icache_opflag        )
    );

    wire [8:0]	CRMD;
    wire [9:0]  ASID;
    wire [31:0]	DMW0;
    wire [31:0]	DMW1;
    assign PLV=CRMD[1:0];
    wire    [31:0]  csr_crmd_diff_0     ;
    wire    [31:0]  csr_prmd_diff_0     ;
    wire    [31:0]  csr_ectl_diff_0     ;
    wire    [31:0]  csr_estat_diff_0    ;
    wire    [31:0]  csr_era_diff_0      ;
    wire    [31:0]  csr_badv_diff_0     ;
    wire	[31:0]  csr_eentry_diff_0   ;
    wire 	[31:0]  csr_tlbidx_diff_0   ;
    wire 	[31:0]  csr_tlbehi_diff_0   ;
    wire 	[31:0]  csr_tlbelo0_diff_0  ;
    wire 	[31:0]  csr_tlbelo1_diff_0  ;
    wire 	[31:0]  csr_asid_diff_0     ;
    wire 	[31:0]  csr_save0_diff_0    ;
    wire 	[31:0]  csr_save1_diff_0    ;
    wire 	[31:0]  csr_save2_diff_0    ;
    wire 	[31:0]  csr_save3_diff_0    ;
    wire 	[31:0]  csr_tid_diff_0      ;
    wire 	[31:0]  csr_tcfg_diff_0     ;
    wire 	[31:0]  csr_tval_diff_0     ;
    wire 	[31:0]  csr_ticlr_diff_0    ;
    wire 	[31:0]  csr_llbctl_diff_0   ;
    wire 	[31:0]  csr_tlbrentry_diff_0;
    wire 	[31:0]  csr_dmw0_diff_0     ;
    wire 	[31:0]  csr_dmw1_diff_0     ;
    wire 	[31:0]  csr_pgdl_diff_0     ;
    wire 	[31:0]  csr_pgdh_diff_0     ;
    
    wire            ertn_flush          ;
    wire    [5:0]   csr_ecode           ;

    wire    [TLB_n-1:0] CSR_rand_index ;
    wire            CSR_tlbfill_en      ;

    wire    [31:0]  CSR_MMU_TLBIDX ;
    wire    [31:0]  CSR_MMU_TLBEHI ;
    wire    [31:0]  CSR_MMU_TLBELO0;
    wire    [31:0]  CSR_MMU_TLBELO1;
    wire    [31:0]  MMU_CSR_TLBIDX ;
    wire    [31:0]  MMU_CSR_TLBEHI ;
    wire    [31:0]  MMU_CSR_TLBELO0;
    wire    [31:0]  MMU_CSR_TLBELO1;
    wire     [9:0]  MMU_CSR_ASID   ;
    
    CSR_control #(
        .TLB_n(TLB_n),
        .TLB_PALEN(TLB_PALEN),
        .TIMER_n(32))
    u_priv(
        //ports
        .clk                    		( clk                    		),
        .rstn                   		( rstn                   		),
        // .pipeline_CSR_flush     		( flush_exe0_exe1_1     		),
        .pipeline_CSR_flush             ( 0                             ),
        // .pipeline_CSR_stall     		( stall_exe0_exe1_1     		),
        .pipeline_CSR_stall     		( 0                      		),
        .CSR_pipeline_clk_stall     	( ifidle               ),
        .CSR_pipeline_flush     		( ifpriv     		            ),
        .CSR_pipeline_outpc     		( pc_priv     		            ),
        .pipeline_CSR_type      		( ctr_reg_exe0_1_excp[3:0]     	),
        .pipeline_CSR_subtype   		( ctr_reg_exe0_1_excp[11:7]     	),
        .pipeline_CSR_din       		( rrd1_forward       		    ),
        .pipeline_CSR_mask      		( rrj1_forward      		    ),
        .CSR_pipeline_dout      		( privresult      		        ),

        .pipeline_CSR_jumpc_valid       ( ifbr0|ifbr1|ifpriv            ),
        .pipeline_CSR_jumpc             ( npc                           ),
        .pipeline_CSR_inpc_valid        ( ir_valid_reg_exe0_1           ),
        .pipeline_CSR_inpc0     		( pc_reg_exe0_1     		    ),
        .pipeline_CSR_excp_arg0 		( excp_arg_reg_exe0_1_excp      ),
        .pipeline_CSR_evaddr0   		( addr_pipeline_dcache          ),

        .pipeline_CSR_inpc1     		( pc_exe0_exe1_1     		    ),
        .pipeline_CSR_excp_arg1 		( MMU_pipeline_excp_arg1        ),
        .pipeline_CSR_evaddr1   		( addr_pipeline_dcache_exe0_exe1		),

        .pipeline_CSR_ESTAT     		( 0     		     ),
        .CSR_pipeline_CRMD      		( CRMD      		 ),
        .CSR_pipeline_LLBit     		( LLbit     		 ),
        .CSR_pipeline_ASID      		( ASID      		 ),
        .CSR_pipeline_DMW0      		( DMW0      		 ),
        .CSR_pipeline_DMW1      		( DMW1      		 ),
        
        .CSR_pipeline_TLBIDX            ( CSR_MMU_TLBIDX  ),
        .CSR_pipeline_TLBEHI            ( CSR_MMU_TLBEHI  ),
        .CSR_pipeline_TLBELO0           ( CSR_MMU_TLBELO0 ),
        .CSR_pipeline_TLBELO1           ( CSR_MMU_TLBELO1 ),
        .pipeline_CSR_TLBIDX            ( MMU_CSR_TLBIDX  ),
        .pipeline_CSR_TLBEHI            ( MMU_CSR_TLBEHI  ),
        .pipeline_CSR_TLBELO0           ( MMU_CSR_TLBELO0 ),
        .pipeline_CSR_TLBELO1           ( MMU_CSR_TLBELO1 ),
        .pipeline_CSR_ASID              ( MMU_CSR_ASID    ),
        
        //debug
        .excp_flush                     ( excp_flush         ),
        .ertn_flush                     ( ertn_flush         ),
        .rand_index                     ( CSR_rand_index    ),
        .tlbfill_en                     ( CSR_tlbfill_en     ),
        .csr_ecode                      ( csr_ecode          ),
        .csr_crmd_diff_0                ( csr_crmd_diff_0    ),
        .csr_prmd_diff_0                ( csr_prmd_diff_0    ),
        .csr_ectl_diff_0                ( csr_ectl_diff_0    ),
        .csr_estat_diff_0               ( csr_estat_diff_0   ),
        .csr_era_diff_0                 ( csr_era_diff_0     ),
        .csr_badv_diff_0                ( csr_badv_diff_0    ),
        .csr_eentry_diff_0              ( csr_eentry_diff_0  ),
        .csr_tlbidx_diff_0              ( csr_tlbidx_diff_0  ),
        .csr_tlbehi_diff_0              ( csr_tlbehi_diff_0  ),
        .csr_tlbelo0_diff_0             ( csr_tlbelo0_diff_0 ),
        .csr_tlbelo1_diff_0             ( csr_tlbelo1_diff_0 ),
        .csr_asid_diff_0                ( csr_asid_diff_0    ),
        .csr_save0_diff_0               ( csr_save0_diff_0   ),
        .csr_save1_diff_0               ( csr_save1_diff_0   ),
        .csr_save2_diff_0               ( csr_save2_diff_0   ),
        .csr_save3_diff_0               ( csr_save3_diff_0   ),
        .csr_tid_diff_0                 ( csr_tid_diff_0     ),
        .csr_tcfg_diff_0                ( csr_tcfg_diff_0    ),
        .csr_tval_diff_0                ( csr_tval_diff_0    ),
        .csr_ticlr_diff_0               ( csr_ticlr_diff_0   ),
        .csr_llbctl_diff_0              ( csr_llbctl_diff_0  ),
        .csr_tlbrentry_diff_0           ( csr_tlbrentry_diff_0),
        .csr_dmw0_diff_0                ( csr_dmw0_diff_0    ),
        .csr_dmw1_diff_0                ( csr_dmw1_diff_0    ),
        .csr_pgdl_diff_0                ( csr_pgdl_diff_0    ),
        .csr_pgdh_diff_0                ( csr_pgdh_diff_0    )
    );

    wire [15:0]	MMU_pipeline_excp_arg0;
    wire [1:0]	MMU_pipeline_memtype0;

    wire [31:0]	MMU_pipeline_PADDR1;
    wire [1:0]	MMU_pipeline_memtype1;

    Memory_Maping_Unit #(
        .TLB_n(TLB_n),
        .TLB_PALEN(TLB_PALEN),
        .TLB_VALEN(32))
    u_MMU(
        //ports
        .clk                    		( clk                    		),
        .rstn                   		( rstn                   		),
        .pipeline_MMU_stall0            ( stall_if0_if1                 ),
        .pipeline_MMU_flush0            ( flush_if0_if1                 ),
        .pipeline_MMU_stall1            ( stall_exe0_exe1_1              ),
        //.pipeline_MMU_flush1            ( flush_exe0_exe1_1              ),
        .pipeline_MMU_flush1            ( excp_flush                    ),
        .pipeline_MMU_stallw            ( 0                             ),
        .pipeline_MMU_flushw            ( 0                             ),
        .pipeline_MMU_type              ( ctr_reg_exe0_1_excp[3:0]       ),
        .pipeline_MMU_subtype           ( ctr_reg_exe0_1_excp[11:7]      ),
        .pipeline_MMU_excp_arg		    ( excp_arg_reg_exe0_1_excp      ),
        .pipeline_MMU_rj                ( rrj1_forward                  ),
        .pipeline_MMU_rk                ( rrk1_forward                  ),
        .pipeline_MMU_CRMD              ( CRMD                          ),
        .pipeline_MMU_ASID              ( ASID                          ),
        .pipeline_MMU_DMW0              ( DMW0                          ),
        .pipeline_MMU_DMW1              ( DMW1                          ),
    
        .MMU_pipeline_TLBIDX    		( MMU_CSR_TLBIDX  ),
        .MMU_pipeline_TLBEHI    		( MMU_CSR_TLBEHI  ),
        .MMU_pipeline_TLBELO0   		( MMU_CSR_TLBELO0 ),
        .MMU_pipeline_TLBELO1   		( MMU_CSR_TLBELO1 ),
        .MMU_pipeline_ASID      		( MMU_CSR_ASID    ),
        .pipeline_MMU_TLBIDX    		( CSR_MMU_TLBIDX  ),
        .pipeline_MMU_TLBEHI    		( CSR_MMU_TLBEHI  ),
        .pipeline_MMU_TLBELO0   		( CSR_MMU_TLBELO0 ),
        .pipeline_MMU_TLBELO1   		( CSR_MMU_TLBELO1 ),

        .pipeline_MMU_optype0   		( 1'b0 	),//fetch
        .pipeline_MMU_VADDR_valid0      ( 1'b1     ),
        .pipeline_MMU_VADDR0    		( pc    ),
        .MMU_pipeline_PADDR0    		( MMU_pipeline_PADDR0	        ),
        .MMU_pipeline_excp_arg0 		( MMU_pipeline_excp_arg0        ),
        .MMU_pipeline_memtype0  		( MMU_pipeline_memtype0         ),

        .pipeline_MMU_optype1   		( type_pipeline_dcache?2'd2:2'd1),
        .pipeline_MMU_VADDR_valid1      ( pipeline_MMU_valid            ),
        .pipeline_MMU_VADDR1    		( addr_pipeline_dcache 		    ),
        .MMU_pipeline_PADDR1    		( MMU_pipeline_PADDR1 		    ),
        .MMU_pipeline_excp_arg1 		( MMU_pipeline_excp_arg1 		),
        .MMU_pipeline_memtype1  		( MMU_pipeline_memtype1 	    ) 
    );

    wire [31:0]	dout_dcache_pipeline;
    wire 	dcache_pipeline_ready;//无用?

    wire [31:0]	addr_dcache_mem;
    wire [31:0]	dout_dcache_mem;
    wire 	dcache_mem_req;
    wire 	dcache_mem_wr;
    wire [1:0]	dcache_mem_size;
    wire [3:0]	dcache_mem_wstrb;
    wire [32*(1<<offset_width)-1:0] din_mem_dcache;
    wire mem_dcache_addrOK;
    wire mem_dcache_dataOK;
    wire    d_bvalid;

    wire 	d_rready;
    wire 	d_wready;
    wire    d_rlast;
    wire    [31:0] d_rdata;

    dcache_extend u_dcache_extend(
        //ports
        .ctr_exe0_exe1_1             		( ctr_exe0_exe1_1      ),
        .addr_pipeline_dcache    		    ( addr_pipeline_dcache_exe0_exe1       ),
        .dout_dcache_pipeline        		( dout_dcache_pipeline ),
        .dout_dcache_pipeline_extend 		( dcacheresult 		   ),
        .din_pipeline_dcache                ( din_pipeline_dcache_exe0_exe1 ),
        .llbit                              ( LLbit_exe0_exe1      )
    );

    writeback u_writeback(
        //ports
        .ifwb0    		        ( ifwb0    		        ),
        .ifwb1    		        ( ifwb1    		        ),
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

    //传给流水线，寄存
    wire [29:0]npc_pdc;
    wire [2:0]kind_pdc;
    wire taken_pdc;
    wire [1:0]choice_pdc;

`ifdef predictor
    //已经处理过的信号
    wire [2:0]mis_pdc;
    wire [1:0]choice_real;
    wire choice_real_btb_ras;
    wire choice_real_g_h;
    parameter NOT_JUMP = 3'd0,DIRECT_JUMP = 3'd1,JUMP=3'd2,CALL = 3'd3,RET = 3'd4,INDIRECT_JUMP = 3'd5,OTHER_JUMP = 3'd6;
    assign mis_pdc={(out_npc_ex!=out_npc_pdc),(out_kind_ex!=out_kind_pdc),(out_taken_ex!=out_taken_pdc)};
    assign choice_real={choice_real_btb_ras,choice_real_g_h};
    assign choice_real_btb_ras=mis_pdc[2]?~out_choice_pdc[1]:out_choice_pdc[1];
    assign choice_real_g_h=mis_pdc[0]?~out_choice_pdc[1]:out_choice_pdc[1];

    wire [29:0]npc_test;//给ccr用的测试线，�??要左移两位使用，0,4交替

    wire        out_taken_pdc ;
    wire [2:0]  out_kind_pdc  ;
    wire [29:0] out_npc_pdc   ;
    wire        out_taken_ex  ;
    wire [2:0]  out_kind_ex   ;
    wire [29:0] out_npc_ex    ;
    wire [29:0] out_pc_ex     ;
    wire [1:0]  out_choice_pdc;
    wire update_en;

    predictor #(
        .k_width       		( 14   		),
        .h_width       		( 14   		),
        .stack_len     		( 16   		),
        .queue_len     		( 16   		),
        .ADDR_WIDTH    		( 30   		))
    u_predictor(
        //ports
        .clk         		( clk         		),
        .rstn        		( rstn        		),
        .update_en          ( update_en         ),

        .pc_ex       		( out_pc_ex         ),
        .mis_pdc     		( mis_pdc     		),
        .npc_ex      		( out_npc_ex  	    ),
        .kind_ex     		( out_kind_ex       ),
        .taken_real  		( out_taken_ex 		),
        .choice_real 		( choice_real 		),

        .npc_pdc     		( npc_pdc  	    	),
        .kind_pdc    		( kind_pdc       	),
        .taken_pdc   		( taken_pdc        	),
        .choice_pdc  		( choice_pdc    	),

        .pc          		( pc[31:2]          ),
        .npc_test           ( npc_test          )
    );

    ex_buffer #(
        .length(4)
    )u_ex_buffer(
        .clk(clk),
        .rstn(rstn),
        .flag(ctr_reg_exe0_0[31]&ctr_reg_exe0_1[31]),
        .stall(stall_reg_exe0_0|(~ctr_reg_exe0_0[31]&~ctr_reg_exe0_1[31])),

        .in_taken_pdc_0(pre_reg_exe0_0[33]),
        .in_kind_pdc_0(pre_reg_exe0_0[32:30]),
        .in_npc_pdc_0(pre_reg_exe0_0[29:0]),
        .in_choice_pdc_0(pre_reg_exe0_0[36:35]),
        .in_taken_ex_0(ifbr_0),
        .in_kind_ex_0(ctr_reg_exe0_0[26:24]),
        .in_npc_ex_0(brresult_0),
        .in_pc_ex_0(pc_reg_exe0_0[31:2]),
        .in_flush_pre_0(flush_pre0),

        .in_taken_pdc_1(pre_reg_exe0_1[33]),
        .in_kind_pdc_1(pre_reg_exe0_1[32:30]),
        .in_npc_pdc_1(pre_reg_exe0_1[29:0]),
        .in_choice_pdc_1(pre_reg_exe0_1[36:35]),
        .in_taken_ex_1(ifbr_1),
        .in_kind_ex_1(ctr_reg_exe0_1[26:24]),
        .in_npc_ex_1(brresult_1),
        .in_pc_ex_1(pc_reg_exe0_1[31:2]),
        .in_flush_pre_1(flush_pre1),

        .out_taken_pdc (out_taken_pdc ),
        .out_kind_pdc  (out_kind_pdc  ),
        .out_npc_pdc   (out_npc_pdc   ),
        .out_taken_ex  (out_taken_ex  ),
        .out_kind_ex   (out_kind_ex   ),
        .out_npc_ex    (out_npc_ex    ),
        .out_pc_ex     (out_pc_ex     ),
        .out_choice_pdc(out_choice_pdc),

        .update_en     (update_en)
    );
`endif

    //PC
    wire [31:0]npc_pdc_32={npc_pdc,2'b0};
    reg ifnpc_pdc;
    always @(*) begin
        ifnpc_pdc=0;
        if(ifpriv) npc=pc_priv;
        else if(ifbr1) npc=pc_br1;
        else if(ifcacop_ibar) npc=pc_reg_exe0_1+4;
        else if(ifbr0) npc=pc_br0;
        `ifdef predictor
        else begin npc=npc_pdc_32;ifnpc_pdc=1; end
        `endif
        `ifndef predictor
        else if(pc[2]) npc=pc+4;
        else npc=pc+8;//Icache ONLY
        `endif
    end

    always @(posedge clk) begin
        if(!rstn) pc<=32'h1c000000;
        else if(!stall_pc|ifbr0|ifbr1|ifpriv|ifcacop_ibar) pc<=npc;
    end

    always @(posedge clk) begin
        if(!rstn|flush_if0_if1) begin
            pc_if0_if1<=0;
            PLV_if0_if1<=0;
            pre_if0_if1<=0;
        end
        else if(stall_if0_if1);
        else begin
            pc_if0_if1<=pc;
            PLV_if0_if1<=PLV;
            //pre
            pre_if0_if1<={27'b0,choice_pdc,ifnpc_pdc,taken_pdc,kind_pdc,npc_pdc};
            //36:35 34 33 32:30 29:0
        end
    end

    //IF1-FIFO
    //flush套壳
    reg fflush_if0_if1;
    always @(posedge clk) begin
        if(!rstn) begin
            fflush_if0_if1 <= 0;
        end
        else if(flush_if0_if1) fflush_if0_if1 <= 1;
        else if(!(stall_icache|stall_to_icache)) fflush_if0_if1 <= 0;
    end

    wire ifflush_if1_fifo;
    assign ifflush_if1_fifo=flush_if0_if1|fflush_if0_if1;

    always @(posedge clk) begin
        if(!rstn|flush_if1_fifo|ifflush_if1_fifo) begin
            pc_if1_fifo<=0;
            ir_if1_fifo<=0;
            icache_valid_if1_fifo<=0;
            flag_if1_fifo<=0;
            PLV_if1_fifo<=0;
            pre_if1_fifo<=0;
            npc_if1_fifo<=0;
            MMU_pipeline_excp_arg0_if1_fifo<=0;
        end
        else if(stall_if1_fifo);
        else begin
            pc_if1_fifo<=pc_if0_if1;
            PLV_if1_fifo<=PLV_if0_if1;
            pre_if1_fifo<=pre_if0_if1;
            ir_if1_fifo<=dout_icache_pipeline;
            icache_valid_if1_fifo<=icache_pipeline_ready;
            flag_if1_fifo<=flag_icache_pipeline;
            MMU_pipeline_excp_arg0_if1_fifo<=MMU_pipeline_excp_arg0;
            npc_if1_fifo<=pc;
        end
    end

    //FIFO-ID
    //即fetch_buffer

    //ID-REG
    always @(posedge clk) begin
        if(!rstn|flush_id_reg0) begin
            ctr_id_reg_0 <= 0;
            imm_id_reg_0<=0;
            rk_id_reg_0<=0;
            rj_id_reg_0<=0;
            rd_id_reg_0<=0;
            pc_id_reg_0<=0;
            ir_id_reg_0<=0;
            ir_valid_id_reg_0<=0;
            pre_id_reg_0<=0;
            npc_id_reg_0<=0;
        end
        else if(stall_id_reg0);
        else begin
            ctr_id_reg_0 <= control00;
            imm_id_reg_0<=imm00;
            rk_id_reg_0<=rk00;
            rj_id_reg_0<=rj00;
            rd_id_reg_0<=rd00;
            pc_id_reg_0<=pc00;
            ir_id_reg_0<=ir00;
            ir_valid_id_reg_0<=ir_valid00;
            pre_id_reg_0<=pre00;
            npc_id_reg_0<=npc00;
        end
    end

    always @(posedge clk) begin
        if(!rstn|flush_id_reg1) begin
            ctr_id_reg_1 <= 0;
            excp_arg_id_reg_1<=0;
            imm_id_reg_1<=0;
            rk_id_reg_1<=0;
            rj_id_reg_1<=0;
            rd_id_reg_1<=0;
            pc_id_reg_1<=0;
            ir_id_reg_1<=0;
            ir_valid_id_reg_1<=0;
            pre_id_reg_1<=0;
            npc_id_reg_1<=0;
        end
        else if(stall_id_reg1);
        else begin
            ctr_id_reg_1 <= control11;
            excp_arg_id_reg_1<=excp_arg11;
            imm_id_reg_1<=imm11;
            rk_id_reg_1<=rk11;
            rj_id_reg_1<=rj11;
            rd_id_reg_1<=rd11;
            pc_id_reg_1<=pc11;
            ir_id_reg_1<=ir11;
            ir_valid_id_reg_1<=ir_valid11;
            pre_id_reg_1<=pre11;
            npc_id_reg_1<=npc11;
        end
    end

    //REG-EXE0
    always @(posedge clk) begin
        if(!rstn|flush_reg_exe0_0) begin
            ctr_reg_exe0_0          <= 0;
            imm_reg_exe0_0          <=0;
            rk_reg_exe0_0           <=0;
            rj_reg_exe0_0           <=0;
            rd_reg_exe0_0           <=0;
            rrk_reg_exe0_0          <=0;
            rrj_reg_exe0_0          <=0;
            rrd_reg_exe0_0          <=0;
            pc_reg_exe0_0           <=0;
            ir_reg_exe0_0           <=0;
            ir_valid_reg_exe0_0     <=0;
            pre_reg_exe0_0          <=0;
            npc_reg_exe0_0          <=0;
        end
        else if(stall_reg_exe0_0);
        else begin
            ctr_reg_exe0_0         <= ctr_id_reg_0;
            imm_reg_exe0_0         <=imm_id_reg_0;
            rrk_reg_exe0_0         <=rrk0_rf;
            rrj_reg_exe0_0         <=rrj0_rf;
            rrd_reg_exe0_0         <=rrd0_rf;
            rk_reg_exe0_0          <=rk_id_reg_0;
            rj_reg_exe0_0          <=rj_id_reg_0;
            rd_reg_exe0_0          <=rd_id_reg_0;
            pc_reg_exe0_0          <=pc_id_reg_0;
            ir_reg_exe0_0          <=ir_id_reg_0;
            ir_valid_reg_exe0_0    <=ir_valid_id_reg_0;
            pre_reg_exe0_0         <=pre_id_reg_0;
            npc_reg_exe0_0         <=npc_id_reg_0;
        end
    end
    
    reg [31:0]  ctr_reg_exe0_1_;
    always @(posedge clk) begin
        if(!rstn|flush_reg_exe0_1) begin
            ctr_reg_exe0_1_<= 0;
            excp_arg_reg_exe0_1<=0;
            imm_reg_exe0_1<=0;
            rk_reg_exe0_1<=0;
            rj_reg_exe0_1<=0;
            rd_reg_exe0_1<=0;
            rrk_reg_exe0_1<=0;
            rrj_reg_exe0_1<=0;
            rrd_reg_exe0_1<=0;
            pc_reg_exe0_1<=0;
            ir_reg_exe0_1<=0;
            ir_valid_reg_exe0_1<=0;
            pre_reg_exe0_1<=0;
            npc_reg_exe0_1<=0;
        end
        else if(stall_reg_exe0_1);
        else begin
            ctr_reg_exe0_1_<= ctr_id_reg_1;
            excp_arg_reg_exe0_1<=excp_arg_id_reg_1;
            imm_reg_exe0_1<=imm_id_reg_1;
            rrk_reg_exe0_1<=rrk1_rf;
            rrj_reg_exe0_1<=rrj1_rf;
            rrd_reg_exe0_1<=rrd1_rf;
            rk_reg_exe0_1<=rk_id_reg_1;
            rj_reg_exe0_1<=rj_id_reg_1;
            rd_reg_exe0_1<=rd_id_reg_1;
            pc_reg_exe0_1<=pc_id_reg_1;
            ir_reg_exe0_1<=ir_id_reg_1;
            ir_valid_reg_exe0_1<=ir_valid_id_reg_1;
            pre_reg_exe0_1<=pre_id_reg_1;
            npc_reg_exe0_1<=npc_id_reg_1;
        end
    end
    always @(*) begin
        ctr_reg_exe0_1 = stall_reg_exe0_1 ? 32'b0 : ctr_reg_exe0_1_;
    end

    //EXE0-EXE1
    localparam liwai = 32'd3,excp_argALE='b001001,excp_argIPE='b0_001110;
    wire [1:0]addr_2=rrj1_forward[1:0]+imm_reg_exe0_1[1:0];

    always @(*) begin//�???测访存地�???是否对齐，特权指令是否内核�?�，否则将访存指令变为例外指�???
        ctr_reg_exe0_1_excp=ctr_reg_exe0_1;
        excp_arg_reg_exe0_1_excp=excp_arg_reg_exe0_1;
        if(ctr_reg_exe0_1[22]&(|PLV)) begin 
            ctr_reg_exe0_1_excp=liwai;
            excp_arg_reg_exe0_1_excp=excp_argIPE; 
        end//用户态访问越�???
        else if(ctr_reg_exe0_1[3:0]==5&ctr_reg_exe0_1[11:7]!=8)
            case (ctr_reg_exe0_1[11:7])
                1: if(addr_2[0]  ) begin ctr_reg_exe0_1_excp=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                2: if(|addr_2[1:0]) begin ctr_reg_exe0_1_excp=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                4: if(addr_2[0]  ) begin ctr_reg_exe0_1_excp=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                5: if(|addr_2[1:0]) begin ctr_reg_exe0_1_excp=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                7: if(addr_2[0]  ) begin ctr_reg_exe0_1_excp=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
            endcase
        else if(ctr_reg_exe0_1[3:0]==6)
            case (ctr_reg_exe0_1[11:7])//for yuanzi, 11:load, 12:store
                11: if(|addr_2[1:0]) begin ctr_reg_exe0_1_excp=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; end
                12: 
                if(LLbit) begin
                    if(|addr_2[1:0]) begin 
                        ctr_reg_exe0_1_excp=liwai;excp_arg_reg_exe0_1_excp=excp_argALE; 
                    end
                end
                else begin
                    ctr_reg_exe0_1_excp={ctr_reg_exe0_1[31:6],1'b0,ctr_reg_exe0_1[4:0]};
                    excp_arg_reg_exe0_1_excp=0;
                end
            endcase
    end

    always @(posedge clk) begin
        if(!rstn|flush_exe0_exe1_0) begin
            ctr_exe0_exe1_0 <= 0;
            rd_exe0_exe1_0 <= 0;
            result_exe0_exe1_0 <= 0;
            pc_exe0_exe1_0<=0;
            ir_exe0_exe1_0<=0;
            ir_valid_exe0_exe1_0<=0;
            countresult_exe0_exe1_0<=0;
        end
        else if(stall_exe0_exe1_0);
        else begin
            ctr_exe0_exe1_0 <= ctr_reg_exe0_0;
            rd_exe0_exe1_0 <= rd_reg_exe0_0;
            result_exe0_exe1_0 <= (ctr_reg_exe0_0[3:0]==7)?countresult0:aluresult0;
            pc_exe0_exe1_0<=pc_reg_exe0_0;
            ir_exe0_exe1_0<=ir_reg_exe0_0;
            ir_valid_exe0_exe1_0<=ir_valid_reg_exe0_0;
            countresult_exe0_exe1_0<=countresult;
        end
    end

    always @(posedge clk) begin
        if(!rstn|flush_exe0_exe1_1) begin
            ctr_exe0_exe1_1 <= 0;
            rd_exe0_exe1_1<=0;
            result_exe0_exe1_1<=0;
            pc_exe0_exe1_1<=0;
            ir_exe0_exe1_1<=0;
            addr_pipeline_dcache_exe0_exe1<=0;
            paddr_exe0_exe1<=0;
            din_pipeline_dcache_exe0_exe1<=0;
            ir_valid_exe0_exe1_1<=0;
            countresult_exe0_exe1_1<=0;
            rand_index_exe0_exe1<=0;
        end
        else if(stall_exe0_exe1_1);
        else begin
            ctr_exe0_exe1_1 <= ctr_reg_exe0_1_excp;
            rd_exe0_exe1_1<=rd_reg_exe0_1;
            result_exe0_exe1_1<=(ctr_reg_exe0_1_excp[3:0]==7)?countresult1:aluresult1;
            pc_exe0_exe1_1<=pc_reg_exe0_1;
            ir_exe0_exe1_1<=ir_reg_exe0_1;
            addr_pipeline_dcache_exe0_exe1<=addr_pipeline_dcache;
            paddr_exe0_exe1<=MMU_pipeline_PADDR1;
            din_pipeline_dcache_exe0_exe1<=din_pipeline_dcache;
            ir_valid_exe0_exe1_1<=ir_valid_reg_exe0_1;
            countresult_exe0_exe1_1<=countresult;
            rand_index_exe0_exe1<=CSR_rand_index;
        end
    end

    //EXE1-WB
    reg [31:0]result0,result1;
    always @(*) begin//0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:priv+dcache, 7:RDCNT, 8:alu+br
        result0=0;
        result1=0;
        case (ctr_exe0_exe1_0[3:0])
            0: result0=result_exe0_exe1_0;
            1: ;
            2: result0=divresult0;
            4: result0=mulresult0;
            7: result0=result_exe0_exe1_0;
            8: result0=result_exe0_exe1_0;
        endcase
        case (ctr_exe0_exe1_1[3:0])
            0: result1=result_exe0_exe1_1;
            1: ;
            2: result1=divresult1;
            3: result1=privresult;
            4: result1=mulresult1;
            5: result1=dcacheresult;
            6: result1=dcacheresult;
            7: result1=result_exe0_exe1_1;
            8: result1=result_exe0_exe1_1;
        endcase
    end

    always @(posedge clk) begin
        if(!rstn|flush_exe1_wb_0) begin
            ctr_exe1_wb_0 <= 0;
            rd_exe1_wb_0<=0;
            result_exe1_wb_0<=0;
            pc_exe1_wb_0<=0;
            ir_exe1_wb_0<=0;
            ir_valid_exe1_wb_0<=0;
            countresult_exe1_wb_0<=0;
            din_pipeline_dcache_exe1_wb<=0;
        end
        else if(stall_exe1_wb_0);
        else begin
            ctr_exe1_wb_0 <= ctr_exe0_exe1_0;
            rd_exe1_wb_0<=rd_exe0_exe1_0;
            result_exe1_wb_0<=result0;
            pc_exe1_wb_0<=pc_exe0_exe1_0;
            ir_exe1_wb_0<=ir_exe0_exe1_0;
            ir_valid_exe1_wb_0<=ir_valid_exe0_exe1_0;
            countresult_exe1_wb_0<=countresult_exe0_exe1_0;
            din_pipeline_dcache_exe1_wb<=din_pipeline_dcache_exe0_exe1;
        end
    end

    always @(posedge clk) begin
        if(!rstn|flush_exe1_wb_1) begin
            ctr_exe1_wb_1 <= 0;
            rd_exe1_wb_1<=0;
            result_exe1_wb_1<=0;
            pc_exe1_wb_1<=0;
            ir_exe1_wb_1<=0;
            vaddr_exe1_wb<=0;
            paddr_exe1_wb<=0;
            ir_valid_exe1_wb_1<=0;
            countresult_exe1_wb_1<=0;
            rand_index_exe1_wb<=0;
            LLbit_exe0_exe1<=0;
        end
        else if(stall_exe1_wb_1);
        else begin
            ctr_exe1_wb_1 <= ctr_exe0_exe1_1;
            rd_exe1_wb_1<=rd_exe0_exe1_1;
            result_exe1_wb_1<=result1;
            pc_exe1_wb_1<=pc_exe0_exe1_1;
            ir_exe1_wb_1<=ir_exe0_exe1_1;
            vaddr_exe1_wb<=addr_pipeline_dcache_exe0_exe1;
            paddr_exe1_wb<=paddr_exe0_exe1;
            ir_valid_exe1_wb_1<=ir_valid_exe0_exe1_1;
            countresult_exe1_wb_1<=countresult_exe0_exe1_1;
            rand_index_exe1_wb<=rand_index_exe0_exe1;
            LLbit_exe0_exe1<=LLbit;
        end
    end

//L2Cache
    wire dma;
    `ifdef DMA
        assign dma = 1'b1;
    `endif
    
    wire [31:0]addr_l2cache_mem_r  ;
    wire [31:0]addr_l2cache_mem_w  ;
    wire [32*(1<<offset_width)-1:0]din_mem_l2cache     ;
    wire [32*(1<<offset_width)-1:0]dout_l2cache_mem    ;
    wire l2cache_mem_req_r   ;
    wire l2cache_mem_req_w   ;
    wire l2cache_mem_rdy     ;
    // wire l2cache_mem_size    ;
    wire [3:0]l2cache_mem_wstrb   ;
    wire mem_l2cache_addrOK_r;
    wire mem_l2cache_addrOK_w;
    wire mem_l2cache_dataOK  ;
    wire l2cache_mem_SUC     ;

    L1_L2cache #(
        .I_index_width  		( 4 		),
        .D_index_width  		( 4 		),
        .L2_index_width  		( 6 		),
        .L1_offset_width 		( 2 		),
        .L2_offset_width 		( 3 		))
    u_L1_L2cache(
        //ports
        .clk                    		( clk                    		),
        .rstn                   		( rstn                   		),

        //  Icache
        // .addr_pipeline_icache   		( |pc[1:0]?0:pc   		),
        .addr_pipeline_icache   		( (|MMU_pipeline_PADDR0[1:0])?0:MMU_pipeline_PADDR0),
        .paddr_pipeline_icache          ( 0                             ),
        .dout_icache_pipeline   		( dout_icache_pipeline   		),//
        .flag_icache_pipeline   		( flag_icache_pipeline   		),//
        .pipeline_icache_valid  		( 1  		),
        .icache_pipeline_ready  		( icache_pipeline_ready  		),//
        .pipeline_icache_opcode 		( pipeline_cache_opcode 		),
        .pipeline_icache_opflag 		( pipeline_icache_opflag 		),
        .pipeline_icache_ctrl           ( {30'b0,flush_if0_if1,stall_to_icache} ),
        .icache_pipeline_stall  		( stall_icache  		),//
        .SUC_pipeline_icache            ( ~MMU_pipeline_memtype0[0] | dma),
        .pc_icache_pipeline             ( pc_icache_pipeline    ),

        //  Dcache
        // .addr_pipeline_dcache   		( addr_pipeline_dcache          ),
        .addr_pipeline_dcache   		( MMU_pipeline_PADDR1   		),
        .paddr_pipeline_dcache          ( 0                             ),
        .din_pipeline_dcache    		( din_pipeline_dcache    		),
        .dout_dcache_pipeline   		( dout_dcache_pipeline   		),
        .type_pipeline_dcache   		( type_pipeline_dcache   		),
        .pipeline_dcache_valid  		( pipeline_dcache_valid  		),
        .dcache_pipeline_ready  		( dcache_pipeline_ready  		),
        .pipeline_dcache_wstrb  		( pipeline_dcache_wstrb  		),
        .pipeline_dcache_opcode 		( pipeline_cache_opcode 		),
        .pipeline_dcache_opflag 		( pipeline_dcache_opflag 		),
        .pipeline_dcache_ctrl   		( {30'b0,flush_exe0_exe1_1,stall_to_dcache}),
        .dcache_pipeline_stall  		( stall_dcache  		        ),
        .pcin_pipeline_dcache           ( pc_reg_exe0_1                 ),
        .SUC_pipeline_dcache            ( ~MMU_pipeline_memtype1[0] | dma),

        //  L2-pipeline
        .addr_pipeline_l2cache          ( addr_pipeline_dcache          ),
        .pipeline_l2cache_opflag        ( pipeline_l2cache_opflag       ),
        .pipeline_l2cache_opcode        ( pipeline_cache_opcode        ),

        //  L2cache to Mem
        .addr_l2cache_mem_r             ( addr_l2cache_mem_r   ),
        .addr_l2cache_mem_w             ( addr_l2cache_mem_w   ),
        .din_mem_l2cache                ( din_mem_l2cache      ),
        .dout_l2cache_mem               ( dout_l2cache_mem     ),
        .l2cache_mem_req_r              ( l2cache_mem_req_r    ),
        .l2cache_mem_req_w              ( l2cache_mem_req_w    ),
        .l2cache_mem_rdy                ( l2cache_mem_rdy      ),
        .l2cache_mem_SUC                ( l2cache_mem_SUC      ),
        .l2cache_mem_wstrb              ( l2cache_mem_wstrb    ),
        .mem_l2cache_addrOK_r           ( mem_l2cache_addrOK_r ),
        .mem_l2cache_addrOK_w           ( mem_l2cache_addrOK_w ),
        .mem_l2cache_dataOK             ( mem_l2cache_dataOK   )
    );



    l2_axi_package#(
        .offset_width(offset_width)
    )
    u_l2_axi_package(
        .clk(clk),
        .rstn(rstn),
        .addr_l2cache_mem_r(addr_l2cache_mem_r),
        .addr_l2cache_mem_w(addr_l2cache_mem_w),
        .din_mem_l2cache(din_mem_l2cache),
        .dout_l2cache_mem(dout_l2cache_mem),
        .l2cache_mem_req_r(l2cache_mem_req_r),
        .l2cache_mem_req_w(l2cache_mem_req_w),
        .l2cache_mem_rdy(l2cache_mem_rdy),
        .l2cache_axi_wstrb(l2cache_mem_wstrb),
        .mem_l2cache_addrOK_r(mem_l2cache_addrOK_r),
        .mem_l2cache_addrOK_w(mem_l2cache_addrOK_w),
        .mem_l2cache_dataOK(mem_l2cache_dataOK),
        .dma_sign(l2cache_mem_SUC),
        //AXI
        .arid           (arid),
        .araddr         (araddr),
        .arlen          (arlen),
        .arsize         (arsize),
        .arburst        (arburst),
        .arlock         (arlock),
        .arcache        (arcache),
        .arprot         (arprot),
        .arvalid        (arvalid),
        .arready        (arready),
        .rid            (rid),
        .rdata          (rdata),
        .rresp          (rresp),
        .rlast          (rlast),
        .rvalid         (rvalid),
        .rready         (rready),
        .awid           (awid),
        .awaddr         (awaddr),
        .awlen          (awlen),
        .awsize         (awsize),
        .awburst        (awburst),
        .awlock         (awlock),
        .awcache        (awcache),
        .awprot         (awprot),
        .awvalid        (awvalid),
        .awready        (awready),
        .wid            (wid),
        .wdata          (wdata),
        .wstrb          (wstrb),
        .wlast          (wlast),
        .wvalid         (wvalid),
        .wready         (wready),
        .bid            (bid),
        .bresp          (bresp),
        .bvalid         (bvalid),
        .bready         (bready)
    );


//debug begin here 
    assign debug0_wb_pc=pc_exe1_wb_0;
    assign debug1_wb_pc=pc_exe1_wb_1;
    assign debug0_wb_rf_wen=stall_exe1_wb_0?0:{4{ifwb0}};
    assign debug1_wb_rf_wen=stall_exe1_wb_1?0:{4{ifwb1}};
    assign debug0_wb_rf_wnum=wb_addr0;
    assign debug1_wb_rf_wnum=wb_addr1;
    assign debug0_wb_rf_wdata=wb_data0;
    assign debug1_wb_rf_wdata=ctr_exe1_wb_1[5]?din_pipeline_dcache_exe1_wb:wb_data1;
    assign debug0_wb_inst=ir_exe1_wb_0;
    assign debug1_wb_inst=ir_exe1_wb_1;
    assign debug0_stall_exe1_wb=stall_exe1_wb_0;
    assign debug1_stall_exe1_wb=stall_exe1_wb_1;
    wire ws_valid0,ws_valid1;
    assign ws_valid0=stall_exe1_wb_0?0:ir_valid_exe1_wb_0;
    assign ws_valid1=stall_exe1_wb_1?0:(ir_valid_exe1_wb_1&~excp_flush);
    assign ws_valid=ws_valid0|ws_valid1;

    reg [31:0]pccount;
    always @(posedge clk) begin
        if(!rstn) begin
            pccount <= 0;
        end
        else case ({ws_valid0,ws_valid1})
            2'b00: ;
            2'b01: pccount <= pccount+1;
            2'b10: pccount <= pccount+1;
            2'b11: pccount <= pccount+2;
            default: ;
        endcase 
    end

//difftest begin here
`ifdef DIFFTEST_EN
    //undefined
    wire            csr_rstat_en_diff   =   0;
    wire    [31:0]  csr_data_diff       =   0;
    
    // from wb_stage    
    wire [TLB_n-1:0]rand_index          =   rand_index_exe1_wb;
    wire            ws_tlbfill_en       =   ctr_exe1_wb_1[27];
    wire            ws_excp_flush       =   excp_flush;
    wire            ws_ertn_flush       =   ertn_flush;
    wire     [5:0]  ws_csr_ecode        =   csr_ecode;
    wire            ws_valid_diff0      =   ws_valid0;
    wire            ws_valid_diff1      =   ws_valid1;
    wire            cnt_inst_diff0      =   ctr_exe1_wb_0[23];
    wire            cnt_inst_diff1      =   ctr_exe1_wb_1[23];
    wire    [63:0]  ws_timer_64_diff    =   countresult_exe1_wb_1;

    wire     [7:0]  inst_ld_en_diff     =   ctr_exe1_wb_1[4];
    wire    [31:0]  ld_paddr_diff       =   paddr_exe1_wb;
    wire    [31:0]  ld_vaddr_diff       =   vaddr_exe1_wb;

    wire    [ 7:0]  inst_st_en_diff     =   ctr_exe1_wb_1[5];
    wire    [31:0]  st_paddr_diff       =   paddr_exe1_wb;
    wire    [31:0]  st_vaddr_diff       =   vaddr_exe1_wb;
    wire    [31:0]  st_data_diff        =   debug1_wb_rf_wdata;

    wire            inst_valid_diff0    =   ws_valid_diff0;
    wire            inst_valid_diff1    =   ws_valid_diff1;

    reg             cmt_valid0           ;
    reg             cmt_valid1           ;
    reg             cmt_cnt_inst0        ;
    reg             cmt_cnt_inst1        ;
    reg     [63:0]  cmt_timer_64         ;
    reg     [ 7:0]  cmt_inst_ld_en       ;
    reg     [31:0]  cmt_ld_paddr         ;
    reg     [31:0]  cmt_ld_vaddr         ;
    reg     [ 7:0]  cmt_inst_st_en       ;
    reg     [31:0]  cmt_st_paddr         ;
    reg     [31:0]  cmt_st_vaddr         ;
    reg     [31:0]  cmt_st_data          ;
    reg             cmt_csr_rstat_en     ;
    reg     [31:0]  cmt_csr_data         ;

    reg             cmt_wen0             ;
    reg             cmt_wen1             ;
    reg     [ 7:0]  cmt_wdest0           ;
    reg     [ 7:0]  cmt_wdest1           ;
    reg     [31:0]  cmt_wdata0           ;
    reg     [31:0]  cmt_wdata1           ;
    reg     [31:0]  cmt_pc0              ;
    reg     [31:0]  cmt_pc1              ;
    reg     [31:0]  cmt_inst0            ;
    reg     [31:0]  cmt_inst1            ;

    reg             cmt_excp_flush       ;
    reg             cmt_ertn             ;
    reg     [5:0]   cmt_csr_ecode        ;
    reg             cmt_tlbfill_en       ;
    reg     [4:0]   cmt_rand_index       ;

    // to difftest debug
    reg             trap                 ;
    reg     [ 7:0]  trap_code            ;
    reg     [63:0]  cycleCnt             ;
    reg     [63:0]  instrCnt             ;

    // from regfile

    // from csr
    reg     [31:0]  csr_crmd_diff_0_reg     ;
    reg     [31:0]  csr_prmd_diff_0_reg     ;
    reg     [31:0]  csr_ectl_diff_0_reg     ;
    reg     [31:0]  csr_estat_diff_0_reg    ;
    reg     [31:0]  csr_era_diff_0_reg      ;
    reg     [31:0]  csr_badv_diff_0_reg     ;
    reg     [31:0]  csr_eentry_diff_0_reg   ;
    reg     [31:0]  csr_tlbidx_diff_0_reg   ;
    reg     [31:0]  csr_tlbehi_diff_0_reg   ;
    reg     [31:0]  csr_tlbelo0_diff_0_reg  ;
    reg     [31:0]  csr_tlbelo1_diff_0_reg  ;
    reg     [31:0]  csr_asid_diff_0_reg     ;
    reg     [31:0]  csr_save0_diff_0_reg    ;
    reg     [31:0]  csr_save1_diff_0_reg    ;
    reg     [31:0]  csr_save2_diff_0_reg    ;
    reg     [31:0]  csr_save3_diff_0_reg    ;
    reg     [31:0]  csr_tid_diff_0_reg      ;
    reg     [31:0]  csr_tcfg_diff_0_reg     ;
    reg     [31:0]  csr_tval_diff_0_reg     ;
    reg     [31:0]  csr_ticlr_diff_0_reg    ;
    reg     [31:0]  csr_llbctl_diff_0_reg   ;
    reg     [31:0]  csr_llbctl_diff_0_last  ;
    reg     [31:0]  csr_llbctl_diff_0_valid ;
    reg     [31:0]  csr_tlbrentry_diff_0_reg;
    reg     [31:0]  csr_dmw0_diff_0_reg     ;
    reg     [31:0]  csr_dmw1_diff_0_reg     ;
    reg     [31:0]  csr_pgdl_diff_0_reg     ;
    reg     [31:0]  csr_pgdh_diff_0_reg     ;

    reg     stall_exe1_wb_1_reg;

    always @(posedge clk) begin
        if(!rstn) begin
            csr_crmd_diff_0_reg         <=  0;
            csr_prmd_diff_0_reg         <=  0;
            csr_ectl_diff_0_reg         <=  0;
            csr_estat_diff_0_reg        <=  0;
            csr_era_diff_0_reg          <=  0;
            csr_badv_diff_0_reg         <=  0;
            csr_eentry_diff_0_reg       <=  0;
            csr_tlbidx_diff_0_reg       <=  0;
            csr_tlbehi_diff_0_reg       <=  0;
            csr_tlbelo0_diff_0_reg      <=  0;
            csr_tlbelo1_diff_0_reg      <=  0;
            csr_asid_diff_0_reg         <=  0;
            csr_save0_diff_0_reg        <=  0;
            csr_save1_diff_0_reg        <=  0;
            csr_save2_diff_0_reg        <=  0;
            csr_save3_diff_0_reg        <=  0;
            csr_tid_diff_0_reg          <=  0;
            csr_tcfg_diff_0_reg         <=  0;
            csr_tval_diff_0_reg         <=  0;
            csr_ticlr_diff_0_reg        <=  0;
            csr_llbctl_diff_0_reg       <=  0;
            csr_tlbrentry_diff_0_reg    <=  0;
            csr_dmw0_diff_0_reg         <=  0;
            csr_dmw1_diff_0_reg         <=  0;
            csr_pgdl_diff_0_reg         <=  0;
            csr_pgdh_diff_0_reg         <=  0;
        end
        else if(!stall_exe1_wb_1)begin
            csr_crmd_diff_0_reg         <=  csr_crmd_diff_0     ;
            csr_prmd_diff_0_reg         <=  csr_prmd_diff_0     ;
            csr_ectl_diff_0_reg         <=  csr_ectl_diff_0     ;
            csr_estat_diff_0_reg        <=  csr_estat_diff_0    ;
            csr_era_diff_0_reg          <=  csr_era_diff_0      ;
            csr_badv_diff_0_reg         <=  csr_badv_diff_0     ;
            csr_eentry_diff_0_reg       <=  csr_eentry_diff_0   ;
            csr_tlbidx_diff_0_reg       <=  csr_tlbidx_diff_0   ;
            csr_tlbehi_diff_0_reg       <=  csr_tlbehi_diff_0   ;
            csr_tlbelo0_diff_0_reg      <=  csr_tlbelo0_diff_0  ;
            csr_tlbelo1_diff_0_reg      <=  csr_tlbelo1_diff_0  ;
            csr_asid_diff_0_reg         <=  csr_asid_diff_0     ;
            csr_save0_diff_0_reg        <=  csr_save0_diff_0    ;
            csr_save1_diff_0_reg        <=  csr_save1_diff_0    ;
            csr_save2_diff_0_reg        <=  csr_save2_diff_0    ;
            csr_save3_diff_0_reg        <=  csr_save3_diff_0    ;
            csr_tid_diff_0_reg          <=  csr_tid_diff_0      ;
            csr_tcfg_diff_0_reg         <=  csr_tcfg_diff_0     ;
            csr_tval_diff_0_reg         <=  csr_tval_diff_0     ;
            csr_ticlr_diff_0_reg        <=  csr_ticlr_diff_0    ;
            csr_llbctl_diff_0_reg       <=  csr_llbctl_diff_0_valid;
            csr_tlbrentry_diff_0_reg    <=  csr_tlbrentry_diff_0;
            csr_dmw0_diff_0_reg         <=  csr_dmw0_diff_0     ;
            csr_dmw1_diff_0_reg         <=  csr_dmw1_diff_0     ;
            csr_pgdl_diff_0_reg         <=  csr_pgdl_diff_0     ;
            csr_pgdh_diff_0_reg         <=  csr_pgdh_diff_0     ;
        end
    end
    always @(posedge clk) begin
        if(!rstn) csr_llbctl_diff_0_last <= 0;
        else if(stall_exe0_exe1_1);
        else csr_llbctl_diff_0_last <= csr_llbctl_diff_0;
    end
    always @(posedge clk) begin
        if(!rstn) stall_exe1_wb_1_reg <= 0;
        else stall_exe1_wb_1_reg <= stall_exe1_wb_1;
    end
    always @(*) begin
        csr_llbctl_diff_0_valid=stall_exe1_wb_1_reg?csr_llbctl_diff_0_last:csr_llbctl_diff_0;
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            {cmt_valid0, cmt_valid1, cmt_cnt_inst0, cmt_cnt_inst1, cmt_timer_64, cmt_inst_ld_en, cmt_ld_paddr, cmt_ld_vaddr, cmt_inst_st_en, cmt_st_paddr, cmt_st_vaddr, cmt_st_data, cmt_csr_rstat_en, cmt_csr_data} <= 0;
            {cmt_wen0, cmt_wen1, cmt_wdest0, cmt_wdest1, cmt_wdata0, cmt_wdata1, cmt_pc0, cmt_pc1, cmt_inst0, cmt_inst1} <= 0;
            {trap, trap_code, cycleCnt, instrCnt} <= 0;
        end else if (~trap) begin
            cmt_valid0       <= inst_valid_diff0          ;
            cmt_cnt_inst0    <= cnt_inst_diff0            ;
            cmt_wen0     <=  debug0_wb_rf_wen            ;
            cmt_wdest0   <=  {3'd0, debug0_wb_rf_wnum}   ;
            cmt_wdata0   <=  debug0_wb_rf_wdata          ;
            cmt_pc0      <=  debug0_wb_pc                ;
            cmt_inst0    <=  debug0_wb_inst              ;

            cmt_valid1       <= inst_valid_diff1          ;
            cmt_cnt_inst1    <= cnt_inst_diff1            ;
            cmt_wen1     <=  debug1_wb_rf_wen            ;
            cmt_wdest1   <=  {3'd0, debug1_wb_rf_wnum}   ;
            cmt_wdata1   <=  debug1_wb_rf_wdata          ;
            cmt_pc1      <=  debug1_wb_pc                ;
            cmt_inst1    <=  debug1_wb_inst              ;

            cmt_rand_index  <= rand_index                ;
            cmt_tlbfill_en  <= ws_tlbfill_en               ;
            cmt_timer_64    <= ws_timer_64_diff            ;

            cmt_inst_ld_en  <= inst_ld_en_diff          ;
            cmt_ld_paddr    <= ld_paddr_diff            ;
            cmt_ld_vaddr    <= ld_vaddr_diff            ;
            cmt_inst_st_en  <= inst_st_en_diff          ;
            cmt_st_paddr    <= st_paddr_diff            ;
            cmt_st_vaddr    <= st_vaddr_diff            ;
            cmt_st_data     <= st_data_diff             ;
            cmt_csr_rstat_en<= csr_rstat_en_diff        ;
            cmt_csr_data    <= csr_data_diff            ;

            cmt_excp_flush  <= ws_excp_flush               ;
            cmt_ertn        <= ws_ertn_flush               ;
            cmt_csr_ecode   <= ws_csr_ecode             ;

            trap            <= 0                        ;
            trap_code       <= regs[10][7:0]            ;
            cycleCnt        <= cycleCnt + 1             ;
            instrCnt        <= instrCnt + inst_valid_diff1;
        end
    end

    DifftestInstrCommit DifftestInstrCommit0(
        .clock              (aclk            ),
        .coreid             (0               ),
        .index              (1               ),
        .valid              (cmt_valid0      ),
        .pc                 (cmt_pc0         ),
        .instr              (cmt_inst0       ),
        .skip               (0               ),
        .is_CNTinst         (cmt_cnt_inst0   ),
        .timer_64_value     (cmt_timer_64    ),
        .wen                (cmt_wen0        ),
        .wdest              (cmt_wdest0      ),
        .wdata              (cmt_wdata0      ),
        .csr_rstat          (cmt_csr_rstat_en),
        .csr_data           (cmt_csr_data    )
    );

    DifftestInstrCommit DifftestInstrCommit1(
        .clock              (aclk           ),
        .coreid             (0              ),
        .index              (0              ),
        .valid              (cmt_valid1      ),
        .pc                 (cmt_pc1         ),
        .instr              (cmt_inst1       ),
        .skip               (0              ),
        .is_TLBFILL         (cmt_tlbfill_en ),
        .TLBFILL_index      (cmt_rand_index ),
        .is_CNTinst         (cmt_cnt_inst1   ),
        .timer_64_value     (cmt_timer_64    ),
        .wen                (cmt_wen1        ),
        .wdest              (cmt_wdest1      ),
        .wdata              (cmt_wdata1      ),
        .csr_rstat          (cmt_csr_rstat_en),
        .csr_data           (cmt_csr_data   )
    );

    DifftestExcpEvent DifftestExcpEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .excp_valid         (cmt_excp_flush ),
        .eret               (cmt_ertn       ),
        .intrNo             (csr_estat_diff_0[12:2]),
        .cause              (cmt_csr_ecode  ),
        .exceptionPC        (pc_exe1_wb_1   ),
        .exceptionInst      (ir_exe1_wb_1   )
    );

    DifftestTrapEvent DifftestTrapEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .valid              (trap           ),
        .code               (trap_code      ),
        .pc                 (cmt_pc1        ),
        .cycleCnt           (cycleCnt       ),
        .instrCnt           (instrCnt       )
    );

    DifftestStoreEvent DifftestStoreEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .index              (0              ),
        .valid              (cmt_inst_st_en ),
        .storePAddr         (cmt_st_paddr   ),
        .storeVAddr         (cmt_st_vaddr   ),
        .storeData          (cmt_st_data    )
    );

    DifftestLoadEvent DifftestLoadEvent(
        .clock              (aclk           ),
        .coreid             (0              ),
        .index              (0              ),
        .valid              (cmt_inst_ld_en ),
        .paddr              (cmt_ld_paddr   ),
        .vaddr              (cmt_ld_vaddr   )
    );

    DifftestCSRRegState DifftestCSRRegState(
        .clock              (aclk                       ),
        .euen               (0                          ),
        .coreid             (0                          ),
        .crmd               ({32'b0,csr_crmd_diff_0_reg        }),
        .prmd               ({32'b0,csr_prmd_diff_0_reg        }),
        .ecfg               ({32'b0,csr_ectl_diff_0_reg        }),
        .estat              ({32'b0,csr_estat_diff_0_reg       }),
        .era                ({32'b0,csr_era_diff_0_reg         }),
        .badv               ({32'b0,csr_badv_diff_0_reg        }),
        .eentry             ({32'b0,csr_eentry_diff_0_reg      }),
        .tlbidx             ({32'b0,csr_tlbidx_diff_0_reg      }),
        .tlbehi             ({32'b0,csr_tlbehi_diff_0_reg      }),
        .tlbelo0            ({32'b0,csr_tlbelo0_diff_0_reg     }),
        .tlbelo1            ({32'b0,csr_tlbelo1_diff_0_reg     }),
        .asid               ({32'b0,csr_asid_diff_0_reg        }),
        .pgdl               ({32'b0,csr_pgdl_diff_0_reg        }),
        .pgdh               ({32'b0,csr_pgdh_diff_0_reg        }),
        .save0              ({32'b0,csr_save0_diff_0_reg       }),
        .save1              ({32'b0,csr_save1_diff_0_reg       }),
        .save2              ({32'b0,csr_save2_diff_0_reg       }),
        .save3              ({32'b0,csr_save3_diff_0_reg       }),
        .tid                ({32'b0,csr_tid_diff_0_reg         }),
        .tcfg               ({32'b0,csr_tcfg_diff_0_reg        }),
        .tval               ({32'b0,csr_tval_diff_0_reg        }),
        .ticlr              ({32'b0,csr_ticlr_diff_0_reg       }),
        .llbctl             ({32'b0,csr_llbctl_diff_0_reg      }),
        .tlbrentry          ({32'b0,csr_tlbrentry_diff_0_reg   }),
        .dmw0               ({32'b0,csr_dmw0_diff_0_reg        }),
        .dmw1               ({32'b0,csr_dmw1_diff_0_reg        })
    );

    DifftestGRegState DifftestGRegState(
        .clock              (aclk       ),
        .coreid             (0          ),
        .gpr_0              (0          ),
        .gpr_1              ({32'b0,regs[1]    }),
        .gpr_2              ({32'b0,regs[2]    }),
        .gpr_3              ({32'b0,regs[3]    }),
        .gpr_4              ({32'b0,regs[4]    }),
        .gpr_5              ({32'b0,regs[5]    }),
        .gpr_6              ({32'b0,regs[6]    }),
        .gpr_7              ({32'b0,regs[7]    }),
        .gpr_8              ({32'b0,regs[8]    }),
        .gpr_9              ({32'b0,regs[9]    }),
        .gpr_10             ({32'b0,regs[10]   }),
        .gpr_11             ({32'b0,regs[11]   }),
        .gpr_12             ({32'b0,regs[12]   }),
        .gpr_13             ({32'b0,regs[13]   }),
        .gpr_14             ({32'b0,regs[14]   }),
        .gpr_15             ({32'b0,regs[15]   }),
        .gpr_16             ({32'b0,regs[16]   }),
        .gpr_17             ({32'b0,regs[17]   }),
        .gpr_18             ({32'b0,regs[18]   }),
        .gpr_19             ({32'b0,regs[19]   }),
        .gpr_20             ({32'b0,regs[20]   }),
        .gpr_21             ({32'b0,regs[21]   }),
        .gpr_22             ({32'b0,regs[22]   }),
        .gpr_23             ({32'b0,regs[23]   }),
        .gpr_24             ({32'b0,regs[24]   }),
        .gpr_25             ({32'b0,regs[25]   }),
        .gpr_26             ({32'b0,regs[26]   }),
        .gpr_27             ({32'b0,regs[27]   }),
        .gpr_28             ({32'b0,regs[28]   }),
        .gpr_29             ({32'b0,regs[29]   }),
        .gpr_30             ({32'b0,regs[30]   }),
        .gpr_31             ({32'b0,regs[31]   })
    );
`endif
endmodule

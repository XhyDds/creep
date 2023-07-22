module CSR_control#(//tlbfill bug?
parameter TLB_n=7,TLB_PALEN=32,TIMER_n=32
)(
    input clk,rstn,
    input pipeline_CSR_stall,
    input pipeline_CSR_flush,
    //output CSR_pipeline_stall,
    output CSR_pipeline_flush,
    output [31:0] CSR_pipeline_outpc,
    input pipeline_CSR_jumpc_valid,
    input [31:0] pipeline_CSR_jumpc,
    input pipeline_CSR_inpc_valid,
    input [31:0] pipeline_CSR_inpc0,//
    input [3:0]pipeline_CSR_type,
    input [4:0]pipeline_CSR_subtype,
    input [15:0] pipeline_CSR_excp_arg0,//csrnum+excparg
    input [31:0]pipeline_CSR_din,
    input [31:0]pipeline_CSR_mask,
    output [31:0] CSR_pipeline_dout,
    input [15:0] pipeline_CSR_excp_arg1,//�????????高位为是否有效，剩余部分分别为esubcode与ecode
    input [31:0] pipeline_CSR_inpc1,//ex2段pc
    input [31:0] pipeline_CSR_evaddr0,//出错虚地�????????，ex1�????????
    input [31:0] pipeline_CSR_evaddr1,
    input [8:0]pipeline_CSR_ESTAT,//中断信息,8为核间中�???????
    output CSR_pipeline_clk_stall,
    output [8:0]CSR_pipeline_CRMD,
    output CSR_pipeline_LLBit,
    output [9:0]CSR_pipeline_ASID,
    output [31:0]CSR_pipeline_DMW0,
    output [31:0]CSR_pipeline_DMW1,
    
    output [31:0] CSR_pipeline_TLBIDX,
    output [31:0] CSR_pipeline_TLBEHI,
    output [31:0] CSR_pipeline_TLBELO0,
    output [31:0] CSR_pipeline_TLBELO1,
    input [31:0] pipeline_CSR_TLBIDX,
    input [31:0] pipeline_CSR_TLBEHI,
    input [31:0] pipeline_CSR_TLBELO0,
    input [31:0] pipeline_CSR_TLBELO1,
    input [9:0]  pipeline_CSR_ASID,

    output reg excp_flush,
    output reg ertn_flush,
    output reg [5:0]csr_ecode,
    output reg [TLB_n-1:0] rand_index,
    output reg tlbfill_en,

    output reg [31:0]  csr_crmd_diff_0     ,
    output reg [31:0]  csr_prmd_diff_0     ,
    output reg [31:0]  csr_ectl_diff_0     ,
    output reg [31:0]  csr_estat_diff_0    ,
    output reg [31:0]  csr_era_diff_0      ,
    output reg [31:0]  csr_badv_diff_0     ,
    output reg [31:0]  csr_eentry_diff_0   ,
    output reg [31:0]  csr_tlbidx_diff_0   ,
    output reg [31:0]  csr_tlbehi_diff_0   ,
    output reg [31:0]  csr_tlbelo0_diff_0  ,
    output reg [31:0]  csr_tlbelo1_diff_0  ,
    output reg [31:0]  csr_asid_diff_0     ,
    output reg [31:0]  csr_save0_diff_0    ,
    output reg [31:0]  csr_save1_diff_0    ,
    output reg [31:0]  csr_save2_diff_0    ,
    output reg [31:0]  csr_save3_diff_0    ,
    output reg [31:0]  csr_tid_diff_0      ,
    output reg [31:0]  csr_tcfg_diff_0     ,
    output reg [31:0]  csr_tval_diff_0     ,
    output reg [31:0]  csr_ticlr_diff_0    ,
    output reg [31:0]  csr_llbctl_diff_0   ,
    output reg [31:0]  csr_tlbrentry_diff_0,
    output reg [31:0]  csr_dmw0_diff_0     ,
    output reg [31:0]  csr_dmw1_diff_0     ,
    output reg [31:0]  csr_pgdl_diff_0     ,
    output reg [31:0]  csr_pgdh_diff_0     
    //output CSR_TLB
);
    reg [8:0] CRMD;reg [2:0] PRMD;reg EUEN;reg [12:0] ECFG_LIE;
    reg [1:0] ESTAT_IS;reg TI_INTE;reg [21:16]ESTAT_Ecode;reg [30:22]ESTAT_EsubCode;
    reg[31:0] ERA;reg [31:0] BADV;reg [31:6] EENTRY;wire [31:0] CPUID;
    reg [31:0] SAVE0,SAVE1,SAVE2,SAVE3;reg  LLBCTL_ROLLB,LLBCTL_KLO;wire LLBCTL_WCLLB;
    reg [TLB_n-1:0] TLBIDX_Index;
    reg [29:24] TLBIDX_PS;reg TLBIDX_NE;reg [31:13] TLBEHI;reg [6:0]TLBELO0_VDPLVMATG;
    reg [TLB_PALEN-5:8]TLBELO0_PPN;reg [6:0]TLBELO1_VDPLVMATG;reg [TLB_PALEN-5:8]TLBELO1_PPN;
    reg [9:0] ASID_ASID;wire [23:16] ASID_ASIDBITS;reg [31:12] PGDL;reg [31:12]PGDH;
    wire [31:12]PGD;reg [31:6]TLBRENTRY;reg DMW0_PLV0;reg DMW0_PLV3;reg [5:4] DMW0_MAT;
    reg [27:25] DMW0_PSEG;reg [31:29] DMW0_VSEG;reg DMW1_PLV0;reg DMW1_PLV3;reg [5:4] DMW1_MAT;
    reg [27:25] DMW1_PSEG;reg [31:29] DMW1_VSEG;reg [31:0]TID;reg [TIMER_n-1:0]TCFG;
    reg [TIMER_n-1:0]TVAL;wire TICLR;
    assign CPUID=0,ASID_ASIDBITS=10,PGD=BADV[31]?PGDH:PGDL,TICLR=0,LLBCTL_WCLLB=0;
    assign CSR_pipeline_CRMD=CRMD,CSR_pipeline_LLBit=LLBCTL_ROLLB;
    assign CSR_pipeline_ASID=ASID_ASID;
    assign CSR_pipeline_DMW0={DMW0_VSEG,1'b0,DMW0_PSEG,19'b0,DMW0_MAT,DMW0_PLV3,2'b0,DMW0_PLV0};
    assign CSR_pipeline_DMW1={DMW1_VSEG,1'b0,DMW1_PSEG,19'b0,DMW1_MAT,DMW1_PLV3,2'b0,DMW1_PLV0};
    
    localparam PRIV=3,LLW=6,PRIV_MMU=10;
    localparam LOAD=0,ERTN=6,IDLE=7,INTE=0,CSRRD=8,CSRWR=9,CSRXCHG=10,
    TLBSRCH=1,TLBRD=2,TLBWR=3,TLBFILL=4;
    localparam INT='H0,PIL='H1,PIS='H2,PIF='H3,PME='H4,PPI='H7,
    ADE='H8,ALE='H9,SYS='HB,BRK='HC,INE='HD,IPE='HE,FPD='HF,
    FPE='H12,TLBR='H3F;
    localparam ADEF='H0,ADEM='H1;
    reg [4:0] mode;wire [31:0] din;reg [31:0]dout,mask;
    wire [8:0] ESTATin;reg flushout;wire stallin,flushin;
    wire exe;wire [15:0] excp_arg1;reg clk_stall;reg [31:0] outpc;
    wire inte;wire [15:0] csr_num;reg [31:0] inpc;wire inpc_valid;reg [5:0]ecode;
    reg [8:0] esubcode;reg [31:0] evaddr;wire [31:0]dwcsr;reg TI_cl;wire [31:0]randnum;
    reg rand_en;reg inst_stop,inst_stop_reg;wire [31:0] jumpc;wire jumpc_valid;
    reg [31:0] TLBIDXout,TLBEHIout,TLBELO0out,TLBELO1out;
    wire [31:0] TLBIDXin,TLBEHIin,TLBELO0in,TLBELO1in;wire [9:0] ASIDin;
    
    reg [31:0] dwcsr_reg;reg flushout_reg;reg [31:0] outpc_reg;
    reg [31:0] dout_reg;reg run_reg;reg [5:0] ecode_reg;reg [8:0] esubcode_reg;
    reg [4:0] mode_reg;reg [31:0] inpc_reg,evaddr_reg;reg [15:0] csr_num_reg;
    reg [31:0] jumpc_reg;reg TCFG0_reg;reg nexcp_flush,nertn_flush;

    assign stallin=pipeline_CSR_stall,flushin=pipeline_CSR_flush;
    assign CSR_pipeline_flush=flushout||flushout_reg;//CSR_pipeline_stall=busy,
    assign exe=pipeline_CSR_type==PRIV||pipeline_CSR_type==PRIV_MMU||excp_arg1[15]||(pipeline_CSR_type==LLW&&pipeline_CSR_subtype==LOAD);
    assign din=pipeline_CSR_din,CSR_pipeline_dout=dout_reg;
    assign excp_arg1=pipeline_CSR_excp_arg1,CSR_pipeline_clk_stall=clk_stall;
    assign CSR_pipeline_outpc=outpc_reg,ESTATin=pipeline_CSR_ESTAT;
    assign csr_num=pipeline_CSR_excp_arg0;
    assign inte={ESTATin[8],TI_INTE,ESTATin[7:0],ESTAT_IS}&{ECFG_LIE[12:11],ECFG_LIE[9:0]}?CRMD[2]&~inst_stop_reg:0;
    assign CSR_pipeline_TLBIDX=TLBIDXout,CSR_pipeline_TLBEHI=TLBEHIout;
    assign CSR_pipeline_TLBELO0=TLBELO0out,CSR_pipeline_TLBELO1=TLBELO1out;
    assign TLBIDXin=pipeline_CSR_TLBIDX,TLBEHIin=pipeline_CSR_TLBEHI;
    assign TLBELO0in=pipeline_CSR_TLBELO0,TLBELO1in=pipeline_CSR_TLBELO1;
    assign ASIDin=pipeline_CSR_ASID;
    assign inpc_valid=pipeline_CSR_inpc_valid,jumpc_valid=pipeline_CSR_jumpc_valid;
    assign jumpc=pipeline_CSR_jumpc;
    Random rand_(.en(rand_en),.clk(clk),.rstn(rstn),.seed(TVAL),.randnum(randnum));
    
    always@(*)
    begin
            csr_crmd_diff_0={23'b0,CRMD};
            csr_prmd_diff_0={29'b0,PRMD};
            csr_ectl_diff_0={19'b0,ECFG_LIE[12:11],1'b0,ECFG_LIE[9:0]};
            csr_estat_diff_0={1'b0,ESTAT_EsubCode,ESTAT_Ecode,3'b0,ESTATin[8],TI_INTE,1'b0,ESTATin[7:0],ESTAT_IS};
            csr_ecode=excp_flush?ESTAT_Ecode:0;
            csr_era_diff_0=ERA;
            csr_badv_diff_0=BADV;
            csr_eentry_diff_0={EENTRY,6'b0};
            begin
            csr_tlbidx_diff_0=0;
            csr_tlbidx_diff_0[TLB_n-1:0]=TLBIDX_Index;
            //rand_index=randnum[TLB_n-1:0];
            rand_index=0;
            csr_tlbidx_diff_0[29:24]=TLBIDX_PS;
            csr_tlbidx_diff_0[31]=TLBIDX_NE;
            end
            csr_tlbehi_diff_0={TLBEHI,13'b0};
            begin
            csr_tlbelo0_diff_0=0;
            csr_tlbelo0_diff_0[6:0]=TLBELO0_VDPLVMATG;
            csr_tlbelo0_diff_0[TLB_PALEN-5:8]=TLBELO0_PPN;
            end
            begin
            csr_tlbelo1_diff_0=0;
            csr_tlbelo1_diff_0[6:0]=TLBELO1_VDPLVMATG;
            csr_tlbelo1_diff_0[TLB_PALEN-5:8]=TLBELO1_PPN;
            end  
            csr_asid_diff_0={8'b0,ASID_ASIDBITS,6'b0,ASID_ASID};
            csr_pgdl_diff_0={PGDL,12'b0};
            csr_pgdh_diff_0={PGDH,12'b0};
            
            csr_save0_diff_0=SAVE0;
            csr_save1_diff_0=SAVE1;
            csr_save2_diff_0=SAVE2;
            csr_save3_diff_0=SAVE3;
            csr_tid_diff_0=TID;
            csr_tcfg_diff_0[TIMER_n-1:0]=TCFG;
            csr_tval_diff_0[TIMER_n-1:0]=TVAL;
            csr_ticlr_diff_0={31'b0,TICLR};
            csr_llbctl_diff_0={29'b0,LLBCTL_KLO,LLBCTL_WCLLB,LLBCTL_ROLLB};
            csr_tlbrentry_diff_0={TLBRENTRY,6'b0};
            
            csr_dmw0_diff_0={DMW0_VSEG,1'b0,DMW0_PSEG,19'b0,DMW0_MAT,DMW0_PLV3,2'b0,DMW0_PLV0};
            csr_dmw1_diff_0={DMW1_VSEG,1'b0,DMW1_PSEG,19'b0,DMW1_MAT,DMW1_PLV3,2'b0,DMW1_PLV0};
    end
    
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn||(flushin&&!inte))
        begin   
        dwcsr_reg<=0;flushout_reg<=0;
        outpc_reg<=0;dout_reg<=0;
        run_reg<=0;
        ecode_reg<=0;esubcode_reg<=0;
        mode_reg<=0;inpc_reg<=0;evaddr_reg<=0;
        csr_num_reg<=0;inst_stop_reg<=0;jumpc_reg<=0;
        //excp_flush<=0;ertn_flush<=0;
        end
    else if(!stallin||inte)
        begin
        dwcsr_reg<=dwcsr;flushout_reg<=flushout;
        outpc_reg<=outpc;dout_reg<=dout;
        run_reg<=(!stallin && !flushin && exe)||inte;
        ecode_reg<=ecode;esubcode_reg<=esubcode;
        mode_reg<=mode;inpc_reg<=inpc;evaddr_reg<=evaddr;
        csr_num_reg<=csr_num;inst_stop_reg<=inst_stop;
        //excp_flush<=nexcp_flush;ertn_flush<=nertn_flush;
        if(jumpc_valid)
            jumpc_reg<=jumpc;
        end
    end
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn)
        begin
        TI_INTE<=0;
        TVAL<=0;
        TCFG0_reg<=0;
        TCFG<=0;
        end
    else
        begin
        TCFG0_reg<=TCFG[0];
        if(TI_cl)
            begin
            TI_INTE<=0;
            end
        else if(TVAL==0&&TCFG[0]&&TCFG0_reg)
            begin
            TI_INTE<=1;
            end

        if((TVAL==0&&TCFG[1])||TCFG[0]&~TCFG0_reg)
            TVAL<={TCFG[TIMER_n-1:2],2'b0};
        else if(~TCFG[0]&TCFG0_reg)
            TVAL<=0;
        else if(TCFG[0]&&TVAL!=~0)
            TVAL<=TVAL-1;
        end
    end
    always@(*)
    begin
    flushout=1;
    outpc=inpc+4;dout=0;
    mask=~0;
    inpc=pipeline_CSR_inpc0;
    ecode=pipeline_CSR_excp_arg0[5:0];
    esubcode=pipeline_CSR_excp_arg0[14:6];
    mode=pipeline_CSR_subtype;
    evaddr=pipeline_CSR_evaddr0;
    TI_cl=0;rand_en=0;
    inst_stop=0;
    TLBIDXout=0;TLBEHIout=0;
    TLBELO0out=0;TLBELO1out=0;
    TLBIDXout[TLB_n-1:0]=TLBIDX_Index;
    TLBIDXout[29:24]=TLBIDX_PS;
    TLBIDXout[31]=TLBIDX_NE;
    TLBEHIout[31:13]=TLBEHI;
    TLBELO0out[6:0]=TLBELO0_VDPLVMATG;
    TLBELO0out[TLB_PALEN-5:8]=TLBELO0_PPN;
    TLBELO1out[6:0]=TLBELO1_VDPLVMATG;
    TLBELO1out[TLB_PALEN-5:8]=TLBELO1_PPN;
    
    nexcp_flush=0;nertn_flush=0;tlbfill_en=0;
    if(!inpc_valid)
        inpc=jumpc_reg;
    if(inte)
        begin
        mode=INTE;
        ecode=INT;
        esubcode=0;
        end 
    else if(excp_arg1[15])
        begin
        mode=INTE;
        inpc=pipeline_CSR_inpc1; 
        ecode=pipeline_CSR_excp_arg1[5:0];
        esubcode=pipeline_CSR_excp_arg1[14:6];
        evaddr=pipeline_CSR_evaddr1;
        end

    if(ecode==ADE&&esubcode==ADEF)
        evaddr=inpc;
   
    if((!stallin && !flushin && exe)||inte)
        begin 
        case(mode)
            ERTN:
                begin
                nertn_flush=1;
                flushout=1;
                outpc=ERA;
                end
            CSRXCHG:
                begin
                flushout=1;                        
                mask=pipeline_CSR_mask;
                if(csr_num=='h44 && dwcsr[0])
                    TI_cl=1;
                end
            INTE:
               begin
                inst_stop=1;
               flushout=1; 
               if(ecode==TLBR)
                    begin
                    outpc={TLBRENTRY,6'b0};
                    end
               else
                    begin
                    nexcp_flush=1;
                    outpc={EENTRY,6'b0};
                    end
               end 
            CSRWR:
                begin
                flushout=1; 
                 if(csr_num=='h44&&dwcsr[0])
                    TI_cl=1; 
                end 
            CSRRD:
                   flushout=0;
            TLBWR:
                begin
                flushout=1; 
                if(ecode==TLBR)
                    TLBIDXout[31]=0;//NE=0,E=1
                end
            TLBFILL:
                begin
                tlbfill_en=1;
                rand_en=1;
                flushout=1; 
                if(ecode==TLBR)
                    TLBIDXout[31]=0;//NE=0,E=1
                //TLBIDXout[TLB_n-1:0]=randnum[TLB_n-1:0];
                TLBIDXout[TLB_n-1:0]=0;
                end
                      
        endcase
        end
    else
        begin
        flushout=0;
        end

    case(csr_num)
        'h0:
            dout={23'b0,CRMD};
        'h1:
            dout={29'b0,PRMD};
        'h2:
            dout={31'b0,EUEN};
        'h4:
            dout={19'b0,ECFG_LIE[12:11],1'b0,ECFG_LIE[9:0]};
        'h5:
            dout={1'b0,ESTAT_EsubCode,ESTAT_Ecode,3'b0,ESTATin[8],TI_INTE,1'b0,ESTATin[7:0],ESTAT_IS};
        'h6:
            dout=ERA;
        'h7:
            dout=BADV;
        'hc:
            dout={EENTRY,6'b0};
        'h10:
            begin
            dout[TLB_n-1:0]=TLBIDX_Index;
            dout[29:24]=TLBIDX_PS;
            dout[31]=TLBIDX_NE;
            end
        'h11:
            dout={TLBEHI,13'b0};
        'h12:
            begin
            dout[6:0]=TLBELO0_VDPLVMATG;
            dout[TLB_PALEN-5:8]=TLBELO0_PPN;
            end
        'h13:
            begin
            dout[6:0]=TLBELO1_VDPLVMATG;
            dout[TLB_PALEN-5:8]=TLBELO1_PPN;
            end  
        'h18:
            dout={8'b0,ASID_ASIDBITS,6'b0,ASID_ASID};
        'h19:
            dout={PGDL,12'b0};
        'h1a:
            dout={PGDH,12'b0};
        'h1b:
            dout={PGD,12'b0};
        'h20:
            dout=CPUID;
        'h30:
            dout=SAVE0;
        'h31:
            dout=SAVE1;
        'h32:
            dout=SAVE2;
        'h33:
            dout=SAVE3;
        'h40:
            dout=TID;
        'h41:
            dout[TIMER_n-1:0]=TCFG;
        'h42:
            dout[TIMER_n-1:0]=TVAL;
        'h44:
            dout={31'b0,TICLR};
        'h60:
            dout={29'b0,LLBCTL_KLO,LLBCTL_WCLLB,LLBCTL_ROLLB};
        'h88:
            dout={TLBRENTRY,6'b0};
        'h98:
            dout=0;
        'h180:
            dout={DMW0_VSEG,1'b0,DMW0_PSEG,19'b0,DMW0_MAT,DMW0_PLV3,2'b0,DMW0_PLV0};
        'h181:
            dout={DMW1_VSEG,1'b0,DMW1_PSEG,19'b0,DMW1_MAT,DMW1_PLV3,2'b0,DMW1_PLV0};
    endcase
    
    end
    
    assign dwcsr=(dout&(~mask))|(din&mask);
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn)
        begin
        clk_stall<=0;
        CRMD<=9'b0000_0100_0;PRMD<=0;EUEN<=0;ECFG_LIE<=0;
        ESTAT_IS<=0;ESTAT_Ecode<=0;ESTAT_EsubCode<=0;
        ERA<=0;BADV<=0;EENTRY<=0;
        SAVE0<=0;SAVE1<=0;SAVE2<=0;SAVE3<=0;LLBCTL_ROLLB<=0;LLBCTL_KLO<=0;
        TLBIDX_Index<=0;
        TLBIDX_PS<=0;TLBIDX_NE<=0;TLBEHI<=0;TLBELO0_VDPLVMATG<=0;
        TLBELO0_PPN<=0;TLBELO1_VDPLVMATG<=0;TLBELO1_PPN<=0;
        ASID_ASID<=0;PGDL<=0;PGDH<=0;
        TLBRENTRY<=0;DMW0_PLV0<=0;DMW0_PLV3<=0;DMW0_MAT<=0;
        DMW0_PSEG<=0;DMW0_VSEG<=0;DMW1_PLV0<=0;DMW1_PLV3<=0;DMW1_MAT<=0;
        DMW1_PSEG<=0;DMW1_VSEG<=0;TID<=0;TCFG<=0;
        excp_flush<=0;ertn_flush<=0;
        end
    else
        begin
        excp_flush<=0;ertn_flush<=0;
            if(run_reg)
                begin
                if(mode_reg==IDLE && !clk_stall)
                    begin
                    clk_stall<=1;
                    end   
                else
                    begin
                    case(mode_reg)
                        ERTN:
                            begin
                            ertn_flush<=1;
                            if(ESTAT_Ecode==TLBR)
                                CRMD[4:0]<={2'b10,PRMD};
                            else
                                CRMD[4:0]<={2'b01,PRMD};
                            LLBCTL_KLO<=0;
                            if(!LLBCTL_KLO)
                                LLBCTL_ROLLB<=0;  
                            end
                        INTE:
                            begin
                            PRMD<=CRMD[2:0];
                            CRMD[2:0]<=0;
                            ERA<=inpc_reg;
                            clk_stall<=0;
                            if(ecode_reg==TLBR)
                                begin
                                CRMD[4:3]<=2'b01;
                                end
                             //else if(ecode_reg==INT)
                                 //begin
                                excp_flush<=1;
                                 //end
                            ESTAT_Ecode<=ecode_reg;
                            ESTAT_EsubCode<=esubcode_reg;
                            case(ecode_reg)
                                TLBR,PIL,PIS,PIF,PME,PPI:
                                    begin
                                    BADV<=evaddr_reg;
                                    TLBEHI<=evaddr_reg[31:13];
                                    end
                                ALE:
                                    BADV<=evaddr_reg;
                                ADE:
                                    if(esubcode_reg==ADEF)
                                        BADV<=evaddr_reg;
                            endcase
                            end
                        LLW:
                            begin
                            LLBCTL_ROLLB<=1;
                            end
                        TLBSRCH:
                            begin
                            TLBIDX_NE<=TLBIDXin[31];
                            if(!TLBIDXin[31])
                                TLBIDX_Index<=TLBIDXin[TLB_n-1:0];
                            end
                        TLBRD:
                            begin
                                TLBIDX_NE<=TLBIDXin[31];
                                if(!TLBIDXin[31])//NE=0
                                    begin
                                    ASID_ASID<=ASIDin;
                                    TLBEHI<=TLBEHIin[31:13];
                                    TLBELO0_VDPLVMATG<=TLBELO0in[6:0];
                                    TLBELO0_PPN<=TLBELO0in[TLB_PALEN-5:8];
                                    TLBELO1_VDPLVMATG<=TLBELO1in[6:0];
                                    TLBELO1_PPN<=TLBELO1in[TLB_PALEN-5:8];
                                    TLBIDX_PS<=TLBIDXin[29:24];
                                    end
                                else
                                    begin
                                    ASID_ASID<=0;
                                    TLBEHI<=0;
                                    TLBELO0_VDPLVMATG<=0;
                                    TLBELO0_PPN<=0;
                                    TLBELO1_VDPLVMATG<=0;
                                    TLBELO1_PPN<=0;
                                    TLBIDX_PS<=0;
                                    end
                            end
                        CSRWR,CSRXCHG:
                           case(csr_num_reg)
                                'h0:
                                    begin
                                    CRMD[2:0]<=dwcsr_reg[2:0];
                                    CRMD[8:5]<=dwcsr_reg[8:5];
                                    if(dwcsr_reg[4]^dwcsr_reg[3])
                                        CRMD[4:3]<=dwcsr_reg[4:3];
                                    end
                                'h1:
                                    PRMD<=dwcsr_reg[2:0];
                                'h2:
                                    EUEN<=dwcsr_reg[0];
                                'h4:
                                    begin
                                    ECFG_LIE[12:11]<=dwcsr_reg[12:11];
                                    ECFG_LIE[9:0]<=dwcsr_reg[9:0];
                                    end
                                'h5:
                                    begin
                                    ESTAT_IS<=dwcsr_reg[1:0];
                                    end
                                'h6:
                                    ERA<=dwcsr_reg;
                                'h7:
                                    BADV<=dwcsr_reg;
                                'hc:
                                    EENTRY<=dwcsr_reg[31:6];
                                'h10:
                                    begin
                                    TLBIDX_Index<=dwcsr_reg[TLB_n-1:0];
                                    TLBIDX_PS<=dwcsr_reg[29:24];
                                    TLBIDX_NE<=dwcsr_reg[31];
                                    end
                                'h11:
                                    TLBEHI<=dwcsr_reg[31:13];
                                'h12:
                                    begin
                                    TLBELO0_VDPLVMATG<=dwcsr_reg[6:0];
                                    TLBELO0_PPN<=dwcsr_reg[TLB_PALEN-5:8];
                                    end
                                'h13:
                                    begin
                                    TLBELO1_VDPLVMATG<=dwcsr_reg[6:0];
                                    TLBELO1_PPN<=dwcsr_reg[TLB_PALEN-5:8];
                                    end  
                                'h18:
                                    begin
                                    ASID_ASID<=dwcsr_reg[9:0];
                                    end
                                'h19:
                                    PGDL<=dwcsr_reg[31:12];
                                'h1a:
                                    PGDH<=dwcsr_reg[31:12];
                                //'h1b:
                                //'h20:
                                    
                                'h30:
                                    SAVE0<=dwcsr_reg;
                                'h31:
                                    SAVE1<=dwcsr_reg;
                                'h32:
                                    SAVE2<=dwcsr_reg;
                                'h33:
                                    SAVE3<=dwcsr_reg;
                                'h40:
                                    TID<=dwcsr_reg;
                                'h41:
                                    TCFG<=dwcsr_reg[TIMER_n-1:0];
                                //'h42:
                                //'h44:    
                                'h60:
                                    begin
                                    if(dwcsr_reg[1])
                                        LLBCTL_ROLLB<=0;
                                    LLBCTL_KLO<=dwcsr_reg[2];
                                    end
                                'h88:
                                    TLBRENTRY<=dwcsr_reg[31:6];
                                //'h98:  
                                'h180:
                                    begin
                                    DMW0_PLV0<=dwcsr_reg[0];
                                    DMW0_PLV3<=dwcsr_reg[3];
                                    DMW0_MAT<=dwcsr_reg[5:4];
                                    DMW0_PSEG<=dwcsr_reg[27:25];
                                    DMW0_VSEG<=dwcsr_reg[31:29];
                                    end
                                'h181:
                                    begin
                                    DMW1_PLV0<=dwcsr_reg[0];
                                    DMW1_PLV3<=dwcsr_reg[3];
                                    DMW1_MAT<=dwcsr_reg[5:4];
                                    DMW1_PSEG<=dwcsr_reg[27:25];
                                    DMW1_VSEG<=dwcsr_reg[31:29];
                                    end
                            endcase 
                    endcase
                    end
                end
        end
    end
    
endmodule



module Random(
    input en, clk, rstn,
    input [31:1] seed,
    output reg [31:0] randnum
    );
    always @(posedge clk) begin
        if(!rstn)   randnum <= 32'b0;
        else if(en) begin
          if(|randnum)  randnum <= {randnum[30:0], ((((randnum[31] ^ randnum[6]) ^ randnum[4]) ^ randnum[2]) ^ randnum[1]) ^ randnum[0]};
          else          randnum <= {seed,1'b1};
        end
    end
  
endmodule










//module Control_State_Register(
//    input clk,rstn,
//    input we,
//    input [31:0] mask,din,
//    input [31:0] addr,
//    output [31:0] dout,
    

//);
    


//endmodule
module CSR_control(
    input clk,rstn,
    input pipeline_CSR_stall,
    input pipeline_CSR_flush,
    output CSR_pipeline_stall,
    output CSR_pipeline_flush,
    output [31:0] CSR_pipeline_outpc,
    input [31:0] pipeline_CSR_inpc0,//
    input [3:0]pipeline_CSR_type,
    input [4:0]pipeline_CSR_subtype,
    input [15:0] pipeline_CSR_excp_arg0,
    input [31:0]pipeline_CSR_din,
    input [31:0]pipeline_CSR_mask,
    output [31:0] CSR_pipeline_dout,
    input [15:0] pipeline_CSR_excp_arg1,//最高位为是否有效，剩余部分分别为esubcode与ecode
    input [31:0] pipeline_CSR_inpc1,//ex2段pc
    input [31:0] pipeline_CSR_evaddr0,//出错虚地址，ex1段
    input [31:0] pipeline_CSR_evaddr1,
    input [8:0]pipeline_CSR_ESTAT,//中断信息,8为核间中断
    output CSR_pipeline_clk_stall,
    output [8:0]CSR_pipeline_CRMD,
    output CSR_pipeline_LLBit,
    output [9:0]CSR_pipeline_ASID,
    output [31:0]CSR_pipeline_DMW0,
    output [31:0]CSR_pipeline_DMW1
    //output CSR_TLB
);
    localparam TLB_n=10,TLB_PALEN=35,TIMER_n=20;
    reg [8:0] CRMD;reg [2:0] PRMD;reg EUEN;reg [12:0] ECFG_LIE;
    reg [1:0] ESTAT_IS;reg TI_INTE;reg [21:16]ESTAT_Ecode;reg [30:22]ESTAT_EsubCode;
    reg[31:0] ERA;reg [31:0] BADV;reg [31:6] EENTRY;wire [31:0] CPUID;
    reg [31:0] SAVE0,SAVE1,SAVE2,SAVE3;reg  LLBCTL_ROLLB,LLBCTL_KLO;wire LLBCTL_WCLLB;
    reg [TLB_n-1:0] TLBIDX_Index;
    reg [29:24] TLBIDX_PS;reg TLBIDX_NE;reg [31:13] TLBEHI;reg [6:0]TLBELO0_VDPLVMATG;
    reg [TLB_PALEN-5:8]TLBELO0_PPN;reg [6:0]TLBELO1_VDPLVMATG;reg [TLB_PALEN-5:8]TLBELO1_PPN;
    reg [9:0] ASID_ASID;wire [23:16] ASID_ASIDBITS;reg [31:12] PGDL;reg [31:12]PGDH;
    wire [31:12]PDG;reg [31:6]TLBRENTRY;reg DMW0_PLV0;reg DMW0_PLV3;reg [5:4] DMW0_MAT;
    reg [27:25] DMW0_PSEG;reg [31:29] DMW0_VSEG;reg DMW1_PLV0;reg DMW1_PLV3;reg [5:4] DMW1_MAT;
    reg [27:25] DMW1_PSEG;reg [31:29] DMW1_VSEG;reg [31:0]TID;reg [TIMER_n-1:0]TCFG;
    reg [TIMER_n-1:0]TVAL;wire TICLR;
    assign CPUID=0,ASID_ASIDBITS=10,PGD=BADV[31]?PGDH:PGDL,TICLR=0,LLBCTL_WCLLB=0;
    assign CSR_pipeline_CRMD=CRMD,CSR_pipeline_LLBit=LLBCTL_ROLLB;
    assign CSR_pipeline_ASID=ASID_ASID;
    assign CSR_pipeline_DMW0={DMW0_VSEG,1'b0,DMW0_PSEG,19'b0,DMW0_MAT,DMW0_PLV3,2'b0,DMW0_PLV0};
    assign CSR_pipeline_DMW1={DMW1_VSEG,1'b0,DMW1_PSEG,19'b0,DMW1_MAT,DMW1_PLV3,2'b0,DMW1_PLV0};
    
    localparam PRIV=3,LLW=6,LOAD=0;
    localparam ERTN=6,IDLE=7,INTE=0,CSRRD=8,CSRWR=9,CSRXCHG=10;
    localparam INT='H0,PIL='H1,PIS='H2,PIF='H3,PME='H4,PPI='H7,
    ADE='H8,ALE='H9,SYS='HB,BRK='HC,INE='HD,IPE='HE,FPD='HF,
    FPE='H12,TLBR='H3F;
    localparam ADEF='H0,ADEM='H1;
    localparam Wait=0;
    reg [4:0]ns,cs;
    reg [4:0] mode;wire [31:0] din;reg [31:0]dout,mask;
    wire [8:0] ESTATin;reg busy,flushout;wire stallin,flushin;
    wire exe;wire [15:0] excp_arg1;reg clk_stall;reg [31:0] outpc;
    wire inte;wire [15:0] csr_num;reg [31:0] inpc;reg [5:0]ecode;reg [8:0] esubcode;
    reg [31:0] evaddr;wire [31:0]dwcsr;reg TI_cl;
    assign stallin=pipeline_CSR_stall,flushin=pipeline_CSR_flush;
    assign CSR_pipeline_stall=busy,CSR_pipeline_flush=flushout;
    assign exe=pipeline_CSR_type==PRIV||excp_arg1[15]||(pipeline_CSR_type==LLW&&pipeline_CSR_subtype==LOAD);
    assign din=pipeline_CSR_din,CSR_pipeline_dout=dout;
    assign excp_arg1=pipeline_CSR_excp_arg1,CSR_pipeline_clk_stall=clk_stall;
    assign CSR_pipeline_outpc=outpc,ESTATin=pipeline_CSR_ESTAT;
    assign csr_num=pipeline_CSR_excp_arg0;
    assign inte={ESTATin[8],TI_INTE,ESTATin[7:0],ESTAT_IS}&{ECFG_LIE[12:11],ECFG_LIE[9:0]}?CRMD[2]:0;
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn||flushin)
        begin
        cs<=Wait;
        end
    else if(!stallin || busy)
        begin
        ns<=cs;
        end
    end
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn)
        begin
        TI_INTE<=0;
        TVAL<=0;
        TCFG<=0;
        end
    else
        begin
        if(TI_cl)
            TI_INTE<=0;
        else if(TVAL==1)
            begin
            TI_INTE<=1;
            end
        if(TVAL==0&&TCFG[1])
            TVAL<={TCFG[TIMER_n-1:2],2'b0};
        else if(TCFG[0]&&TVAL!=0)
            TVAL<=TVAL-1;
        end
    end
    always@(*)
    begin
    busy=1;flushout=1;
    outpc=inpc+4;dout=0;
    mask=~0;
    inpc=pipeline_CSR_inpc0;
    ecode=pipeline_CSR_excp_arg0[5:0];
    esubcode=pipeline_CSR_excp_arg0[14:6];
    mode=pipeline_CSR_subtype;
    evaddr=pipeline_CSR_evaddr0;
    TI_cl=0;
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
    if(mode==ERTN)
        begin
        outpc=ERA;
        end
    else if(ecode==TLBR)
        begin
        outpc={TLBRENTRY,6'b0};
        end
    if(ecode==ADE&&esubcode==ADEF)
        evaddr=inpc;
    case(cs)
        Wait:
            begin
            busy=0;
            if((!stallin && !flushin && exe)||inte)
                begin 
                case(mode)
                    ERTN:
                        begin
                        flushout=1;
                        outpc=ERA;
                        end
                    CSRXCHG:
                        begin
                        mask=pipeline_CSR_mask;
                        if(csr_num=='h44&&dwcsr[0])
                            TI_cl=1;
                        end
                    INTE:
                       begin
                       flushout=1; 
                       if(ecode==TLBR)
                            begin
                            outpc={TLBRENTRY,6'b0};
                            end
                       else
                            outpc={EENTRY,6'b0};
                       end 
                    CSRWR:
                         if(csr_num=='h44&&dwcsr[0])
                            TI_cl=1;          
                endcase
                end
            else
                begin
                flushout=0;
                ns=Wait;
                end
            end
    endcase
    
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
        DMW1_PSEG<=0;DMW1_VSEG<=0;TID<=0;
        end
    else
        begin
        case(cs)
            Wait:
                begin
                if((!stallin && !flushin && exe)||inte)
                    begin
                    if(mode==IDLE && !clk_stall)
                        begin
                        clk_stall<=1;
                        end   
                    else
                        begin
                        case(mode)
                            ERTN:
                                begin
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
                                ERA<=inpc;
                                clk_stall<=0;
                                if(ecode==TLBR)
                                    begin
                                    CRMD[4:3]<=2'b01;
                                    end
                                ESTAT_Ecode<=ecode;
                                ESTAT_EsubCode<=esubcode;
                                BADV<=evaddr;
                                end
                            LLW:
                                begin
                                LLBCTL_ROLLB<=1;
                                end
                            CSRWR,CSRXCHG:
                               case(csr_num)
                                    'h0:
                                        begin
                                        CRMD[2:0]<=dwcsr[2:0];
                                        CRMD[8:5]<=dwcsr[8:5];
                                        if(dwcsr[4]^dwcsr[3])
                                            CRMD[4:3]<=dwcsr[4:3];
                                        end
                                    'h1:
                                        PRMD<=dwcsr[2:0];
                                    'h2:
                                        EUEN<=dwcsr[0];
                                    'h4:
                                        begin
                                        ECFG_LIE[12:11]<=dwcsr[12:11];
                                        ECFG_LIE[9:0]<=dwcsr[9:0];
                                        end
                                    'h5:
                                        begin
                                        ESTAT_IS<=dwcsr[1:0];
                                        end
                                    'h6:
                                         ERA<=dwcsr;
                                    'h7:
                                        BADV<=dwcsr;
                                    'hc:
                                        EENTRY<=dwcsr[31:6];
                                    'h10:
                                        begin
                                        TLBIDX_Index<=dwcsr[TLB_n-1:0];
                                        TLBIDX_PS<=dwcsr[29:24];
                                        TLBIDX_NE<=dwcsr[31];
                                        end
                                    'h11:
                                        TLBEHI<=dwcsr[31:13];
                                    'h12:
                                        begin
                                        TLBELO0_VDPLVMATG<=dwcsr[6:0];
                                        TLBELO0_PPN<=dwcsr[TLB_PALEN-5:8];
                                        end
                                    'h13:
                                        begin
                                        TLBELO1_VDPLVMATG<=dwcsr[6:0];
                                        TLBELO1_PPN<=dwcsr[TLB_PALEN-5:8];
                                        end  
                                    'h18:
                                        begin
                                        ASID_ASID<=dwcsr[9:0];
                                        end
                                    'h19:
                                        PGDL<=dwcsr[31:12];
                                    'h1a:
                                        PGDH<=dwcsr[31:12];
                                    //'h1b:
                                    //'h20:
                                        
                                    'h30:
                                        SAVE0<=dwcsr;
                                    'h31:
                                        SAVE1<=dwcsr;
                                    'h32:
                                        SAVE2<=dwcsr;
                                    'h33:
                                        SAVE3<=dwcsr;
                                    'h40:
                                        TID<=dwcsr;
                                    'h41:
                                        TCFG<=dwcsr[TIMER_n-1:0];
                                    //'h42:
                                    //'h44:    
                                    'h60:
                                        begin
                                        if(dwcsr[1])
                                            LLBCTL_ROLLB<=0;
                                        LLBCTL_KLO<=dwcsr[2];
                                        end
                                    'h88:
                                        TLBRENTRY<=dwcsr[31:6];
                                    //'h98:  
                                    'h180:
                                        begin
                                        DMW0_PLV0<=dwcsr[0];
                                        DMW0_PLV3<=dwcsr[3];
                                        DMW0_MAT<=dwcsr[5:4];
                                        DMW0_PSEG<=dwcsr[27:25];
                                        DMW0_VSEG<=dwcsr[31:29];
                                        end
                                    'h181:
                                        begin
                                        DMW1_PLV0<=dwcsr[0];
                                        DMW1_PLV3<=dwcsr[3];
                                        DMW1_MAT<=dwcsr[5:4];
                                        DMW1_PSEG<=dwcsr[27:25];
                                        DMW1_VSEG<=dwcsr[31:29];
                                        end
                                endcase 
                        endcase
                        end
                    end
                else
                    begin
                    
                    end
                end
            
            
            
            
        endcase
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
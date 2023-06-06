module CSR_control(
    input clk,rstn,
    input pipeline_CSR_stall,
    input pipeline_CSR_flush,
    output CSR_pipeline_stall,
    output CSR_pipeline_flush,
    output [31:0] CSR_pipeline_outpc,
    input [3:0]pipeline_CSR_type,
    input [4:0]pipeline_CSR_subtype,
    input [15:0] pipeline_CSR_csr_num,
    input [31:0]pipeline_CSR_din,
    input [31:0]pipeline_CSR_mask,
    output [31:0] CSR_pipeline_dout,
    input [3:0] pipeline_CSR_exceptionTLB,//最高位表示是否有效,高优先级
    //input [15:0] pipeline_CSR_exception2,
    input [8:0]pipeline_CSR_ESTAT,//最高位为核间中断
    output CSR_pipeline_clk_stall
    //output CSR_TLB
);
    localparam TLB_n=10,TLB_PALEN=35,TIMER_n=20;
    reg [8:0] CRMD;reg [2:0] PRMD;wire [31:0] EUEN;reg [12:0] ECFG_LIE;
    reg [1:0] ESTAT_IS;wire TI_INTE;reg [21:16]ESTAT_Ecode;reg [30:22]ESTAT_EsubCode;
    reg[31:0] ERA;reg [31:0] BADV;reg [31:6] EENTRY;wire [31:0] CPUID;
    reg [31:0] SAVE0,SAVE1,SAVE2,SAVE3;reg  LLBCTL_ROLLB,LLBCTL_KLO;reg [TLB_n-1:0] TLBIDX_Index;
    reg [29:24] TLBIDX_PS;reg TLBIDX_NE;reg [31:13] TLBEHI;reg [6:0]TLBELO0_VDPLVMATG;
    reg [TLB_PALEN-5:8]TLBELO0_PPN;reg [6:0]TLBELO1_VDPLVMATG;reg [TLB_PALEN-5:8]TLBELO1_PPN;
    reg [9:0] ASID_ASID;wire [23:16] ASID_ASIDBITS;reg [31:12] PGDL;reg [31:12]PGDH;
    wire [31:12]PDG;reg [31:6]TLBRENTRY;reg DMW0_PLV0;reg DMW0_PLV3;reg [5:4] DMW0_MAT;
    reg [27:25] DMW0_PSEG;reg [31:29] DMW0_VSEG;reg DMW1_PLV0;reg DMW1_PLV3;reg [5:4] DMW1_MAT;
    reg [27:25] DMW1_PSEG;reg [31:29] DMW1_VSEG;reg [31:0]TID;reg [TIMER_n-1:0]TCFG;
    reg [TIMER_n-1:0]TAVL;wire TICLR;
    
    localparam PRIV=3,LLW=6,LOAD=0;
    localparam ERTN=6,IDLE=7,BRK=11,SYS=12,INTER=13,CSRRD=8,CSRWR=9,CSRXCHG=10,IPE=14;
    localparam Wait=0;
    reg [4:0]ns,cs;
    reg [4:0] mode;wire [31:0] din;reg [31:0]dout,mask;
    wire [8:0] ESTATin;reg busy,flushout;wire stallin,flushin;
    wire exe;wire [3:0] expTLB;reg clk_stall;reg [31:0] outpc;
    wire inte;wire [15:0] csr_num;
    assign stallin=pipeline_CSR_stall,flushin=pipeline_CSR_flush;
    assign CSR_pipeline_stall=busy,CSR_pipeline_flush=flushout;
    assign exe=pipeline_CSR_type==PRIV||expTLB[3]||(pipeline_CSR_type==LLW&&pipeline_CSR_subtype==LOAD);
    assign din=pipeline_CSR_din,CSR_pipeline_dout=dout;
    assign expTLB=pipeline_CSR_exceptionTLB,CSR_pipeline_clk_stall=clk_stall;
    assign CSR_pipeline_outpc=outpc,ESTATin=pipeline_CSR_ESTAT;
    assign csr_num=pipeline_CSR_csr_num;
    assign inte={ESTATin[8],TI_INTE,ESTATin[7:0],ESTAT_IS}&{ECFG_LIE[12:11],ECFG_LIE[9:0]}?1:0;
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
    always@(*)
    begin
    busy=1;flushout=0;
    outpc=ERA;dout=0;
    mask=~0;
    if(inte)
        mode=INTER;
    else
        mode=pipeline_CSR_subtype;
    case(csr_num)
        'h0:
            dout={23'b0,CRMD};
        'h1:
            dout={29'b0,PRMD};
        'h2:
            dout=0;
        'h4:
            dout={19'b0,ECFG_LIE[12:11],1'b0,ECFG_LIE[9:0]};
        'h5:
        'h6:
        'h7:
        'hc:
        'h10:
        'h11:
        'h12:
        'h13:  
        'h18:
        'h19:
        'h1a:
        'h20:
        'h30:
        'h31:
        'h32:
        'h33:
        'h40:
        'h41:
        'h42:
        'h44:
        'h60:
        'h88:
        'h98:
        'h180;
        'h181:
        
    endcase
    case(cs)
        Wait:
          begin
          if(!stallin && !flushin && exe)
              begin
              if(expTLB[3])
                  begin
                  end
              else
                begin
                case(mode)
                    ERTN:
                        begin
                        flushout=1;
                        outpc=ERA;
                        end  
                    CSRRD,CSRWR,CSRXCHG:
                        begin
                        if(mode==CSRXCHG)
                            mask=pipeline_CSR_mask;
                        
                        end
                    
                endcase
                end
              end
          else
              begin
              ns=Wait;
              busy=0;
              end
          end
    endcase
    end
    always@(posedge(clk),negedge(rstn))
    begin
    if(!rstn)
        begin
        clk_stall<=0;
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
                    else if(mode==LLW)
                        begin
                        LLBCTL_ROLLB<=1;
                        end
                    else if(expTLB[3])
                        begin
                        end
                    else
                        begin
                        case(mode)
                            ERTN:
                                begin
                                if(ESTAT_Ecode=='h3f)
                                    CRMD[4:0]<={2'b10,PRMD};
                                else
                                    CRMD[4:0]<={2'b01,PRMD};
                                LLBCTL_KLO<=0;
                                if(!LLBCTL_KLO)
                                    LLBCTL_ROLLB<=0;  
                                end
                            BRK:
                                begin
                                end
                            SYS:
                                begin
                                end
                            
                                
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
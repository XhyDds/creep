module decoder (
    input [31:0]ir,
    input [31:0]pc,
    input valid,
    input [1:0]PLV,
    output [31:0]control,
    output reg [4:0]rk,rj,rd,
    output reg [31:0]imm,
    output reg [15:0]excp_arg
);
    localparam yu=0,huo=1,huofei=2,yihuo=3,jia=4,jian=5,zuoyi=6,youyi=7,ssyouyi=8,sxiaoyu=9,xiaoyu=10,tong1=11,tong2=12;
    localparam alu=0,tiao=1,cheng=4,chu=2,liwai=3,dcache=5,yuanzi=6,shizhong=7,tiaoxie=8;
    reg [1:0]pcsrc;//1:br, 0:writeback, 2:predecoder, 3:predictor
    reg [1:0]alusrc1;//0:reg, 1:pc
    reg [1:0]alusrc2;//0:reg, 1:imm
    reg [3:0]type_;//0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:llbit, 7:RDCNT, 8:alu+br, 9:ibar, 10:priv+mmu, 11:mmu
    reg [3:0]aluop;//0:&, 1:|, 2:~|, 3:^, 4:+, 5:-, 6:<<, 7:>>, 8:>>>, 9:sign<, 10:<, 11:alu1, 12:alu2, 13:alu1+4
    reg [4:0]subtype;//可与aluop合并？×有同时使用
    //for priv, 0:exception, 6:ertn, 7:idle, 8~10:csr
    //for mmu, 5:invtlb
    //for priv+mmu: 1~4:tlb
    //for div, 0:div.w, 1:mod.w, 2:div.wu, 3:mod.wu
    //for mul, 0:mul.w, 1:mulh.w, 2:mulh.wu
    //for dcache, 0~2:load, 3~5:store, 6~7:load, 8:cacop
    //for br, 0:b, 1:beq, 2:bne, 3:blt, 4:bge, 5:bltu, 6:bgeu
    //for yuanzi, 0:load, 1:store
    //for tiaoxie, 0:jirl, 1:bl
    //for rdcnt, 0:rdcntvl.w, 1:rdcntvh.w, (2:rdcntid)
    reg memread,memwrite,regwrite,nop,priv,ifrdc;
    assign control=(valid)?{8'b0,ifrdc,priv,aluop,pcsrc,alusrc1,alusrc2,subtype,regwrite,memwrite,memread,type_}:0;//顺序可调换
    always @(*) begin
        rk=0;rj=0;rd=0;imm=0;excp_arg=0;aluop=0;pcsrc=0;alusrc1=0;alusrc2=0;type_=0;subtype=0;regwrite=0;memwrite=0;memread=0;nop=0;priv=0;ifrdc=0;
        if(|pc[1:0]) begin //ADEF 
            type_=liwai;subtype=0;excp_arg='b0_001000; 
        end
        else 
        if(pc[31]&PLV!=0) begin //ADEM 
            type_=liwai;subtype=0;excp_arg='b1_001000; 
        end
        else 
        case (ir[31:26])
        'b000000: 
            case (ir[25:22])
                'b0000: 
                    case (ir[21:15])
                        'b0000000: 
                            if(ir[14:11]=='b1100) 
                                if(!ir[10])
                                    if(|ir[9:5])         begin excp_arg=16'h40;rd=ir[9:5];type_=liwai;subtype=8;regwrite=1;ifrdc=1; end//RDCNTID
                                    else if(|ir[4:0])    begin rd=ir[4:0];type_=shizhong;subtype=0;regwrite=1;ifrdc=1; end//RDCNTVL.W
                                    else                 begin type_=liwai;subtype=0;excp_arg='b001101; end
                                else 
                                    if(~|ir[9:5])        begin rd=ir[4:0];type_=shizhong;subtype=1;regwrite=1;ifrdc=1; end//RDCNTVH.W
                                    else                 begin type_=liwai;subtype=0;excp_arg='b001101; end
                            // else    if(~|ir[14:0])       begin nop=1; end//全0为也是不存在例外！！
                            else                         begin type_=liwai;subtype=0;excp_arg='b001101; end
                        'b0100000: //ADD.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=jia;regwrite=1;
                            end
                        'b0100010: //SUB.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=jian;regwrite=1;
                            end
                        'b0100100: //SLT
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=sxiaoyu;regwrite=1;
                            end
                        'b0100101: //SLTU
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=xiaoyu;regwrite=1;
                            end
                        'b0101000: //NOR
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=huofei;regwrite=1;
                            end
                        'b0101001: //AND
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=yu;regwrite=1;
                            end
                        'b0101010: //OR
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=huo;regwrite=1;
                            end
                        'b0101011: //XOR
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=yihuo;regwrite=1;
                            end
                        'b0101110: //SLL.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=zuoyi;regwrite=1;
                            end
                        'b0101111: //SRL.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=youyi;regwrite=1;
                            end
                        'b0110000: //SRA.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=alu;aluop=ssyouyi;regwrite=1;
                            end
                        'b0111000: //MUL.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=cheng;subtype=0;regwrite=1;
                            end
                        'b0111001: //MULH.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=cheng;subtype=1;regwrite=1;
                            end
                        'b0111010: //MULH.WU
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=cheng;subtype=2;regwrite=1;
                            end
                        'b1000000: //DIV.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=chu;subtype=0;regwrite=1;
                            end
                        'b1000001: //MOD.W
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=chu;subtype=1;regwrite=1;
                            end
                        'b1000010: //DIV.WU
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=chu;subtype=2;regwrite=1;
                            end
                        'b1000011: //MOD.WU
                            begin
                                rk=ir[14:10];rj=ir[9:5];rd=ir[4:0];type_=chu;subtype=3;regwrite=1;
                            end
                        'b1010100: //BREAK
                            begin
                                // excp_arg={ir[14:0]};
                                type_=liwai;subtype=0;excp_arg='b001100;
                            end
                        'b1010110: //SYSCALL
                            begin
                                // excp_arg=ir[14:0];
                                type_=liwai;subtype=0;excp_arg='b001011;
                            end
                        default: begin type_=liwai;subtype=0;excp_arg='b001101; end
                    endcase
                'b0001: 
                    if(ir[21:20]=='b00&ir[17:15]=='b001)
                        case (ir[19:18])
                            'b00: //SLLI.W
                                begin
                                    imm={27'b0,ir[14:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=zuoyi;regwrite=1;
                                end
                            'b01: //SRLI.W
                                begin
                                    imm={27'b0,ir[14:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=youyi;regwrite=1;
                                end
                            'b10: //SRAI.W
                                begin
                                    imm={27'b0,ir[14:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=ssyouyi;regwrite=1;
                                end
                            default: begin type_=liwai;subtype=0;excp_arg='b001101; end
                        endcase
                    else begin type_=liwai;subtype=0;excp_arg='b001101; end
                'b1000: //SLTI
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=sxiaoyu;regwrite=1;
                    end
                'b1001: //SLTUI
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=xiaoyu;regwrite=1;
                    end
                'b1010: //ADDI.W
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=jia;regwrite=1;
                    end
                'b1101: //ANDI
                    begin
                        imm={20'b0,ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=yu;regwrite=1;
                    end
                'b1110: //ORI
                    begin
                        imm={20'b0,ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=huo;regwrite=1;
                    end
                'b1111: //XORI
                    begin
                        imm={20'b0,ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=alu;alusrc2=1;aluop=yihuo;regwrite=1;
                    end
                default: begin type_=liwai;subtype=0;excp_arg='b001101; end
            endcase
        'b000001: 
            case (ir[25:24])
                'b00: //CSR
                    case (ir[9:5])
                        'b00000: //CSRRD
                            begin
                                excp_arg={2'b0,ir[23:10]};rd=ir[4:0];type_=liwai;subtype=8;regwrite=1;priv=1;
                            end
                        'b00001: //CSRWR
                            begin
                                excp_arg={2'b0,ir[23:10]};rd=ir[4:0];type_=liwai;subtype=9;regwrite=1;priv=1;
                            end
                        default: //CSRXCHG
                            begin
                                excp_arg={2'b0,ir[23:10]};rd=ir[4:0];rj=ir[9:5];type_=liwai;subtype=10;regwrite=1;priv=1;
                            end
                    endcase
                'b10: 
                    case (ir[23:22])
                        'b00: //CACOP
                            begin
                                imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];excp_arg={11'b0,ir[4:0]};type_=dcache;subtype=8;priv=(ir[4:3]!=2);
                            end
                        'b01: 
                            if(ir[21:17]=='b00100&ir[9:0]=='b0000000000)
                            case (ir[16:15])
                                'b00: 
                                    case (ir[14:10])
                                        'b01010: begin type_=10;subtype=1; end//TLBSRCH
                                        'b01011: begin type_=10;subtype=2; end//TLBRD
                                        'b01100: begin type_=10;subtype=3; end//TLBWR
                                        'b01101: begin type_=10;subtype=4; end//TLBFILL
                                        'b01110: begin type_=liwai;subtype=6;priv=1; end //ERTN
                                        default: begin type_=liwai;subtype=0;excp_arg='b001101; end
                                    endcase
                                'b01: begin  //IDLE
                                    type_=liwai;subtype=7;excp_arg={1'b0,ir[14:0]};priv=1;
                                end
                                'b11: begin 
                                    type_=11;subtype=5;rk=ir[14:10];rj=ir[9:5];excp_arg={11'b0,ir[4:0]};priv=1; 
                                end//INVTLB
                                default: begin type_=liwai;subtype=0;excp_arg='b001101; end
                            endcase
                            else begin type_=liwai;subtype=0;excp_arg='b001101; end
                        default: begin type_=liwai;subtype=0;excp_arg='b001101; end
                    endcase
                default: begin type_=liwai;subtype=0;excp_arg='b001101; end
            endcase
        'b000101: 
            if(!ir[25]) //LU12I.W
                begin 
                    imm={ir[24:5],12'b0};rd=ir[4:0];type_=alu;aluop=tong2;regwrite=1;alusrc2=1;
                end 
            else begin type_=liwai;subtype=0;excp_arg='b001101; end
        'b000111: 
            if(!ir[25]) //PCADDU12I
                begin  
                    imm={ir[24:5],12'b0};rd=ir[4:0];type_=alu;aluop=jia;alusrc1=1;regwrite=1;alusrc2=1;
                end 
            else begin type_=liwai;subtype=0;excp_arg='b001101; end
        'b001000:
            case (ir[25:24])
                'b00: //LL.W
                    begin
                        imm={{18{ir[23]}},ir[23:10]};rj=ir[9:5];rd=ir[4:0];type_=yuanzi;subtype=0;regwrite=1;memread=1;
                    end
                'b01: //SC.W
                    begin
                        imm={{18{ir[23]}},ir[23:10]};rj=ir[9:5];rd=ir[4:0];type_=yuanzi;subtype=1;memwrite=1;
                    end
                default: begin type_=liwai;subtype=0;excp_arg='b001101; end
            endcase
        'b001010: 
            case (ir[25:22])
                'b0000: //LD.B
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=0;regwrite=1;memread=1;
                    end
                'b0001: //LD.H
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=1;regwrite=1;memread=1;
                    end
                'b0010: //LD.W
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=2;regwrite=1;memread=1;
                    end
                'b0100: //ST.B
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=3;memwrite=1;
                    end
                'b0101: //ST.H
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=4;memwrite=1;
                    end
                'b0110: //ST.W
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=5;memwrite=1;
                    end
                'b1000: //LD.BU
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=6;regwrite=1;memread=1;
                    end
                'b1001: //LD.HU
                    begin
                        imm={{20{ir[21]}},ir[21:10]};rj=ir[9:5];rd=ir[4:0];type_=dcache;subtype=7;regwrite=1;memread=1;
                    end
                'b1011: nop=1;//PRELD
                default: begin type_=liwai;subtype=0;excp_arg='b001101; end
            endcase
        'b001110: 
            if(ir[25:18]=='b0001110010)
                case (ir[17])
                    'b0: nop=1;//DBAR
                    'b1: begin type_=9; end//IBAR
                    default: begin type_=liwai;subtype=0;excp_arg='b001101; end
                endcase
            else begin type_=liwai;subtype=0;excp_arg='b001101; end
        'b010011: //JIRL
            begin 
                imm={{14{ir[25]}},ir[25:10],2'b0};type_=tiaoxie;subtype=0;regwrite=1;pcsrc=1;
                aluop=jia;alusrc1=1;alusrc2=3;rj=ir[9:5];rd=ir[4:0];
            end
        'b010100: //B
            begin 
                imm={{4{ir[9]}},ir[9:0],ir[25:10],2'b0};type_=tiao;subtype=0;pcsrc=1;
            end
        'b010101: //BL
            begin 
                imm={{4{ir[9]}},ir[9:0],ir[25:10],2'b0};type_=tiaoxie;subtype=1;regwrite=1;pcsrc=1;aluop=jia;alusrc1=1;alusrc2=3;rd=1;
            end
        'b010110: //BEQ
            begin
                imm={{14{ir[25]}},ir[25:10],2'b0};rj=ir[9:5];rd=ir[4:0];type_=tiao;subtype=1;pcsrc=1;aluop=jian;alusrc2=2;
            end
        'b010111: //BNE
            begin
                imm={{14{ir[25]}},ir[25:10],2'b0};rj=ir[9:5];rd=ir[4:0];type_=tiao;subtype=2;pcsrc=1;aluop=jian;alusrc2=2;
            end
        'b011000: //BLT
            begin
                imm={{14{ir[25]}},ir[25:10],2'b0};rj=ir[9:5];rd=ir[4:0];type_=tiao;subtype=3;pcsrc=1;aluop=sxiaoyu;alusrc2=2;
            end
        'b011001: //BGE
            begin
                imm={{14{ir[25]}},ir[25:10],2'b0};rj=ir[9:5];rd=ir[4:0];type_=tiao;subtype=4;pcsrc=1;aluop=sxiaoyu;alusrc2=2;
            end
        'b011010: //BLTU
            begin
                imm={{14{ir[25]}},ir[25:10],2'b0};rj=ir[9:5];rd=ir[4:0];type_=tiao;subtype=5;pcsrc=1;aluop=xiaoyu;alusrc2=2;
            end
        'b011011: //BGEU
            begin
                imm={{14{ir[25]}},ir[25:10],2'b0};rj=ir[9:5];rd=ir[4:0];type_=tiao;subtype=6;pcsrc=1;aluop=xiaoyu;alusrc2=2;
            end
        default: begin type_=liwai;subtype=0;excp_arg='b001101; end
        endcase
    end
endmodule

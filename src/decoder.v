module decoder (
    input [31:0]addr,
    output [31:0]control
);
    reg [3:0]alusrc;//0:&, 1:|, 2:~|, 3:^, 4:+, 5:-, 6:<<, 7:>>, 8:>>>, 9:sign<, 10:<, 11:alu1, 12:alu2,
    reg [1:0]pcsrc;//0:br, 1:writeback, 2:predecoder, 3:predictor
    reg [2:0]type;//0:alu, 1:br, 2:div, 3:priv, 4:mul, 5:dcache, 6:ll.w/sc.w
    reg memread,memtoreg,memwrite,regwrite;
    reg nop;
    assign control=nop?0:{alusrc};
    always @(*) begin
        case (addr[31:26])
        'b000000: 
            case (addr[25:22])
                'b0000: 
                    case (addr[21:15])
                        'b0000000: ;//CSRRD
                        'b0100000: ;//ADD.W
                        'b0100010: ;//SUB.W
                        'b0100100: ;//SLT
                        'b0100101: ;//SLTU
                        'b0101000: ;//NOR
                        'b0101001: ;//AND
                        'b0101010: ;//OR
                        'b0101011: ;//XOR
                        'b0101110: ;//SLL.W
                        'b0101111: ;//SRL.W
                        'b0110000: ;//SRA.W
                        'b0111000: ;//MUL.W
                        'b0111001: ;//MULH.W
                        'b0111010: ;//MULH.WU
                        'b1000000: ;//DIV.W
                        'b1000001: ;//MOD.W
                        'b1000010: ;//DIV.WU
                        'b1000011: ;//MOD.WU
                        'b1010100: ;//BREAK
                        'b1010110: ;//SYSCALL
                        default:  nop=1;
                    endcase
                'b0001: 
                    if(addr[21:20]=='b00&addr[17:15]=='b001)
                        case (addr[19:18])
                            'b00: ;//SLLI.W
                            'b01: ;//SRLI.W
                            'b10: ;//SRAI.W
                            default:  nop=1;
                        endcase
                    else nop=1;
                'b1000: ;//SLTI
                'b1001: ;//SLTUI
                'b1010: ;//ADDI.W
                'b1101: ;//ANDI
                'b1110: ;//ORI
                'b1111: ;//XORI
                default:  nop=1;
            endcase
        'b000001: 
            case (addr[25:24])
                'b00: //CSR
                case (addr[9:5])
                    'b00000: ;//CSRRD
                    'b00001: ;//CSRWR
                    default:  ;//CSRXCHG
                endcase
                'b10: 
                    case (addr[23:22])
                        'b00: ;//CACOP
                        'b01: 
                            if(addr[21:17]=='b00100&addr[9:0]=='b0000000000)
                            case (addr[16:15])
                                00: 
                                    case (addr[14:10])
                                        // 'b01010: ;//TLBSRCH
                                        // 'b01011: ;//TLBRD
                                        // 'b01100: ;//TLBWR
                                        // 'b01101: ;//TLBFILL
                                        'b01110: ;//ERTN
                                        default: nop=1;
                                    endcase
                                01: ;//IDLE
                                // 11: ;//INVTLB
                                default: nop=1;
                            endcase
                            else nop=1;
                    default: nop=1;
                    endcase
            default: nop=1;
            endcase
        'b000101: if(!addr[25]) ;else nop=1;//LU12I.W
        'b000111: if(!addr[25]) ;else nop=1;//PCADDU12I
        'b001000:
            case (addr[25:24])
                'b00: ;//LL.W
                'b01: ;//SC.W
            default: nop=1;
            endcase
        'b001010: 
            case (addr[25:22])
                'b0000: ;//LD.B
                'b0001: ;//LD.H
                'b0010: ;//LD.W
                'b0100: ;//ST.B
                'b0101: ;//ST.H
                'b0110: ;//ST.W
                'b1000: ;//LD.BU
                'b1001: ;//LD.HU
                'b1011: ;//PRELD
            default: nop=1;
            endcase
        'b001110: 
            if(addr[25:18]=='b0001110010)
                case (addr[17])
                    // 'b0: ;//DBAR
                    'b1: ;//IBAR
                default: nop=1;
                endcase
            else nop=1;
        // 'b010010: ;
        // 'b010011: ;
        'b010100: ;//B
        // 'b010101:
        'b010110: ;//BEQ
        'b010111: ;//BNE
        'b011000: ;//BLT
        'b011001: ;//BGE
        'b011010: ;//BLTU
        'b011011: ;//BGEU
        default: nop=1;
        endcase
    end
endmodule
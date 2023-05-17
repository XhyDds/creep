//soc confreg
#define CONFREG_NULL            0xbfaf8ffc

#define CONFREG_CR0             0xbfaf8000
#define CONFREG_CR1             0xbfaf8010
#define CONFREG_CR2             0xbfaf8020
#define CONFREG_CR3             0xbfaf8030
#define CONFREG_CR4             0xbfaf8040
#define CONFREG_CR5             0xbfaf8050
#define CONFREG_CR6             0xbfaf8060
#define CONFREG_CR7             0xbfaf8070

#define IO_SIMU_ADDR            0xbfafff00
#define UART_ADDR               0xbfafff10
#define SIMU_FLAG_ADDR          0xbfafff20
#define OPEN_TRACE_ADDR         0xbfafff30
#define NUM_MONITOR_ADDR        0xbfafff40
#define LED_ADDR                0xbfaff020
#define LED_RG0_ADDR            0xbfaff030
#define LED_RG1_ADDR            0xbfaff040
#define NUM_ADDR                0xbfaff050
#define SWITCH_ADDR             0xbfaff060
#define BTN_KEY_ADDR            0xbfaff070
#define BTN_STEP_ADDR           0xbfaff080
#define SW_INTER_ADDR           0xbfaff090 //switch interleave
#define TIMER_ADDR              0xbfafe000

#define SOC_LED            (* (volatile unsigned *)  LED_ADDR      )
#define SOC_LED_RG0        (* (volatile unsigned *)  LED_RG0_ADDR  )
#define SOC_LED_RG1        (* (volatile unsigned *)  LED_RG1_ADDR  )
#define SOC_NUM            (* (volatile unsigned *)  NUM_ADDR      )
#define SOC_SWITCHE        (* (volatile unsigned *)  SWITCH_ADDR   )
#define SOC_BTN_KEY        (* (volatile unsigned *)  BTN_KEY_ADDR  )
#define SOC_BTN_STEP       (* (volatile unsigned *)  BTN_STEP_ADDR )
#define SOC_TIMER          (* (volatile unsigned *)  TIMER_ADDR    )
//#define disable_trace_cmp  *((volatile int *)OPEN_TRACE_ADDR) = 0; \
//                           *((volatile int *)CONFREG_NULL   ) = 0; \
//                           *((volatile int *)CONFREG_NULL   ) = 0
//#define enable_trace_cmp   *((volatile int *)OPEN_TRACE_ADDR) = 1; \
//                           *((volatile int *)CONFREG_NULL   ) = 0; 
//                          *((volatile int *)CONFREG_NULL   ) = 0;
#define trace_cmp_flag     (*((volatile int *)OPEN_TRACE_ADDR))
#define disable_trace_cmp  asm volatile( \
                               ".set noreorder;" \
                               "lui $25,0xbfb0\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "sw $0,-0x8($25)\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "lw $0,-0x7004($25)\n\t" \
                               "lw $25,-0x8($25)\n\t" \
                               ".set reorder" \
                               :::"$25" \
                               )
#define disable_trace_cmp_s    .set noreorder;  \
                               lui k1,0xbfb0;  \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x8(k1); \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x7004(k1); \
                               lw $0,-0x7004(k1); \
                               lw k1,-0x8(k1); \
                               .set reorder; \

#define disable_num_monitor_s  .set noreorder;  \
                               lui k1,0xbfb0;  \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x4(k1); \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x7004(k1); \
                               lw $0,-0x7004(k1); \
                               lw k1,-0x4(k1); \
                               .set reorder; \

#define enable_trace_cmp  asm volatile( \
                               ".set noreorder;" \
                               "lui $25,0xbfb0\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "sw $25,-8($25)\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "sw $0,-0x7004($25)\n\t" \
                               "lw $0,-0x7004($25)\n\t" \
                               "lw $25,-0x8($25)\n\t" \
                               ".set reorder" \
                               :::"$25" \
                               )

#define enable_trace_cmp_s     .set noreorder; \
                               lui k1,0xbfb0; \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x7004(k1); \
                               sw k1,-8(k1); \
                               sw $0,-0x7004(k1); \
                               sw $0,-0x7004(k1); \
                               lw $0,-0x7004(k1); \
                               lw k1,-0x8(k1); \
                               .set reorder; \
                               
#define write_confreg_cr(num,data) *((volatile int *)(CONFREG_CR0+4*num)) = data
#define read_confreg_cr(num,data) data=*((volatile int *)(CONFREG_CR0+4*num))
#define nop
#define NOP
#define NOP4 NOP;NOP;NOP;NOP
#define LI(reg, imm) \
    lu12i.w reg , (((imm>>12)+((imm&0x00000800)>>11))&0x000fffff)&0x80000?(((imm>>12)+((imm&0x00000800)>>11))&0x000fffff)-0x100000:(((imm>>12)+((imm&0x00000800)>>11))&0x000fffff); \
    NOP4; \
    addi.w reg, reg, (imm & 0x00000fff)&0x800?(imm & 0x00000fff)-0x1000:(imm & 0x00000fff)


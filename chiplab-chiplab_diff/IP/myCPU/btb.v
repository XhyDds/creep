module btb
#(
    parameter BTBNUM = 32
)
(
    input             clk           ,
    input             reset         ,
    //from/to if
    input  [31:0]     fetch_pc      ,
    input             fetch_en      ,
    output [31:0]     ret_pc        ,
    output            taken         ,
    output            ret_en        ,
    output [ 4:0]     ret_index     ,
    //from id
    input             operate_en    ,
    input  [31:0]     operate_pc    ,
    input  [ 4:0]     operate_index ,
    input             pop_ras       ,
    input             push_ras      ,
    input             add_entry     ,
    input             delete_entry  ,
    input             pre_error     ,
    input             pre_right     ,
    input             target_error  ,
    input             right_orien   ,
    input  [31:0]     right_target  
);

reg [29:0] pc      [BTBNUM-1:0];
reg [29:0] target  [BTBNUM-1:0];
reg [ 2:0] counter [BTBNUM-1:0];

reg [BTBNUM-1:0] jirl_flag;
reg [BTBNUM-1:0] valid    ;

reg [29:0] ras [7:0];
reg [ 2:0] ras_ptr;

reg [29:0] ras_buffer;

wire ras_full;
wire ras_empty;

reg [31:0] match_rd;

wire [29:0] match_target;
wire [ 2:0] match_counter;
wire [ 4:0] match_index;
wire        match_jirl_flag;

wire all_entry_valid;
wire [4:0] select_one_invalid_entry;

wire [4:0] add_entry_index;

assign add_entry_index = all_entry_valid ? fcsr[4:0] : select_one_invalid_entry;

assign all_entry_valid = &valid;

assign select_one_invalid_entry = !valid[ 0] ? 5'd0  :
                                  !valid[ 1] ? 5'd1  :
                                  !valid[ 2] ? 5'd2  :
                                  !valid[ 3] ? 5'd3  :
                                  !valid[ 4] ? 5'd4  :
                                  !valid[ 5] ? 5'd5  :
                                  !valid[ 6] ? 5'd6  :
                                  !valid[ 7] ? 5'd7  : 
                                  !valid[ 8] ? 5'd8  :
                                  !valid[ 9] ? 5'd9  :
                                  !valid[10] ? 5'd10 :
                                  !valid[11] ? 5'd11 :
                                  !valid[12] ? 5'd12 :
                                  !valid[13] ? 5'd13 :
                                  !valid[14] ? 5'd14 : 
                                  !valid[15] ? 5'd15 : 
                                  !valid[16] ? 5'd16 :
                                  !valid[17] ? 5'd17 :
                                  !valid[18] ? 5'd18 :
                                  !valid[19] ? 5'd19 :
                                  !valid[20] ? 5'd20 :
                                  !valid[21] ? 5'd21 :
                                  !valid[22] ? 5'd22 : 
                                  !valid[23] ? 5'd23 : 
                                  !valid[24] ? 5'd24 :
                                  !valid[25] ? 5'd25 :
                                  !valid[26] ? 5'd26 :
                                  !valid[27] ? 5'd27 :
                                  !valid[28] ? 5'd28 :
                                  !valid[29] ? 5'd29 :
                                  !valid[30] ? 5'd30 :
                                  !valid[31] ? 5'd31 : 5'h0; 

always @(posedge clk) begin
    if (reset) begin
        valid <= 8'b0;
    end
    else if (operate_en) begin
        if (add_entry) begin
            valid[add_entry_index]     <= 1'b1;
            pc[add_entry_index]        <= operate_pc[31:2];
            target[add_entry_index]    <= right_target[31:2];
            counter[add_entry_index]   <= 3'b100;
            jirl_flag[add_entry_index] <= pop_ras;
        end
        else if (delete_entry) begin
            valid[operate_index]       <= 1'b0;
            jirl_flag[add_entry_index] <= 1'b0;
        end
        else if (target_error && !pop_ras) begin
            target[operate_index]      <= right_target[31:2];
            counter[operate_index]     <= 3'b100;
            jirl_flag[add_entry_index] <= pop_ras;
        end
        else if (pre_error || pre_right) begin
            if (right_orien) begin
                if (counter[operate_index] != 3'b111) begin
                    counter[operate_index] <= counter[operate_index] + 3'b1;
                end
            end
            else begin
                if (counter[operate_index] != 3'b000) begin
                    counter[operate_index] <= counter[operate_index] - 3'b1;
                end
            end
        end
    end
    
end

genvar i;
generate 
    for (i = 0; i < BTBNUM; i = i + 1)
        begin: match
        always @(posedge clk) begin
            if (reset) begin
                match_rd[i] <= 1'b0;
            end
            else if (fetch_en) begin
                match_rd[i] <= (fetch_pc[31:2] == pc[i]) && valid[i] && !(jirl_flag[i] && ras_empty);
            end
        end
        end
endgenerate

always @(posedge clk) begin
    if (fetch_en) begin
        ras_buffer <= ras[ras_ptr - 3'b1]; //ras modify may before inst fetch
    end
end

assign {match_target, match_counter, match_index, match_jirl_flag} = {39{match_rd[0 ]}} & {target[0 ], counter[0 ], 5'd0 , jirl_flag[0 ]} |
                                                                     {39{match_rd[1 ]}} & {target[1 ], counter[1 ], 5'd1 , jirl_flag[1 ]} |
                                                                     {39{match_rd[2 ]}} & {target[2 ], counter[2 ], 5'd2 , jirl_flag[2 ]} |
                                                                     {39{match_rd[3 ]}} & {target[3 ], counter[3 ], 5'd3 , jirl_flag[3 ]} |
                                                                     {39{match_rd[4 ]}} & {target[4 ], counter[4 ], 5'd4 , jirl_flag[4 ]} |
                                                                     {39{match_rd[5 ]}} & {target[5 ], counter[5 ], 5'd5 , jirl_flag[5 ]} |
                                                                     {39{match_rd[6 ]}} & {target[6 ], counter[6 ], 5'd6 , jirl_flag[6 ]} |
                                                                     {39{match_rd[7 ]}} & {target[7 ], counter[7 ], 5'd7 , jirl_flag[7 ]} |
                                                                     {39{match_rd[8 ]}} & {target[8 ], counter[8 ], 5'd8 , jirl_flag[8 ]} |
                                                                     {39{match_rd[9 ]}} & {target[9 ], counter[9 ], 5'd9 , jirl_flag[9 ]} |
                                                                     {39{match_rd[10]}} & {target[10], counter[10], 5'd10, jirl_flag[10]} |
                                                                     {39{match_rd[11]}} & {target[11], counter[11], 5'd11, jirl_flag[11]} |
                                                                     {39{match_rd[12]}} & {target[12], counter[12], 5'd12, jirl_flag[12]} |
                                                                     {39{match_rd[13]}} & {target[13], counter[13], 5'd13, jirl_flag[13]} |
                                                                     {39{match_rd[14]}} & {target[14], counter[14], 5'd14, jirl_flag[14]} |
                                                                     {39{match_rd[15]}} & {target[15], counter[15], 5'd15, jirl_flag[15]} |
                                                                     {39{match_rd[16]}} & {target[16], counter[16], 5'd16, jirl_flag[16]} |
                                                                     {39{match_rd[17]}} & {target[17], counter[17], 5'd17, jirl_flag[17]} |
                                                                     {39{match_rd[18]}} & {target[18], counter[18], 5'd18, jirl_flag[18]} |
                                                                     {39{match_rd[19]}} & {target[19], counter[19], 5'd19, jirl_flag[19]} |
                                                                     {39{match_rd[20]}} & {target[20], counter[20], 5'd20, jirl_flag[20]} |
                                                                     {39{match_rd[21]}} & {target[21], counter[21], 5'd21, jirl_flag[21]} |
                                                                     {39{match_rd[22]}} & {target[22], counter[22], 5'd22, jirl_flag[22]} |
                                                                     {39{match_rd[23]}} & {target[23], counter[23], 5'd23, jirl_flag[23]} |
                                                                     {39{match_rd[24]}} & {target[24], counter[24], 5'd24, jirl_flag[24]} |
                                                                     {39{match_rd[25]}} & {target[25], counter[25], 5'd25, jirl_flag[25]} |
                                                                     {39{match_rd[26]}} & {target[26], counter[26], 5'd26, jirl_flag[26]} |
                                                                     {39{match_rd[27]}} & {target[27], counter[27], 5'd27, jirl_flag[27]} |
                                                                     {39{match_rd[28]}} & {target[28], counter[28], 5'd28, jirl_flag[28]} |
                                                                     {39{match_rd[29]}} & {target[29], counter[29], 5'd29, jirl_flag[29]} |
                                                                     {39{match_rd[30]}} & {target[30], counter[30], 5'd30, jirl_flag[30]} |
                                                                     {39{match_rd[31]}} & {target[31], counter[31], 5'd31, jirl_flag[31]};

assign ret_pc = match_jirl_flag ? {ras_buffer, 2'b0} : {match_target, 2'b0};
assign ret_en = |match_rd;
assign taken  = match_counter[2];
assign ret_index = match_index;

assign ras_full  = (ras_ptr == 3'd7);
assign ras_empty = (ras_ptr == 3'd0);

always @(posedge clk) begin
    if (reset) begin
        ras_ptr <= 3'b0;
    end
    else if (operate_en) begin
        if (push_ras && !ras_full) begin
            ras[ras_ptr] <= operate_pc[31:2] + 30'b1;
            ras_ptr <= ras_ptr + 3'b1;
        end
        else if (pop_ras && !ras_empty) begin
            ras_ptr <= ras_ptr - 3'b1;
        end
    end
end

reg [5:0] fcsr;

always @(posedge clk) begin
    if (reset) begin
        fcsr <= 6'b100010;
    end
    else begin
        fcsr[0] <= fcsr[5];
        fcsr[1] <= fcsr[0];
        fcsr[2] <= fcsr[1];
        fcsr[3] <= fcsr[2] ^ fcsr[5];
        fcsr[4] <= fcsr[3] ^ fcsr[5];
        fcsr[5] <= fcsr[4];
    end
end

endmodule

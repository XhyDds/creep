module pred_replace#(//PLRU
    parameter   addr_width=16,
                way=4
)
(
    input       clk,
    input       [way-1:0]use1,
    input       [way-1:0]valid,

    input       [addr_width-1:0]addr,
    output      [1:0]way_sel_i
    );
reg [3:0]record[(1<<addr_width)-1:0];
reg [1:0]i;
assign way_sel_i = i;
//i_sel
always @(posedge clk) begin
    if(!valid[0])i <= 2'd0;
    else if(!valid[1])i <= 2'd1;
    else if(!valid[2])i <= 2'd2;
    else if(!valid[3])i <= 2'd3;
    else begin
        if(!record[addr][0])begin
            if(!record[addr][1])i <= 2'd0;
            else i <= 2'd1;
        end
        else begin
            if(!record[addr][2])i <= 2'd2;
            else i <= 2'd3;
        end
    end
end
//Write
always @(posedge clk) begin
    if(use1[0])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b1;
    end
    else if(use1[1])begin
        record[addr][0] <= 1'b1;
        record[addr][1] <= 1'b0;
    end
    else if(use1[2])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b1;
    end
    else if(use1[3])begin
        record[addr][0] <= 1'b0;
        record[addr][2] <= 1'b0;
    end
end
endmodule

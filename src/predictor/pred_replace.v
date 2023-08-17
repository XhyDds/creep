module pred_replace#(//PLRU
    parameter   addr_width=8,
                way=4
)
(
    input       clk,
    input       [way-1:0]use1,
    input       update_en,

    input       [addr_width-1:0]addr,
    output reg  [1:0]way_sel
    );
reg [2:0]record[(1<<addr_width)-1:0];
//i_sel
always @(posedge clk) begin
    begin
    if(!record[addr][0])begin
        if(!record[addr][1])way_sel <= 2'd0;
        else way_sel <= 2'd1;
    end
    else begin
        if(!record[addr][2])way_sel <= 2'd2;
        else way_sel <= 2'd3;
    end
    end
end
//Write
always @(posedge clk) begin
    if(~update_en) ;
    else if(use1[0])begin
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

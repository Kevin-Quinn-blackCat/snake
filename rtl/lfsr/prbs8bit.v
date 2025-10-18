module prbs8bit
(
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    input  wire [7:0] seed,
    input  wire       seed_en,
    input  wire       shift_en,

    output wire [7:0] prbs_out_8bit
);

/*===内部变量===*/
reg     [7:0]  lfsr_reg;
wire            feedback;

/*===抽取与线性叠加===*/
assign feedback = lfsr_reg[4] ^ lfsr_reg[3] ^ lfsr_reg[2] ^ lfsr_reg[0];

/*===移位与补空===*/
always @(posedge sys_clk) begin
    if (!sys_rst_n) begin
        lfsr_reg <= seed;
    end
    else if(seed_en) begin
        lfsr_reg <= seed;
    end
    else if(shift_en) begin
        lfsr_reg <= {lfsr_reg[6:0],feedback};
    end
    else
        lfsr_reg <= lfsr_reg;
end

assign prbs_out_8bit = lfsr_reg;

endmodule

/*==================================================================================*/
// Author        : Kevin_Quinn
// Create Date   : 2025/10/10
// Module Name   : prbs32_to_4
// Project Name  : prbs32_to_4
// Target Devices: Altera EP4CE10F17C8N
// Tool Versions : Quartus 13.0
// Description   : 8位二进制伪随机生成器(循环周期2^32-1)
//
// Revision      : V1.0
// Additional Comments:
// 种子：       非零32位二进制数，且建议输入高熵值种子，否则热机时首32个值会有大段规律数
// 算法：       线性反馈移位寄存器
// 本源多项式：  x^32 + x^22 + x^2 + x + 1
/*==================================================================================*/

module prbs32_to_8 
#(
    parameter SEED = 32'hbada55e5
)
(
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    
    output wire [7:0] prbs_out_8bit
);

/*===内部变量===*/
reg     [31:0]  lfsr_reg;
wire            feedback;

/*===抽取与线性叠加===*/
assign feedback = lfsr_reg[22] ^ lfsr_reg[2] ^ lfsr_reg[1] ^ lfsr_reg[0];

/*===移位与补空===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        lfsr_reg <= SEED;
    end
    else
        lfsr_reg <= {lfsr_reg[30:0],feedback};
end

/*===选取8位输出===*/
assign prbs_out_8bit = {
        lfsr_reg[23], 
        lfsr_reg[5], 
        lfsr_reg[17], 
        lfsr_reg[9],
        lfsr_reg[30],
        lfsr_reg[1],
        lfsr_reg[14],
        lfsr_reg[26]
    };


endmodule

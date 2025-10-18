module direct_sig_ctrl (
    input  wire         sys_clk,
    input  wire         sys_rst_n,
    input  wire [19:0]  inf_data,
    input  wire         game_tick,

    output reg  [3:0]   direct
);

/*===internal_sig===*/
reg     [3:0]   direct_reg;
reg     [3:0]   direct_tick;

/*===loca_param===*/
localparam UP    = 4'b0001;
localparam DOWN  = 4'b0010;
localparam LEFT  = 4'b0100;
localparam RIGHT = 4'b1000;

/*===识别并寄存此时红外信号的合法方向===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        direct_reg <= RIGHT;
    end
    else    case (inf_data)
        20'd2:  direct_reg <=  UP;
        20'd8:  direct_reg <=  DOWN;
        20'd4:  direct_reg <=  LEFT;
        20'd6:  direct_reg <=  RIGHT;
        default: direct_reg <= RIGHT;
    endcase
end

/*===如果和上一tick的信号相反则输出不变===*/
// 没有和上tick一样
// 不是非法值
// 才能传出
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        direct <= RIGHT;
    end
    else if((direct_reg == UP) && (direct_tick == DOWN)) begin
        direct <= direct;
    end
    else if((direct_reg == DOWN) && (direct_tick == UP)) begin
        direct <= direct;
    end
    else if((direct_reg == RIGHT) && (direct_tick == LEFT)) begin
        direct <= direct;
    end
    else if((direct_reg == LEFT) && (direct_tick == RIGHT)) begin
        direct <= direct;
    end
    else
        direct <= direct_reg;
end

/*===游戏刻拉高时预示着此时的direct被取走一次,此时需要同时保存===*/
// 保存上一tick的移动方向
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        direct_tick <= RIGHT;
    end
    else if(game_tick) begin
        direct_tick <= direct;
    end
    else
        direct_tick <= direct_tick;
end

endmodule //direct_sig_ctrl

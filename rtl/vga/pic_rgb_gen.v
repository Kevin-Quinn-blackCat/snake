module pic_rgb_gen 
#(
    parameter CNT_25MHZ_0_25S = 23'd6_250_000
)
(
    input  wire sys_clk,
    input  wire sys_rst_n,
    input  wire [9:0]   pix_x,
    input  wire [9:0]   pix_y,
    input  wire [19:0]  data,

    output reg  [15:0]  pix_rgb_data
);


/*======================================*/
/*===loca_param===*/
/*======================================*/
localparam  H_VALID  = 10'd640,
            V_VALID  = 10'd480;
localparam  H_BOX    = 'd40,
            V_BOX    = 'd30;
localparam  RED      = 16'hf800,
            GREEN    = 16'h07e0,
            BLUE     = 16'h001f,
            BLACK    = 16'h0000,
            WHITE    = 16'hffff;
localparam  IDLE     = 5'b00_001,
            TICK     = 5'b00_010,
            LFSR     = 5'b00_100,
            ARBIT    = 5'b01_000,
            GENF     = 5'b10_000;
localparam  UP       = 4'b0001;
localparam  DOWN     = 4'b0010;
localparam  LEFT     = 4'b0100;
localparam  RIGHT    = 4'b1000;
/*===-------------------------------===*/


/*======================================*/
/*===internal_sig===*/
/*======================================*/
// 控制方向
wire    [3:0]   direct;
// ram
reg     [7:0]   address_a;
reg     [7:0]   address_b;
reg     [1:0]   wr_data_a;
reg             wr_en_a;
wire    [1:0]   rd_data_a;
wire    [1:0]   rd_data_b;
// fifo
reg     [7:0]   pi_data;
reg             pi_en;
wire    [7:0]   po_data;
reg             po_en;
wire            fifo_full;
// 状态机状态
reg     [5:0]   state;
// 初始化
reg             pre_game;
reg             pre_game_dly;
wire            pre_game_p;
reg     [7:0]   cnt_pre_addr;
// 游戏进行中
reg     [22:0]  cnt_tick;
reg             game_tick;
reg             game_tick_dly1;
reg     [3:0]   new_head_x;
reg     [3:0]   new_head_y;
wire    [7:0]   new_head_addr;
reg             game_tick_dly2;
reg             game_tick_dly4;
reg             death;
reg             fruit;
reg             game_tick_dly5;
reg             game_tick_dly7;
// 生成果子
reg             fruit_req;
reg     [7:0]   seed;
reg             fruit_req_dly1;
reg             fruit_req_dly2;
reg             lfsr_shift;
wire    [7:0]   lfsr_addr;
reg             lfsr_shift_dly1;
reg             lfsr_shift_dly2;
reg             lfsr_shift_dly3;
reg             gen_en;
wire    [7:0]   prbs_out_8bit;
reg             seed_en;
// rgb565信号
wire    [7:0]   rgb_addr;
wire    [3:0]   box_x;
wire    [3:0]   box_y;
/*===-------------------------------===*/


/*======================================*/
/*===mem_moduel===*/
/*======================================*/
/*===ram===*/
ram_256x2	ram_256x2_inst (
	.address_a ( address_a ),
	.address_b ( address_b ),
	.clock ( sys_clk ),
	.data_a ( wr_data_a ),
	.data_b ( 2'b10 ),
	.wren_a ( wr_en_a ),
	.wren_b ( 1'b0 ),
	.q_a ( rd_data_a ),
	.q_b ( rd_data_b )
	);

/*===fifo===*/
fifo_256x8	fifo_256x8_inst (
	.aclr ( ~sys_rst_n ),
	.clock ( sys_clk ),
	.data ( pi_data ),
	.rdreq ( po_en ),
	.wrreq ( pi_en ),
	.full ( fifo_full ),
	.q ( po_data )
	);
/*===-------------------------------===*/


/*=============================================================*/
/*===游戏进行状态机===*/
/*=============================================================*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        state <= IDLE;
    end
    else
        case (state)
            IDLE:   if (pre_game_p) begin
                        state <= TICK;
                    end
                    else
                        state <= IDLE;
            TICK:   if (fruit_req_dly2) begin
                        state <= LFSR;
                    end
                    else
                        state <= TICK;
            ARBIT:  if (lfsr_shift_dly3 && (rd_data_a == 2'b01)) begin
                        state <= LFSR;
                    end
                    else if(lfsr_shift_dly3 && (rd_data_a == 2'b10)) begin
                        state <= GENF;
                    end
                    else if(lfsr_shift_dly3 && (rd_data_a == 2'b11)) begin
                        state <= LFSR;
                    end
                    else
                        state <= ARBIT;
            LFSR:   if (lfsr_shift) begin
                        state <= ARBIT;
                    end
                    else
                        state <= LFSR;
            GENF:   if (wr_en_a) begin
                        state <= TICK;
                    end
                    else
                        state <= GENF;
            default:    state <= IDLE;
        endcase
end
/*===-------------------------------===*/


/*=============================================================*/
/*===游戏初始化===*/
/*=============================================================*/
/*===初始化完成信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pre_game <= 1'b0;
    end
    else if(cnt_pre_addr == 8'd255) begin
        pre_game <= 1'b1;
    end
    else
        pre_game <= pre_game;
end

/*===初始化完成信号上升沿===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pre_game_dly <= 1'b0;
    end
    else
        pre_game_dly <= pre_game;
end

assign pre_game_p = (!pre_game_dly) & pre_game;

/*===初始化地址生成器===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt_pre_addr <= 8'd0;
    end
    else if(cnt_pre_addr == 8'd255) begin
        cnt_pre_addr <= cnt_pre_addr;
    end
    else
        cnt_pre_addr <= cnt_pre_addr + 8'd1;
end
/*===-------------------------------===*/

/*=============================================================*/
/*===ram端口a===*/
/*=============================================================*/
/*===地址a控制器===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        address_a <= 8'd0;
    end
    else if(state == IDLE) begin
        address_a <= cnt_pre_addr;
    end
    else if((state == TICK) && game_tick_dly2) begin
        address_a <= new_head_addr;
    end
    else if((state == TICK) && game_tick_dly7) begin
        address_a <= po_data;
    end
    else if((state == ARBIT) && lfsr_shift_dly1) begin
        address_a <= lfsr_addr;
    end
    else
        address_a <= address_a;
end

/*===写入信息a控制器===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        wr_data_a <= 2'b10;
    end
    else if((state == IDLE) && (cnt_pre_addr == 8'd0)) begin
        wr_data_a <= 2'b01;
    end
    else if((state == IDLE) && (cnt_pre_addr == 8'd136)) begin
        wr_data_a <= 2'b11;
    end
    else if(state == IDLE) begin
        wr_data_a <= 2'b10;
    end
    else if((state == TICK) && game_tick_dly4) begin
        wr_data_a <= 2'b01;
    end
    else if((state == TICK) && game_tick_dly7) begin
        wr_data_a <= 2'b10;
    end
    else if((state == GENF) && gen_en) begin
        wr_data_a <= 2'b11;
    end
    else
        wr_data_a <= wr_data_a;
end

/*===写入a使能信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        wr_en_a <= 1'b0;
    end
    else if(state == IDLE) begin
        wr_en_a <= 1'b1;
    end
    else if((state == TICK) && game_tick_dly5) begin
        wr_en_a <= 1'b1;
    end
    else if((state == TICK) && game_tick_dly7) begin
        wr_en_a <= 1'b1;
    end
    else if((state == GENF) && gen_en) begin
        wr_en_a <= 1'b1;
    end
    else
        wr_en_a <= 1'b0;
end
/*===-------------------------------===*/


/*=============================================================*/
/*===fifo===*/
/*=============================================================*/
/*===弹入信息===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pi_data <= 8'd0;
    end
    else if((state == IDLE) && (cnt_pre_addr == 8'd0)) begin
        pi_data <= 8'd0;
    end
    else if((state == TICK) && game_tick_dly2) begin
        pi_data <= new_head_addr;
    end
    else
        pi_data <= pi_data;
end

/*===弹入使能信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pi_en <= 1'b0;
    end
    else if((state == IDLE) && (cnt_pre_addr == 8'd0)) begin
        pi_en <= 1'b1;
    end
    else if((state == TICK) && game_tick_dly2) begin
        pi_en <= 1'b1;
    end
    else
        pi_en <= 1'b0;
end

/*===弹出使能信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        po_en <= 1'b0;
    end
    else if((state == TICK) && game_tick_dly5 && (!fruit)) begin
        po_en <= 1'b1;
    end
    else
        po_en <= 1'b0;
end
/*===-------------------------------===*/


/*=============================================================*/
/*===游戏进行信号===*/
/*=============================================================*/
/*===游戏刻时钟===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt_tick <= 23'd0;
    end
    else if(!pre_game) begin
        cnt_tick <= 23'd0;
    end
    else if(death) begin
        cnt_tick <= 23'd0;
    end
    else if(cnt_tick == CNT_25MHZ_0_25S) begin
        cnt_tick <= 23'd0;
    end
    else
        cnt_tick <= cnt_tick + 23'd1;
end

/*===游戏刻===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        game_tick <= 1'b0;
    end
    else if(cnt_tick == CNT_25MHZ_0_25S) begin
        game_tick <= 1'b1;
    end
    else
        game_tick <= 1'b0;
end

/*===game_tick_dly1===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        game_tick_dly1 <= 1'b0;
    end
    else
        game_tick_dly1 <= game_tick;
end

/*===新头的指针===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        new_head_x <= 4'd0;
    end
    else if(game_tick_dly1 && (direct == RIGHT)) begin
        new_head_x <= new_head_x + 4'd1;
    end
    else if(game_tick_dly1 && (direct == LEFT)) begin
        new_head_x <= new_head_x - 4'd1;
    end
    else
        new_head_x <= new_head_x;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        new_head_y <= 4'd0;
    end
    else if(game_tick_dly1 && (direct == DOWN)) begin
        new_head_y <= new_head_y + 4'd1;
    end
    else if(game_tick_dly1 && (direct == UP)) begin
        new_head_y <= new_head_y - 4'd1;
    end
    else
        new_head_y <= new_head_y;
end

/*===新头地址信号===*/
assign new_head_addr = (new_head_y << 4) + new_head_x;

/*===game_tick_dly2===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        game_tick_dly2 <= 1'b0;
    end
    else
        game_tick_dly2 <= game_tick_dly1;
end

/*===game_tick_dly4===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        game_tick_dly4 <= 1'b0;
    end
    else if(state == TICK) begin
        game_tick_dly4 <= pi_en;
    end
    else
        game_tick_dly4 <= 1'b0;
end

/*===game_tick_dly5===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        game_tick_dly5 <= 1'b0;
    end
    else
        game_tick_dly5 <= game_tick_dly4;
end

/*===死亡信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        death <= 1'b0;
    end
    else if(game_tick_dly4 && (rd_data_a == 2'd01)) begin
        death <= 1'b1;
    end
    else
        death <= death;
end

/*===吃果子信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        fruit <= 1'b0;
    end
    else if(game_tick_dly4 && (rd_data_a == 2'b11)) begin
        fruit <= 1'b1;
    end
    else
        fruit <= 1'b0;
end

/*===game_tick_dly7===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        game_tick_dly7 <= 1'b0;
    end
    else if(state == TICK) begin
        game_tick_dly7 <= po_en;
    end
    else
        game_tick_dly7 <= 1'b0;
end

/*===新果子请求信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        fruit_req <= 1'b0;
    end
    else if(fruit && game_tick_dly5) begin
        fruit_req <= 1'b1;
    end
    else
        fruit_req <= 1'b0;
end

/*===fruit_req_dly1===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        fruit_req_dly1 <= 1'b0;
    end
    else
        fruit_req_dly1 <= fruit_req;
end

/*===fruit_req_dly2===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        fruit_req_dly2 <= 1'b0;
    end
    else
        fruit_req_dly2 <= fruit_req_dly1;
end

/*===随机数种子生成===*/
prbs32_to_8 # (
    .SEED()
)
prbs32_to_8_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .prbs_out_8bit(prbs_out_8bit)
);

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        seed <= 8'b1010_1010;
    end
    else if(fruit_req) begin
        seed <= prbs_out_8bit;
    end
    else
        seed <= seed;
end

/*===新种子应用信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        seed_en <= 1'b0;
    end
    else if(fruit_req_dly1) begin
        seed_en <= 1'b1;
    end
    else
        seed_en <= 1'b0;
end

/*===伪随机数生成器移位信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        lfsr_shift <= 1'b0;
    end
    else if((state == LFSR) && (!lfsr_shift)) begin
        lfsr_shift <= 1'b1;
    end
    else
        lfsr_shift <= 1'b0;
end

/*===lfsr_shift_dly1===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        lfsr_shift_dly1 <= 1'b0;
    end
    else
        lfsr_shift_dly1 <= lfsr_shift;
end

/*===lfsr_shift_dly2===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        lfsr_shift_dly2 <= 1'b0;
    end
    else
        lfsr_shift_dly2 <= lfsr_shift_dly1;
end

/*===lfsr_shift_dly1===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        lfsr_shift_dly3 <= 1'b0;
    end
    else
        lfsr_shift_dly3 <= lfsr_shift_dly2;
end

/*===写入果子信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        gen_en <= 1'b0;
    end
    else
        gen_en <= lfsr_shift_dly3;
end

/*===伪随机地址生成器===*/
prbs8bit  prbs8bit_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .seed(seed),
    .seed_en(seed_en),
    .shift_en(lfsr_shift),
    .prbs_out_8bit(lfsr_addr)
);

/*===控制方向信号===*/
direct_sig_ctrl  direct_sig_ctrl_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .inf_data(data),
    .game_tick(game_tick),
    .direct(direct)
);
/*===-------------------------------===*/


/*=============================================================*/
/*===rgb565输出信号===*/
/*=============================================================*/
/*===像素坐标转方格坐标===*/
assign box_x = (pix_x/6'd40);
assign box_y = (pix_y/5'd30);

/*===坐标转地址===*/
assign rgb_addr = (box_y << 3'd4) + box_x;

/*===读取方格信息===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        address_b <= 8'd0;
    end
    else
        address_b <= rgb_addr;
end

/*===颜色输出===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pix_rgb_data <= WHITE;
    end
    else if(rd_data_b == 2'b01) begin
        pix_rgb_data <= BLACK;
    end
    else if(rd_data_b == 2'b10) begin
        pix_rgb_data <= WHITE;
    end
    else if(rd_data_b == 2'b11) begin
        pix_rgb_data <= RED;
    end
    else
        pix_rgb_data <= WHITE;
end

endmodule //pic_rgb_gen

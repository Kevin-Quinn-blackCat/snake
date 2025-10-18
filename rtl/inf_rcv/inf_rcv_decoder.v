module inf_rcv_decoder (
    input  wire         sys_clk,
    input  wire         sys_rst_n,
    input  wire         inf_in,

    output reg  [19:0]  data,
    output reg          repeat_en
);

/*===internal_port===*/
reg [4:0]   state;
reg         inf_in_dly1;
reg         inf_in_dly2;
reg         inf_in_dly3;
wire        inf_in_n;
wire        inf_in_p;
reg [18:0]  cnt;
reg         flag_9ms;
reg         flag_4_5ms;
reg         flag_560us;
reg         flag_1_69ms;
reg         flag_2_25ms;
reg [5:0]   cnt_data_bit;
reg [31:0]  data_reg;
/*===================*/

/*===============================================local_parameter=====================================================*/
localparam  CNT_560US_MIN = 19'd20_000,     //
            CNT_560US_MAX = 19'd35_000;     // 560_000ns需27999个周期，提供15_000个周期的裕量
localparam  CNT_1_69MS_MIN = 19'd80_000,    //
            CNT_1_69MS_MAX = 19'd90_000;    // 1_690_000ns需84_500个周期，提供10_000个周期的裕量
localparam  CNT_2_25MS_MIN = 19'd100_000,   //
            CNT_2_25MS_MAX = 19'd125_000;   // 2_250_000ns需112_500个周期，提供25_000个周期的裕量
localparam  CNT_4_5MS_MIN = 19'd175_000,    //
            CNT_4_5MS_MAX = 19'd275_000;    // 4_500_000ns需225_000个周期，提供100_000个周期的裕量
localparam  CNT_9MS_MIN = 19'd400_000,      //
            CNT_9MS_MAX = 19'd490_000;      // 9_000_000ns需450_000个周期，提供90_000个周期的裕量
/*===================================================================================================================*/


/*===================================================================================================================*/
/*=====================================================状态机========================================================*/
/*===================================================================================================================*/

/*==========状态编码===========*/
localparam IDLE     = 5'b0_0001;
localparam N_9MS    = 5'b0_0010;
localparam ARBIT    = 5'b0_0100;
localparam DATA     = 5'b0_1000;
localparam REPEAT   = 5'b1_0000;
/*============================*/


/*================================================状态变化======================================================*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        state <= IDLE;
    end
    else
        case (state)
            IDLE:   if(inf_in_n)                                    // |下降沿到来================================
                        state <= N_9MS;                             // -跳转到9ms计时状态
                    else                                            // |没有下降沿到来
                        state <= IDLE;                              // -保持初始状态==============================
            N_9MS:  if(inf_in_p && flag_9ms)                        // |上升沿到来，且低电平保持9ms
                        state <= ARBIT;                             // -跳转到断言状态
                    else    if(inf_in_p && (!flag_9ms))             // |上升沿到来，但低电平并无保持9ms
                        state <= IDLE;                              // -跳转到初始状态
                    else                                            // |上升沿没有到来
                        state <= N_9MS;                             // -保持9ms计时状态
            ARBIT:  if(inf_in_n && flag_2_25ms)                     // |下降沿到来且高电平保持2.25ms===============
                        state <= REPEAT;                            // -跳转到重复状态
                    else    if(inf_in_n && flag_4_5ms)              // |下降沿到来且高电平保持4.5ms
                        state <= DATA;                              // -跳转到数据状态
                    else    if(inf_in_n)                            // |下降沿来到，但以上两个条件都不满足
                        state <= IDLE;                              // -跳转到初始状态
                    else                                            // |没有下降沿到来
                        state <= ARBIT;                             // -保持断言状态
            DATA:   if(inf_in_p && (!flag_560us))                   // |上升沿到来，但低电平不是560us===============
                        state <= IDLE;                              // -跳转到初始状态
                    else    if(inf_in_n && (!flag_560us)            // |下降沿到来，但高电平不是560us(非0)
                                        && (!flag_1_69ms))          // |也不是1.69ms(非1)
                        state <= IDLE;                              // -跳转到初始状态
                    else    if(inf_in_p && (cnt_data_bit == 6'd32)) // |上升沿到来，且已经记录32bit
                        state <= IDLE;                              // -跳转到初始状态
                    else                                            // |数据读取，繁忙状态
                        state <= DATA;                              // -保持数据状态
            REPEAT: if(inf_in_p)                                    // |上升沿到来(结束位结束)=====================
                        state <= IDLE;                              // -回到初始状态
                    else                                            // |未退出重复状态
                        state <= REPEAT;                            // -保持重复状态
            default: state <= IDLE;                                 // |==========================================
        endcase
end
/*===================================================================================================================*/

/*===-------------------------------------------------------------------------------------------------------------===*/
/*===================================================================================================================*/

/*===输入信号同步===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        inf_in_dly1 <= 1'b0;
        inf_in_dly2 <= 1'b0;
        inf_in_dly3 <= 1'b0;
    end
    else begin
        inf_in_dly1 <= inf_in;
        inf_in_dly2 <= inf_in_dly1;
        inf_in_dly3 <= inf_in_dly2;
    end
end

/*===输入信号边沿检测===*/
assign inf_in_n = (!inf_in_dly2) & (inf_in_dly3);
assign inf_in_p = (inf_in_dly2) & (!inf_in_dly3);

/*===全局通用计时器===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt <= 19'd0;
    end
    else
        case (state)
            IDLE:   cnt <= 19'd0;                       // 初始状态时钟不工作，清零
            N_9MS:  if(inf_in_p && flag_9ms)            // 跳转到断言状态时需要清零
                        cnt <= 19'd0;                   // 由状态机可知，除此之外不是保持就是跳转到IDLE
                    else                                // 跳转IDLE不需要清零(自动清零)，以下同理
                        cnt <= cnt + 19'd1;             // 保持N_9MS时持续自增
            ARBIT:  if(inf_in_n && flag_2_25ms)         // 跳转REPEAT时清零
                        cnt <= 19'd0;
                    else    if(inf_in_n && flag_4_5ms)  // 跳转DATA时清零
                        cnt <= 19'd0;
                    else
                        cnt <= cnt + 19'd1;             // 保持时自增
            DATA:   if(inf_in_p && flag_560us)          // 成功读取到标志位时清零
                        cnt <= 19'd0;
                    else    if(inf_in_n && flag_560us)  // 成功读取到0时清零
                        cnt <= 19'd0;
                    else    if(inf_in_n && flag_1_69ms)
                        cnt <= 19'd0;
                    else
                        cnt <= cnt + 19'd1;             // 保持时自增
            default: cnt <= 19'd0;                      // 其他情况无需计数
        endcase
end

/*===================================时间标志信号===========================================*/
// 9ms
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        flag_9ms <= 1'b0;
    end
    else if((state == N_9MS) && (cnt >= CNT_9MS_MIN) && (cnt <= CNT_9MS_MAX)) begin
        flag_9ms <= 1'b1;
    end
    else
        flag_9ms <= 1'b0;
end

// 4.5ms
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        flag_4_5ms <= 1'b0;
    end
    else if((state == ARBIT) && (cnt >= CNT_4_5MS_MIN) && (cnt <= CNT_4_5MS_MAX)) begin
        flag_4_5ms <= 1'b1;
    end
    else
        flag_4_5ms <= 1'b0;
end

// 560us
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        flag_560us <= 1'b0;
    end
    else if((state == DATA) && (cnt >= CNT_560US_MIN) && (cnt <= CNT_560US_MAX)) begin
        flag_560us <= 1'b1;
    end
    else
        flag_560us <= 1'b0;
end

// 1.69ms
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        flag_1_69ms <= 1'b0;
    end
    else if((state == DATA) && (cnt >= CNT_1_69MS_MIN) && (cnt <= CNT_1_69MS_MAX)) begin
        flag_1_69ms <= 1'b1;
    end
    else
        flag_1_69ms <= 1'b0;
end

// 2.25ms
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        flag_2_25ms <= 1'b0;
    end
    else if((state == ARBIT) && (cnt >= CNT_2_25MS_MIN) && (cnt <= CNT_2_25MS_MAX)) begin
        flag_2_25ms <= 1'b1;
    end
    else
        flag_2_25ms <= 1'b0;
end

/*=========================================================================================*/

/*===比特位计数器===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt_data_bit <= 6'd0;
    end
    else if(inf_in_p && (cnt_data_bit == 6'd32)) begin
        cnt_data_bit <= 6'd0;
    end
    else if(inf_in_n && (state == DATA)) begin
        cnt_data_bit <= cnt_data_bit + 6'd1;
    end
    else
        cnt_data_bit <= cnt_data_bit;
end

/*===数据寄存===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        data_reg <= 32'b0;
    end
    else if(inf_in_n && flag_560us && (state == DATA)) begin
        data_reg[cnt_data_bit] <= 1'b0;
    end
    else if(inf_in_n && flag_1_69ms && (state == DATA)) begin
        data_reg[cnt_data_bit] <= 1'b1;
    end
    else
        data_reg <= data_reg;
end

/*===数据输出===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        data <= 20'b0;
    end
    else if((cnt_data_bit == 6'd32)                         // 结束标记
            && (~data_reg[23:16] == data_reg[31:24])        // 数据码验证
            && (~data_reg[15:8] == data_reg[7:0])) begin    // 地址码验证
        data <= {12'b0,data_reg[23:16]};
    end
    else
        data <= data;
end

/*===重复使能信号===*/
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        repeat_en <= 1'b0;
    end
    else if((state == REPEAT) && (~data_reg[23:16] == data_reg[31:24])) begin
        repeat_en <= 1'b1;
    end
    else
        repeat_en <= 1'b0;
end
endmodule //inf_rcv_decoder

/////////////////////////////////////////////////////////////////////
// 设计单元：fir
// 文件名：fir.sv
//
// 16 抽头、16 位 FIR 低通滤波器（使用给定系数）
// 顺序乘加结构：复用 1 个乘法器和 1 个加法器完成 16 次 MAC 运算
//
// 模块接口需与原设计规范保持一致
/////////////////////////////////////////////////////////////////////

module fir (
    input  logic signed [15:0] in,
    input  logic        input_ready,
    input  logic        ck,
    input  logic        rst,
    output logic signed [15:0] out,
    output logic        output_ready
);

  // 统一定义 16 位有符号采样数据类型
  typedef logic signed [15:0] sample_t;

  // 16 级采样延迟线，保存当前及前 15 个输入采样
  sample_t samples [0:15];

  // FIR 系数，采用 Q0.15 定点格式，共 16 个抽头
  const sample_t coefficients [0:15] =
      '{16'sd30,  16'sd136, 16'sd457, 16'sd1119,
        16'sd2116,16'sd3278,16'sd4317,16'sd4932,
        16'sd4932,16'sd4317,16'sd3278,16'sd2116,
        16'sd1119,16'sd457, 16'sd136, 16'sd30};

  // 四状态有限状态机：等待、装载、处理、保存
  typedef enum logic [1:0] {waiting, loading, processing, saving} state_t;
  state_t state, next_state;

  // 数据装载、抽头计数和累加器复位控制信号
  logic load, count, reset_accumulator;

  // 4 位抽头地址计数器，可覆盖 0～15 共 16 个抽头
  logic unsigned [3:0] address;

  // 32 位有符号累加器，用于保存乘加结果
  logic signed [31:0] sum;

  // 状态寄存器：异步高电平复位，复位后进入 waiting 状态
  always_ff @(posedge ck or posedge rst) begin
    if (rst)
      state <= waiting;
    else
      state <= next_state;
  end

  // 状态转移和控制信号组合逻辑
  always_comb begin
    // 默认保持当前状态，并关闭各控制信号，避免产生锁存器
    next_state        = state;
    load              = 1'b0;
    count             = 1'b0;
    reset_accumulator = 1'b0;
    output_ready      = 1'b0;

    case (state)

      // 等待状态：保持累加器和地址计数器清零，等待有效输入
      waiting: begin
        reset_accumulator = 1'b1;
        if (input_ready)
          next_state = loading;
      end

      // 装载状态：移入新的采样值，同时清零累加器和地址计数器
      loading: begin
        load              = 1'b1;
        reset_accumulator = 1'b1;
        next_state        = processing;
      end

      // 处理状态：address 从 0 计数到 15，每个周期完成一个抽头的乘加运算
      processing: begin
        count = 1'b1;
        if (address == 4'd15)
          next_state = saving;
        else
          next_state = processing;
      end

      // 保存状态：output_ready 拉高一个周期，通知上层输出数据有效
      saving: begin
        output_ready = 1'b1;
        next_state   = waiting;
      end

      // 异常状态返回 waiting
      default: begin
        next_state = waiting;
      end

    endcase
  end

  // 输入采样移位寄存器：新采样写入 samples[0]，历史采样依次后移
  integer i;
  always_ff @(posedge ck) begin
    if (load) begin
      for (i = 15; i > 0; i = i - 1)
        samples[i] <= samples[i-1];
      samples[0] <= in;
    end
  end

  // 抽头地址计数器：处理阶段依次访问 16 个采样和系数
  always_ff @(posedge ck or posedge rst) begin
    if (rst)
      address <= 4'd0;
    else if (reset_accumulator)
      address <= 4'd0;
    else if (count)
      address <= address + 4'd1;
  end

  // 顺序 MAC 累加器：每个时钟周期执行一次“采样 × 系数 + 累加”
  always_ff @(posedge ck or posedge rst) begin
    if (rst)
      sum <= 32'sd0;
    else if (reset_accumulator)
      sum <= 32'sd0;
    else
      sum <= sum + ($signed(samples[address]) * $signed(coefficients[address]));
  end

  // Q0.15 定点结果缩放：舍弃低 15 位小数部分，得到 16 位输出
  always_ff @(posedge ck) begin
    if (output_ready)
      out <= sum[30:15];
  end

endmodule

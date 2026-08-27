module D1 (
    input  logic        CLOCK_50,
    input  logic        CLOCK2_50,
    input  logic [0:0]  KEY,

    // I2C 音频/视频配置接口
    output logic        FPGA_I2C_SCLK,
    inout  wire         FPGA_I2C_SDAT,

    // 音频 CODEC 接口
    output logic        AUD_XCK,
    input  logic        AUD_DACLRCK,
    input  logic        AUD_ADCLRCK,
    input  logic        AUD_BCLK,
    input  logic        AUD_ADCDAT,
    output logic        AUD_DACDAT
);

    // KEY[0] 为低电平有效按键，取反后得到高电平有效复位信号
    wire reset = ~KEY[0];

    // 与音频 CODEC 之间的读写握手及左右声道数据
    wire        read_ready, write_ready;
    logic       read, write;
    wire [23:0] readdata_left, readdata_right;
    logic [23:0] writedata_left, writedata_right;

    // FIR 启动、输入、输出及完成信号
    logic                fir_start;
    logic signed [15:0]  fir_in_l, fir_in_r;
    logic signed [15:0]  fir_out_l, fir_out_r;
    logic                fir_ready_l, fir_ready_r;

    // 24 位音频数据转换为 16 位：截取高 16 位并按有符号数解释
    assign fir_in_l = $signed(readdata_left[23:8]);
    assign fir_in_r = $signed(readdata_right[23:8]);

    // 顶层控制状态标志
    logic processing;   // FIR 正在进行滤波运算
    logic capture;      // FIR 已完成，下一周期捕获更新后的输出
    logic pending;      // FIR 输出已缓存，等待写回音频 CODEC

    // 顶层数据流控制：读取音频、启动 FIR、捕获结果并写回 CODEC
    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            read            <= 1'b0;
            write           <= 1'b0;
            fir_start       <= 1'b0;
            processing      <= 1'b0;
            capture         <= 1'b0;
            pending         <= 1'b0;
            writedata_left  <= 24'd0;
            writedata_right <= 24'd0;
        end else begin
            // 默认拉低握手信号，使 read、write 和 fir_start 形成单周期脉冲
            read      <= 1'b0;
            write     <= 1'b0;
            fir_start <= 1'b0;

            if (processing) begin
                // 左右两个 FIR 均完成后进入捕获阶段
                // FIR 输出寄存器与 ready 信号在相关时钟边沿更新，因此延后一周期读取输出
                if (fir_ready_l && fir_ready_r) begin
                    processing <= 1'b0;
                    capture    <= 1'b1;
                end
            end else if (capture) begin
                // 此时 FIR 输出已经更新，将 16 位结果左移 8 位重新对齐为 24 位音频格式
                writedata_left  <= {fir_out_l, 8'b0};
                writedata_right <= {fir_out_r, 8'b0};
                capture         <= 1'b0;
                pending         <= 1'b1;
            end else if (pending) begin
                // 当 CODEC 输出侧可以接收数据时，将左右声道滤波结果写回
                if (write_ready) begin
                    write   <= 1'b1;
                    pending <= 1'b0;
                end
            end else begin
                // 空闲状态下，仅当 ADC 侧存在新的立体声采样时启动一次滤波处理
                if (read_ready) begin
                    read       <= 1'b1;   // 从 ADC FIFO 读取一组左右声道采样
                    fir_start  <= 1'b1;   // 同时启动左右两个 FIR
                    processing <= 1'b1;
                end
            end
        end
    end

    // 左声道 16 抽头 FIR
    fir fir_left (
        .in          (fir_in_l),
        .input_ready (fir_start),
        .ck          (CLOCK_50),
        .rst         (reset),
        .out         (fir_out_l),
        .output_ready(fir_ready_l)
    );

    // 右声道 16 抽头 FIR
    fir fir_right (
        .in          (fir_in_r),
        .input_ready (fir_start),
        .ck          (CLOCK_50),
        .rst         (reset),
        .out         (fir_out_r),
        .output_ready(fir_ready_r)
    );

    // 生成音频 CODEC 所需的主时钟 AUD_XCK
    clock_generator my_clock_gen(
        // 输入
        CLOCK2_50,
        reset,
        // 输出
        AUD_XCK
    );

    // 通过 I2C 完成音频 CODEC 的寄存器配置
    audio_and_video_config cfg(
        // 输入
        CLOCK_50,
        reset,
        // 双向接口
        FPGA_I2C_SDAT,
        FPGA_I2C_SCLK
    );

    // 音频 CODEC 数据接口：负责 ADC 采样读取和 DAC 数据写回
    audio_codec codec(
        // 输入
        CLOCK_50,
        reset,

        read, write,
        writedata_left, writedata_right,

        AUD_ADCDAT,

        // 双向接口
        AUD_BCLK,
        AUD_ADCLRCK,
        AUD_DACLRCK,

        // 输出
        read_ready, write_ready,
        readdata_left, readdata_right,
        AUD_DACDAT
    );

endmodule

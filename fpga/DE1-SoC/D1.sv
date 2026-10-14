// Reconstructed from D1(1-3).png: stereo FIR/audio CODEC integration.
module D1 (
    input logic CLOCK_50, CLOCK2_50,
    input logic [0:0] KEY,
    output logic FPGA_I2C_SCLK,
    inout wire FPGA_I2C_SDAT,
    output logic AUD_XCK,
    input logic AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT,
    output logic AUD_DACDAT
);
    wire reset = ~KEY[0];
    wire read_ready, write_ready;
    logic read, write;
    wire [23:0] readdata_left, readdata_right;
    logic [23:0] writedata_left, writedata_right;

    logic fir_start;
    logic signed [15:0] fir_in_l, fir_in_r;
    logic signed [15:0] fir_out_l, fir_out_r;
    logic fir_ready_l, fir_ready_r;
    assign fir_in_l = $signed(readdata_left[23:8]);
    assign fir_in_r = $signed(readdata_right[23:8]);

    logic processing, capture, pending;
    always_ff @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            read <= 1'b0;
            write <= 1'b0;
            fir_start <= 1'b0;
            processing <= 1'b0;
            capture <= 1'b0;
            pending <= 1'b0;
            writedata_left <= 24'd0;
            writedata_right <= 24'd0;
        end else begin
            read <= 1'b0;
            write <= 1'b0;
            fir_start <= 1'b0;
            if (processing) begin
                if (fir_ready_l && fir_ready_r) begin
                    processing <= 1'b0;
                    capture <= 1'b1;
                end
            end else if (capture) begin
                writedata_left <= {fir_out_l, 8'b0};
                writedata_right <= {fir_out_r, 8'b0};
                capture <= 1'b0;
                pending <= 1'b1;
            end else if (pending) begin
                if (write_ready) begin
                    write <= 1'b1;
                    pending <= 1'b0;
                end
            end else if (read_ready) begin
                read <= 1'b1;
                fir_start <= 1'b1;
                processing <= 1'b1;
            end
        end
    end

    fir fir_left (
        .in(fir_in_l), .input_ready(fir_start), .ck(CLOCK_50),
        .rst(reset), .out(fir_out_l), .output_ready(fir_ready_l)
    );
    fir fir_right (
        .in(fir_in_r), .input_ready(fir_start), .ck(CLOCK_50),
        .rst(reset), .out(fir_out_r), .output_ready(fir_ready_r)
    );
    clock_generator my_clock_gen(CLOCK2_50, reset, AUD_XCK);
    audio_and_video_config cfg(CLOCK_50, reset, FPGA_I2C_SDAT, FPGA_I2C_SCLK);
    audio_codec codec(
        CLOCK_50, reset, read, write, writedata_left, writedata_right,
        AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK,
        read_ready, write_ready, readdata_left, readdata_right, AUD_DACDAT
    );
endmodule

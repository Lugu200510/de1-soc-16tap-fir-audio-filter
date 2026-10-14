// 16 taps, signed 16-bit samples, Q0.15 coefficients, sequential MAC.
module fir (
    input  logic signed [15:0] in,
    input  logic               input_ready, ck, rst,
    output logic signed [15:0] out,
    output logic               output_ready
);
    typedef logic signed [15:0] sample_t;
    sample_t samples [0:15];
    const sample_t coefficients [0:15] = '{
        16'sd30, 16'sd136, 16'sd457, 16'sd1119,
        16'sd2116, 16'sd3278, 16'sd4317, 16'sd4932,
        16'sd4932, 16'sd4317, 16'sd3278, 16'sd2116,
        16'sd1119, 16'sd457, 16'sd136, 16'sd30
    };

    typedef enum logic [1:0] {waiting, loading, processing, saving} state_t;
    state_t state, next_state;
    logic load, count, reset_accumulator;
    logic [3:0] address;
    logic signed [31:0] sum;

    always_ff @(posedge ck or posedge rst) begin
        if (rst) state <= waiting;
        else     state <= next_state;
    end

    always_comb begin
        next_state = state;
        load = 1'b0;
        count = 1'b0;
        reset_accumulator = 1'b0;
        output_ready = 1'b0;
        case (state)
            waiting: begin
                reset_accumulator = 1'b1;
                if (input_ready) next_state = loading;
            end
            loading: begin
                load = 1'b1;
                reset_accumulator = 1'b1;
                next_state = processing;
            end
            processing: begin
                count = 1'b1;
                if (address == 4'd15) next_state = saving;
            end
            saving: begin
                output_ready = 1'b1;
                next_state = waiting;
            end
            default: next_state = waiting;
        endcase
    end

    // Delay line deliberately retains history across reset, matching screenshots.
    always_ff @(posedge ck) begin
        if (load) begin
            for (int i = 15; i >= 1; i--)
                samples[i] <= samples[i-1];
            samples[0] <= in;
        end
    end

    always_ff @(posedge ck or posedge rst) begin
        if (rst)                    address <= 4'd0;
        else if (reset_accumulator) address <= 4'd0;
        else if (count)             address <= address + 4'd1;
    end

    always_ff @(posedge ck or posedge rst) begin
        if (rst)                    sum <= 32'sd0;
        else if (reset_accumulator) sum <= 32'sd0;
        else if (count)
            sum <= sum + ($signed(samples[address]) * $signed(coefficients[address]));
    end

    always_ff @(posedge ck) begin
        if (output_ready) out <= sum[30:15];
    end
endmodule

// Reconstructed from 高通1-3.png. Separate 17-tap high-pass variant.
module fir #(
    parameter int W = 16,
    parameter int TAPS = 17,
    parameter logic signed [W-1:0] COEFFS [0:TAPS-1] = '{
        16'sd0, -16'sd66, -16'sd264, -16'sd701,
        -16'sd1408, -16'sd2300, -16'sd3191, -16'sd3852,
        16'sd28672, -16'sd3852, -16'sd3191, -16'sd2300,
        -16'sd1408, -16'sd701, -16'sd264, -16'sd66, 16'sd0
    }
)(
    input  logic signed [W-1:0] in,
    input  logic input_ready, ck, rst,
    output logic signed [W-1:0] out,
    output logic output_ready
);
    typedef logic signed [W-1:0] sample_t;
    sample_t samples [0:TAPS-1];
    typedef enum logic [1:0] {waiting, loading, processing, saving} state_t;
    state_t state, next_state;
    logic load, count, reset_accumulator;
    localparam int ADDR_W = (TAPS <= 1) ? 1 : $clog2(TAPS);
    logic [ADDR_W-1:0] address;
    localparam int ACC_W = 2*W + ((TAPS <= 1) ? 1 : $clog2(TAPS)) + 1;
    logic signed [ACC_W-1:0] sum;

    always_ff @(posedge ck or posedge rst) begin
        if (rst) state <= waiting;
        else state <= next_state;
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
                if (address == ADDR_W'(TAPS-1)) next_state = saving;
            end
            saving: begin
                output_ready = 1'b1;
                next_state = waiting;
            end
            default: next_state = waiting;
        endcase
    end
    always_ff @(posedge ck) begin
        if (load) begin
            for (int i = TAPS-1; i >= 1; i--)
                samples[i] <= samples[i-1];
            samples[0] <= in;
        end
    end
    always_ff @(posedge ck or posedge rst) begin
        if (rst) address <= '0;
        else if (reset_accumulator) address <= '0;
        else if (count) address <= address + 1'b1;
    end
    always_ff @(posedge ck or posedge rst) begin
        if (rst) sum <= '0;
        else if (reset_accumulator) sum <= '0;
        else if (count)
            sum <= sum + ($signed(samples[address]) * $signed(COEFFS[address]));
    end
    always_ff @(posedge ck or posedge rst) begin
        if (rst) out <= '0;
        else if (output_ready) out <= $signed(sum >>> (W-1));
    end
endmodule

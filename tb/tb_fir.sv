`timescale 1ns/100ps
// Compile one configuration at a time; see sim/run.sh.
module tb_fir;
`ifdef MODE_PARAM8
    localparam int W = 8, TAPS = 8;
    localparam logic signed [W-1:0] COEFFS [0:TAPS-1] =
        '{8'sd16, 8'sd16, 8'sd16, 8'sd16, 8'sd16, 8'sd16, 8'sd16, 8'sd16};
`elsif MODE_HIGHPASS
    localparam int W = 16, TAPS = 17;
    localparam logic signed [W-1:0] COEFFS [0:TAPS-1] = '{
        16'sd0, -16'sd66, -16'sd264, -16'sd701,
        -16'sd1408, -16'sd2300, -16'sd3191, -16'sd3852,
        16'sd28672, -16'sd3852, -16'sd3191, -16'sd2300,
        -16'sd1408, -16'sd701, -16'sd264, -16'sd66, 16'sd0};
`else
    localparam int W = 16, TAPS = 16;
    localparam logic signed [W-1:0] COEFFS [0:TAPS-1] = '{
        16'sd30, 16'sd136, 16'sd457, 16'sd1119,
        16'sd2116, 16'sd3278, 16'sd4317, 16'sd4932,
        16'sd4932, 16'sd4317, 16'sd3278, 16'sd2116,
        16'sd1119, 16'sd457, 16'sd136, 16'sd30};
`endif
    logic ck = 0;
    always #500 ck = ~ck;
    logic rst = 1, input_ready = 0;
    logic signed [W-1:0] in = '0, out;
    logic output_ready;
    int signed hist [0:TAPS-1];
    int accepted = 0, checked = 0, errors = 0;
`ifdef MODE_PARAM8
    fir #(.W(W), .TAPS(TAPS), .COEFFS(COEFFS)) dut (.*);
`elsif MODE_PARAM16
    fir #(.W(W), .TAPS(TAPS), .COEFFS(COEFFS)) dut (.*);
`elsif MODE_HIGHPASS
    fir #(.W(W), .TAPS(TAPS), .COEFFS(COEFFS)) dut (.*);
`else
    fir dut (.*);
`endif

    task automatic push_and_check(input int signed value);
        longint signed acc, predicted;
        bit got_ready;
        int latency;
        @(negedge ck);
        in = W'(value);
        input_ready = 1'b1;
        @(posedge ck);
        // Stable until the DUT's loading state samples it on the next edge.
        @(negedge ck);
        input_ready = 1'b0;
        for (int k=TAPS-1; k>0; k--) hist[k] = hist[k-1];
        hist[0] = $signed(W'(value));
        accepted++;
        acc = 0;
        for (int k=0; k<TAPS; k++)
            acc += hist[k] * $signed(COEFFS[k]);
        predicted = acc >>> (W-1);

        got_ready = 0;
        latency = 0;
        for (int i=0; i<TAPS+7; i++) begin
            @(posedge ck);
            #1ns;
            if (output_ready) begin
                got_ready = 1;
                latency = i+1;
                break;
            end
        end
        if (!got_ready) begin
            errors++;
            $error("No output_ready for sample %0d",accepted);
        end else begin
            @(posedge ck);
            #1ns;
            if (accepted >= TAPS) begin
                checked++;
                if ($signed(out) !== $signed(W'(predicted))) begin
                    errors++;
                    $error("sample=%0d predicted=%0d got=%0d", accepted, predicted, $signed(out));
                end
            end
            $display("sample=%0d latency=%0d out=%0d", accepted, latency, $signed(out));
        end
    endtask

    initial begin
        for (int k=0; k<TAPS; k++) hist[k] = 0;
        repeat (2) @(negedge ck);
        rst = 0;
        for (int i=0; i<2*TAPS+4; i++)
            push_and_check((i%5 - 2) * ((W==8) ? 17 : 1800));
        // Reset the controller, not the delay line; test retained history.
        @(negedge ck); rst = 1;
        @(negedge ck); rst = 0;
        push_and_check((W==8) ? 20 : 2000);
        if (errors == 0) $display("TB PASS: %0d checked samples",checked);
        else $fatal(1,"TB FAIL: %0d mismatches",errors);
        $finish;
    end
endmodule

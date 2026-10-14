`timescale 1ns/100ps
module test_fir;
    localparam int W_TB = 16, TAPS_TB = 17;
    localparam logic signed [W_TB-1:0] COEFFS_TB [0:TAPS_TB-1] = '{16'sd0, -16'sd66, -16'sd264, -16'sd701, -16'sd1408, -16'sd2300, -16'sd3191, -16'sd3852, 16'sd28672, -16'sd3852, -16'sd3191, -16'sd2300, -16'sd1408, -16'sd701, -16'sd264, -16'sd66, 16'sd0};
    logic signed [W_TB-1:0] in = '0, out;
    logic input_ready = 0, ck = 0, rst = 0, output_ready;
    logic signed [W_TB-1:0] COEFFS_SIG [0:TAPS_TB-1];
    initial for (int k=0; k<TAPS_TB; k++) COEFFS_SIG[k] = COEFFS_TB[k];
    localparam int input_frequency = 5000;
    fir #(.W(W_TB), .TAPS(TAPS_TB), .COEFFS(COEFFS_TB)) CUT (.*);
    initial forever #500ns ck = ~ck;
    initial begin
        forever begin
            #(500000000/input_frequency) in = W_TB'(-10000);
            #(500000000/input_frequency) in = W_TB'(10000);
        end
    end
    initial begin
        forever begin
            #24us input_ready = 1'b1;
            #1us input_ready = 1'b0;
        end
    end
    initial begin
        #10ns rst = 1'b1;
        #10ns rst = 1'b0;
        #4ms $finish;
    end
endmodule

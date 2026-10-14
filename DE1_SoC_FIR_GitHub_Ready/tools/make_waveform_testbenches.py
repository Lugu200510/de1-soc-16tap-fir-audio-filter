from pathlib import Path
root=Path(__file__).resolve().parents[1]/'tb'
sets={
  'tb_waveform_param16.sv':(16,[30,136,457,1119,2116,3278,4317,4932,4932,4317,3278,2116,1119,457,136,30],10000),
  'tb_waveform_param8.sv':(8,[16]*8,50),
  'tb_waveform_highpass.sv':(16,[0,-66,-264,-701,-1408,-2300,-3191,-3852,28672,-3852,-3191,-2300,-1408,-701,-264,-66,0],10000),
}
for name,(w,co,amp) in sets.items():
  rows=', '.join((f"-{w}'sd{abs(c)}" if c<0 else f"{w}'sd{c}") for c in co)
  s=f'''`timescale 1ns/100ps
// Waveform stimulus recreated from the original ModelSim testbench screenshots.
module test_fir;
    localparam int W_TB = {w}, TAPS_TB = {len(co)};
    localparam logic signed [W_TB-1:0] COEFFS_TB [0:TAPS_TB-1] = '{{{rows}}};
    logic signed [W_TB-1:0] in = '0, out;
    logic input_ready = 0, ck = 0, rst = 0, output_ready;
    logic signed [W_TB-1:0] COEFFS_SIG [0:TAPS_TB-1];
    initial for (int k=0; k<TAPS_TB; k++) COEFFS_SIG[k] = COEFFS_TB[k];
    localparam int input_frequency = 5000;
    fir #(.W(W_TB), .TAPS(TAPS_TB), .COEFFS(COEFFS_TB)) CUT (.*);
    initial forever #500ns ck = ~ck;
    initial begin
        forever begin
            #(500000000/input_frequency) in = W_TB'(-{amp});
            #(500000000/input_frequency) in = W_TB'({amp});
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
'''
  (root/name).write_text(s)
  print(name,len(s))

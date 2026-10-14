# Recovery status

- ✅ `rtl/fir.sv`: reconstructed from `FIR(1–3).png` (sequential 16×16-bit low-pass).
- ✅ `rtl/fir_param.sv`: reconstructed from `参数化1–3.png` (W/TAPS/COEFFS).
- ✅ `rtl/fir_highpass.sv`: reconstructed from `高通1–3.png` (17-tap high-pass).
- ✅ `fpga/DE1-SoC/D1.sv`: reconstructed from `D1(1–3).png` (stereo FIR integration).
- ✅ `tb/tb_waveform_*.sv`: completed waveform generators based on screenshot parameters; not line-for-line replicas.
- ✅ `tb/tb_fir.sv`: new model-based self-checking testbench.
- ✅ `docs/code-screenshots/`: exact original screenshot images retained.
- ⚠️ Original zip source `template_FIR_module.sv` is an unfinished course template and original `DE1-SoC/D1.sv` is audio passthrough. Private archive retains them for provenance.
- ⚠️ New source files have not been run through commercial EDA tools in this environment. The upload's ModelSim/Quartus screenshots reflect the original historical work.

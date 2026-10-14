# Screenshot code recovery / 图片代码恢复

| Screenshot group | Editable reconstruction |
| --- | --- |
| `fir-01/02/03.png` | [`../../rtl/fir.sv`](../../rtl/fir.sv) — fixed 16-tap low-pass FIR |
| `parameterized-01/02/03.png` | [`../../rtl/fir_param.sv`](../../rtl/fir_param.sv) — generic-width/tap FIR |
| `highpass-01/02/03.png` | [`../../rtl/fir_highpass.sv`](../../rtl/fir_highpass.sv) — 17-tap high-pass FIR |
| `de1-audio-01/02/03.png` | [`../../fpga/DE1-SoC/D1.sv`](../../fpga/DE1-SoC/D1.sv) — stereo CODEC integration |
| `tb-param8`, `tb-param16`, `tb-highpass` | [`../../tb/tb_fir.sv`](../../tb/tb_fir.sv) — **new equivalent self-checking TB**, not a verbatim transcription |

Original screen images are included here so the recovered source can be checked against them. Empty or cut-off image regions cannot be certified as pixel-perfect source code; the TB is an independently written complete substitute.

原图均保留；固定低通、参数化、高通及音频顶层恢复为可编辑 `.sv`。截图中的各版测试平台由全新自检 TB 代替，**不宣称与截图逐字一致**。

Waveform-stimulus testbenches were additionally reconstructed into [`../../tb/tb_waveform_param8.sv`](../../tb/tb_waveform_param8.sv), [`../../tb/tb_waveform_param16.sv`](../../tb/tb_waveform_param16.sv), and [`../../tb/tb_waveform_highpass.sv`](../../tb/tb_waveform_highpass.sv). Their signal parameters, coefficients, sampling and clock rates follow the screenshots; formatting and missing lines have been independently completed.

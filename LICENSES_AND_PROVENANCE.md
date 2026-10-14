# Source provenance & third-party code

- `rtl/fir.sv`, `rtl/fir_param.sv`, `rtl/fir_highpass.sv` and `fpga/DE1-SoC/D1.sv`: reconstructed from user-supplied screenshots. The source skeleton and coefficient data were supplied in an educational assignment; authorship of the provided template is attributed to the original course author in `docs/original/template_FIR_module.sv`.
- `tb/tb_fir.sv`, `sim/`, `assets/fir-sweep.gif`: new supplementary implementations.
- `docs/images/`, `docs/code-screenshots/`: original user-provided screenshots and board photo.
- The original `.v` audio CODEC support files from the bundled Intel/Altera package contain restrictive license notices. **They are not included in the GitHub-ready archive.** Obtain them from an authorized Intel/Altera/DE1-SoC distribution and add to `fpga/DE1-SoC/` locally.
- Original educational materials/reports are retained solely for reference to project history. Check their sharing requirements before publishing.
- The rebuilt RTL and TB have not been rerun here with ModelSim/VCS/Quartus. Uploaded screenshots are evidence of previous work, not proof of the new build.

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-lowpass}"
case "$mode" in
  lowpass) rtl="rtl/fir.sv"; define="";;
  param16) rtl="rtl/fir_param.sv"; define="+define+MODE_PARAM16";;
  param8) rtl="rtl/fir_param.sv"; define="+define+MODE_PARAM8";;
  highpass) rtl="rtl/fir_highpass.sv"; define="+define+MODE_HIGHPASS";;
  *) echo "Usage: $0 [lowpass|param16|param8|highpass]"; exit 2;;
esac
mkdir -p build
if command -v vlog >/dev/null && command -v vsim >/dev/null; then
  (cd build && vlib work >/dev/null 2>&1 || true)
  # Run from build/ with local work library, preserving relative source paths.
  (cd build && vlog -sv $define "../$rtl" ../tb/tb_fir.sv && vsim -c work.tb_fir -do 'run -all; quit -f')
elif command -v vcs >/dev/null; then
  vcs -full64 -sverilog $define -o build/simv "$rtl" tb/tb_fir.sv
  build/simv
else
  echo 'ModelSim/Questa or Synopsys VCS is required; no simulation performed.' >&2
  exit 1
fi

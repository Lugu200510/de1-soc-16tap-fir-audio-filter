# Execute in ModelSim GUI from repository root: do sim/run.do
vlib work
vlog -sv rtl/fir.sv tb/tb_fir.sv
vsim -voptargs=+acc work.tb_fir
add wave -r sim:/tb_fir/*
run -all

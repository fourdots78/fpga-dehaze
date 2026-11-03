onerror {quit -code 1}
onbreak {quit -code 1}
vlib slip_work
vmap work slip_work
vlog -work work cam2dvi/src/sign_detector.v sim/tb_sign.v
vsim -novopt work.tb_sign_v12
run -all
quit -code 0

onerror {quit -code 1 -force}
onbreak {quit -code 1 -force}
vlib feature_work
vmap work feature_work
vlog cam2dvi/src/demo_controls.v sim/tb_controls.v
vsim -novopt work.tb_controls
run -all
quit -code 0 -force

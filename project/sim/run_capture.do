onerror {quit -code 1 -force}
onbreak {quit -code 1 -force}
vlib feature_work
vmap work feature_work
vlog cam2dvi/src/video_compare.v sim/tb_capture.v
vsim -novopt work.tb_capture
run -all
quit -code 0 -force

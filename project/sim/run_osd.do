onerror {quit -code 1 -force}
onbreak {quit -code 1 -force}
vlib osd_work
vmap work osd_work
vlog cam2dvi/src/video_osd.v sim/tb_osd.v
vsim -novopt work.tb_osd_v12
run -all
quit -code 0 -force

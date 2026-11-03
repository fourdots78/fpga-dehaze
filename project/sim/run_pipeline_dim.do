onerror {quit -code 1 -force}
onbreak {quit -code 1 -force}
vlib pipeline_work
vmap work pipeline_work
vlog cam2dvi/src/demo_controls.v cam2dvi/src/dehaze_color_safe.v cam2dvi/src/dehaze_stream_top.v cam2dvi/src/video_compare.v cam2dvi/src/video_osd.v cam2dvi/src/sign_detector.v cam2dvi/src/rgb_invert.v sim/tb_pipeline.v
vsim -novopt -gINPUT_FILE=sim/slip_holdout_dim.hex -gEXPECTED_CLASS=5 work.tb_pipeline_v12
run -all
quit -code 0 -force

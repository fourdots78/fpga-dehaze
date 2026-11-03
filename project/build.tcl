open_project T:/cam2dvi/cam2dvi.gprj
set_option -top_module top
set_option -rw_check_on_ram 1
set_option -print_all_synthesis_warning 1
set_option -reg_in_iob 1
set_option -ireg_in_iob 1
set_option -oreg_in_iob 1
set_option -ioreg_in_iob 1
set_option -place_option 2
set_option -route_option 0
set_option -retiming_resource none
set_option -use_sspi_as_gpio 1
set_option -bit_compress 0
set_option -bit_incl_bsram_init 1
run all
exit

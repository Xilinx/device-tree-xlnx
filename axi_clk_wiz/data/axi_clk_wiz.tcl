proc generate {drv_handle} {
	# try to source the common tcl procs
	# assuming the order of return is based on repo priority
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}

	set ip [get_cells $drv_handle]
	set speedgrade "([get_property SPEEDGRADE [get_hw_designs]])"
	if {![string equal $speedgrade "()"]} {
		hsi::utils::add_new_property $drv_handle "speed-grade" int $speedgrade
	}

	set output_names ""
	for {set i 1} {$i < 8} {incr i} {
		if {[get_property CONFIG.C_CLKOUT${i}_USED $ip] != 0} {
			set freq [get_property CONFIG.C_CLKOUT${i}_OUT_FREQ $ip]
			set pin_name [get_property CONFIG.C_CLK_OUT${i}_PORT $ip]
			lappend output_names $pin_name
		}
	}
	if {![string_is_empty $output_names]} {
		set_property CONFIG.clock-output-names $output_names $drv_handle
	}

	gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
}

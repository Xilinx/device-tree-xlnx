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

	# get bus clock frequency
	set clk_freq [get_clock_frequency [get_cells $drv_handle] "S_AXI_ACLK"]
	if {![string equal $clk_freq ""]} {
		set_property CONFIG.clock-frequency $clk_freq $drv_handle
	}
	set_drv_conf_prop $drv_handle "C_WDT_ENABLE_ONCE" "xlnx,wdt-enable-once"
	set_drv_conf_prop $drv_handle "C_WDT_INTERVAL" "xlnx,wdt-interval"

}


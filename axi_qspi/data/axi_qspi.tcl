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

	set kernel_version [get_property CONFIG.kernel_version [get_os]]
	puts $kernel_version
	switch -exact $kernel_version {
		"2014.2" {
			set_drv_conf_prop $drv_handle "C_NUM_SS_BITS" "xlnx,num-ss-bits"
		} "2014.3" -
		"2014.4" -
		default {
			set_drv_conf_prop $drv_handle "C_NUM_SS_BITS" "num-cs"
		}
	}
}

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

	set check_list "enable-profile enable-trace num-monitor-slots enable-event-count enable-event-log have-sampled-metric-cnt num-of-counters metric-count-width metrics-sample-count-width global-count-width metric-count-scale"
	foreach p ${check_list} {
		set ip_conf [string toupper "c_${p}"]
		regsub -all {\-} $ip_conf {_} ip_conf
		set_drv_conf_prop $drv_handle ${ip_conf} xlnx,${p} hexint
	}
}

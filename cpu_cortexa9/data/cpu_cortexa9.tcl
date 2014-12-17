proc generate {drv_handle} {
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}

	# create root node
	set master_root_node [gen_root_node $drv_handle]
	set nodes [gen_cpu_nodes $drv_handle]
}

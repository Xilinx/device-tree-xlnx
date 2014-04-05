proc set_zynq_comp_str {drv_handle} {
	set slave [get_cells $drv_handle]
	set vlnv [get_property "VLNV" $slave]
	set list [split "$vlnv" ":"]
	if { [regexp "ps7_.*" [lindex $list 2] matched]} {
		set vendor [lindex $list 0]
		if { [regexp "xilinx.com" $vendor matched]} {
			set vendor "xlnx"
		}
		set ip [lindex $list 2]
		regsub -- "ps7_" $ip "zynq-" ip
		set ip_ver [lindex $list 3]
		regsub -- "[0-9].[1-z]$" $ip_ver "" ip_ver
		set comp_str ${vendor},${ip}-${ip_ver}
		set cur_comp_str [get_property "CONFIG.compatible" $drv_handle]
		# TODO: Check if we should unconditionally add it
		# empty check before set it
		if {[string equal "" $cur_comp_str]} {
			set_property "CONFIG.compatible" "$comp_str $cur_comp_str" $drv_handle
		}
	}
}

proc generate {drv_handle} {
	set_zynq_comp_str $drv_handle
}

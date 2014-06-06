proc set_pcie_ranges {drv_handle} {
	set axibar_num [get_ip_property $drv_handle "CONFIG.AXIBAR_NUM"]
	set range_type 0x02000000
	# 64-bit high address.
	set high_64bit 0x00000000
	set ranges ""
	for {set x 0} {$x < $axibar_num} {incr x} {
		set axi_baseaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR_%d" $x]]
		set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR2PCIEBAR_%d" $x]]
		set axi_highaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR_HIGHADDR_%d" $x]]
		set size [format 0x%X [expr $axi_highaddr -$axi_baseaddr + 1]]
		set value "<$range_type $high_64bit $pcie_baseaddr $axi_baseaddr $high_64bit $size>"
		if {[string match "" $ranges]} {
			set ranges $value
		} else {
			append ranges ", " $value
		}
	}
	set_property CONFIG.ranges $ranges $drv_handle
}

proc set_pcie_reg {drv_handle} {
	set baseaddr [get_ip_property $drv_handle CONFIG.BASEADDR]
	set highaddr [get_ip_property $drv_handle CONFIG.HIGHADDR]
	set size [format 0x%X [expr $highaddr -$baseaddr + 1]]
	set_property CONFIG.reg "$baseaddr $size" $drv_handle
}

proc axibar_num_workaround {drv_handle} {
	# this required to workaround 2014.2_web tag kernel
	# must have both xlnx,pciebar2axibar-0 and xlnx,pciebar2axibar-1 generated
	set axibar_num [get_ip_property $drv_handle "CONFIG.AXIBAR_NUM"]
	if {[expr $axibar_num <= 1]} {
		set axibar_num 2
	}
	return $axibar_num
}

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

	set axibar_num [axibar_num_workaround $drv_handle]
	for {set x 0} {$x < $axibar_num} {incr x} {
		set_drv_conf_prop $drv_handle [format "PCIEBAR2AXIBAR_%d" $x] [format "xlnx,pciebar2axibar-%d" $x]
	}

	set_drv_conf_prop $drv_handle "C_INCLUDE_RC" "xlnx,include-rc"
	set_drv_conf_prop $drv_handle "C_DEVICE_NUM" "xlnx,device-num"
	set_drv_conf_prop $drv_handle "C_PCIEBAR_NUM" "xlnx,pciebar-num"
	set_pcie_reg $drv_handle
	set_pcie_ranges $drv_handle
}

#
# (C) Copyright 2014-2015 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

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
		set size [expr $axi_highaddr -$axi_baseaddr + 1]
		# Check the size of pci memory region is 4GB or not,if
		# yes then split the size to MSB and LSB.
		if {[regexp -nocase {([0-9a-f]{9})} "$size" match]} {
		       set size [format 0x%016x [expr $axi_highaddr -$axi_baseaddr + 1]]
                       set low_size [string range $size 0 9]
                       set high_size "0x[string range $size 10 17]"
                       set size "$low_size $high_size"
                } else {
                       set size [format 0x%08x [expr $axi_highaddr - $axi_baseaddr + 1]]
		       set size "$high_64bit $size"
                }
		set value "<$range_type $high_64bit $pcie_baseaddr $axi_baseaddr $size>"
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

	set_pcie_reg $drv_handle
	set_pcie_ranges $drv_handle
	set tab "\n\t\t\t\t\t"
	set int_map "0 0 0 1 &pcie_intc 1>,$tab<0 0 0 2 &pcie_intc 2>,$tab<0 0 0 3 &pcie_intc 3>,\
		$tab<0 0 0 4 &pcie_intc 4"
	set_drv_prop $drv_handle interrupt-map-mask "0 0 0 7" intlist
	set_drv_prop $drv_handle interrupt-map $int_map int
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "microblaze"] } {
		set_drv_prop $drv_handle bus-range "0x0 0xff" hexint
	}
	# Add Interrupt controller child node
	set node [gen_peripheral_nodes $drv_handle]
	set pcie_child_intc_node [add_or_get_dt_node -l "pcie_intc" -n interrupt-controller -p $node]
	hsi::utils::add_new_dts_param "${pcie_child_intc_node}" "interrupt-controller" "" boolean
	hsi::utils::add_new_dts_param "${pcie_child_intc_node}" "#address-cells" 0 int
	hsi::utils::add_new_dts_param "${pcie_child_intc_node}" "#interrupt-cells" 1 int

}

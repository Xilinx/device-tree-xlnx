#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc set_pcie_ranges {drv_handle proctype} {
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "qdma"] \
		|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "xdma"]} {
		set axibar_num [get_ip_property $drv_handle "CONFIG.axibar_num"]
	} else {
		set axibar_num [get_ip_property $drv_handle "CONFIG.AXIBAR_NUM"]
	}
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "pcie_dma_versal"]} {
		set axibar_num [get_ip_property $drv_handle "CONFIG.C_AXIBAR_NUM"]
	}
	set range_type 0x02000000
	# 64-bit high address.
	set high_64bit 0x00000000
	set ranges ""
	for {set x 0} {$x < $axibar_num} {incr x} {
		if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "qdma"] \
			|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "xdma"] \
			|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "axi_pcie3"] \
			|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "pcie_dma_versal"] \
			} {
			set axi_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar_%d" $x]]
			set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar2pciebar_%d" $x]]
			set axi_highaddr [get_ip_property $drv_handle [format "CONFIG.axibar_highaddr_%d" $x]]
		} else {
			set axi_baseaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR_%d" $x]]
			set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR2PCIEBAR_%d" $x]]
			set axi_highaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR_HIGHADDR_%d" $x]]
		}
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
		if {[regexp -nocase {([0-9a-f]{9})} "$axi_baseaddr" match] || [regexp -nocase {([0-9a-f]{9})} "$axi_highaddr" match]} {
			set range_type 0x43000000
		}

		if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "qdma"] \
			|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "xdma"] \
			|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "pcie_dma_versal"]} {
			if {[regexp -nocase {([0-9a-f]{9})} "$pcie_baseaddr" match]} {
				set temp $pcie_baseaddr
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_base "0x[string range $temp $rem $len]"
				set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_base [format 0x%08x $low_base]
				set pcie_baseaddr "$low_base $high_base"
			} else {
				set pcie_baseaddr "$high_64bit $pcie_baseaddr"
			}
			if {[regexp -nocase {([0-9a-f]{9})} "$axi_baseaddr" match]} {
				set temp $axi_baseaddr
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_base "0x[string range $temp $rem $len]"
				set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_base [format 0x%08x $low_base]
				set axi_baseaddr "$low_base $high_base"
			} else {
				if {[string match -nocase $proctype "microblaze"] } {
					set axi_baseaddr "$axi_baseaddr"
				} else {
					set axi_baseaddr "0x0 $axi_baseaddr"
				}
			}
			set value "<$range_type $pcie_baseaddr $axi_baseaddr $size>"
		} else {
			set value "<$range_type $high_64bit $pcie_baseaddr $axi_baseaddr $size>"
		}
		if {[string match "" $ranges]} {
			set ranges $value
		} else {
			append ranges ", " $value
		}
	}
	set_property CONFIG.ranges $ranges $drv_handle
}

proc get_reg_prop {highaddr baseaddr proctype} {
	set reg ""
	set size [format 0x%X [expr $highaddr -$baseaddr + 1]]
	if {[regexp -nocase {0x([0-9a-f]{9})} "$baseaddr" match]} {
		set temp $baseaddr
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_base "0x[string range $temp $rem $len]"
		set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_base [format 0x%08x $low_base]
		set reg "$low_base $high_base 0x0 $size"
	} else {
		if {[string match -nocase $proctype "microblaze"] } {
			set reg "$baseaddr $size"
		} else {
			set reg "0x0 $baseaddr 0x0 $size"
		}
	}
	return $reg
}

proc set_pcie_reg {drv_handle proctype} {
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "xdma"] \
		|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "axi_pcie3"] \
		|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "pcie_dma_versal"]} {
		set baseaddr [get_ip_property $drv_handle CONFIG.baseaddr]
		set highaddr [get_ip_property $drv_handle CONFIG.highaddr]
		set reg [get_reg_prop $highaddr $baseaddr $proctype]
		if {[llength $reg]} {
			set_property CONFIG.reg $reg $drv_handle
		}
	} elseif {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "qdma"]} {
		set mem_ranges [hsi::utils::get_ip_mem_ranges $drv_handle]
		set reg ""
		set reg_names ""
		foreach mem_range $mem_ranges {
			set baseaddr [string tolower [get_property BASE_VALUE $mem_range]]
			set highaddr [string tolower [get_property HIGH_VALUE $mem_range]]
			set slave_intf [string tolower [get_property SLAVE_INTERFACE $mem_range]]
			dtg_verbose "slave_intf:$slave_intf"
			set reg_prop ""
			if {[string match -nocase $slave_intf "s_axi_lite"]} {
				set reg_prop [get_reg_prop $highaddr $baseaddr $proctype]
				append reg_names " " "cfg"
			} elseif {[string match -nocase $slave_intf "s_axi_lite_csr"]} {
				set reg_prop [get_reg_prop $highaddr $baseaddr $proctype]
				append reg_names " " "breg"
			}
			if {[llength $reg_prop]} {
				if {![llength $reg]} {
					set reg "$reg_prop"
				} else {
					append reg ">, <" "$reg_prop"
				}
			}
		}
		if {[llength $reg]} {
			set_property CONFIG.reg $reg $drv_handle
		}
		if {[llength $reg_names]} {
			hsi::utils::add_new_property $drv_handle "reg-names" stringlist "$reg_names"
		}
	} else {
		set baseaddr [get_ip_property $drv_handle CONFIG.BASEADDR]
		set highaddr [get_ip_property $drv_handle CONFIG.HIGHADDR]
		set size [format 0x%X [expr $highaddr -$baseaddr + 1]]
		set_property CONFIG.reg "$baseaddr $size" $drv_handle
	}
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
	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	set compatible [get_comp_str $drv_handle]
	if {![string match -nocase $proctype "psv_cortexa72"]} {
		set compatible [append compatible " " "xlnx,axi-pcie-host-1.00.a"]
	}
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "xdma"]} {
		hsi::utils::add_new_property $drv_handle "compatible" stringlist "xlnx,xdma-host-3.00"
		set msi_rx_pin_en [get_property CONFIG.msi_rx_pin_en [get_cells -hier $drv_handle]]
		if {[string match -nocase $msi_rx_pin_en "true"]} {
			set intr_names "misc msi0 msi1"
			set_drv_prop $drv_handle "interrupt-names" $intr_names stringlist
		}
	}
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "qdma"]} {
		hsi::utils::add_new_property $drv_handle "compatible" stringlist "xlnx,qdma-host-3.00"
	}
	set_pcie_reg $drv_handle $proctype
	set_pcie_ranges $drv_handle $proctype
	set_drv_prop $drv_handle interrupt-map-mask "0 0 0 7" intlist
	if {[string match -nocase $proctype "microblaze"] } {
		set_drv_prop $drv_handle bus-range "0x0 0xff" hexint
	}
	# Add Interrupt controller child node
	if {[string match -nocase $proctype "psv_cortexa72"]} {
		set psv_pcieintc_cnt [get_os_dev_count "psv_pci_intc_cnt"]
		set pcie_child_intc_node [add_or_get_dt_node -l "psv_pcie_intc_${psv_pcieintc_cnt}" -n interrupt-controller -p $node]
		set int_map "0 0 0 1 &psv_pcie_intc_${psv_pcieintc_cnt} 1>, <0 0 0 2 &psv_pcie_intc_${psv_pcieintc_cnt} 2>, <0 0 0 3 &psv_pcie_intc_${psv_pcieintc_cnt} 3>,\
			<0 0 0 4 &psv_pcie_intc_${psv_pcieintc_cnt} 4"
			incr psv_pcieintc_cnt
			hsi::utils::set_os_parameter_value "psv_pci_intc_cnt" $psv_pcieintc_cnt
			set intr_names "misc msi0 msi1"
			set_drv_prop $drv_handle "interrupt-names" $intr_names stringlist
	} else {
		set pcieintc_cnt [get_os_dev_count "pci_intc_cnt"]
		set pcie_child_intc_node [add_or_get_dt_node -l "pcie_intc_${pcieintc_cnt}" -n interrupt-controller -p $node]
		set int_map "0 0 0 1 &pcie_intc_${pcieintc_cnt} 1>, <0 0 0 2 &pcie_intc_${pcieintc_cnt} 2>, <0 0 0 3 &pcie_intc_${pcieintc_cnt} 3>,\
			<0 0 0 4 &pcie_intc_${pcieintc_cnt} 4"
		incr pcieintc_cnt
		hsi::utils::set_os_parameter_value "pci_intc_cnt" $pcieintc_cnt
	}
	set_drv_prop $drv_handle interrupt-map $int_map int
	hsi::utils::add_new_dts_param "${pcie_child_intc_node}" "interrupt-controller" "" boolean
	hsi::utils::add_new_dts_param "${pcie_child_intc_node}" "#address-cells" 0 int
	hsi::utils::add_new_dts_param "${pcie_child_intc_node}" "#interrupt-cells" 1 int
}

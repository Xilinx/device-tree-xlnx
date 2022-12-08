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
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,xps-gpio-1.00.a"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set intr_present [get_property CONFIG.C_INTERRUPT_PRESENT [get_cells -hier $drv_handle]]
	if {[string match $intr_present "1"]} {
		set node [gen_peripheral_nodes $drv_handle]
		if {$node != 0} {
			hsi::utils::add_new_dts_param "${node}" "#interrupt-cells" 2 int ""
		}
		hsi::utils::add_new_property $drv_handle "interrupt-controller" boolean ""
	}
	set proc_type [get_sw_proc_prop IP_NAME]
	switch $proc_type {
		"microblaze"   {
			gen_dev_ccf_binding $drv_handle "s_axi_aclk"
			set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_aclk" stringlist
		}
	}
	#Workaround: There is no unique way to differentiate the gt_ctrl, so hardcoding the size
	#for the address 0xa4010000 to 0x40000
	set ips [get_cells -hier -filter {IP_NAME == "mrmac"}]
	if {[llength $ips]} {
		set mem_ranges [hsi::utils::get_ip_mem_ranges [get_cells -hier $drv_handle]]
		foreach mem_range $mem_ranges {
			set base_addr [string tolower [get_property BASE_VALUE $mem_range]]
			set high_addr [string tolower [get_property HIGH_VALUE $mem_range]]
			if {[string match -nocase $base_addr "0xa4010000"]} {
				set reg "0x0 0xa4010000 0x0 0x40000"
				hsi::utils::add_new_dts_param "${node}" "reg" $reg inthexlist
			}
		}
	}
}

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
	set intr_present [get_property CONFIG.C_INTERRUPT_PRESENT [get_cells -hier $drv_handle]]
	if {[string match $intr_present "1"]} {
		set node [gen_peripheral_nodes $drv_handle]
		hsi::utils::add_new_dts_param "${node}" "#interrupt-cells" 2 int ""
		hsi::utils::add_new_property $drv_handle "interrupt-controller" boolean ""
	}
	set proc_type [get_sw_proc_prop IP_NAME]
	switch $proc_type {
		"psu_cortexa53" {
			update_clk_node $drv_handle "s_axi_aclk"
		} "microblaze"   {
			gen_dev_ccf_binding $drv_handle "s_axi_aclk"
			set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_aclk" stringlist
		} "ps7_cortexa9" {
			update_zynq_clk_node $drv_handle "s_axi_aclk"
		} default {
			error "Unknown arch"
		}
	}
}

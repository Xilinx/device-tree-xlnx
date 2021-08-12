#
# (C) Copyright 2018 Xilinx, Inc.
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
	set compatible [append compatible " " "xlnx,ai-engine-v1.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set intr_names "interrupt1"
	lappend intr_names "interrupt2"
	lappend intr_names "interrupt3"
	set intr_num "0x0 0x94 0x4>, <0x0 0x95 0x4>, <0x0 0x96 0x4"
	set power_domain "&versal_firmware 0x18224072"
	hsi::utils::add_new_dts_param "${node}" "interrupt-names" $intr_names stringlist
	hsi::utils::add_new_dts_param ${node} "interrupts" $intr_num intlist
	hsi::utils::add_new_dts_param "${node}" "interrupt-parent" gic reference
	hsi::utils::add_new_dts_param "${node}" "power-domains" $power_domain intlist
	hsi::utils::add_new_dts_param "${node}" "#address-cells" "2" intlist
	hsi::utils::add_new_dts_param "${node}" "#size-cells" "2" intlist

	# Add one AI engine partition child node
	set ai_part_id 0
	set ai_part_nid 1
	set ai_part_node [add_or_get_dt_node -n "aie_partition" -u "${ai_part_id}" -l "aie_partition${ai_part_id}" -p ${node}]
	hsi::utils::add_new_dts_param "${ai_part_node}" "reg" "0 0 50 9" intlist
	hsi::utils::add_new_dts_param "${ai_part_node}" "xlnx,partition-id" "${ai_part_nid}" intlist

	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set RpRm [hsi::utils::get_rp_rm_for_drv $drv_handle]
		regsub -all { } $RpRm "" RpRm
		if {[llength $RpRm]} {
			set bus_node "overlay2_$RpRm"
		} else  {
			set bus_node "overlay2"
		}
	} else {
		set bus_node "amba_pl"
	}
}

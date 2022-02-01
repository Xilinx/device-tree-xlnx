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

proc generate_aie_array_device_info {node drv_handle bus_node} {
	set aie_array_id 0
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,ai-engine-v2.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist

	append aiegen "/bits/ 8 <0x1>"
	hsi::utils::add_new_dts_param "${node}" "xlnx,aie-gen" $aiegen noformating
	append shimrows "/bits/ 8 <0 1>"
	hsi::utils::add_new_dts_param "${node}" "xlnx,shim-rows" $shimrows noformating
	append corerows "/bits/ 8 <1 8>"
	hsi::utils::add_new_dts_param "${node}" "xlnx,core-rows" $corerows noformating
	append memrows "/bits/ 8 <0 0>"
	hsi::utils::add_new_dts_param "${node}" "xlnx,mem-rows" $memrows noformating
	set power_domain "&versal_firmware 0x18224072"
	hsi::utils::add_new_dts_param "${node}" "power-domains" $power_domain intlist
	hsi::utils::add_new_dts_param "${node}" "#address-cells" "2" intlist
	hsi::utils::add_new_dts_param "${node}" "#size-cells" "2" intlist
	hsi::utils::add_new_dts_param "${node}" "ranges" "" boolean

	set ai_clk_node [add_or_get_dt_node -n "aie_core_ref_clk_0" -l "aie_core_ref_clk_0" -p ${bus_node}]
	set clk_freq [get_property CONFIG.AIE_CORE_REF_CTRL_FREQMHZ [get_cells -hier $drv_handle]]
	set clk_freq [expr ${clk_freq} * 1000000]
	hsi::utils::add_new_dts_param "${ai_clk_node}" "compatible" "fixed-clock" stringlist
	hsi::utils::add_new_dts_param "${ai_clk_node}" "#clock-cells" 0 int
	hsi::utils::add_new_dts_param "${ai_clk_node}" "clock-frequency" $clk_freq int

	set clocks "aie_core_ref_clk_0"
	set_drv_prop $drv_handle clocks "$clocks" reference
	hsi::utils::add_new_dts_param "${node}" "clock-names" "aclk0" stringlist

	return ${node}
}


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

	generate_aie_array_device_info ${node} ${drv_handle} ${bus_node}

	set ip [get_cells -hier $drv_handle]
	set unit_addr [get_baseaddr ${ip} no_prefix]
	set aperture_id 0
	set aperture_node [add_or_get_dt_node -n "aie_aperture" -u "${unit_addr}" -l "aie_aperture_${aperture_id}" -p ${node}]

	set reg [get_property CONFIG.reg ${drv_handle}]
	hsi::utils::add_new_dts_param "${aperture_node}" "reg" $reg noformat

	set intr_names "interrupt1"
	lappend intr_names "interrupt2"
	lappend intr_names "interrupt3"
	set intr_num "0x0 0x94 0x4>, <0x0 0x95 0x4>, <0x0 0x96 0x4"
	set power_domain "&versal_firmware 0x18224072"

	hsi::utils::add_new_dts_param "${aperture_node}" "interrupt-names" $intr_names stringlist
	hsi::utils::add_new_dts_param "${aperture_node}" "interrupts" $intr_num intlist
	hsi::utils::add_new_dts_param "${aperture_node}" "interrupt-parent" gic reference
	hsi::utils::add_new_dts_param "${aperture_node}" "power-domains" $power_domain intlist
	hsi::utils::add_new_dts_param "${aperture_node}" "#address-cells" "2" intlist
	hsi::utils::add_new_dts_param "${aperture_node}" "#size-cells" "2" intlist

	set aperture_nodeid 0x18800000
	hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,columns" "0 50" intlist
	hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,node-id" "${aperture_nodeid}" intlist

}

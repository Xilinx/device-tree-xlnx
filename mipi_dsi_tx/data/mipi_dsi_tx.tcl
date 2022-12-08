#
# (C) Copyright 2018-2022 Xilinx, Inc.
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
	set compatible [append compatible " " "xlnx,dsi"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set dsi_num_lanes [get_property CONFIG.DSI_LANES [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dsi-num-lanes" $dsi_num_lanes int
	set dsi_pixels_perbeat [get_property CONFIG.DSI_PIXELS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dsi-pixels-perbeat" $dsi_pixels_perbeat int
	set dsi_datatype [get_property CONFIG.DSI_DATATYPE [get_cells -hier $drv_handle]]
	if {[string match -nocase $dsi_datatype "RGB888"]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,dsi-data-type" 0 int
	} elseif {[string match -nocase $dsi_datatype "RGB666_L"]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,dsi-data-type" 1 int
	} elseif {[string match -nocase $dsi_datatype "RGB666_P"]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,dsi-data-type" 2 int
	} elseif {[string match -nocase $dsi_datatype "RGB565"]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,dsi-data-type" 3 int
	}
	set panel_node [add_or_get_dt_node -n "simple_panel" -l simple_panel$drv_handle -u 0 -p $node]
	hsi::utils::add_new_dts_param "${panel_node}" "/* User needs to add the panel node based on their requirement */" "" comment
	hsi::utils::add_new_dts_param "$panel_node" "reg" 0 int
	hsi::utils::add_new_dts_param "$panel_node" "compatible" "auo,b101uan01" string
}

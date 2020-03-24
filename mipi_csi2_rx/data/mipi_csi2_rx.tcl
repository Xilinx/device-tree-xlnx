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
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set dphy_en_reg_if [get_property CONFIG.DPY_EN_REG_IF [get_cells -hier $drv_handle]]
	if {[string match -nocase $dphy_en_reg_if "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,dphy-present" "" boolean
	}
	set dphy_lanes [get_property CONFIG.C_DPHY_LANES [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-lanes" $dphy_lanes int
	set en_csi_v2_0 [get_property CONFIG.C_EN_CSI_V2_0 [get_cells -hier $drv_handle]]
	set en_vcx [get_property CONFIG.C_EN_VCX [get_cells -hier $drv_handle]]
	set cmn_vc [get_property CONFIG.CMN_VC [get_cells -hier $drv_handle]]
	if {$en_csi_v2_0 == true && $en_vcx == true && [string match -nocase $cmn_vc "ALL"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vc" 16  int
	} elseif {$en_csi_v2_0 == false && [string match -nocase $cmn_vc "ALL"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vc" 4  int
	}
	if {[llength $en_csi_v2_0] == 0} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vc" $cmn_vc int
	}
	set cmn_pxl_format [get_property CONFIG.CMN_PXL_FORMAT [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,csi-pxl-format" $cmn_pxl_format string
	set csi_en_activelanes [get_property CONFIG.C_CSI_EN_ACTIVELANES [get_cells -hier $drv_handle]]
	if {[string match -nocase $csi_en_activelanes "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,en-active-lanes" "" boolean
	}
	set cmn_inc_vfb [get_property CONFIG.CMN_INC_VFB [get_cells -hier $drv_handle]]
	if {[string match -nocase $cmn_inc_vfb "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vfb" "" boolean
	}
	set cmn_num_pixels [get_property CONFIG.CMN_NUM_PIXELS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,ppc" "$cmn_num_pixels" int
	set axis_tdata_width [get_property CONFIG.AXIS_TDATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,axis-tdata-width" "$axis_tdata_width" int
}

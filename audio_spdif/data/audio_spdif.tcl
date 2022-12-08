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
	set compatible [append compatible " " "xlnx,spdif-2.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set spdif_mode [get_property CONFIG.SPDIF_Mode [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,spdif-mode" $spdif_mode int
	set cstatus_reg [get_property CONFIG.CSTATUS_REG [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,chstatus-reg" $cstatus_reg int
	set userdata_reg [get_property CONFIG.USERDATA_REG [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,userdata-reg" $userdata_reg int
	set axi_buffer_size [get_property CONFIG.AXI_BUFFER_Size [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,fifo-depth" $axi_buffer_size int
	set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "aud_clk_i"]
	if {[llength $clk_freq] != 0} {
		hsi::utils::add_new_dts_param "${node}" "clock-frequency" $clk_freq int
	}
}

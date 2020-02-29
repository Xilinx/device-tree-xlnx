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
	set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
	if {$topology == 0} {
	#scaler
		set name [get_property NAME [get_cells -hier $drv_handle]]
		set compatible [get_comp_str $drv_handle]
		set compatible [append compatible " " "xlnx,vpss-scaler-2.2 xlnx,v-vpss-scaler-2.2 xlnx,vpss-scaler"]
		set_drv_prop $drv_handle compatible "$compatible" stringlist
		set ip [get_cells -hier $drv_handle]
		set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,csc-enable-window" $csc_enable_window string
		set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,topology" $topology int
		set v_scaler_phases [get_property CONFIG.C_V_SCALER_PHASES [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,v-scaler-phases" $v_scaler_phases int
		set v_scaler_taps [get_property CONFIG.C_V_SCALER_TAPS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,v-scaler-taps" $v_scaler_taps int
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-vert-taps" $v_scaler_taps int
		set h_scaler_phases [get_property CONFIG.C_H_SCALER_PHASES [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,h-scaler-phases" $h_scaler_phases int
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-num-phases" $h_scaler_phases int
		set h_scaler_taps [get_property CONFIG.C_H_SCALER_TAPS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,h-scaler-taps" $h_scaler_taps int
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-hori-taps" $h_scaler_taps int
		set max_cols [get_property CONFIG.C_MAX_COLS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-width" $max_cols int
		set max_rows [get_property CONFIG.C_MAX_ROWS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-height" $max_rows int
		set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,samples-per-clk" $samples_per_clk int
		hsi::utils::add_new_dts_param "${node}" "xlnx,pix-per-clk" $samples_per_clk int
		set scaler_algo [get_property CONFIG.C_SCALER_ALGORITHM [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,scaler-algorithm" $scaler_algo int
		set enable_csc [get_property CONFIG.C_ENABLE_CSC [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,enable-csc" $enable_csc string
		set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,colorspace-support" $color_support int
		set use_uram [get_property CONFIG.C_USE_URAM [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,use-uram" $use_uram int
		set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,video-width" $max_data_width int
	}
	if {$topology == 3} {
	#CSC
		set name [get_property NAME [get_cells -hier $drv_handle]]
		set compatible [get_comp_str $drv_handle]
		set compatible [append compatible " " "xlnx,vpss-csc xlnx,v-vpss-csc"]
		set_drv_prop $drv_handle compatible "$compatible" stringlist
		set ip [get_cells -hier $drv_handle]
		set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,topology" $topology int
		set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,colorspace-support" $color_support int
		set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,csc-enable-window" $csc_enable_window string
		set max_cols [get_property CONFIG.C_MAX_COLS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-width" $max_cols int
		set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,video-width" $max_data_width int
		set max_rows [get_property CONFIG.C_MAX_ROWS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-height" $max_rows int
		set num_video_comp [get_property CONFIG.C_NUM_VIDEO_COMPONENTS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-video-components" $num_video_comp int
		set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,samples-per-clk" $samples_per_clk int
		set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,topology" $topology int
		set use_uram [get_property CONFIG.C_USE_URAM [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,use-uram" $use_uram int
	}
}

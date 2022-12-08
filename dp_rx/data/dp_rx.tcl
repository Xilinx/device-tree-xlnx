#
# (C) Copyright 2020-2022 Xilinx, Inc.
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
	set audio_channels [get_property CONFIG.AUDIO_CHANNELS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,audio-channels" $audio_channels int
	set audio_enable [get_property CONFIG.AUDIO_ENABLE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,audio-enable" $audio_enable int
	set bits_per_color [get_property CONFIG.BITS_PER_COLOR [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,bits-per-color" $bits_per_color int
	set hdcp22_enable [get_property CONFIG.HDCP22_ENABLE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp22-enable" $hdcp22_enable int
	set hdcp_enable [get_property CONFIG.HDCP_ENABLE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp-enable" $hdcp_enable int
	set include_fec_ports [get_property CONFIG.INCLUDE_FEC_PORTS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,include-fec-ports" $include_fec_ports int
	set lane_count [get_property CONFIG.LANE_COUNT [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,lane-count" $lane_count int
	set link_rate [get_property CONFIG.LINK_RATE [get_cells -hier $drv_handle]]
	set link_rate [expr {${link_rate} * 1000}]
	set link_rate [expr int ($link_rate)]
	hsi::utils::add_new_dts_param "${node}" "xlnx,linkrate" $link_rate int
	set mode [get_property CONFIG.MODE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mode" $mode int
	set num_streams [get_property CONFIG.NUM_STREAMS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,num-streams" $num_streams int
	set phy_data_width [get_property CONFIG.PHY_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,phy-data-width" $phy_data_width int
	set pixel_mode [get_property CONFIG.PIXEL_MODE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,pixel-mode" $pixel_mode int
	set sim_mode [get_property CONFIG.SIM_MODE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,sim-mode" $sim_mode string
	set video_interface [get_property CONFIG.VIDEO_INTERFACE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,video-interface" $video_interface int
}


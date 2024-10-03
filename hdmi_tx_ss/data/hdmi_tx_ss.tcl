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
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "v_hdmi_tx_ss"]} {
		set compatible [append compatible " " "xlnx,v-hdmi-tx-ss-3.1"]
	}
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set input_pixels_per_clock [get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,input-pixels-per-clock" $input_pixels_per_clock hexint
	set max_bits_per_component [get_property CONFIG.C_MAX_BITS_PER_COMPONENT [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-bits-per-component" $max_bits_per_component hexint
	set vid_interface [get_property CONFIG.C_VID_INTERFACE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,vid-interface" $vid_interface hexint

	set max_frl_rate [get_property CONFIG.C_MAX_FRL_RATE [get_cells -hier $drv_handle]]
	if {[llength $max_frl_rate]} {
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-frl-rate" $max_frl_rate hextint
	}

	set phy_names ""
	set phys ""
	set link_data0 [get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA0_OUT"]
	set link_data1 [get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA1_OUT"]
	set link_data2 [get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA2_OUT"]
	set link_data3 [get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA3_OUT"]
	if {[llength $link_data0]} {
		set ip_mem_handles [hsi::utils::get_ip_mem_ranges $link_data0]
		if {[llength $ip_mem_handles]} {
			set link_data0_inst $link_data0
			set link_data0 [get_property IP_NAME $link_data0]
			if {[string match -nocase $link_data0 "vid_phy_controller"] || [string match -nocase $link_data0 "hdmi_gt_controller"] || [string match -nocase $link_data0 "v_hdmi_phy1"]} {
				append phy_names " " "hdmi-phy0"
				if {[llength $link_data1]} {
					append phys  "${link_data0_inst}txphy_lane0 0 1 1 1>,"
				} else {
					append phys  "${link_data0_inst}txphy_lane0 0 1 1 1"
				}
			}
		}
	} else {
		dtg_warning "connected stream of LINK_DATA0_IN is NULL...check the design"
	}

	if {[llength $link_data1]} {
		set ip_mem_handles [hsi::utils::get_ip_mem_ranges $link_data1]
		if {[llength $ip_mem_handles]} {
			set link_data1_inst $link_data1
			set link_data1 [get_property IP_NAME $link_data1]
			if {[string match -nocase $link_data1 "vid_phy_controller"] || [string match -nocase $link_data1 "hdmi_gt_controller"] || [string match -nocase $link_data1 "v_hdmi_phy1"]} {
				append phy_names " " "hdmi-phy1"
				if {[llength $link_data2]} {
					append phys  " <&${link_data1_inst}txphy_lane1 0 1 1 1>,"
				} else {
					append phys  " <&${link_data1_inst}txphy_lane1 0 1 1 1"
				}
			}
		}
	} else {
		dtg_warning "Connected stream of LINK_DATA1_IN is NULL...check the design"
	}

	if {[llength $link_data2]} {
		set ip_mem_handles [hsi::utils::get_ip_mem_ranges $link_data2]
		if {[llength $ip_mem_handles]} {
			set link_data2_inst $link_data2
			set link_data2 [get_property IP_NAME $link_data2]
			if {[string match -nocase $link_data2 "vid_phy_controller"] || [string match -nocase $link_data2 "hdmi_gt_controller"] || [string match -nocase $link_data2 "v_hdmi_phy1"]} {
				append phy_names " " "hdmi-phy2"
				if {[llength $link_data3]} {
					append phys  " <&${link_data2_inst}txphy_lane2 0 1 1 1>,"
				} else {
					append phys  " <&${link_data2_inst}txphy_lane2 0 1 1 1"
				}
			}
		}
	} else {
		dtg_warning "Connected stream of LINK_DATA2_IN is NULL...check the design"
	}

	if {[llength $link_data3]} {
		set ip_mem_handles [hsi::utils::get_ip_mem_ranges $link_data3]
		if {[llength $ip_mem_handles]} {
			set link_data3_inst $link_data3
			set link_data3 [get_property IP_NAME $link_data3]
			if {[string match -nocase $link_data3 "vid_phy_controller"] || [string match -nocase $link_data3 "hdmi_gt_controller"] || [string match -nocase $link_data3 "v_hdmi_phy1"]} {
				append phy_names " " "hdmi-phy3"
				append phys " <&${link_data3_inst}txphy_lane3 0 1 1 1"
			}
		}
	} else {
		dtg_warning "Connected stream of LINK_DATA3_IN is NULL...check the design"
	}

	if {![string match -nocase $phy_names ""]} {
		hsi::utils::add_new_dts_param "$node" "phy-names" $phy_names stringlist
	}
	if {![string match -nocase $phys ""]} {
		hsi::utils::add_new_dts_param "$node" "phys" $phys reference
	}
	set include_hdcp_1_4 [get_property CONFIG.C_INCLUDE_HDCP_1_4 [get_cells -hier $drv_handle]]
	if {[string match -nocase $include_hdcp_1_4 "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,include-hdcp-1-4" "" boolean
	}
	set include_hdcp_2_2 [get_property CONFIG.C_INCLUDE_HDCP_2_2 [get_cells -hier $drv_handle]]
	if {[string match -nocase $include_hdcp_2_2 "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,include-hdcp-2-2" "" boolean
	}
	if {[string match -nocase $include_hdcp_1_4 "true"] || [string match -nocase $include_hdcp_2_2 "true"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp-authenticate" 0x1 int
		hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp-encrypt" 0x1 int
	}
	set audio_in_connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "AUDIO_IN"]
	if {[llength $audio_in_connect_ip] != 0} {
		set audio_in_connect_ip_type [get_property IP_NAME $audio_in_connect_ip]
		if {[string match -nocase $audio_in_connect_ip_type "axis_switch"]} {
			set connected_ip [hsi::utils::get_connected_stream_ip $audio_in_connect_ip "S00_AXIS"]
			if {[llength $connected_ip] != 0} {
				hsi::utils::add_new_dts_param "$node" "xlnx,snd-pcm" $connected_ip reference
				hsi::utils::add_new_dts_param "${node}" "xlnx,audio-enabled" "" boolean
			}
		} elseif {[string match -nocase $audio_in_connect_ip_type "audio_formatter"]} {
			hsi::utils::add_new_dts_param "$node" "xlnx,snd-pcm" $audio_in_connect_ip reference
			hsi::utils::add_new_dts_param "${node}" "xlnx,audio-enabled" "" boolean
		}
	} else {
		dtg_warning "$drv_handle pin AUDIO_IN is not connected... check your design"
	}
	set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier [get_cells -hier $drv_handle]] "acr_cts"]]
	foreach pin $pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			if {[string match -nocase "[get_property IP_NAME $sink_periph]" "hdmi_acr_ctrl"]} {
				hsi::utils::add_new_dts_param "$node" "xlnx,xlnx-hdmi-acr-ctrl" $sink_periph reference
			}
		} else {
			dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
		}
	}
}

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
	set compatible [append compatible " " "xlnx,v-hdmi-tx-ss-3.1"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ip [get_cells -hier $drv_handle]
	set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $ip "acr_n"]]]
	foreach pin $pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [get_property IP_NAME $sink_periph]
			if {[string match -nocase $sink_ip "hdmi_acr_ctrl"]} {
				hsi::utils::add_new_dts_param "$node" "xlnx,xlnx-hdmi-acr-ctrl" $sink_periph reference
			}
		} else {
			dtg_warning "$drv_handle:peripheral is NULL for the $pin $sink_periph"
		}
	}
	set ports_node [add_or_get_dt_node -n "ports" -l hdmitx_ports -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_IN"]
	if {![llength $connected_ip]} {
		dtg_warning "$drv_handle pin VIDEO_IN is not connected... check your design"
	}
	foreach connect_ip $connected_ip {
		if {[llength $connect_ip] != 0} {
			set connected_ip_type [get_property IP_NAME $connect_ip]
			if {[string match -nocase $connected_ip_type "system_ila"]} {
				continue
			}
			if {[string match -nocase $connected_ip_type "v_mix"]} {
				set hdmi_port_node [add_or_get_dt_node -n "port" -l encoder_hdmi_port -u 0 -p $ports_node]
				hsi::utils::add_new_dts_param "$hdmi_port_node" "reg" 0 int
				set hdmi_encoder_node [add_or_get_dt_node -n "endpoint" -l hdmi_encoder -p $hdmi_port_node]
				hsi::utils::add_new_dts_param "$hdmi_encoder_node" "remote-endpoint" mixer_crtc reference
			}
			set input_pixels_per_clock [get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [get_cells -hier $drv_handle]]
			hsi::utils::add_new_dts_param "${node}" "xlnx,input-pixels-per-clock" $input_pixels_per_clock int
			set max_bits_per_component [get_property CONFIG.C_MAX_BITS_PER_COMPONENT [get_cells -hier $drv_handle]]
			hsi::utils::add_new_dts_param "${node}" "xlnx,max-bits-per-component" $max_bits_per_component int
			if {[string match -nocase $connected_ip_type "v_frmbuf_rd"]} {
				set hdmi_port_node [add_or_get_dt_node -n "port" -l encoder_hdmi_port -u 0 -p $ports_node]
				hsi::utils::add_new_dts_param "$hdmi_port_node" "reg" 0 int
				set hdmi_encoder_node [add_or_get_dt_node -n "endpoint" -l hdmi_encoder -p $hdmi_port_node]
				hsi::utils::add_new_dts_param "$hdmi_encoder_node" "remote-endpoint" pl_disp_crtc reference
				set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
				if {$dt_overlay} {
					set bus_node "overlay2"
				} else {
					set bus_node "amba_pl"
				}
				set dts_file [current_dt_tree]
				set drm_pl_disp_drv_count [hsi::utils::get_os_parameter_value "drm_pl_disp_drv_count"]
				if { [llength $drm_pl_disp_drv_count] == 0 } {
					set drm_pl_disp_drv_count 0
				}
				if {$drm_pl_disp_drv_count != 0} {
					dtg_warning "Design might consists of two similar pipelines...user may need to add the input and output port"
					continue
				}
				set pl_display [add_or_get_dt_node -n "drm-pl-disp-drv" -l "v_pl_disp" -d $dts_file -p $bus_node]
				incr drm_pl_disp_drv_count
				hsi::utils::set_os_parameter_value "drm_pl_disp_drv_count" $drm_pl_disp_drv_count
				hsi::utils::add_new_dts_param "${pl_display}" "/* Fill the fields xlnx,vformat based on user requirement */" "" comment
				hsi::utils::add_new_dts_param $pl_display "compatible" "xlnx,pl-disp" string
				hsi::utils::add_new_dts_param $pl_display "dmas" "$connect_ip 0" reference
				hsi::utils::add_new_dts_param $pl_display "dma-names" "dma0" string
				hsi::utils::add_new_dts_param $pl_display "xlnx,vformat" "YUYV" string
				set pl_display_port_node [add_or_get_dt_node -n "port" -l pl_display_port -u 0 -p $pl_display]
				hsi::utils::add_new_dts_param "$pl_display_port_node" "reg" 0 int
				set pl_disp_crtc_node [add_or_get_dt_node -n "endpoint" -l pl_disp_crtc -p $pl_display_port_node]
				hsi::utils::add_new_dts_param "$pl_disp_crtc_node" "remote-endpoint" hdmi_encoder reference
			}
			if {[string match -nocase $connected_ip_type "axis_register_slice"]} {
				set axis_reg_slice_ip [hsi::utils::get_connected_stream_ip $connect_ip "S_AXIS"]
				set axis_reg_slice_connected_out_ip_type [get_property IP_NAME $axis_reg_slice_ip]
				if {[string match -nocase $axis_reg_slice_connected_out_ip_type "v_frmbuf_rd"]} {
					set hdmi_port_node [add_or_get_dt_node -n "port" -l encoder_hdmi_port -u 0 -p $ports_node]
					hsi::utils::add_new_dts_param "$hdmi_port_node" "reg" 0 int
					set hdmi_encoder_node [add_or_get_dt_node -n "endpoint" -l hdmi_encoder -p $hdmi_port_node]
					hsi::utils::add_new_dts_param "$hdmi_encoder_node" "remote-endpoint" dmaengine_crtc reference
					set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
					if {$dt_overlay} {
						set bus_node "overlay2"
					} else {
						set bus_node "amba_pl"
					}
					set dts_file [current_dt_tree]
					set drm_dmaengine_drv_count [hsi::utils::get_os_parameter_value "drm_dmaengine_drv_count"]
					if { [llength $drm_dmaengine_drv_count] == 0 } {
						set drm_dmaengine_drv_count 0
					}
					if {$drm_dmaengine_drv_count != 0} {
						dtg_warning "Design might consists of two similar pipelines...user may need to add the input and output port"
						continue
					}
					set pl_display [add_or_get_dt_node -n "drm-dmaengine-drv" -l "v_drm_dmaengine_drv" -d $dts_file -p $bus_node]
					incr drm_dmaengine_drv_count
					hsi::utils::set_os_parameter_value "drm_dmaengine_drv_count" $drm_dmaengine_drv_count
					hsi::utils::add_new_dts_param "${pl_display}" "/* Fill the fields xlnx,vformat based on user requirement */" "" comment
					hsi::utils::add_new_dts_param $pl_display "compatible" "xlnx,pl-disp" string
					hsi::utils::add_new_dts_param $pl_display "dmas" "$axis_reg_slice_ip 0" reference
					hsi::utils::add_new_dts_param $pl_display "dma-names" "dma0" string
					hsi::utils::add_new_dts_param $pl_display "xlnx,vformat" "YUYV" string
					hsi::utils::add_new_dts_param "$pl_display" "#address-cells" 1 int
					hsi::utils::add_new_dts_param "$pl_display" "#size-cells" 0 int
					set pl_display_port_node [add_or_get_dt_node -n "port" -l dmaengine_port -u 0 -p $pl_display]
					hsi::utils::add_new_dts_param "$pl_display_port_node" "reg" 0 int
					set pl_disp_crtc_node [add_or_get_dt_node -n "endpoint" -l dmaengine_crtc -p $pl_display_port_node]
					hsi::utils::add_new_dts_param "$pl_disp_crtc_node" "remote-endpoint" hdmi_encoder reference
				}
			}
		}
	}
	set phy_names ""
	set phys ""
	set link_data0 [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA0_OUT"]
	if {[llength $link_data0]} {
		set link_data0 [get_property IP_NAME $link_data0]
		if {[string match -nocase $link_data0 "vid_phy_controller"]} {
			append phy_names " " "hdmi-phy0"
			append phys  "vphy_lane0 0 1 1 1>,"
		}
	} else {
		dtg_warning "connected stream of LINK_DATA0_IN is NULL...check the design"
	}

	set link_data1 [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA1_OUT"]
	if {[llength $link_data1]} {
		set link_data1 [get_property IP_NAME $link_data1]
		if {[string match -nocase $link_data1 "vid_phy_controller"]} {
			append phy_names " " "hdmi-phy1"
			append phys  " <&vphy_lane1 0 1 1 1>,"
		}
	} else {
		dtg_warning "Connected stream of LINK_DATA1_IN is NULL...check the design"
	}

	set link_data2 [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA2_OUT"]
	if {[llength $link_data2]} {
		set link_data2 [get_property IP_NAME $link_data2]
		if {[string match -nocase $link_data2 "vid_phy_controller"]} {
			append phy_names " " "hdmi-phy2"
			append phys " <&vphy_lane2 0 1 1 1"
		}
	} else {
		dtg_warning "Connected stream of LINK_DATA2_IN is NULL...check the design"
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
	set audio_in_connect_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "AUDIO_IN"]
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
}

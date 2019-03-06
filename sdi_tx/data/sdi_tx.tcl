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
	set compatible [append compatible " " "xlnx,sdi-tx"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set exdes_board [get_property CONFIG.C_EXDES_BOARD [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,exdes-board" $exdes_board string
	set exdes_config [get_property CONFIG.C_EXDES_CONFIG [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,exdes-config" $exdes_config string
	set adv_features [get_property CONFIG.C_INCLUDE_ADV_FEATURES [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,include-adv-features" $adv_features string
	set axilite [get_property CONFIG.C_INCLUDE_AXILITE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,include-axilite" $axilite string
	set edh [get_property CONFIG.C_INCLUDE_EDH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,include-edh" $edh string
	set linerate [get_property CONFIG.C_LINE_RATE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,line-rate" $linerate string
	set pixelclock [get_property CONFIG.C_PIXELS_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,pixels-per-clock" $pixelclock string
	set video_intf [get_property CONFIG.C_VIDEO_INTF [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,video-intf" $video_intf string
	set ports_node [add_or_get_dt_node -n "ports" -l sditx_ports -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_IN"]
	if {![llength $connected_ip]} {
		dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
	}
	if {[llength $connected_ip]} {
		set connected_ip_type [get_property IP_NAME $connected_ip]
		set ip_type ""
		set ip ""
		if {[string match -nocase $connected_ip_type "axis_subset_converter"]} {
			set ip [hsi::utils::get_connected_stream_ip $connected_ip "S_AXIS"]
			set ip_type [get_property IP_NAME $ip]
			if {[string match -nocase $ip_type "v_proc_ss"]} {
				hsi::utils::add_new_dts_param "$node" "xlnx,vpss" $ip reference
			}
		}
		if {[string match -nocase $connected_ip_type "v_proc_ss"]} {
			hsi::utils::add_new_dts_param "$node" "xlnx,vpss" $connected_ip reference
		}
		if {[string match -nocase $connected_ip_type "v_frmbuf_rd"] || [string match -nocase $connected_ip_type "v_proc_ss"]|| [string match -nocase $ip_type "v_proc_ss"]} {
			set sdi_port_node [add_or_get_dt_node -n "port" -l encoder_sdi_port -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "$sdi_port_node" "reg" 0 int
			set sdi_encoder_node [add_or_get_dt_node -n "endpoint" -l sdi_encoder -p $sdi_port_node]
			hsi::utils::add_new_dts_param "$sdi_encoder_node" "remote-endpoint" pl_disp_crtc reference
			set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
			if {$dt_overlay} {
				set bus_node "overlay2"
			} else {
				set bus_node "amba_pl"
			}
			set dts_file [current_dt_tree]
			set pl_display [add_or_get_dt_node -n "drm-pl-disp-drv" -l "v_pl_disp" -d $dts_file -p $bus_node]
			hsi::utils::add_new_dts_param $pl_display "compatible" "xlnx,pl-disp" string
			if {[string match -nocase $ip_type "v_proc_ss"]} {
				set connect_ip [hsi::utils::get_connected_stream_ip $ip "S_AXIS"]
				set connected_ip [hsi::utils::get_connected_stream_ip $connect_ip "S_AXIS"]
			}
			if {[string match -nocase $connected_ip_type "v_proc_ss"]} {
				set connected_ip [hsi::utils::get_connected_stream_ip $connected_ip "S_AXIS"]
			}
			hsi::utils::add_new_dts_param $pl_display "dmas" "$connected_ip 0" reference
			hsi::utils::add_new_dts_param $pl_display "dma-names" "dma0" string
			hsi::utils::add_new_dts_param "${pl_display}" "/* Fill the field xlnx,vformat based on user requirement */" "" comment
			hsi::utils::add_new_dts_param $pl_display "xlnx,vformat" "YUYV" string
			set pl_display_port_node [add_or_get_dt_node -n "port" -l pl_display_port -u 0 -p $pl_display]
			hsi::utils::add_new_dts_param "$pl_display_port_node" "reg" 0 int
			set pl_disp_crtc_node [add_or_get_dt_node -n "endpoint" -l pl_disp_crtc -p $pl_display_port_node]
			hsi::utils::add_new_dts_param "$pl_disp_crtc_node" "remote-endpoint" sdi_encoder reference
		}
		if {[string match -nocase $connected_ip_type "v_mix"] || [string match -nocase $ip_type "v_mix"]} {
			set sdi_port_node [add_or_get_dt_node -n "port" -l encoder_sdi_port -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "$sdi_port_node" "reg" 0 int
			set sdi_encoder_node [add_or_get_dt_node -n "endpoint" -l sdi_encoder -p $sdi_port_node]
			hsi::utils::add_new_dts_param "$sdi_encoder_node" "remote-endpoint" mixer_crtc reference
		}
	}
	set audio_connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "SDI_TX_ANC_DS_OUT"]
	if {[llength $audio_connected_ip] != 0} {
		set audio_connected_ip_type [get_property IP_NAME $audio_connected_ip]
		if {[string match -nocase $audio_connected_ip_type "v_uhdsdi_audio"]} {
			set sdi_audio_port [add_or_get_dt_node -n "port" -l sdi_audio_port -u 1 -p $ports_node]
			hsi::utils::add_new_dts_param "$sdi_audio_port" "reg" 1 int
			set sdi_audio_node [add_or_get_dt_node -n "endpoint" -l sdi_audio_sink_port -p $sdi_audio_port]
			hsi::utils::add_new_dts_param "$sdi_audio_node" "remote-endpoint" sditx_audio_embed_src reference
		}
	} else {
		dtg_warning "$drv_handle:connected ip for audio port pin SDI_TX_ANC_DS_OUT is NULL"
	}
}

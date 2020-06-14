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
	set compatible [append compatible " " "xlnx,v-uhdsdi-audio-2.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set connected_embed_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "SDI_EMBED_ANC_DS_IN"]
	if {[llength $connected_embed_ip] != 0} {
		set connected_embed_ip_type [get_property IP_NAME $connected_embed_ip]
		if {[string match -nocase $connected_embed_ip_type "v_smpte_uhdsdi_tx_ss"]} {
			set sdi_av_port [add_or_get_dt_node -n "port" -l sdi_av_port -u 0 -p $node]
			hsi::utils::add_new_dts_param "$sdi_av_port" "reg" 0 int
			set sdi_embed_node [add_or_get_dt_node -n "endpoint" -l sditx_audio_embed_src -p $sdi_av_port]
			hsi::utils::add_new_dts_param "$sdi_embed_node" "remote-endpoint" sdi_audio_sink_port reference
		}
	} else {
		dtg_warning "$drv_handle connected_ip is NULL for the pin SDI_EMBED_ANC_DS_IN"
	}
	set connected_extract_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "SDI_EXTRACT_ANC_DS_IN"]
	if {[llength $connected_extract_ip] != 0} {
		hsi::utils::add_new_dts_param "$node" "xlnx,sdi-rx-video" $connected_extract_ip reference
	} else {
		dtg_warning "$drv_handle connected_extract_ip is NULL for the pin SDI_EXTRACT_ANC_DS_IN"
	}
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_DATA"]
	if {[llength $connected_ip] != 0} {
		hsi::utils::add_new_dts_param "$node" "xlnx,snd-pcm" $connected_ip reference
	} else {
		dtg_warning "$drv_handle connected ip is NULL for the pin S_AXIS_DATA"
	}
	set connect_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS_DATA"]
	if {[llength $connect_ip] != 0} {
		hsi::utils::add_new_dts_param "$node" "xlnx,snd-pcm" $connect_ip reference
	} else {
		dtg_warning "$drv_handle connected ip is NULL for the pin M_AXIS_DATA"
	}
}

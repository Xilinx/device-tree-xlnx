#
# (C) Copyright 2020-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

# If there are multiple dp_rx nodes, the bindings to the corresponding
# sub nodes (edid, vidphy, ..) can be specified by putting them
# into the same hierarchical subblock.
# This way their names will have common prefixes.
# 'find_best_match' is used to return the sub node whose name matches
# best the name of the dp_rx node

proc common_prefix {a b} {
	set res {}
	foreach i [split $a {}] j [split $b {}] {
		if {$i eq $j} {append res $i} else break
	}
	set res
}

proc find_best_match {dp cells} {
	set idx 0
	set max_len 0
	set nr 0
	foreach cell $cells {
		set sub [common_prefix $cell $dp]
		set len [string length $sub]
		if {$len > $max_len} {
			set max_len $len
			set idx $nr
		}
	        incr nr
	}
	set res [lindex $cells $idx]
}

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
	lappend compatible "xlnx,v-dp-rxss-3.0" "xlnx,v-dp-rxss-3.1"
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set audio_enable [get_property CONFIG.AUDIO_ENABLE [get_cells -hier $drv_handle]]
	if {$audio_enable == 1} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,audio-enable" "" boolean
		set audio_channels [get_property CONFIG.AUDIO_CHANNELS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,audio-channels" $audio_channels int
	}
	set bits_per_color [get_property CONFIG.BITS_PER_COLOR [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,bpc" $bits_per_color int
	set hdcp22_enable [get_property CONFIG.HDCP22_ENABLE [get_cells -hier $drv_handle]]
	if {$hdcp22_enable == 1} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp22-enable" "" boolean
	}
	set hdcp_enable [get_property CONFIG.HDCP_ENABLE [get_cells -hier $drv_handle]]
	if {$hdcp_enable == 1} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp-enable" "" boolean
	}
	set hdcp_keymngmt [get_cells -hier -filter IP_NAME==hdcp_keymngmt_blk]
	if {[llength $hdcp_keymngmt]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp1x_keymgmt" [lindex $hdcp_keymngmt 0] reference
	}

	set versal_gt [get_property CONFIG.C_VERSAL [get_cells -hier $drv_handle]]
	if {$versal_gt == 1} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,versal-gt" "" boolean
	}
	set include_fec_ports [get_property CONFIG.INCLUDE_FEC_PORTS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,include-fec-ports" $include_fec_ports int
	set edid_ip [find_best_match $node [get_cells -hier -filter IP_NAME==vid_edid]]
	if {[llength $edid_ip]} {
		set baseaddr_dp_rx [get_property CONFIG.C_BASEADDR [get_cells -hier $drv_handle]]
		set highaddr_dp_rx [get_property CONFIG.C_HIGHADDR [get_cells -hier $drv_handle]]
		set baseaddr [get_property CONFIG.C_BASEADDR [get_cells -hier $edid_ip]]
		set highaddr [get_property CONFIG.C_HIGHADDR [get_cells -hier $edid_ip]]
		set reg_val_0 [generate_reg_property $baseaddr_dp_rx $highaddr_dp_rx]
		set updat [lappend updat $reg_val_0]
		set reg_val_1 [generate_reg_property $baseaddr $highaddr]
		set updat [lappend updat $reg_val_1]
		set reg_val [lindex $updat 0]
		append reg_val ">, <[lindex $updat 1]"
		set_drv_prop $drv_handle reg "$reg_val" hexint
	}
	lappend reg_names "dp_base" "edid_base"
	hsi::utils::add_new_dts_param "${node}" "reg-names" $reg_names stringlist
	if {$versal_gt == 1} {
		lappend phy_names "dp-gtquad"
	} else {
		lappend phy_names "dp-phy0" "dp-phy1" "dp-phy2" "dp-phy3"
	}
	hsi::utils::add_new_dts_param "${node}" "phy-names" $phy_names stringlist
	set lane_count [get_property CONFIG.LANE_COUNT [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,lane-count" $lane_count int
	hsi::utils::add_new_dts_param "${node}" "xlnx,dp-retimer" "xfmc" reference
	set i 0
	set updat ""
	while {$i < $lane_count} {
		set rxpinname "s_axis_lnk_rx_lane$i"
		set channelip [get_connected_stream_ip [get_cells -hier $drv_handle] $rxpinname]
		if {[llength $channelip] && [llength [hsi::utils::get_ip_mem_ranges $channelip]]} {
			set phy_s "${channelip}rxphy_lane${i} 0 1 1 0"
			set clocks [lappend clocks $phy_s]
			set updat  [lappend updat $phy_s]
		}
		incr i
	}
	set len [llength $updat]
	switch $len {
		"1" {
			set refs [lindex $updat 0]
			hsi::utils::add_new_dts_param "${node}" "phys" "$refs" reference
		}
		"2" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]"
			hsi::utils::add_new_dts_param "${node}" "phys" "$refs" reference
		}
		"3" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
			hsi::utils::add_new_dts_param "${node}" "phys" "$refs" reference
		}
		"4" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
			hsi::utils::add_new_dts_param "${node}" "phys" "$refs" reference
		}
	}
	if {$versal_gt == 1} {
		set rxpinname "s_axis_lnk_rx_lane0"
		set channelip [get_connected_stream_ip [get_cells -hier $drv_handle] $rxpinname]

		set gtpinname "GT_RX0"
		set gtip [get_connected_stream_ip [get_cells -hier $channelip] $gtpinname]

		if {[llength $gtip] && [llength [hsi::utils::get_ip_mem_ranges $gtip]]} {
			set phy_s "${gtip}rxphy_lane0 0 1 1 0"
			set updat  [lappend updat $phy_s]
			set refs [lindex $updat 0]
			hsi::utils::add_new_dts_param "${node}" "phys" "$refs" reference
		}
	}
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
	set vid_phy_ctlr [find_best_match $node [get_cells -hier -filter IP_NAME==vid_phy_controller]]
	if {[llength $vid_phy_ctlr]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vidphy" $vid_phy_ctlr reference
	}
	set ports_node [add_or_get_dt_node -n "ports" -l dprx_ports$drv_handle -p ${node}]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set port0_node [add_or_get_dt_node -n "port" -u 0 -l dprx_port$drv_handle -p $ports_node]
	hsi::utils::add_new_dts_param "$port0_node" "reg" 0 int
	hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-format" 0 int
	hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-width" 8 int

	set dprxip [get_connected_stream_ip [get_cells -hier $drv_handle] "m_axis_video_stream1"]
	foreach ip $dprxip {
		if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
			continue
		}
		set intfpins [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
		set ip_mem_handles [hsi::utils::get_ip_mem_ranges $ip]
		if {[llength $ip_mem_handles]} {
			set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
			set dp_rx_node [add_or_get_dt_node -n "endpoint" -l dprx_out$drv_handle -p $port0_node]
			gen_endpoint $drv_handle "dprx_out$drv_handle"
			if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
				hsi::utils::add_new_dts_param "$dp_rx_node" "remote-endpoint" $ip$drv_handle reference
				gen_remoteendpoint $drv_handle $ip$drv_handle
				gen_frmbuf_wr_node $ip $drv_handle
			} else {
				hsi::utils::add_new_dts_param "$dp_rx_node" "remote-endpoint" $ip reference
				gen_remoteendpoint $drv_handle $ip$drv_handle
			}
		} else {
			set connectip [get_connect_ip $ip $intfpins]
			if {[llength $connectip]} {
				set sdi_rx_node [add_or_get_dt_node -n "endpoint" -l dprx_out$drv_handle -p $port0_node]
				gen_endpoint $drv_handle "dprx_out$drv_handle"
				hsi::utils::add_new_dts_param "$dp_rx_node" "remote-endpoint" $connectip$drv_handle reference
				gen_remoteendpoint $drv_handle $connectip$drv_handle
				if {[string match -nocase [get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
					gen_frmbuf_wr_node $connectip $drv_handle
				}
			}
		}
	}
}

proc gen_frmbuf_wr_node {outip drv_handle} {
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}
        set vcap [add_or_get_dt_node -n "vcap_dprx$drv_handle" -p $bus_node]
        hsi::utils::add_new_dts_param $vcap "compatible" "xlnx,video" string
        hsi::utils::add_new_dts_param $vcap "dmas" "$outip 0" reference
        hsi::utils::add_new_dts_param $vcap "dma-names" "port0" string
        set vcap_ports_node [add_or_get_dt_node -n "ports" -l vcap_ports$drv_handle -p $vcap]
        hsi::utils::add_new_dts_param "$vcap_ports_node" "#address-cells" 1 int
        hsi::utils::add_new_dts_param "$vcap_ports_node" "#size-cells" 0 int
        set vcap_port_node [add_or_get_dt_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node]
        hsi::utils::add_new_dts_param "$vcap_port_node" "reg" 0 int
        hsi::utils::add_new_dts_param "$vcap_port_node" "direction" input string
        set vcap_in_node [add_or_get_dt_node -n "endpoint" -l $outip$drv_handle -p $vcap_port_node]
        hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" dprx_out$drv_handle reference
}


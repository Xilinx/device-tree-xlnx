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
	lappend compatible "xlnx,v-dp-txss-3.1"
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set num_audio_channels [get_property CONFIG.Number_of_Audio_Channels [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,num-audio-channels" $num_audio_channels int
	set audio_enable [get_property CONFIG.AUDIO_ENABLE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,audio-enable" $audio_enable int
	set bits_per_color [get_property CONFIG.BITS_PER_COLOR [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,bpc" $bits_per_color int
	set hdcp22_enable [get_property CONFIG.HDCP22_ENABLE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp22-enable" $hdcp22_enable int
	set hdcp_enable [get_property CONFIG.HDCP_ENABLE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp-enable" $hdcp_enable int
	set include_fec_ports [get_property CONFIG.INCLUDE_FEC_PORTS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,include-fec-ports" $include_fec_ports int
	lappend reg_names "dp_base"
	hsi::utils::add_new_dts_param "${node}" "reg-names" $reg_names stringlist
	lappend phy_names "dp-phy0" "dp-phy1" "dp-phy2" "dp-phy3"
	hsi::utils::add_new_dts_param "${node}" "phy-names" $phy_names stringlist
	set lane_count [get_property CONFIG.LANE_COUNT [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-lanes" $lane_count int
	hsi::utils::add_new_dts_param "${node}" "xlnx,dp-retimer" "xfmc" reference
	set hdcp_keymngmt [get_cells -hier -filter IP_NAME==hdcp_keymngmt_blk]
	if {[llength $hdcp_keymngmt]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,hdcp1x-keymgmt" [lindex $hdcp_keymngmt 1] reference
	}
	set i 0
	set updat ""
	while {$i < $lane_count} {
		set txpinname "m_axis_lnk_tx_lane$i"
		set channelip [get_connected_stream_ip [get_cells -hier $drv_handle] $txpinname]
		if {[llength $channelip] && [llength [hsi::utils::get_ip_mem_ranges $channelip]]} {
			set phy_s "${channelip}txphy_lane${i} 0 1 1 1"
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
	set link_rate [get_property CONFIG.LINK_RATE [get_cells -hier $drv_handle]]
	set link_rate [expr {${link_rate} * 100000}]
	set link_rate [expr int ($link_rate)]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-link-rate" $link_rate int
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
	set vtcip [get_cells -hier -filter {IP_NAME == "v_tc"}]
	if {[llength $vtcip]} {
		set baseaddr [get_property CONFIG.C_BASEADDR [get_cells -hier $vtcip]]
		if {[llength $baseaddr]} {
			hsi::utils::add_new_dts_param "${node}" "xlnx,vtc-offset" "$baseaddr" int
		}
	}
	set ports_node [add_or_get_dt_node -n "ports" -l dptx_ports$drv_handle -p ${node}]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set port0_node [add_or_get_dt_node -n "port" -u 0 -l dptx_port$drv_handle -p $ports_node]
	hsi::utils::add_new_dts_param "$port0_node" "reg" 0 int
	set dptxip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video_stream1"]
	foreach ip $dptxip {
		if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
			continue
		}
		set intfpins [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
		set ip_mem_handles [hsi::utils::get_ip_mem_ranges $ip]
		if {[llength $ip_mem_handles]} {
			set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
			set dp_tx_node [add_or_get_dt_node -n "endpoint" -l dptx_out$drv_handle -p $ports_node]
			gen_endpoint $drv_handle "dptx_out$drv_handle"
			hsi::utils::add_new_dts_param "$dp_tx_node" "remote-endpoint" $ip$drv_handle reference
			gen_remoteendpoint $drv_handle $ip$drv_handle
			if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_rd"]} {
				gen_pl_disp_node $ip $drv_handle
			}
		} else {
			set connectip [get_connect_ip $ip $intfpins]
			if {[llength $connectip]} {
				set dp_tx_node [add_or_get_dt_node -n "endpoint" -l dptx_out$drv_handle -p $port_node]
				gen_endpoint $drv_handle "dptx_out$drv_handle"
				hsi::utils::add_new_dts_param "$dp_tx_node" "remote-endpoint" $connectip$drv_handle reference
				gen_remoteendpoint $drv_handle $connectip$drv_handle
				if {[string match -nocase [get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_rd"]} {
					gen_pl_disp_node $connectip $drv_handle
				}
			}
		}
		gen_xfmc_node
	}
}

proc gen_pl_disp_node {outip drv_handle} {
        set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
        if {$dt_overlay} {
                set bus_node "amba"
        } else {
                set bus_node "amba_pl"
        }
        set pl_disp [add_or_get_dt_node -n "drm-pl-disp-drv" -l "v_pl_disp" -p $bus_node]
        hsi::utils::add_new_dts_param $pl_disp "compatible" "xlnx,pl-disp" string
        hsi::utils::add_new_dts_param $pl_disp "dmas" "$outip 0" reference
        hsi::utils::add_new_dts_param $pl_disp "dma-names" "dma0" string
        hsi::utils::add_new_dts_param $pl_disp "xlnx,vformat" "YUYV" string
        set pl_port [add_or_get_dt_node -n "port" -l "pl_disp_port" -u 0 -p $pl_disp]
        hsi::utils::add_new_dts_param "$pl_port" "reg" 0 int
        set pl_disp_crtc [add_or_get_dt_node -n "endpoint" -l $outip$drv_handle -p $pl_port]
        hsi::utils::add_new_dts_param "$pl_disp_crtc" "remote-endpoint" dptx_out$drv_handle reference
}

#generate fmc card node as this is required when display port exits
proc gen_xfmc_node {} {
        set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
        if {$dt_overlay} {
                set bus_node "amba"
        } else {
                set bus_node "amba_pl"
        }
        set pl_disp [add_or_get_dt_node -n "xv_fmc" -l "xfmc" -p $bus_node]
        hsi::utils::add_new_dts_param $pl_disp "compatible" "xilinx-vfmc" string
}

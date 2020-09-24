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
	} elseif {$en_csi_v2_0 == true && $en_vcx == false && [string match -nocase $cmn_vc "ALL"]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vc" 4  int
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

	set ports_node [add_or_get_dt_node -n "ports" -l mipi_csi_ports$drv_handle -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set port_node [add_or_get_dt_node -n "port" -l mipi_csi_port0$drv_handle -u 0 -p $ports_node]
	hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
	hsi::utils::add_new_dts_param "${port_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format and video-width user needs to fill */" "" comment
	hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 12 int
	hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 8 int
	hsi::utils::add_new_dts_param "$port_node" "xlnx,cfa-pattern" rggb string

	set port1_node [add_or_get_dt_node -n "port" -l mipi_csi_port1$drv_handle -u 1 -p $ports_node]
	hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
	hsi::utils::add_new_dts_param "${port1_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format,video-width user needs to fill */" "" comment
	hsi::utils::add_new_dts_param "${port1_node}" "/* User need to add something like remote-endpoint=<&out> under the node csiss_in:endpoint */" "" comment
	hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 12 int
	hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" 8 int
	hsi::utils::add_new_dts_param "$port1_node" "xlnx,cfa-pattern" rggb string
	set csiss_rx_node [add_or_get_dt_node -n "endpoint" -l mipi_csi_in$drv_handle -p $port1_node]

	set outip [get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_OUT"]
	if {[llength $outip]} {
		if {[string match -nocase [get_property IP_NAME $outip] "axis_broadcaster"]} {
			set mipi_node [add_or_get_dt_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node]
			gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
			hsi::utils::add_new_dts_param "$mipi_node" "remote-endpoint" $outip$drv_handle reference
			gen_remoteendpoint $drv_handle "$outip$drv_handle"
		}
	}
	foreach ip $outip {
		if {[llength $ip]} {
			set intfpins [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $ip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
				set csi_rx_node [add_or_get_dt_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node]
				gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
				hsi::utils::add_new_dts_param "$csi_rx_node" "remote-endpoint" $ip$drv_handle reference
				gen_remoteendpoint $drv_handle $ip$drv_handle
				if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
                                        gen_frmbuf_node $ip $drv_handle
                                }
			} else {
				set connectip [get_connect_ip $ip $intfpins]
				if {[llength $connectip]} {
					set csi_rx_node [add_or_get_dt_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node]
					gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
					hsi::utils::add_new_dts_param "$csi_rx_node" "remote-endpoint" $connectip$drv_handle reference
					gen_remoteendpoint $drv_handle $connectip$drv_handle
					if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
						gen_frmbuf_node $connectip $drv_handle
					}
				}
			}
		}
	}

}

proc gen_frmbuf_node {outip drv_handle} {
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "overlay2"
	} else {
		set bus_node "amba_pl"
	}
        set vcap [add_or_get_dt_node -n "vcap_$drv_handle" -p $bus_node]
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
        hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" mipi_csirx_out$drv_handle reference
}

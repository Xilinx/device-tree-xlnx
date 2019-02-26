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
	set compatible [append compatible " " "xlnx,mipi-csi2-rx-subsystem-4.0"]
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
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_OUT"]
	if {![llength $connected_ip]} {
		dtg_warning "$drv_handle VIDEO_OUT pin is not connected...check your design"
	}
	foreach connect_ip $connected_ip {
		if {[llength $connect_ip] != 0} {
			set connected_ip_type [get_property IP_NAME $connect_ip]
			if {[string match -nocase $connected_ip_type "system_ila"]} {
				continue
			}
			if {[llength $connected_ip_type] != 0} {
				if {[string match -nocase $connected_ip_type "axis_subset_converter"]} {
					set ip [hsi::utils::get_connected_stream_ip $connected_ip "M_AXIS"]
					set ip_type [get_property IP_NAME $ip]
					if {[string match -nocase $ip_type "v_demosaic"]|| [string match -nocase $ip_type "v_proc_ss"]} {
						set ports_node [add_or_get_dt_node -n "ports" -l csiss_ports -p $node]
						hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
						set port_node [add_or_get_dt_node -n "port" -l csiss_port0 -u 0 -p $ports_node]
						hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
						hsi::utils::add_new_dts_param "${port_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format and video-width user needs to fill */" "" comment
						hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 12 int
						hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 8 int
						hsi::utils::add_new_dts_param "$port_node" "xlnx,cfa-pattern" rggb string
						set sdi_rx_node [add_or_get_dt_node -n "endpoint" -l csiss_out -p $port_node]
						if {[string match -nocase $ip_type "v_demosaic"]} {
							hsi::utils::add_new_dts_param "$sdi_rx_node" "remote-endpoint" demosaic_in reference
						}
						if {[string match -nocase $ip_type "v_proc_ss"]} {
							hsi::utils::add_new_dts_param "$sdi_rx_node" "remote-endpoint" scaler_in reference
						}
						set port1_node [add_or_get_dt_node -n "port" -l csiss_port1 -u 1 -p $ports_node]
						hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
						hsi::utils::add_new_dts_param "${port1_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format,video-width user needs to fill */" "" comment
						hsi::utils::add_new_dts_param "${port1_node}" "/* User need to add something like remote-endpoint=<&out> under the node csiss_in:endpoint */" "" comment
						hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 12 int
						hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" 8 int
						hsi::utils::add_new_dts_param "$port1_node" "xlnx,cfa-pattern" rggb string
						set csiss_rx_node [add_or_get_dt_node -n "endpoint" -l csiss_in -p $port1_node]
					}
					if {[string match -nocase $ip_type "v_frmbuf_wr"]} {
						set ports_node [add_or_get_dt_node -n "ports" -l csiss_ports -p $node]
						hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
						set port_node [add_or_get_dt_node -n "port" -l csiss_port0 -u 0 -p $ports_node]
						hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
						hsi::utils::add_new_dts_param "${port_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format and video-width user needs to fill */" "" comment
						hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 12 int
						hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 8 int
						hsi::utils::add_new_dts_param "$port_node" "xlnx,cfa-pattern" rggb string
						set rx_node [add_or_get_dt_node -n "endpoint" -l csiss_out -p $port_node]
						hsi::utils::add_new_dts_param "$rx_node" "remote-endpoint" vcap_mipi_in reference
						set port1_node [add_or_get_dt_node -n "port" -l csiss_port1 -u 1 -p $ports_node]
						hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
						hsi::utils::add_new_dts_param "${port1_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format,video-width user needs to fill */" "" comment
						hsi::utils::add_new_dts_param "${port1_node}" "/* User need to add something like remote-endpoint=<&out> under the node csiss_in:endpoint */" "" comment
						hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 12 int
						hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" 8 int
						hsi::utils::add_new_dts_param "$port1_node" "xlnx,cfa-pattern" rggb string
						set csiss_rx_node [add_or_get_dt_node -n "endpoint" -l csiss_in -p $port1_node]
						set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
						if {$dt_overlay} {
							set bus_node "overlay2"
						} else {
							set bus_node "amba_pl"
						}
						set dts_file [current_dt_tree]
						set vcap_mipirx [add_or_get_dt_node -n "vcap_mipi" -d $dts_file -p $bus_node]
						hsi::utils::add_new_dts_param $vcap_mipirx "compatible" "xlnx,video" string
						hsi::utils::add_new_dts_param $vcap_mipirx "dmas" "$ip 0" reference
						hsi::utils::add_new_dts_param $vcap_mipirx "dma-names" "port0" string
						set vcap_mipi_node [add_or_get_dt_node -n "ports" -l vcap_mipi_ports -p $vcap_mipirx]
						hsi::utils::add_new_dts_param "$vcap_mipi_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$vcap_mipi_node" "#size-cells" 0 int
						set vcap_mipiport_node [add_or_get_dt_node -n "port" -l vcap_mipi_port -u 0 -p $vcap_mipi_node]
						hsi::utils::add_new_dts_param "$vcap_mipiport_node" "reg" 0 int
						hsi::utils::add_new_dts_param "$vcap_mipiport_node" "direction" input string
						set vcap_mipi_in_node [add_or_get_dt_node -n "endpoint" -l vcap_mipi_in -p $vcap_mipiport_node]
						hsi::utils::add_new_dts_param "$vcap_mipi_in_node" "remote-endpoint" csiss_out reference
					}
				}
			}
		}
	}
}

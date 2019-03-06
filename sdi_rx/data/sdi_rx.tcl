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
	set compatible [append compatible " " "xlnx,v-smpte-uhdsdi-rx-ss"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ports_node [add_or_get_dt_node -n "ports" -l sdirx_ports -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_OUT"]
	if {![llength $connected_ip]} {
		dtg_warning "$drv_handle pin VIDEO_OUT is not connected...check your design"
	}
	if {[llength $connected_ip]} {
		set connected_ip_type [get_property IP_NAME $connected_ip]
		if {[string match -nocase $connected_ip_type "axis_subset_converter"]} {
			set connected_ip [hsi::utils::get_connected_stream_ip $connected_ip "M_AXIS"]
		}
		if {[llength $connected_ip]} {
			set connected_ip_type [get_property IP_NAME $connected_ip]
		}
		if {[string match -nocase $connected_ip_type "v_frmbuf_wr"] || [string match -nocase $connected_ip_type "axi_vdma"]} {
			set port_node [add_or_get_dt_node -n "port" -l sdirx_port -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "${port_node}" "/* Fill the fields xlnx,video-format and xlnx,video-width based on user requirement */" "" comment
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 0 int
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 10 int
			hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
			set sdi_rx_node [add_or_get_dt_node -n "endpoint" -l sdi_rx_out -p $port_node]
			hsi::utils::add_new_dts_param "$sdi_rx_node" "remote-endpoint" vcap_sdirx_in reference
			set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
			if {$dt_overlay} {
				set bus_node "overlay2"
			} else {
				set bus_node "amba_pl"
			}
			set dts_file [current_dt_tree]
			set vcap_sdirx [add_or_get_dt_node -n "vcap_sdirx" -d $dts_file -p $bus_node]
			hsi::utils::add_new_dts_param $vcap_sdirx "compatible" "xlnx,video" string
			hsi::utils::add_new_dts_param $vcap_sdirx "dmas" "$connected_ip 0" reference
			hsi::utils::add_new_dts_param $vcap_sdirx "dma-names" "port0" string
			set vcap_ports_node [add_or_get_dt_node -n "ports" -l vcap_ports -p $vcap_sdirx]
			hsi::utils::add_new_dts_param "$vcap_ports_node" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "$vcap_ports_node" "#size-cells" 0 int
			set vcap_port_node [add_or_get_dt_node -n "port" -l vcap_port -u 0 -p $vcap_ports_node]
			hsi::utils::add_new_dts_param "$vcap_port_node" "reg" 0 int
			hsi::utils::add_new_dts_param "$vcap_port_node" "direction" input string
			set vcap_sdirx_in_node [add_or_get_dt_node -n "endpoint" -l vcap_sdirx_in -p $vcap_port_node]
			hsi::utils::add_new_dts_param "$vcap_sdirx_in_node" "remote-endpoint" sdi_rx_out reference
		}
		if {[string match -nocase $connected_ip_type "v_mix"]} {
			set sdi_port_node [add_or_get_dt_node -n "port" -l encoder_sdi_port -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "$sdi_port_node" "reg" 0 int
			set sdi_encoder_node [add_or_get_dt_node -n "endpoint" -l sdi_encoder -p $sdi_port_node]
			hsi::utils::add_new_dts_param "$sdi_encoder_node" "remote-endpoint" mixer_crtc reference
		}
		if {[string match -nocase $connected_ip_type "v_proc_ss"]} {
			set ports_node [add_or_get_dt_node -n "ports" -l sdirx_ports -p $node]
			hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
			set port_node [add_or_get_dt_node -n "port" -l sdirx_port -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "${port_node}" "/* Fill the fields xlnx,video-format and xlnx,video-width based on user requirement */" "" comment
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 0 int
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 10 int
			hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
			set sdi_rx_node [add_or_get_dt_node -n "endpoint" -l sdi_rx_out -p $port_node]
			set topology [get_property CONFIG.C_TOPOLOGY $connected_ip]
			if {$topology == 0} {
				hsi::utils::add_new_dts_param "$sdi_rx_node" "remote-endpoint" scaler_in reference
			} else {
				hsi::utils::add_new_dts_param "$sdi_rx_node" "remote-endpoint" csc_in reference
			}
		}
	}
}

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

	set ports_node [add_or_get_dt_node -n "ports" -l sdirx_ports$drv_handle -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set port_node [add_or_get_dt_node -n "port" -l sdirx_port$drv_handle -u 0 -p $ports_node]
	hsi::utils::add_new_dts_param "${port_node}" "/* Fill the fields xlnx,video-format and xlnx,video-width based on user requirement */" "" comment
	hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 0 int
	hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 10 int
	hsi::utils::add_new_dts_param "$port_node" "reg" 0 int

	set sdirxip [get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_OUT"]
	foreach ip $sdirxip {
		if {[llength $ip]} {
			if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
				continue
			}
			set intfpins [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $ip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
				set sdi_rx_node [add_or_get_dt_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node]
				gen_endpoint $drv_handle "sdirx_out$drv_handle"
				hsi::utils::add_new_dts_param "$sdi_rx_node" "remote-endpoint" $ip$drv_handle reference
				gen_remoteendpoint $drv_handle $ip$drv_handle
				if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
					gen_frmbuf_wr_node $ip $drv_handle
				}
			} else {
				set connectip [get_connect_ip $ip $intfpins]
				if {[llength $connectip]} {
					set sdi_rx_node [add_or_get_dt_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node]
					gen_endpoint $drv_handle "sdirx_out$drv_handle"
					hsi::utils::add_new_dts_param "$sdi_rx_node" "remote-endpoint" $connectip$drv_handle reference
					gen_remoteendpoint $drv_handle $connectip$drv_handle
					if {[string match -nocase [get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
						gen_frmbuf_wr_node $connectip $drv_handle
					}
				}
			}
		}
	}
}

proc gen_frmbuf_wr_node {outip drv_handle} {
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "overlay2"
	} else {
		set bus_node "amba_pl"
	}
        set vcap [add_or_get_dt_node -n "vcap_sdirx$drv_handle" -p $bus_node]
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
        hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" sdirx_out$drv_handle reference
}

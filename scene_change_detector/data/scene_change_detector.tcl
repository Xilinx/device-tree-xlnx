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
	set compatible "xlnx,v-scd"
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ip [get_cells -hier $drv_handle]
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-data-width" $max_data_width int
	set memory_scd [get_property CONFIG.MEMORY_BASED [get_cells -hier $drv_handle]]
	if {$memory_scd == 1} {
		set max_nr_streams [get_property CONFIG.MAX_NR_STREAMS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "$node" "xlnx,numstreams" $max_nr_streams int
		hsi::utils::add_new_dts_param $node "#address-cells" 1 int
		hsi::utils::add_new_dts_param $node "#size-cells" 0 int
		hsi::utils::add_new_dts_param $node "xlnx,memorybased" "" boolean
		hsi::utils::add_new_dts_param "$node" "#dma-cells" 1 int
		set aximm_addr_width [get_property CONFIG.AXIMM_ADDR_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "$node" "xlnx,addrwidth" $aximm_addr_width hexint
		for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
			set scd_node [add_or_get_dt_node -n "subdev@$stream" -p $node]
			set port_node [add_or_get_dt_node -n "port@0" -l port_$stream -p $scd_node]
			hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
			set endpoint [add_or_get_dt_node -n "endpoint" -l scd_in$stream -p $port_node]
			hsi::utils::add_new_dts_param "$endpoint" "remote-endpoint" vcap0_out$stream reference
		}
		set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
		if {$dt_overlay} {
			set bus_node "overlay2"
		} else {
			set bus_node "amba_pl"
		}
		set dts_file [current_dt_tree]
		set dma_names ""
		set dmas ""
		set vcap_scd [add_or_get_dt_node -n "video_cap" -l videocap -d $dts_file -p $bus_node]
		for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
			append dma_names " " "port$stream"
			set peri "$drv_handle $stream"
			set dmas [lappend dmas $peri]
		}
		hsi::utils::add_new_dts_param "$vcap_scd" "dma-names" $dma_names stringlist
		generate_dmas $vcap_scd $dmas
		set ports_vcap [add_or_get_dt_node -n "ports" -l ports_vcap -p $vcap_scd]
		hsi::utils::add_new_dts_param $ports_vcap "#address-cells" 1 int
		hsi::utils::add_new_dts_param $ports_vcap "#size-cells" 0 int
		hsi::utils::add_new_dts_param $vcap_scd "compatible" "xlnx,video" string
		for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
			set port_vcap_node [add_or_get_dt_node -n "port@$stream" -l port$stream -p $ports_vcap]
			hsi::utils::add_new_dts_param "$port_vcap_node" "reg" $stream int
			hsi::utils::add_new_dts_param "$port_vcap_node" "direction" output string
			set vcap_endpoint [add_or_get_dt_node -n "endpoint" -l vcap0_out$stream -p $port_vcap_node]
			hsi::utils::add_new_dts_param "$vcap_endpoint" "remote-endpoint" scd_in$stream reference
		}
	} else {
		set max_nr_streams [get_property CONFIG.MAX_NR_STREAMS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "$node" "xlnx,numstreams" $max_nr_streams int
		hsi::utils::add_new_dts_param $node "#address-cells" 1 int
		hsi::utils::add_new_dts_param $node "#size-cells" 0 int
		set hdmi_ports_node [add_or_get_dt_node -n "scd" -l scd_ports -p $node]
		hsi::utils::add_new_dts_param "$hdmi_ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$hdmi_ports_node" "#size-cells" 0 int
		set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
		if {![llength $connected_ip]} {
			dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected...check your design"
		}
		if {[llength $connected_ip]} {
			set connected_in_ip_type [get_property IP_NAME $connected_ip]
			if {[string match -nocase $connected_in_ip_type "v_hdmi_rx_ss"]} {
				set hdmi_port_node [add_or_get_dt_node -n "port" -l scd_port0 -u 0 -p $hdmi_ports_node]
				hsi::utils::add_new_dts_param "$hdmi_port_node" "reg" 0 int
				set hdmi_in_node [add_or_get_dt_node -n "endpoint" -l scd_in -p $hdmi_port_node]
				hsi::utils::add_new_dts_param "$hdmi_in_node" "remote-endpoint" hdmirx_out reference
			}
			if {[string match -nocase $connected_in_ip_type "v_proc_ss"]} {
				set scaler_port_node [add_or_get_dt_node -n "port" -l scd_port0 -u 0 -p $hdmi_ports_node]
				hsi::utils::add_new_dts_param "$scaler_port_node" "reg" 0 int
				set scaler_in_node [add_or_get_dt_node -n "endpoint" -l scd_in -p $scaler_port_node]
				hsi::utils::add_new_dts_param "$scaler_in_node" "remote-endpoint" vpss_scaler_out reference
			}
		}
		set connected_out_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS_VIDEO"]
		if {![llength $connected_out_ip]} {
			dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected... check your design"
		}
		if {[llength $connected_out_ip]} {
			set connected_out_ip_type [get_property IP_NAME $connected_out_ip]
			if {[string match -nocase $connected_out_ip_type "v_frmbuf_wr"]} {
				set hdmi_port1_node [add_or_get_dt_node -n "port" -l scd_port1 -u 1 -p $hdmi_ports_node]
				hsi::utils::add_new_dts_param "$hdmi_port1_node" "reg" 1 int
				set hdmi_scd_node [add_or_get_dt_node -n "endpoint" -l scd_out -p $hdmi_port1_node]
				hsi::utils::add_new_dts_param "$hdmi_scd_node" "remote-endpoint" scd_hdmi_in reference
				set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
				if {$dt_overlay} {
					set bus_node "overlay2"
				} else {
					set bus_node "amba_pl"
				}
				set dts_file [current_dt_tree]
				set scd_hdmirx [add_or_get_dt_node -n "scd_hdmi" -d $dts_file -p $bus_node]
				hsi::utils::add_new_dts_param $scd_hdmirx "compatible" "xlnx,video" string
				hsi::utils::add_new_dts_param $scd_hdmirx "dmas" "$connected_out_ip 0" reference
				hsi::utils::add_new_dts_param $scd_hdmirx "dma-names" "port0" string
				set scd_hdmi_node [add_or_get_dt_node -n "ports" -l scd_hdmi_ports -p $scd_hdmirx]
				hsi::utils::add_new_dts_param "$scd_hdmi_node" "#address-cells" 1 int
				hsi::utils::add_new_dts_param "$scd_hdmi_node" "#size-cells" 0 int
				set scd_hdmiport_node [add_or_get_dt_node -n "port" -l scd_hdmi_port -u 0 -p $scd_hdmi_node]
				hsi::utils::add_new_dts_param "$scd_hdmiport_node" "reg" 0 int
				hsi::utils::add_new_dts_param "$scd_hdmiport_node" "direction" input string
				set scd_hdmi_in_node [add_or_get_dt_node -n "endpoint" -l scd_hdmi_in -p $scd_hdmiport_node]
				hsi::utils::add_new_dts_param "$scd_hdmi_in_node" "remote-endpoint" scd_out reference
			}
		}
	}
	set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] "ap_rst_n"]]
	foreach pin $pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [get_property IP_NAME $sink_periph]
			if {[string match -nocase $sink_ip "xlslice"]} {
				set gpio [get_property CONFIG.DIN_FROM $sink_periph]
				set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $sink_periph "Din"]]]
				foreach pin $pins {
					set periph [::hsi::get_cells -of_objects $pin]
					if {[llength $periph]} {
						set ip [get_property IP_NAME $periph]
						set proc_type [get_sw_proc_prop IP_NAME]
						if {[string match -nocase $proc_type "psu_cortexa53"]} {
							if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
								set gpio [expr $gpio + 78]
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio $gpio 1" reference
								break
							}
						}
						if {[string match -nocase $ip "axi_gpio"]} {
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 0 1" reference
						}
					} else {
						dtg_warning "$drv_handle: peripheral is NULL for the $pin $periph"
					}
				}
			}
		} else {
			dtg_warning "$drv_handle:peripheral is NULL for the $pin $sink_periph"
		}
	}
}

proc generate_dmas {vcap_scd dmas} {
	set len [llength $dmas]
	switch $len {
		"1" {
			set refs [lindex $dmas 0]
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
		"2" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]"
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
		"3" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]"
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
		"4" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]"
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
		"5" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]"
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
		"6" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]"
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
		"7" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]>, <&[lindex $dmas 6]"
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
		"8" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]>, <&[lindex $dmas 6]>, <&[lindex $dmas 7]"
			hsi::utils::add_new_dts_param "$vcap_scd" "dmas" $refs reference
		}
	}
}

#
# (C) Copyright 2018-2022 Xilinx, Inc.
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
	set tpg_count [hsi::utils::get_os_parameter_value "tpg_count"]
	if { [llength $tpg_count] == 0 } {
		set tpg_count 0
	}
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,v-tpg-8.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ip [get_cells -hier $drv_handle]
	set s_axi_ctrl_addr_width [get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int
	set s_axi_ctrl_data_width [get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
	set pixels_per_clock [get_property CONFIG.SAMPLES_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,ppc" $pixels_per_clock int
	set max_cols [get_property CONFIG.MAX_COLS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-width" $max_cols int
	set max_rows [get_property CONFIG.MAX_ROWS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-height" $max_rows int
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "ps7_cortexa9"]} {
		# Workaround for issue (TBF)
		return
	}
	set ports_node [add_or_get_dt_node -n "ports" -l tpg_ports$drv_handle -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set port1_node [add_or_get_dt_node -n "port" -l tpg_port1$drv_handle -u 1 -p $ports_node]
	hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
	hsi::utils::add_new_dts_param "${port1_node}" "/* Fill the field xlnx,video-format based on user requirement */" "" comment
	hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 2 int
	hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" $max_data_width int

	set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
	if {![llength $connect_ip]} {
		dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected..check your design"
	}
	foreach connected_ip $connect_ip {
		if {[llength $connected_ip] != 0} {
			set connected_ip_type [get_property IP_NAME $connected_ip]
			set ports_node ""
			set sink_periph ""
			if {[llength $connected_ip_type] != 0} {
				if {[string match -nocase $connected_ip_type "system_ila"]} {
					continue
				}
				if {[string match -nocase $connected_ip_type "v_vid_in_axi4s"]} {
					set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $connected_ip "vid_active_video"]]]
					foreach pin $pins {
						set sink_periph [::hsi::get_cells -of_objects $pin]
						set sink_ip [get_property IP_NAME $sink_periph]
						if {[string match -nocase $sink_ip "v_tc"]} {
							hsi::utils::add_new_dts_param "$node" "xlnx,vtc" "$sink_periph" reference
						}
					}
				}
			}
		}
	}

	set connect_out_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS_VIDEO"]
	if {![llength $connect_out_ip]} {
		dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected ...check your design"
	}
	foreach out_ip $connect_out_ip {
		if {[llength $out_ip] != 0} {
			set connected_out_ip_type [get_property IP_NAME $out_ip]
			if {[llength $connected_out_ip_type] != 0} {
				if {[string match -nocase $connected_out_ip_type "system_ila"]} {
					continue
				}
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $out_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $out_ip]
				if {[llength $ip_mem_handles]} {
					set tpg_node [add_or_get_dt_node -n "endpoint" -l tpg_out$drv_handle -p $port1_node]
					gen_endpoint $drv_handle "tpg_out$drv_handle"
					hsi::utils::add_new_dts_param "$tpg_node" "remote-endpoint" $out_ip$drv_handle reference
					gen_remoteendpoint $drv_handle "$out_ip$drv_handle"
					if {[string match -nocase [get_property IP_NAME $out_ip] "v_frmbuf_wr"] || [string match -nocase [get_property IP_NAME $out_ip] "axi_vdma"]} {
						gen_frmbuf_node $out_ip $drv_handle
					}
				 } else {
					set connectip [get_connect_ip $out_ip $master_intf]
					puts "connectip:$connectip"
					if {[llength $connectip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
						puts "ip_mem_handles:$ip_mem_handles"
						if {[llength $ip_mem_handles]} {
							set tpg_node [add_or_get_dt_node -n "endpoint" -l tpg_out$drv_handle -p $port1_node]
							gen_endpoint $drv_handle "tpg_out$drv_handle"
							hsi::utils::add_new_dts_param "$tpg_node" "remote-endpoint" $connectip$drv_handle reference
							gen_remoteendpoint $drv_handle "$connectip$drv_handle"
							if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"] || [string match -nocase [get_property IP_NAME $connectip] "axi_vdma"]} {
								gen_frmbuf_node $connectip $drv_handle
							}
						}
					}
				}
			}
		} else {
			dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected ...check your design"
		}
	}
	gen_gpio_reset $drv_handle $node
}

proc gen_frmbuf_node {ip drv_handle} {
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}
	set vcap [add_or_get_dt_node -n "vcap_$drv_handle" -p $bus_node]
	hsi::utils::add_new_dts_param $vcap "compatible" "xlnx,video" string
	hsi::utils::add_new_dts_param $vcap "dmas" "$ip 0" reference
	hsi::utils::add_new_dts_param $vcap "dma-names" "port0" string
	set vcap_ports_node [add_or_get_dt_node -n "ports" -l vcap_ports$drv_handle -p $vcap]
	hsi::utils::add_new_dts_param "$vcap_ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$vcap_ports_node" "#size-cells" 0 int
	if {[string match -nocase $proctype "ps7_cortexa9"]} {
		#Workaround for issue (TBF)
		set vcap_port_node [add_or_get_dt_node -n "port" -l vcap_port$drv_handle -p $vcap_ports_node]
	} else {
		set vcap_port_node [add_or_get_dt_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node]
	}
	hsi::utils::add_new_dts_param "$vcap_port_node" "reg" 0 int
	hsi::utils::add_new_dts_param "$vcap_port_node" "direction" input string
	set vcap_in_node [add_or_get_dt_node -n "endpoint" -l $ip$drv_handle -p $vcap_port_node]
	hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" tpg_out$drv_handle reference
}

proc gen_gpio_reset {drv_handle node} {
	set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier [get_cells -hier $drv_handle]] "ap_rst_n"]]
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
						if {[string match -nocase $proc_type "psv_cortexa72"] } {
							if {[string match -nocase $ip "versal_cips"]} {
								# As versal has only bank0 for MIOs
								set gpio [expr $gpio + 26]
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio0 $gpio 1" reference
								break
							}
						}
						if {[string match -nocase $proc_type "psu_cortexa53"] } {
							if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
								set gpio [expr $gpio + 78]
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio $gpio 1" reference
								break
							}
						}
						if {[string match -nocase $ip "axi_gpio"]} {
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 1" reference
						}
					} else {
						dtg_warning "$drv_handle peripheral is NULL for the $pin $periph"
					}
				}
			}
		} else {
			dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
		}
	}
}

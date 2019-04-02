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
	set tpg_count [hsi::utils::get_os_parameter_value "tpg_count"]
	if { [llength $tpg_count] == 0 } {
		set tpg_count 0
	}
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,v-tpg-7.0"]
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
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
	if {![llength $connected_ip]} {
		dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected..check your design"
	}
	if {[llength $connected_ip] != 0} {
		set connected_ip_type [get_property IP_NAME $connected_ip]
		set ports_node ""
		set sink_periph ""
		if {[llength $connected_ip_type] != 0} {
			if {[string match -nocase $connected_ip_type "v_vid_in_axi4s"]} {
				set connected1_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $connected_ip] "VID_ACTIVE_VIDEO"]
				set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $connected_ip "vid_active_video"]]]
				foreach pin $pins {
					set sink_periph [::hsi::get_cells -of_objects $pin]
					set sink_ip [get_property IP_NAME $sink_periph]
					if {[string match -nocase $sink_ip "v_tc"]} {
						hsi::utils::add_new_dts_param "$node" "xlnx,vtc" "$sink_periph" reference
						set ports_node [add_or_get_dt_node -n "ports" -l tpg_ports$tpg_count -p $node]
						hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
					}
				}
			}
		}
		set connected_out_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS_VIDEO"]
		if {![llength $connected_out_ip]} {
			dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected ...check your design"
		}
		if {[llength $connected_out_ip] != 0} {
			set connected_out_ip_type [get_property IP_NAME $connected_out_ip]
			if {[llength $connected_out_ip_type] != 0} {
				if {[string match -nocase $connected_out_ip_type "v_demosaic"]} {
					set port0_node [add_or_get_dt_node -n "port" -l tpg_port0 -u 0 -p $ports_node]
					hsi::utils::add_new_dts_param "$port0_node" "reg" 0 int
					hsi::utils::add_new_dts_param "${port0_node}" "/* Fill the field xlnx,video-format based on user requirement */" "" comment
					hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-format" 12 int
					hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-width" $max_data_width int
					set demosaic_node [add_or_get_dt_node -n "endpoint" -l tpg_out -p $port0_node]
					hsi::utils::add_new_dts_param "$demosaic_node" "remote-endpoint" demosaic_in reference
				}
				if {[string match -nocase $connected_out_ip_type "v_proc_ss"]} {
					set port0_node [add_or_get_dt_node -n "port" -l tpg_port0 -u 0 -p $ports_node]
					hsi::utils::add_new_dts_param "$port0_node" "reg" 0 int
					hsi::utils::add_new_dts_param "${port0_node}" "/* Fill the field xlnx,video-format based on user requirement */" "" comment
					hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-format" 12 int
					hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-width" $max_data_width int
					set csiss_node [add_or_get_dt_node -n "endpoint" -l tpg_out -p $port0_node]
					set topology [get_property CONFIG.C_TOPOLOGY $connected_out_ip]
					if {$topology == 0} {
						hsi::utils::add_new_dts_param "$csiss_node" "remote-endpoint" scaler_in reference
					} else {
						hsi::utils::add_new_dts_param "$csiss_node" "remote-endpoint" csc_in reference
					}
				}
				if {[string match -nocase $connected_out_ip_type "v_frmbuf_wr"]} {
					set port0_node [add_or_get_dt_node -n "port" -l tpg_port$tpg_count -u 0 -p $ports_node]
					hsi::utils::add_new_dts_param "$port0_node" "reg" 0 int
					hsi::utils::add_new_dts_param "${port0_node}" "/* Fill the field xlnx,video-format based on user requirement */" "" comment
					hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-format" 12 int
					hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-width" $max_data_width int
					set frmbufwr_node [add_or_get_dt_node -n "endpoint" -l tpg_out$tpg_count -p $port0_node]
					hsi::utils::add_new_dts_param "$frmbufwr_node" "remote-endpoint" vcap_dev_in$tpg_count reference
					set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
					if {$dt_overlay} {
						set bus_node "overlay2"
					} else {
						set bus_node "amba_pl"
					}
					set dts_file [current_dt_tree]
					set vcap_tpg [add_or_get_dt_node -n "vcap_tp$tpg_count" -d $dts_file -p $bus_node]
					hsi::utils::add_new_dts_param $vcap_tpg "compatible" "xlnx,video" string
					hsi::utils::add_new_dts_param $vcap_tpg "dmas" "$connected_out_ip 0" reference
					hsi::utils::add_new_dts_param $vcap_tpg "dma-names" "port0" string
					set vcap_ports_node [add_or_get_dt_node -n "ports" -l v_ports$tpg_count -p $vcap_tpg]
					hsi::utils::add_new_dts_param "$vcap_ports_node" "#address-cells" 1 int
					hsi::utils::add_new_dts_param "$vcap_ports_node" "#size-cells" 0 int
					set vcap_port_node [add_or_get_dt_node -n "port" -l v_port$tpg_count -u 0 -p $vcap_ports_node]
					hsi::utils::add_new_dts_param "$vcap_port_node" "reg" 0 int
					hsi::utils::add_new_dts_param "$vcap_port_node" "direction" input string
					set vcap_tpg_in_node [add_or_get_dt_node -n "endpoint" -l vcap_dev_in$tpg_count -p $vcap_port_node]
					hsi::utils::add_new_dts_param "$vcap_tpg_in_node" "remote-endpoint" tpg_out$tpg_count reference
				}
			}
		}
	}
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "ap_rst_n"]
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
						if {[string match -nocase $proc_type "psu_cortexa53"] } {
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
						dtg_warning "$drv_handle peripheral is NULL for the $pin $periph"
					}
				}
			}
		} else {
			dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
		}
	}
	incr tpg_count
	hsi::utils::set_os_parameter_value "tpg_count" $tpg_count
}

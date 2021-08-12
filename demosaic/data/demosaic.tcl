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
	set compatible [append compatible " " "xlnx,v-demosaic"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set s_axi_ctrl_addr_width [get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int
	set s_axi_ctrl_data_width [get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
	set max_rows [get_property CONFIG.MAX_ROWS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,max-height" $max_rows int
	set max_cols [get_property CONFIG.MAX_COLS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,max-width" $max_cols int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]

	set ports_node [add_or_get_dt_node -n "ports" -l demosaic_ports$drv_handle -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set port1_node [add_or_get_dt_node -n "port" -l demosaic_port1$drv_handle -u 1 -p $ports_node]
	hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
	hsi::utils::add_new_dts_param "${port1_node}" "/* For cfa-pattern=rggb user needs to fill as per BAYER format */" "" comment
	hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" $max_data_width int
	hsi::utils::add_new_dts_param "$port1_node" "xlnx,cfa-pattern" rggb string

	set outip [get_connected_stream_ip [get_cells -hier $drv_handle] "m_axis_video"]
	foreach ip $outip {
		if {[llength $ip]} {
			set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $ip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
				set demonode [add_or_get_dt_node -n "endpoint" -l demo_out$drv_handle -p $port1_node]
				gen_endpoint $drv_handle "demo_out$drv_handle"
				hsi::utils::add_new_dts_param "$demonode" "remote-endpoint" $ip$drv_handle reference
				gen_remoteendpoint $drv_handle "$ip$drv_handle"
				if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
					gen_frmbuf_wr_node $ip $drv_handle
				}
			} else {
				if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
					continue
				}
				set connectip [get_connect_ip $ip $master_intf]
				if {[llength $connectip]} {
					set demonode [add_or_get_dt_node -n "endpoint" -l demo_out$drv_handle -p $port1_node]
					gen_endpoint $drv_handle "demo_out$drv_handle"
					hsi::utils::add_new_dts_param "$demonode" "remote-endpoint" $connectip$drv_handle reference
					gen_remoteendpoint $drv_handle "$connectip$drv_handle"
					if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
						gen_frmbuf_wr_node $connectip $drv_handle
					}
				}
			}
		} else {
			dtg_warning "$drv_handle pin m_axis_video is not connected..check your design"
		}
	}
	gen_gpio_reset $drv_handle $node
}

proc gen_frmbuf_wr_node {outip drv_handle} {
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
        gen_endpoint $drv_handle "demo_out$drv_handle"
        hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" demo_out$drv_handle reference
        gen_remoteendpoint $drv_handle "$outip$drv_handle"
}

proc gen_gpio_reset {drv_handle node} {
	set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier [get_cells -hier $drv_handle]] "ap_rst_n"]]
	set proc_type [get_sw_proc_prop IP_NAME]
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
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 0 1" reference
						}
					} else {
						dtg_warning "$drv_handle: peripheral is NULL for the $pin $periph"
					}
				}
			}
		} else {
			dtg_warning "$drv_handle: peripheral is NULL for the $pin $sink_periph"
		}
	}
}

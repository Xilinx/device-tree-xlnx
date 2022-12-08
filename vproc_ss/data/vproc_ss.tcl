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
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
	if {$topology == 0} {
	#scaler
		set name [get_property NAME [get_cells -hier $drv_handle]]
		set compatible [get_comp_str $drv_handle]
		set compatible [append compatible " " "xlnx,vpss-scaler-2.2 xlnx,v-vpss-scaler-2.2 xlnx,vpss-scaler"]
		set_drv_prop $drv_handle compatible "$compatible" stringlist
		set ip [get_cells -hier $drv_handle]
		set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,csc-enable-window" $csc_enable_window string
		set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,topology" $topology int
		set v_scaler_phases [get_property CONFIG.C_V_SCALER_PHASES [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,v-scaler-phases" $v_scaler_phases int
		set v_scaler_taps [get_property CONFIG.C_V_SCALER_TAPS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,v-scaler-taps" $v_scaler_taps int
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-vert-taps" $v_scaler_taps int
		set h_scaler_phases [get_property CONFIG.C_H_SCALER_PHASES [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,h-scaler-phases" $h_scaler_phases int
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-num-phases" $h_scaler_phases int
		set h_scaler_taps [get_property CONFIG.C_H_SCALER_TAPS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,h-scaler-taps" $h_scaler_taps int
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-hori-taps" $h_scaler_taps int
		set max_cols [get_property CONFIG.C_MAX_COLS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-width" $max_cols int
		set max_rows [get_property CONFIG.C_MAX_ROWS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-height" $max_rows int
		set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,samples-per-clk" $samples_per_clk int
		hsi::utils::add_new_dts_param "${node}" "xlnx,pix-per-clk" $samples_per_clk int
		set scaler_algo [get_property CONFIG.C_SCALER_ALGORITHM [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,scaler-algorithm" $scaler_algo int
		set enable_csc [get_property CONFIG.C_ENABLE_CSC [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,enable-csc" $enable_csc string
		set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,colorspace-support" $color_support int
		set use_uram [get_property CONFIG.C_USE_URAM [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,use-uram" $use_uram int
		set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,video-width" $max_data_width int

		set ports_node [add_or_get_dt_node -n "ports" -l scaler_ports$drv_handle -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set port1_node [add_or_get_dt_node -n "port" -l scaler_port1$drv_handle -u 1 -p $ports_node]
		hsi::utils::add_new_dts_param "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
		hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
		hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 3 int
		hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" $max_data_width int
		set scaoutip [get_connected_stream_ip [get_cells -hier $drv_handle] "m_axis"]
		if {[llength $scaoutip]} {
			if {[string match -nocase [get_property IP_NAME $scaoutip] "axis_broadcaster"]} {
				set sca_node [add_or_get_dt_node -n "endpoint" -l sca_out$drv_handle -p $port1_node]
				gen_endpoint $drv_handle "sca_out$drv_handle"
				hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $scaoutip$drv_handle reference
				gen_remoteendpoint $drv_handle "$scaoutip$drv_handle"
			}
		}
		foreach outip $scaoutip {
			if {[llength $outip]} {
				if {[string match -nocase [get_property IP_NAME $outip] "system_ila"]} {
					continue
				}
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $outip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
					set sca_node [add_or_get_dt_node -n "endpoint" -l sca_out$drv_handle -p $port1_node]
					gen_endpoint $drv_handle "sca_out$drv_handle"
					hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $outip$drv_handle reference
					gen_remoteendpoint $drv_handle "$outip$drv_handle"
					if {[string match -nocase [get_property IP_NAME $outip] "v_frmbuf_wr"] \
						|| [string match -nocase [get_property IP_NAME $outip] "axi_vdma"]} {
						gen_sca_frm_buf_node $outip $drv_handle
					}
				} else {
					set connectip [get_connect_ip $outip $master_intf]
					if {[llength $connectip]} {
						set sca_node [add_or_get_dt_node -n "endpoint" -l sca_out$drv_handle -p $port1_node]
						gen_endpoint $drv_handle "sca_out$drv_handle"
						hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $connectip$drv_handle reference
						gen_remoteendpoint $drv_handle "$connectip$drv_handle"
						if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"] \
							|| [string match -nocase [get_property IP_NAME $connectip] "axi_vdma"]} {
							gen_sca_frm_buf_node $connectip $drv_handle
						}
					}
				}
			} else {
				dtg_warning "$drv_handle pin m_axis is not connected..check your design"
			}
		}
		gen_gpio_reset $drv_handle $node $topology

	}
	if {$topology == 3} {
	#CSC
		set name [get_property NAME [get_cells -hier $drv_handle]]
		set compatible [get_comp_str $drv_handle]
		set compatible [append compatible " " "xlnx,vpss-csc xlnx,v-vpss-csc"]
		set_drv_prop $drv_handle compatible "$compatible" stringlist
		set ip [get_cells -hier $drv_handle]
		set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,topology" $topology int
		set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,colorspace-support" $color_support int
		set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,csc-enable-window" $csc_enable_window string
		set max_cols [get_property CONFIG.C_MAX_COLS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-width" $max_cols int
		set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,video-width" $max_data_width int
		set max_rows [get_property CONFIG.C_MAX_ROWS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,max-height" $max_rows int
		set num_video_comp [get_property CONFIG.C_NUM_VIDEO_COMPONENTS [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-video-components" $num_video_comp int
		set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,samples-per-clk" $samples_per_clk int
		set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,topology" $topology int
		set use_uram [get_property CONFIG.C_USE_URAM [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "${node}" "xlnx,use-uram" $use_uram int

		set ports_node [add_or_get_dt_node -n "ports" -l csc_ports$drv_handle -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set port1_node [add_or_get_dt_node -n "port" -l csc_port1$drv_handle -u 1 -p $ports_node]
		hsi::utils::add_new_dts_param "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
		hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
		hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 3 int
		hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" $max_data_width int
		set outip [get_connected_stream_ip [get_cells -hier $drv_handle] "m_axis"]
		if {[llength $outip]} {
			if {[string match -nocase [get_property IP_NAME $outip] "axis_broadcaster"]} {
				set csc_node [add_or_get_dt_node -n "endpoint" -l csc_out$drv_handle -p $port1_node]
				gen_endpoint $drv_handle "csc_out$drv_handle"
				hsi::utils::add_new_dts_param "$csc_node" "remote-endpoint" $outip$drv_handle reference
				gen_remoteendpoint $drv_handle "$outip$drv_handle"
			}
		}
		foreach ip $outip {
			if {[llength $ip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $ip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
					set cscoutnode [add_or_get_dt_node -n "endpoint" -l csc_out$drv_handle -p $port1_node]
					gen_endpoint $drv_handle "csc_out$drv_handle"
					hsi::utils::add_new_dts_param "$cscoutnode" "remote-endpoint" $ip$drv_handle reference
					gen_remoteendpoint $drv_handle "$ip$drv_handle"
					if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"] \
						|| [string match -nocase [get_property IP_NAME $ip] "axi_vdma"]} {
						gen_csc_frm_buf_node $ip $drv_handle
					}
				} else {
					if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
						continue
					}
					set connectip [get_connect_ip $ip $master_intf]
					if {[llength $connectip]} {
						set cscoutnode [add_or_get_dt_node -n "endpoint" -l csc_out$drv_handle -p $port1_node]
						gen_endpoint $drv_handle "csc_out$drv_handle"
						hsi::utils::add_new_dts_param "$cscoutnode" "remote-endpoint" $connectip$drv_handle reference
						gen_remoteendpoint $drv_handle "$connectip$drv_handle"
						if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"] \
							|| [string match -nocase [get_property IP_NAME $ip] "axi_vdma"]} {
							gen_csc_frm_buf_node $connectip $drv_handle
						}
					}
				}
			} else {
				dtg_warning "$drv_handle pin m_axis is not connected..check your design"
			}
		}
		gen_gpio_reset $drv_handle $node $topology
	}
}

proc gen_sca_frm_buf_node {outip drv_handle} {
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
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
	gen_endpoint $drv_handle "sca_out$drv_handle"
	hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" sca_out$drv_handle reference
	gen_remoteendpoint $drv_handle "$outip$drv_handle"
}

proc gen_csc_frm_buf_node {outip drv_handle} {
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
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
	gen_endpoint $drv_handle "csc_out$drv_handle"
	hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" csc_out$drv_handle reference
	gen_remoteendpoint $drv_handle "$outip$drv_handle"
}

proc gen_gpio_reset {drv_handle node topology} {
	set proc_type [get_sw_proc_prop IP_NAME]
	if {$topology == 3} {
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier [get_cells -hier $drv_handle]] "aresetn"]]
	}
	if {$topology == 0} {
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier [get_cells -hier $drv_handle]] "aresetn_ctrl"]]
	}
	foreach pin $pins {
			set sink_periph [::hsi::get_cells -of_objects $pin]
			if {[llength $sink_periph]} {
				set sink_ip [get_property IP_NAME $sink_periph]
				if {[string match -nocase $sink_ip "axi_gpio"]} {
					hsi::utils::add_new_dts_param "$node" "reset-gpios" "$sink_periph 0 1" reference
				}
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
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 1" reference
							}
						} else {
							dtg_warning "peripheral is NULL for the $pin $periph"
						}
					}
				}
			} else {
				dtg_warning "$drv_handle:peripheral is NULL for the $pin $sink_periph"
			}
		}
}

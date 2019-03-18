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
	set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
	if {$topology == 0} {
	#scaler
		set name [get_property NAME [get_cells -hier $drv_handle]]
		set compatible [get_comp_str $drv_handle]
		set compatible [append compatible " " "xlnx,v-vpss-scaler-1.0 xlnx,vpss-scaler"]
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
		set connected_in_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS"]
		set scaler_ports_node ""
		if {[llength $connected_in_ip] != 0} {
			set connected_in_ip_type [get_property IP_NAME $connected_in_ip]
			set ip_type ""
			if {[string match -nocase $connected_in_ip_type "axis_subset_converter"]} {
				set in_ip [hsi::utils::get_connected_stream_ip $connected_in_ip "S_AXIS"]
				set ip_type [get_property IP_NAME $in_ip]
			}
			if {[string match -nocase $connected_in_ip_type "v_proc_ss"]|| [string match -nocase $connected_in_ip_type "v_tpg"] || [string match -nocase $connected_in_ip_type "v_smpte_uhdsdi_rx_ss"]|| [string match -nocase $ip_type "mipi_csi2_rx_subsystem"]} {
				set scaler_ports_node [add_or_get_dt_node -n "ports" -l scaler_ports -p $node]
				hsi::utils::add_new_dts_param "$scaler_ports_node" "#address-cells" 1 int
				hsi::utils::add_new_dts_param "$scaler_ports_node" "#size-cells" 0 int
				set scaler_port_node [add_or_get_dt_node -n "port" -l scaler_port0 -u 0 -p $scaler_ports_node]
				hsi::utils::add_new_dts_param "${scaler_port_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
				hsi::utils::add_new_dts_param "$scaler_port_node" "reg" 0 int
				hsi::utils::add_new_dts_param "$scaler_port_node" "xlnx,video-format" 12 int
				hsi::utils::add_new_dts_param "$scaler_port_node" "xlnx,video-width" $max_data_width int
				set scaler_in_node [add_or_get_dt_node -n "endpoint" -l scaler_in -p $scaler_port_node]
				if {[string match -nocase $connected_in_ip_type "v_proc_ss"]} {
					hsi::utils::add_new_dts_param "$scaler_in_node" "remote-endpoint" csc_out reference
				}
				if {[string match -nocase $connected_in_ip_type "v_tpg"]} {
					hsi::utils::add_new_dts_param "$scaler_in_node" "remote-endpoint" tpg_out reference
				}
				if {[string match -nocase $connected_in_ip_type "v_smpte_uhdsdi_rx_ss"]} {
					hsi::utils::add_new_dts_param "$scaler_in_node" "remote-endpoint" sdi_rx_out reference
				}
				if {[string match -nocase $ip_type "mipi_csi2_rx_subsystem"]} {
					hsi::utils::add_new_dts_param "$scaler_in_node" "remote-endpoint" csiss_out reference
				}
			}
			if {[string match -nocase $connected_in_ip_type "v_hdmi_rx_ss"]} {
				set hdmi_ports_node [add_or_get_dt_node -n "ports" -l vpss_ports -p $node]
				hsi::utils::add_new_dts_param "$hdmi_ports_node" "#address-cells" 1 int
				hsi::utils::add_new_dts_param "$hdmi_ports_node" "#size-cells" 0 int
				set hdmi_port_node [add_or_get_dt_node -n "port" -l vpss_port0 -u 0 -p $hdmi_ports_node]
				hsi::utils::add_new_dts_param "${hdmi_port_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
				hsi::utils::add_new_dts_param "$hdmi_port_node" "reg" 0 int
				hsi::utils::add_new_dts_param "$hdmi_port_node" "xlnx,video-format" 12 int
				hsi::utils::add_new_dts_param "$hdmi_port_node" "xlnx,video-width" $max_data_width int
				set hdmi_in_node [add_or_get_dt_node -n "endpoint" -l vpss_scaler_in -p $hdmi_port_node]
				hsi::utils::add_new_dts_param "$hdmi_in_node" "remote-endpoint" hdmi_rx_out reference
			}
		} else {
			dtg_warning "$drv_handle:input port pin S_AXIS is not connected"
		}
		set connected_out_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS"]
		if {[llength $connected_out_ip] != 0} {
			set connected_out_ip_type [get_property IP_NAME $connected_out_ip]
			if {[string match -nocase $connected_out_ip_type "axis_broadcaster"]} {
				set broad_connected_out_ip [hsi::utils::get_connected_stream_ip $connected_out_ip "M00_AXIS"]
				set broad_connected_out_ip_type [get_property IP_NAME $broad_connected_out_ip]
				if {[string match -nocase $broad_connected_out_ip_type "axis_data_fifo"]} {
					set fifo_connected_out_ip [hsi::utils::get_connected_stream_ip $broad_connected_out_ip "M_AXIS"]
					set fifo_connected_out_ip_type [get_property IP_NAME $fifo_connected_out_ip]
				}
				if {[string match -nocase $fifo_connected_out_ip_type "axis_register_slice"]} {
					set axis_reg_slice_ip [hsi::utils::get_connected_stream_ip $fifo_connected_out_ip "M_AXIS"]
					set axis_reg_slice_connected_out_ip_type [get_property IP_NAME $axis_reg_slice_ip]
					if {[string match -nocase $axis_reg_slice_connected_out_ip_type "v_frmbuf_wr"]} {
						set hdmi_port1_node [add_or_get_dt_node -n "port" -l vpss_port1 -u 1 -p $hdmi_ports_node]
						hsi::utils::add_new_dts_param "${hdmi_port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
						hsi::utils::add_new_dts_param "$hdmi_port1_node" "reg" 1 int
						hsi::utils::add_new_dts_param "$hdmi_port1_node" "xlnx,video-format" 12 int
						hsi::utils::add_new_dts_param "$hdmi_port1_node" "xlnx,video-width" $max_data_width int
						set hdmi_scaler_node [add_or_get_dt_node -n "endpoint" -l vpss_scaler_out -p $hdmi_port1_node]
						hsi::utils::add_new_dts_param "$hdmi_scaler_node" "remote-endpoint" vcap_hdmi_in reference
						set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
						if {$dt_overlay} {
							set bus_node "overlay2"
						} else {
							set bus_node "amba_pl"
						}
						set dts_file [current_dt_tree]
						set vcap_hdmirx [add_or_get_dt_node -n "vcap_hdmi" -d $dts_file -p $bus_node]
						hsi::utils::add_new_dts_param $vcap_hdmirx "compatible" "xlnx,video" string
						hsi::utils::add_new_dts_param $vcap_hdmirx "dmas" "$axis_reg_slice_ip 0" reference
						hsi::utils::add_new_dts_param $vcap_hdmirx "dma-names" "port0" string
						set vcap_hdmi_node [add_or_get_dt_node -n "ports" -l vcap_hdmi_ports -p $vcap_hdmirx]
						hsi::utils::add_new_dts_param "$vcap_hdmi_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$vcap_hdmi_node" "#size-cells" 0 int
						set vcap_hdmiport_node [add_or_get_dt_node -n "port" -l vcap_hdmi_port -u 0 -p $vcap_hdmi_node]
						hsi::utils::add_new_dts_param "$vcap_hdmiport_node" "reg" 0 int
						hsi::utils::add_new_dts_param "$vcap_hdmiport_node" "direction" input string
						set vcap_hdmi_in_node [add_or_get_dt_node -n "endpoint" -l vcap_hdmi_in -p $vcap_hdmiport_node]
						hsi::utils::add_new_dts_param "$vcap_hdmi_in_node" "remote-endpoint" vpss_scaler_out reference
					}
				}
			}
			if {[string match -nocase $connected_out_ip_type "v_scenechange"]} {
				set scd_port1_node [add_or_get_dt_node -n "port" -l vpss_port1 -u 1 -p $hdmi_ports_node]
				hsi::utils::add_new_dts_param "${scd_port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
				hsi::utils::add_new_dts_param "$scd_port1_node" "reg" 1 int
				hsi::utils::add_new_dts_param "$scd_port1_node" "xlnx,video-format" 12 int
				hsi::utils::add_new_dts_param "$scd_port1_node" "xlnx,video-width" $max_data_width int
				set hdmi_scd_node [add_or_get_dt_node -n "endpoint" -l vpss_scaler_out -p $scd_port1_node]
				hsi::utils::add_new_dts_param "$hdmi_scd_node" "remote-endpoint" scd_in reference
			}
			if {[string match -nocase $connected_out_ip_type "v_frmbuf_wr"]} {
				if {[string match -nocase $connected_in_ip_type "v_hdmi_rx_ss"]} {
					set hdmi_port1_node [add_or_get_dt_node -n "port" -l vpss_port1 -u 1 -p $hdmi_ports_node]
					hsi::utils::add_new_dts_param "${hdmi_port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
					hsi::utils::add_new_dts_param "$hdmi_port1_node" "reg" 1 int
					hsi::utils::add_new_dts_param "$hdmi_port1_node" "xlnx,video-format" 12 int
					hsi::utils::add_new_dts_param "$hdmi_port1_node" "xlnx,video-width" $max_data_width int
					set hdmi_scaler_node [add_or_get_dt_node -n "endpoint" -l vpss_scaler_out -p $hdmi_port1_node]
					hsi::utils::add_new_dts_param "$hdmi_scaler_node" "remote-endpoint" vcap_hdmi_in reference
					set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
					if {$dt_overlay} {
						set bus_node "overlay2"
					} else {
						set bus_node "amba_pl"
					}
					set dts_file [current_dt_tree]
					set vcap_hdmirx [add_or_get_dt_node -n "vcap_hdmi" -d $dts_file -p $bus_node]
					hsi::utils::add_new_dts_param $vcap_hdmirx "compatible" "xlnx,video" string
					hsi::utils::add_new_dts_param $vcap_hdmirx "dmas" "$connected_out_ip 0" reference
					hsi::utils::add_new_dts_param $vcap_hdmirx "dma-names" "port0" string
					set vcap_hdmi_node [add_or_get_dt_node -n "ports" -l vcap_hdmi_ports -p $vcap_hdmirx]
					hsi::utils::add_new_dts_param "$vcap_hdmi_node" "#address-cells" 1 int
					hsi::utils::add_new_dts_param "$vcap_hdmi_node" "#size-cells" 0 int
					set vcap_hdmiport_node [add_or_get_dt_node -n "port" -l vcap_hdmi_port -u 0 -p $vcap_hdmi_node]
					hsi::utils::add_new_dts_param "$vcap_hdmiport_node" "reg" 0 int
					hsi::utils::add_new_dts_param "$vcap_hdmiport_node" "direction" input string
					set vcap_hdmi_in_node [add_or_get_dt_node -n "endpoint" -l vcap_hdmi_in -p $vcap_hdmiport_node]
					hsi::utils::add_new_dts_param "$vcap_hdmi_in_node" "remote-endpoint" vpss_scaler_out reference
				} else {
					if {![string match -nocase $connected_in_ip_type "v_frmbuf_rd"]} {
						if {[llength $scaler_ports_node]} {
							set port1_node [add_or_get_dt_node -n "port" -l scaler_port1 -u 1 -p $scaler_ports_node]
							hsi::utils::add_new_dts_param "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
							hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
							hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 12 int
							hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" $max_data_width int
							set scaler_node [add_or_get_dt_node -n "endpoint" -l scaler_out -p $port1_node]
							hsi::utils::add_new_dts_param "$scaler_node" "remote-endpoint" vcap_csi_in reference
							set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
							if {$dt_overlay} {
								set bus_node "overlay2"
							} else {
								set bus_node "amba_pl"
							}
							set dts_file [current_dt_tree]
							if {[string match -nocase $connected_in_ip_type "v_smpte_uhdsdi_rx_ss"]} {
								set vcap_csirx [add_or_get_dt_node -n "vcap_sdi" -d $dts_file -p $bus_node]
							} else {
								set vcap_csirx [add_or_get_dt_node -n "vcap_csi" -d $dts_file -p $bus_node]
							}
							hsi::utils::add_new_dts_param $vcap_csirx "compatible" "xlnx,video" string
							hsi::utils::add_new_dts_param $vcap_csirx "dmas" "$connected_out_ip 0" reference
							hsi::utils::add_new_dts_param $vcap_csirx "dma-names" "port0" string
							set vcap_ports_node [add_or_get_dt_node -n "ports" -l vcap_ports -p $vcap_csirx]
							hsi::utils::add_new_dts_param "$vcap_ports_node" "#address-cells" 1 int
							hsi::utils::add_new_dts_param "$vcap_ports_node" "#size-cells" 0 int
							set vcap_port_node [add_or_get_dt_node -n "port" -l vcap_port -u 0 -p $vcap_ports_node]
							hsi::utils::add_new_dts_param "$vcap_port_node" "reg" 0 int
							hsi::utils::add_new_dts_param "$vcap_port_node" "direction" input string
							set vcap_csi_in_node [add_or_get_dt_node -n "endpoint" -l vcap_csi_in -p $vcap_port_node]
							hsi::utils::add_new_dts_param "$vcap_csi_in_node" "remote-endpoint" scaler_out reference
						}
					}
				}
			}
		} else {
			dtg_warning "$drv_handle: output port pin M_AXIS is not connected"
		}
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
		set connected_in_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS"]
		set ports_node ""
		if {[llength $connected_in_ip]} {
			set connected_in_ip_type [get_property IP_NAME $connected_in_ip]
			if {[string match -nocase $connected_in_ip_type "v_gamma_lut"]|| [string match -nocase $connected_in_ip_type "v_tpg"]} {
				set ports_node [add_or_get_dt_node -n "ports" -l csc_ports -p $node]
				hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
				hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
				set port_node [add_or_get_dt_node -n "port" -l csc_port0 -u 0 -p $ports_node]
				hsi::utils::add_new_dts_param "${port_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
				hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
				hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 12 int
				hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" $max_data_width int
				set gamma_node [add_or_get_dt_node -n "endpoint" -l csc_in -p $port_node]
				if {[string match -nocase $connected_in_ip_type "v_gamma_lut"]} {
					hsi::utils::add_new_dts_param "$gamma_node" "remote-endpoint" gamma_out reference
				}
				if {[string match -nocase $connected_in_ip_type "v_tpg"]} {
					hsi::utils::add_new_dts_param "$gamma_node" "remote-endpoint" tpg_out reference
				}
			}
		} else {
			dtg_warning "$drv_handle: input port pin S_AXIS is not connected"
		}
		set connected_out_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS"]
		if {[llength $connected_out_ip]} {
			set connected_out_ip_type [get_property IP_NAME $connected_out_ip]
			if {[string match -nocase $connected_out_ip_type "v_proc_ss"]|| [string match -nocase $connected_out_ip_type "v_frmbuf_wr"]} {
				if {[llength $ports_node]} {
					set port1_node [add_or_get_dt_node -n "port" -l csc_port1 -u 1 -p $ports_node]
					hsi::utils::add_new_dts_param "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
					hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
					hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-format" 12 int
					hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" $max_data_width int
					set csiss_node [add_or_get_dt_node -n "endpoint" -l csc_out -p $port1_node]
					if {[string match -nocase $connected_out_ip_type "v_proc_ss"]} {
						hsi::utils::add_new_dts_param "$csiss_node" "remote-endpoint" scaler_in reference
					}
					if {[string match -nocase $connected_out_ip_type "v_frmbuf_wr"]} {
						hsi::utils::add_new_dts_param "$csiss_node" "remote-endpoint" vcap_in reference
						set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
						if {$dt_overlay} {
							set bus_node "overlay2"
						} else {
							set bus_node "amba_pl"
						}
						set dts_file [current_dt_tree]
						set vcap_sdirx [add_or_get_dt_node -n "vcap_sdirx" -d $dts_file -p $bus_node]
						hsi::utils::add_new_dts_param $vcap_sdirx "compatible" "xlnx,video" string
						hsi::utils::add_new_dts_param $vcap_sdirx "dmas" "$connected_out_ip 0" reference
						hsi::utils::add_new_dts_param $vcap_sdirx "dma-names" "port0" string
						set vcap_ports_node [add_or_get_dt_node -n "ports" -l vcap_ports -p $vcap_sdirx]
						hsi::utils::add_new_dts_param "$vcap_ports_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$vcap_ports_node" "#size-cells" 0 int
						set vcap_port_node [add_or_get_dt_node -n "port" -l vcap_port -u 0 -p $vcap_ports_node]
						hsi::utils::add_new_dts_param "$vcap_port_node" "reg" 0 int
						hsi::utils::add_new_dts_param "$vcap_port_node" "direction" input string
						set vcap_sdirx_in_node [add_or_get_dt_node -n "endpoint" -l vcap_in -p $vcap_port_node]
						hsi::utils::add_new_dts_param "$vcap_sdirx_in_node" "remote-endpoint" csc_out reference
					}
				}
			}
		} else {
			dtg_warning "$drv_handle:output port pin M_AXIS is not connected"
		}
	}
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "aresetn_ctrl"]
	if {$topology == 3} {
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] "aresetn"]]
	}
	if {$topology == 0} {
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] "aresetn_ctrl"]]
	}
	if {$topology == 0 || $topology == 3} {
		set proc_type [get_sw_proc_prop IP_NAME]
		foreach pin $pins {
			set sink_periph [::hsi::get_cells -of_objects $pin]
			if {[llength $sink_periph]} {
				set sink_ip [get_property IP_NAME $sink_periph]
				if {[string match -nocase $sink_ip "axi_gpio"]} {
					hsi::utils::add_new_dts_param "$node" "reset-gpios" "$sink_periph 0 0 1" reference
				}
				if {[string match -nocase $sink_ip "xlslice"]} {
					set gpio [get_property CONFIG.DIN_FROM $sink_periph]
					set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $sink_periph "Din"]]]
					foreach pin $pins {
						set periph [::hsi::get_cells -of_objects $pin]
						if {[llength $periph]} {
							set ip [get_property IP_NAME $periph]
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
							dtg_warning "peripheral is NULL for the $pin $periph"
						}
					}
				}
			} else {
				dtg_warning "$drv_handle:peripheral is NULL for the $pin $sink_periph"
			}
		}
	}
}

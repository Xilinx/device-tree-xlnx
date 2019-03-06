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
	set demosaic_ip [get_cells -hier $drv_handle]
	set s_axi_ctrl_addr_width [get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int
	set s_axi_ctrl_data_width [get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
	set max_rows [get_property CONFIG.MAX_ROWS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,max-height" $max_rows int
	set max_cols [get_property CONFIG.MAX_COLS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,max-width" $max_cols int
	set ports_node [add_or_get_dt_node -n "ports" -l demosaic_ports -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
	if {[llength $connected_ip]} {
		set connected_ip_type [get_property IP_NAME $connected_ip]
		if {[string match -nocase $connected_ip_type "axis_subset_converter"]} {
			set ip [hsi::utils::get_connected_stream_ip $connected_ip "S_AXIS"]
			set ip_type [get_property IP_NAME $ip]
			if {[string match -nocase $ip_type "mipi_csi2_rx_subsystem"]} {
				set port_node [add_or_get_dt_node -n "port" -l demosaic_port0 -u 0 -p $ports_node]
				hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
				hsi::utils::add_new_dts_param "${port_node}" "/* For cfa-pattern=rggb user needs to fill as per BAYER format */" "" comment
				hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" $max_data_width int
				hsi::utils::add_new_dts_param "$port_node" "xlnx,cfa-pattern" rggb string
				set demosaic_node [add_or_get_dt_node -n "endpoint" -l demosaic_in -p $port_node]
				hsi::utils::add_new_dts_param "$demosaic_node" "remote-endpoint" csiss_out reference
			}
		}
		if {[string match -nocase $connected_ip_type "v_tpg"]} {
			set ports_node [add_or_get_dt_node -n "ports" -l demosaic_ports -p $node]
			hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
			set port_node [add_or_get_dt_node -n "port" -l demosaic_port0 -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
			hsi::utils::add_new_dts_param "${port_node}" "/* For cfa-pattern=rggb user needs to fill as per BAYER format */" "" comment
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" $max_data_width int
			hsi::utils::add_new_dts_param "$port_node" "xlnx,cfa-pattern" rggb string
			set demosaic_node [add_or_get_dt_node -n "endpoint" -l demosaic_in -p $port_node]
			hsi::utils::add_new_dts_param "$demosaic_node" "remote-endpoint" tpg_out reference
		}
	} else {
		dtg_warning "$drv_handle input port pin S_AXIS_VIDEO is not connected...check your design"
	}
	set connected_out_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS_VIDEO"]
	if {[llength $connected_out_ip]} {
		set connected_out_ip_type [get_property IP_NAME $connected_out_ip]
		if {[string match -nocase $connected_out_ip_type "v_gamma_lut"]} {
			set port1_node [add_or_get_dt_node -n "port" -l demosaic_port1 -u 1 -p $ports_node]
			hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
			hsi::utils::add_new_dts_param "${port1_node}" "/* For cfa-pattern=rggb user needs to fill as per BAYER format */" "" comment
			hsi::utils::add_new_dts_param "$port1_node" "xlnx,video-width" $max_data_width int
			hsi::utils::add_new_dts_param "$port1_node" "xlnx,cfa-pattern" rggb string
			set csiss_rx_node [add_or_get_dt_node -n "endpoint" -l demosaic_out -p $port1_node]
			hsi::utils::add_new_dts_param "$csiss_rx_node" "remote-endpoint" gamma_in reference
		}
	} else {
		dtg_warning "$drv_handle output port pin M_AXIS_VIDEO is not connected ...check your design"
	}
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "ap_rst_n"]
	set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $demosaic_ip] "ap_rst_n"]]
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

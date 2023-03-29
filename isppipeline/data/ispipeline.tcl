#
# (C) Copyright 2023 Advanced Micro Devices, Inc. All Rights Reserved.
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
proc gen_reset_gpio {drv_handle node} {
	set ip [get_cells -hier $drv_handle]
	set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] "ap_rst_n"]]
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
					set proc_type [get_sw_proc_prop IP_NAME]
					if {[string match -nocase $proc_type "psv_cortexa72"] } {
						if {[string match -nocase $ip "versal_cips"]} {
							# As in versal there is only bank0 for MIOs
							set gpio [expr $gpio + 26]
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio0 $gpio 0" reference
							break
						}
					}
					if {[string match -nocase $proc_type "psu_cortexa53"] } {
						if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
							set gpio [expr $gpio + 78]
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio $gpio 0" reference
							break
						}
					}
					if {[string match -nocase $ip "axi_gpio"]} {
						hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 0 1" reference
					}
					} else {
						dtg_warning "periph for the pin:$pin is NULL $periph...check the design"
					}
				}
			}
		} else {
			dtg_warning "peripheral for the pin:$pin is NULL $sink_periph...check the design"
		}
	}
}

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
	set ip_name [get_property IP_NAME [get_cells -hier $drv_handle]]
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,isppipeline-1.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	hsi::utils::add_new_dts_param $node "xlnx,max-height" "/bits/ 16 <2160>" noformating
	hsi::utils::add_new_dts_param $node "xlnx,max-width" "/bits/ 16 <3840>" noformating
	hsi::utils::add_new_dts_param $node "xlnx,rgain" "/bits/ 16 <128>" noformating
	hsi::utils::add_new_dts_param $node "xlnx,bgain" "/bits/ 16 <210>" noformating
	hsi::utils::add_new_dts_param $node "xlnx,pawb" "/bits/ 16 <350>" noformating
	hsi::utils::add_new_dts_param $node "xlnx,mode-reg" "" boolean
	gen_reset_gpio "$drv_handle" "$node"
	# generating ports node for ispipeline ip
	set isppipeline_ports_node [add_or_get_dt_node -n "ports" -l isppipeline_ports$drv_handle -p $node]
	hsi::utils::add_new_dts_param "$isppipeline_ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$isppipeline_ports_node" "#size-cells" 0 int
	# find input ip which is connected to s_axis_video
	set inip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video"]
	if {[llength $inip]} {
		if {[string match -nocase [get_property IP_NAME $inip] "axis_data_fifo"]} {
			set inip [get_connected_stream_ip [get_cells -hier $inip] "S_AXIS"]
		}
		# generating port0 node for ispipeline ip
		set isppipeline_port0_node [add_or_get_dt_node -n "port" -l isppipeline_port0$drv_handle -u 0 -p $isppipeline_ports_node]
		hsi::utils::add_new_dts_param "$isppipeline_port0_node" "reg" 0 int
		set isppipeline_port_node_endpoint [add_or_get_dt_node -n "endpoint" -l $drv_handle$inip -p $isppipeline_port0_node]
		hsi::utils::add_new_dts_param "$isppipeline_port_node_endpoint" "remote-endpoint" isppipeline$drv_handle reference
		}
	# find outip which is connected to m_axis_video
	set outip [get_connected_stream_ip [get_cells -hier $drv_handle] "m_axis_video"]
	if {[llength $outip]} {
		# generating port1 node for ispipeline ip
		set isppipeline_port1_node [add_or_get_dt_node -n "port" -l isppipeline_port1$drv_handle -u 1 -p $isppipeline_ports_node]
		hsi::utils::add_new_dts_param "$isppipeline_port1_node" "reg" 1 int
		set isppipeline_port1_node_endpoint [add_or_get_dt_node -n "endpoint" -l $drv_handle$outip -p $isppipeline_port1_node]
		if {[string match -nocase [get_property IP_NAME $outip] "v_proc_ss"]} {
			# generating remote-endpoint  only when it is connected to v_proc_ss ip
			hsi::utils::add_new_dts_param "$isppipeline_port1_node_endpoint" "remote-endpoint" v_proc_ss$drv_handle reference
		 } else {
			# generating remote-endpoint when it is connected to another ip
			hsi::utils::add_new_dts_param "$isppipeline_port1_node_endpoint" "remote-endpoint" $outip$drv_handle reference
		}
	}
}

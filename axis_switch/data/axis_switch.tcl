#
# (C) Copyright 2020-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
#
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
	# try to source the common tcl procs
	# assuming the order of return is based on repo priority
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
	#set compatible [append compatible " " "xlnx,axis-switch"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
        set routing_mode [get_property CONFIG.ROUTING_MODE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,routing-mode" $routing_mode int
	set num_si [get_property CONFIG.NUM_SI [get_cells -hier $drv_handle]]
        hsi::utils::add_new_dts_param "$node" "xlnx,num-si-slots" $num_si int
        set num_mi [get_property CONFIG.NUM_MI [get_cells -hier $drv_handle]]
        hsi::utils::add_new_dts_param "$node" "xlnx,num-mi-slots" $num_mi int

	set ports_node [add_or_get_dt_node -n "ports" -l axis_switch_ports$drv_handle -p $node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
        set port1_node [add_or_get_dt_node -n "port" -l axis_switch_port1$drv_handle -u 1 -p $ports_node]
	hsi::utils::add_new_dts_param "$port1_node" "reg" 1 int
	set count 0
	set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $drv_handle] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
	set ip [get_cells -hier $drv_handle]
        foreach intf $master_intf {
		set connectip [get_connected_stream_ip [get_cells -hier $ip] $intf]
		if {[llength $connectip]} {
		set outipname [get_property IP_NAME $connectip]
		set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_uhdsdi_audio i2s_receiver mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
		if {[lsearch  -nocase $valid_mmip_list $outipname] >= 0} {
                        set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
			incr count
		}
		if {$count ==1} {
			if {[llength $connectip]} {
				set port_node [add_or_get_dt_node -n "port" -l axis_switch_port1$ip -u 1 -p $ports_node]
				hsi::utils::add_new_dts_param "$port_node" "reg" 1 int
                                set axis_node [add_or_get_dt_node -n "endpoint" -l axis_switch_out1$ip -p $port_node]
                                gen_axis_switch_port1_endpoint $ip "axis_switch_out1$ip"
                                hsi::utils::add_new_dts_param "$axis_node" "remote-endpoint" $connectip$ip reference
                                gen_axis_switch_port1_remote_endpoint $ip $connectip$ip
			}
		}
                if {$count == 2} {
                        if {[llength $connectip]} {
                                set port_node [add_or_get_dt_node -n "port" -l axis_switch_port2$ip -u 2 -p $ports_node]
                                hsi::utils::add_new_dts_param "$port_node" "reg" 2 int
                                set axis_node [add_or_get_dt_node -n "endpoint" -l axis_switch_out2$ip -p $port_node]
                                gen_axis_switch_port2_endpoint $ip "axis_switch_out2$ip"
                                hsi::utils::add_new_dts_param "$axis_node" "remote-endpoint" $connectip$ip reference
                                gen_axis_switch_port2_remote_endpoint $ip $connectip$ip
			}
		}
		}
	}
}

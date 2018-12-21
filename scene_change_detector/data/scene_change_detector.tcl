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
	set compatible [append compatible " " "xlnx,v-scd"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ip [get_cells -hier $drv_handle]
	set max_nr_streams [get_property CONFIG.MAX_NR_STREAMS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,numstreams" $max_nr_streams int
	hsi::utils::add_new_dts_param $node "#address-cells" 1 int
	hsi::utils::add_new_dts_param $node "#size-cells" 0 int
	set scd_ports_node [add_or_get_dt_node -n "scenechangedma" -l scdma -p $node]
	hsi::utils::add_new_dts_param "$scd_ports_node" "#dma-cells" 1 int
	hsi::utils::add_new_dts_param "$scd_ports_node" "dma-channels" 1 int
	set aximm_addr_width [get_property CONFIG.AXIMM_ADDR_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$scd_ports_node" "xlnx,addrwidth" $aximm_addr_width hexint
	set intr_val [get_property CONFIG.interrupts $drv_handle]
	set intr_parent [get_property CONFIG.interrupt-parent $drv_handle]
	if { [llength $intr_val] && ![string match -nocase $intr_val "-1"] } {
		hsi::utils::add_new_dts_param $scd_ports_node "interrupts" $intr_val intlist
		hsi::utils::add_new_dts_param $scd_ports_node "interrupt-parent" $intr_parent reference
	} else {
		dtg_warning "ERROR: ${drv_handle}: interrupt port is not connected"
	}
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
	set connected_in_ip_type [get_property IP_NAME $connected_ip]
	if {[string match -nocase $connected_in_ip_type "v_hdmi_rx_ss"]} {
		set hdmi_ports_node [add_or_get_dt_node -n "ports" -l scd_ports -p $node]
		hsi::utils::add_new_dts_param "$hdmi_ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$hdmi_ports_node" "#size-cells" 0 int
		set hdmi_port_node [add_or_get_dt_node -n "port" -l scd_port0 -u 0 -p $hdmi_ports_node]
		hsi::utils::add_new_dts_param "$hdmi_port_node" "reg" 0 int
		set hdmi_in_node [add_or_get_dt_node -n "endpoint" -l scd_in -p $hdmi_port_node]
		hsi::utils::add_new_dts_param "$hdmi_in_node" "remote-endpoint" hdmirx_out reference
	}
	set connected_out_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "M_AXIS_VIDEO"]
	set connected_out_ip_type [get_property IP_NAME $connected_out_ip]
	if {[string match -nocase $connected_out_ip_type "v_frmbuf_wr"]} {
		set hdmi_port1_node [add_or_get_dt_node -n "port" -l scd_port1 -u 1 -p $hdmi_ports_node]
		hsi::utils::add_new_dts_param "$hdmi_port1_node" "reg" 1 int
		set hdmi_scd_node [add_or_get_dt_node -n "endpoint" -l scd_out -p $hdmi_port1_node]
		hsi::utils::add_new_dts_param "$hdmi_scd_node" "remote-endpoint" scd_hdmi_in reference
		set dts_file [current_dt_tree]
		set bus_node "amba_pl"
		set scd_hdmirx [add_or_get_dt_node -n "scd_hdmi" -d $dts_file -p $bus_node]
		hsi::utils::add_new_dts_param $scd_hdmirx "compatible" "xlnx,video" string
		hsi::utils::add_new_dts_param $scd_hdmirx "dmas" "scdma 0" reference
		hsi::utils::add_new_dts_param $scd_hdmirx "dma-names" "port0" string
		set scd_hdmi_node [add_or_get_dt_node -n "ports" -l scd_hdmi_ports -p $scd_hdmirx]
		hsi::utils::add_new_dts_param "$scd_hdmi_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$scd_hdmi_node" "#size-cells" 0 int
		set scd_hdmiport_node [add_or_get_dt_node -n "port" -l scd_hdmi_port -u 0 -p $scd_hdmi_node]
		hsi::utils::add_new_dts_param "$scd_hdmiport_node" "reg" 0 int
		hsi::utils::add_new_dts_param "$scd_hdmiport_node" "direction" output string
		set scd_hdmi_in_node [add_or_get_dt_node -n "endpoint" -l scd_hdmi_in -p $scd_hdmiport_node]
		hsi::utils::add_new_dts_param "$scd_hdmi_in_node" "remote-endpoint" scd_out reference
	}
	set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $ip "ap_rst_n"]]]
	foreach pin $pins {
			set sink_periph [::hsi::get_cells -of_objects $pin]
			set sink_ip [get_property IP_NAME $sink_periph]
			if {[string match -nocase $sink_ip "xlslice"]} {
				set gpio [get_property CONFIG.DIN_FROM $sink_periph]
				set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $sink_periph "Din"]]]
				foreach pin $pins {
					set periph [::hsi::get_cells -of_objects $pin]
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
				}
			}
	}
}

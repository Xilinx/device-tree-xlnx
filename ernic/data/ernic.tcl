#
# (C) Copyright 2019-2022 Xilinx, Inc.
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
	set proc_type [get_sw_proc_prop IP_NAME]
	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set ernic_ip [get_cells -hier $drv_handle]
	set ip_name [get_property IP_NAME $ernic_ip]

	set ethip [get_connected_ip $drv_handle "rx_pkt_hndler_s_axis"]
	if {[llength $ethip]} {
		set_drv_property $drv_handle eth-handle "$ethip" reference
	}
}

proc get_connected_ip {drv_handle dma_pin} {
	global connected_ip
	set intf [::hsi::get_intf_pins -of_objects [get_cells -hier $drv_handle] $dma_pin]
	set valid_eth_list "l_ethernet"
	if {[string_is_empty ${intf}]} {
		return 0
	}
	set connected_ip [::hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] $intf]
	if {[string_is_empty ${connected_ip}]} {
		dtg_warning "$drv_handle connected ip is NULL for the pin $intf"
		return 0
	}
	set iptype [get_property IP_NAME [get_cells -hier $connected_ip]]
	if {[string match -nocase $iptype "axis_data_fifo"] } {
		set dma_pin "M_AXIS"
		get_connected_ip $connected_ip $dma_pin
	} elseif {[lsearch -nocase $valid_eth_list $iptype] >= 0 } {
		return $connected_ip
	} else {
		set dma_pin "S_AXIS"
		get_connected_ip $connected_ip $dma_pin
	}
}

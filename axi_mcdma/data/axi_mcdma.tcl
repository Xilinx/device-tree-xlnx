#
# (C) Copyright 2019-2020 Xilinx, Inc.
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
	set compatible [append compatible " " "xlnx,axi-mcdma-1.00.a"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set mcdma_ip [get_cells -hier $drv_handle]
	set axiethernetfound 0
	set connected_ip [hsi::utils::get_connected_stream_ip $mcdma_ip "M_AXIS_MM2S"]
	if { [llength $connected_ip] } {
		set connected_ip_type [get_property IP_NAME $connected_ip]
		if { [string match -nocase $connected_ip_type axi_ethernet ] || [string match -nocase $connected_ip_type axi_ethernet_buffer ] } {
			set axiethernetfound 1
		}
	} else {
		dtg_warning "$drv_handle connected ip is NULL for the pin M_AXIS_MM2S"
	}

	set is_xxv [get_connected_ip $drv_handle "M_AXIS_MM2S"]
	if { $axiethernetfound || $is_xxv == 1} {
		set compatstring "xlnx,eth-dma"
		set_property compatible "$compatstring" $drv_handle
	}
	if { $axiethernetfound != 1 && $is_xxv != 1} {
		set_drv_conf_prop $drv_handle c_addr_width xlnx,addrwidth
	} else {
		set addr_width [get_property CONFIG.c_addr_width $mcdma_ip]
		set inhex [format %x $addr_width]
		append addrwidth "/bits/ 8 <0x$inhex>"
		hsi::utils::add_new_dts_param "$node" "xlnx,addrwidth" $addrwidth noformating
	}
}

proc get_connected_ip {drv_handle dma_pin} {
	global connected_ip
	# Check whether dma is connected to 10G/25G MAC
	# currently we are handling only data fifo
	set intf [::hsi::get_intf_pins -of_objects [get_cells -hier $drv_handle] $dma_pin]
	set valid_eth_list "xxv_ethernet axi_ethernet axi_10g_ethernet usxgmii"
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
		# here dma connected to data fifo
		set dma_pin "M_AXIS"
		get_connected_ip $connected_ip $dma_pin
	} elseif {[lsearch -nocase $valid_eth_list $iptype] >= 0 } {
		# dma connected to 10G/25G MAC, 1G or 10G
		return 1
	} else {
		# dma connected via interconnects
		set dma_pin "M_AXIS"
		get_connected_ip $connected_ip $dma_pin
	}
}

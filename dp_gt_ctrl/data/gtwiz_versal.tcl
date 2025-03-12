#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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
	set compatible [append compatible " " "xlnx,gt-quad-base-1.1"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	puts prasanna
	# Get the number of Rx and Tx interfaces
	set Rx_No_Of_Interfaces [get_property CONFIG.INTF0_NO_OF_LANES [get_cells -hier $drv_handle]]
	set Tx_No_Of_Interfaces [get_property CONFIG.INTF1_NO_OF_LANES [get_cells -hier $drv_handle]]

	# Create PHY nodes for both Rx and Tx interfaces
	for {set ch 0} {$ch < $Rx_No_Of_Interfaces} {incr ch} {
		create_rx_phy_node "rx" $ch $drv_handle $node
	}
	for {set ch 0} {$ch < $Tx_No_Of_Interfaces} {incr ch} {
		create_tx_phy_node "tx" $ch $drv_handle $node
	}
}


proc create_rx_phy_node {channel_type ch drv_handle node} {
	set pinname "INTF0_RX${ch}_GT_IP_interface"
	set channelip [get_connected_stream_ip [get_cells -hier $drv_handle] $pinname]
	if {[llength $channelip] && [llength [::hsi::get_intf_pins -of_objects $channelip]]} {
		set phy_node [add_or_get_dt_node -n "${pinname}${channelip}" -l "${drv_handle}${channel_type}phy_lane${ch}" -p $node]
		hsi::utils::add_new_dts_param "$phy_node" "#phy-cells" 4 int
	}
}

proc create_tx_phy_node {channel_type ch drv_handle node} {
	set pinname "INTF1_TX${ch}_GT_IP_interface"
	set channelip [get_connected_stream_ip [get_cells -hier $drv_handle] $pinname]
	if {[llength $channelip] && [llength [::hsi::get_intf_pins -of_objects $channelip]]} {
		set phy_node [add_or_get_dt_node -n "${pinname}${channelip}" -l "${drv_handle}${channel_type}phy_lane${ch}" -p $node]
		hsi::utils::add_new_dts_param "$phy_node" "#phy-cells" 4 int
	}
}

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
	set compatible [append compatible " " "xlnx,audio-formatter-1.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set tx_connect_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "m_axis_mm2s"]
	foreach connect_ip $tx_connect_ip {
		if {[llength $connect_ip] != 0} {
			set connected_ip_type [get_property IP_NAME $connect_ip]
			if {[string match -nocase $connected_ip_type "system_ila"]} {
				continue
			}
			hsi::utils::add_new_dts_param "$node" "xlnx,tx" $connect_ip reference
		} else {
			dtg_warning "$drv_handle pin m_axis_mm2s is not connected... check your design"
		}
	}
	set rx_connect_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_s2mm"]
	foreach connect_ip $rx_connect_ip {
		if {[llength $connect_ip] != 0} {
			set connected_ip_type [get_property IP_NAME $connect_ip]
			if {[string match -nocase $connected_ip_type "system_ila"]} {
				continue
			}
			hsi::utils::add_new_dts_param "$node" "xlnx,rx" $connect_ip reference
		} else {
			dtg_warning "$drv_handle pin s_axis_s2mm is not connected... check your design"
		}
	}

}

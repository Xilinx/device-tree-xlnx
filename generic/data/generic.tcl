#
# (C) Copyright 2014-2015 Xilinx, Inc.
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

	set hsi_version [get_hsi_version]
	set ver [split $hsi_version "."]
	set value [lindex $ver 0]
	if {$value >= 2018} {
		set generic_node [gen_peripheral_nodes $drv_handle]
		set last [string last "@" $generic_node]
		if {$last != -1} {
			hsi::utils::add_new_dts_param "${generic_node}" "/* This is a place holder node for a custom IP, user may need to update the entries */" "" comment
		}
	}
}

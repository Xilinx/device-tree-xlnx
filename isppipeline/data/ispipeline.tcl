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
	if {[llength $ip_name]} {
		set compatible [get_comp_str $drv_handle]
		set compatible [append compatible " " "xlnx,isppipeline-1.0"]
		set_drv_prop $drv_handle compatible "$compatible" stringlist
	}
}

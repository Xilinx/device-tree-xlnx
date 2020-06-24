#
# (C) Copyright 2019 Xilinx, Inc.
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

	set ospi_handle [get_cells -hier $drv_handle]
	set ospi_mode [hsi::utils::get_ip_param_value $ospi_handle "C_OSPI_MODE"]
	set is_stacked 0
	set is_dual 0
	if {$ospi_mode == 1} {
		set is_stacked 1
	}

	set_property CONFIG.is-dual $is_dual $drv_handle
	set_property CONFIG.is-stacked $is_stacked $drv_handle

}

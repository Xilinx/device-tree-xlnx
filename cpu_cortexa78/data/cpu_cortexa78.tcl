#
# (C) Copyright 2018-2022 Xilinx, Inc.
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
	global dtsi_fname
    set board_dtsi_file ""
	set overrides [get_property CONFIG.periph_type_overrides [get_os]]
	foreach override $overrides {
	    if {[lindex $override 0] == "BOARD"} {
	        set board_dtsi_file [lindex $override 1]
	    }
	}
    #TMP fix to support ipp fixed clocks
    if {[string match -nocase $board_dtsi_file "versal-net-ipp-rev1.9"]} {
        set dtsi_fname "versal-net/versal-net-ipp-rev1.9.dtsi"
    } else {
	    set dtsi_fname "versal-net/versal-net.dtsi"
    }

	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}

	# create root node
	set master_root_node [gen_root_node $drv_handle]
	set nodes [gen_cpu_nodes $drv_handle]
}

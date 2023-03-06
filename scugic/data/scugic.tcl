#
# (C) Copyright 2014-2022 Xilinx, Inc.
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
	set default_dts [set_drv_def_dts $drv_handle]
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	set cpm_ip [get_cells -hier -filter IP_NAME==psv_cpm]
	if {[string match -nocase $proctype "psv_cortexa72"] && \
		[string match -nocase [get_property CONFIG.APU_GIC_ITS_CTL [get_cells -hier $drv_handle]] "0xF9020000"] && \
		[llength $cpm_ip]} {
		set gic_node [add_or_get_dt_node -n "&gic_its" -d $default_dts]
		hsi::utils::add_new_dts_param "${gic_node}" "status" "okay" string
	}
}

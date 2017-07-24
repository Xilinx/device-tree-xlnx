#
# (C) Copyright 2017 Xilinx, Inc.
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
	set ldpc_decode [get_property CONFIG.LDPC_Decode [get_cells -hier $drv_handle]]
	set ldpc_encode [get_property CONFIG.LDPC_Encode [get_cells -hier $drv_handle]]
	set turbo_decode [get_property CONFIG.Turbo_Decode [get_cells -hier $drv_handle]]
	if {[string match -nocase $turbo_decode "true"]} {
		set sdfec_code "turbo"
		set sdfec_op_mode "decode"
	} else {
		set sdfec_code "ldpc"
		if {[string match -nocase $ldpc_encode "true"]} {
			set sdfec_op_mode "encode"
		} else {
			set sdfec_op_mode "decode"
		}
	}
	set_drv_property $drv_handle xlnx,sdfec-op-mode $sdfec_op_mode string
	set_drv_property $drv_handle xlnx,sdfec-code $sdfec_code string
}

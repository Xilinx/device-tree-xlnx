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

	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set enable_enc_dec [get_property CONFIG.ENABLE_ENC_DEC [get_cells -hier $drv_handle]]
	if {$enable_enc_dec == 0} {
	#encode case
		hsi::utils::add_new_dts_param "${node}" "xlnx,encode" "" boolean
		set no_of_enc_chan [get_property CONFIG.NO_OF_ENC_CHAN [get_cells -hier $drv_handle]]
		set no_of_enc_chan [expr $no_of_enc_chan + 1]
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-chan" $no_of_enc_chan int
	} else {
	#decode case
		set no_of_dec_chan [get_property CONFIG.NO_OF_DEC_CHAN [get_cells -hier $drv_handle]]
		set no_of_dec_chan [expr $no_of_dec_chan + 1]
		hsi::utils::add_new_dts_param "${node}" "xlnx,num-chan" $no_of_dec_chan int
	}
}

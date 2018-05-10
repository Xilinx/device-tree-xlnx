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
	set compatible [get_ipdetails $drv_handle]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ldpc_decode [get_property CONFIG.LDPC_Decode [get_cells -hier $drv_handle]]
	set ldpc_encode [get_property CONFIG.LDPC_Encode [get_cells -hier $drv_handle]]
	set turbo_decode [get_property CONFIG.Turbo_Decode [get_cells -hier $drv_handle]]
	if {[string match -nocase $turbo_decode "true"]} {
		set sdfec_code "turbo"
	} else {
		set sdfec_code "ldpc"
	}
	set_drv_property $drv_handle xlnx,sdfec-code $sdfec_code string
	set sdfec_dout_words [get_property CONFIG.C_S_DOUT_WORDS_MODE [get_cells -hier $drv_handle]]
	set sdfec_dout_width [get_property CONFIG.DOUT_Lanes [get_cells -hier $drv_handle]]
	set sdfec_din_words [get_property CONFIG.C_S_DIN_WORDS_MODE [get_cells -hier $drv_handle]]
	set sdfec_din_width [get_property CONFIG.DIN_Lanes [get_cells -hier $drv_handle]]
	set_drv_property $drv_handle xlnx,sdfec-dout-words $sdfec_dout_words int
	set_drv_property $drv_handle xlnx,sdfec-dout-width $sdfec_dout_width int
	set_drv_property $drv_handle xlnx,sdfec-din-words  $sdfec_din_words int
	set_drv_property $drv_handle xlnx,sdfec-din-width  $sdfec_din_width int
}

proc get_ipdetails {drv_handle} {
	set slave [get_cells -hier ${drv_handle}]
	set vlnv [split [get_property VLNV $slave] ":"]
	set name [lindex $vlnv 2]
	set ver [lindex $vlnv 3]
	set comp_prop "xlnx,${name}-${ver}"
	regsub -all {_} $comp_prop {-} comp_prop
	return $comp_prop
}

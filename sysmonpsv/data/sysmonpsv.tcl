#
# (C) Copyright 2020 Xilinx, Inc.
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
    set num_supply_channels 0
    set periph_list [get_cells -hier]
    set node [gen_peripheral_nodes $drv_handle]
    if {$node == 0} {
	return
    }
    hsi::utils::add_new_dts_param $node "#address-cells" 1 int
    hsi::utils::add_new_dts_param $node "#size-cells" 0 int

    for {set supply_num 0} {$supply_num < 160} {incr supply_num} {
	    set meas "C_MEAS_${supply_num}"
	    set id "${meas}_ROOT_ID"
	    set value [get_property CONFIG.$meas [get_cells -hier $drv_handle]]
	    if {[llength $value] != 0} {
		    set local_value [string tolower [get_property CONFIG.$meas [get_cells -hier $drv_handle]]]
		    set id_value [get_property CONFIG.$id [get_cells -hier $drv_handle]]
		    set supply_node [add_or_get_dt_node -n "supply@$id_value" -p $node]
		    hsi::utils::add_new_dts_param "$supply_node" "reg" "$id_value" int
		    hsi::utils::add_new_dts_param "$supply_node" "xlnx,name" "$local_value" string
		    incr num_supply_channels
	    }
    }
    append numsupplies "/bits/8 <$num_supply_channels>"
    hsi::utils::add_new_dts_param $node "xlnx,numchannels" $numsupplies noformating
}

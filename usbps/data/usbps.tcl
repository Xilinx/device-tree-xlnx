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

    ps7_reset_handle $drv_handle CONFIG.C_USB_RESET CONFIG.usb-reset
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    set default_dts [set_drv_def_dts $drv_handle]
    if {[string match -nocase $proctype "ps7_cortexa9"] } {
        set_drv_prop $drv_handle phy_type ulpi string
    } else {
        set index [string index $drv_handle end]
        set rt_node [add_or_get_dt_node -n usb -l usb$index -d $default_dts -auto_ref_parent]
        hsi::utils::add_new_dts_param "${rt_node}" "status" "okay" string
    }
}

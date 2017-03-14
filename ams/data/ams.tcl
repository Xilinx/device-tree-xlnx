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
    set ams_list "ams_ps ams_pl"
    set dts_file [get_property CONFIG.pcw_dts [get_os]]
    foreach ams_name ${ams_list} {
        set ams_node [add_or_get_dt_node -n "&${ams_name}" -d $dts_file]
        hsi::utils::add_new_dts_param "${ams_node}" "status" "okay" string
    }
}

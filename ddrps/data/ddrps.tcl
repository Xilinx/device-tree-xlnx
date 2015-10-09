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

# workaround for ps7 ddrc has none zero start address
proc gen_ps7_ddr_reg_property {drv_handle} {
    proc_called_by
    set reg ""
    set psu_cortexa53 ""
    set slave [get_cells -hier ${drv_handle}]
    set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]

    if {[string match -nocase $proctype "psu_cortexa53"]} {
        set psu_cortexa53 "1"
    }
    foreach mem_handle ${ip_mem_handles} {
        #set base [get_property BASE_VALUE $mem_handle]
        set base 0x0
        set high [get_property HIGH_VALUE $mem_handle]
        set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
        if {$psu_cortexa53 == 1} {
                # check if size is crossing 4GB split the size to MSB and LSB
                if {[regexp -nocase {([0-9a-f]{9})} "$mem_size" match]} {
                        set size [format 0x%016x [expr {${high} - ${base} + 1}]]
                        set low_size [string range $size 0 9]
                        set high_size "0x[string range $size 10 17]"
		        set size "$low_size $high_size"
                } else {
                        set size [format 0x%08x [expr {${high} - ${base} + 1}]]
                }
        }
        if {[string_is_empty $reg]} {
                if {$psu_cortexa53 == 1} {
		       set reg "0x0 $base $mem_size"
                } else {
	               set reg "$base $mem_size"
                }
        } else {
            # ensure no duplication
            if {![regexp ".*${reg}.*" "$base $size" matched]} {
                set reg "$reg $base $size"
            }
        }
    }
    set_drv_prop_if_empty $drv_handle reg $reg intlist
}


proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }
    gen_ps7_ddr_reg_property $drv_handle
    add_memory_node $drv_handle
}

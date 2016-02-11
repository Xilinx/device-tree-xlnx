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
    foreach mem_handle ${ip_mem_handles} {
        #set base [get_property BASE_VALUE $mem_handle]
        set base 0x0
        set high [get_property HIGH_VALUE $mem_handle]
        set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
        if {[string match -nocase $proctype "psu_cortexa53"]} {
		# Check if memory crossing 4GB map, then split 2GB below 32 bit limit
		# and remaining above 32 bit limit
		if { [expr {${mem_size} + ${base}}] >= [expr 0x100000000] } {
			set low_mem_size [expr {0x80000000 - ${base}}]
			set high_mem_size [expr {${mem_size} - ${low_mem_size}}]
			set low_mem_size [format "0x%x" ${low_mem_size}]
			set high_mem_size [get_high_mem_size $high_mem_size]
			set regval "0x0 ${base} 0x0 $low_mem_size>, <0x8 0x00000000 $high_mem_size"
		} else {
			set regval "0x0 ${base} 0x0 ${mem_size}"
		}
        } else {
		set regval "$base $mem_size"
	}
        if {[string_is_empty $reg]} {
		set reg $regval
        } else {
            # ensure no duplication
            if {![regexp ".*${reg}.*" "$regval" matched]} {
                set reg "$regval"
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

proc get_high_mem_size {high_mem_size} {
	set size "0x0 0x0"
	set high_mem_size [format "0x%x" ${high_mem_size}]
	if {[regexp -nocase {0x([0-9a-f]{9})} "$high_mem_size" match]} {
		set temp $high_mem_size
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_mem "0x[string range $temp $rem $len]"
		set low_mem "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_mem [format 0x%08x $low_mem]
		set size "$low_mem $high_mem"
	} else {
		set size "0x0 $high_mem_size"
	}
	return $size
}

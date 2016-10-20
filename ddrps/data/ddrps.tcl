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
    set regprop [ hsi::utils::get_os_parameter_value "regp"]
    set psu_cortexa53 ""
    set slave [get_cells -hier ${drv_handle}]
    set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[string match -nocase $proctype "ps7_cortexa9"]} {
        set value 0
    } else {
        set value [generate_secure_memory $drv_handle]
    }
    if { $value !=0} {
        hsi::utils::set_os_parameter_value "regp" $value
        set_drv_prop_if_empty $drv_handle reg $value intlist
    } else {
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
        if {[string_is_empty $regprop]} {
		set regprop $regval
        } else {
            # ensure no duplication
            if {![regexp ".*${regprop}.*" "$regval" matched]} {
                set regprop "$regval"
            }
        }
    }
    hsi::utils::set_os_parameter_value "regp" $regprop
    set_drv_prop_if_empty $drv_handle reg $regprop intlist
    }
}

proc generate_secure_memory {drv_handle} {
    set regprop [ hsi::utils::get_os_parameter_value "regp"]
    set psu_cortexa53 ""
    set slave [get_cells -hier ${drv_handle}]
    set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
    set firstelement [lindex $ip_mem_handles 0]
    set index [lsearch [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] [get_cells $firstelement]]
    set avail_param [list_property [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] $index]]
    set addr_64 "0"
    set size_64 "0"
    if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
        foreach bank ${ip_mem_handles} {
            set state [get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] $index]]
            if {[string match -nocase $state "NonSecure"]} {
                set index [lsearch -start $index [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] [get_cells -hier $bank]]
                set base [get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] $index]]
                set high [get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] $index]]
                set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
                if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                    set addr_64 "1"
                    set temp $base
                    set temp [string trimleft [string trimleft $temp 0] x]
                    set len [string length $temp]
                    set rem [expr {${len} - 8}]
                    set high_base "0x[string range $temp $rem $len]"
                    set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                    set low_base [format 0x%08x $low_base]
                }
                if {[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]} {
                    set size_64 "1"
                    set temp $mem_size
                    set temp [string trimleft [string trimleft $temp 0] x]
                    set len [string length $temp]
                    set rem [expr {${len} - 8}]
                    set high_size "0x[string range $temp $rem $len]"
                    set low_size "0x[string range $temp 0 [expr {${rem} - 1}]]"
                    set low_size [format 0x%08x $low_size]
                }
                if {[string match $regprop ""]} {
                    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
                        set regprop "$low_base $high_base $low_size $high_size"
                    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
                        set regprop "${low_base} ${high_base} 0x0 ${mem_size}"
                    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
                        set regprop "0x0 ${base} 0x0 ${mem_size}"
                    } else {
                        set regprop "0x0 ${base} 0x0 ${mem_size}"
                    }
                } else {
                    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
                        append regprop ">, " "<$low_base $high_base $low_size $high_size"
                    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
                        append regprop ">, " "<${low_base} ${high_base} 0x0 ${mem_size}"
                    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
                        append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
                    } else {
                        append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
                    }
                }
            }
            set addr_64 "0"
            set size_64 "0"
            set index [expr $index + 1]
        }
        return $regprop
    } else {
        return 0
    }
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
    set value [get_property CONFIG.reg $drv_handle]
    if {![string match $value ""]} {
       add_memory_node $drv_handle
    }
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

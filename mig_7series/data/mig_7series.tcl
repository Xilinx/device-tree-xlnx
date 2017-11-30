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
	set ddr_ip ""
	set slave [get_cells -hier ${drv_handle}]
	set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
	set main_memory  [get_property CONFIG.main_memory [get_os]]
	if {![string match -nocase $main_memory "none"]} {
		set ddr_ip [get_property IP_NAME [get_cells -hier $main_memory]]
	}
	set drv_ip [get_property IP_NAME [get_cells -hier $drv_handle]]

	if {[regexp $drv_ip $ddr_ip match]} {
		set master_dts [get_property CONFIG.master_dts [get_os]]
		set cur_dts [current_dt_tree]
		set master_dts_obj [get_dt_trees ${master_dts}]
		set_cur_working_dts $master_dts

		set parent_node [add_or_get_dt_node -n / -d ${master_dts}]
		set base [get_property CONFIG.C_BASEADDR [get_cells -hier $drv_handle]]
		set high [get_property CONFIG.C_HIGHADDR [get_cells -hier $drv_handle]]
		set size [format 0x%x [expr {${high} - ${base} + 1}]]
		set memory_node [add_or_get_dt_node -n memory -u 0 -p $parent_node]
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
				set temp $base
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_base "0x[string range $temp $rem $len]"
				set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_base [format 0x%08x $low_base]
				if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
					set temp $size
					set temp [string trimleft [string trimleft $temp 0] x]
					set len [string length $temp]
					set rem [expr {${len} - 8}]
					set high_size "0x[string range $temp $rem $len]"
					set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
					set low_size [format 0x%08x $low_size]
					set reg "$low_base $high_base $low_size $high_size"
				} else {
					set reg "$low_base $high_base 0x0 $size"
				}
			} else {
				set reg "0x0 $base 0x0 $size"
			}
		} else {
			set reg "$base $size"
		}

		hsi::utils::add_new_dts_param "${memory_node}" "reg" $reg inthexlist
		if {[catch {set dev_type [get_property CONFIG.device_type $drv_handle]} msg]} {
			set dev_type memory
		}
		if {[string_is_empty $dev_type]} {set dev_type memory}
		hsi::utils::add_new_dts_param "${memory_node}" "device_type" $dev_type string
	}

	set ip_mem_handle [lindex [hsi::utils::get_ip_mem_ranges [get_cells -hier $slave]] 0]
	set addr [string tolower [get_property BASE_VALUE $ip_mem_handle]]
	set base [string tolower [get_property BASE_VALUE $ip_mem_handle]]
	set high [string tolower [get_property HIGH_VALUE $ip_mem_handle]]
	set size [format 0x%x [expr {${high} - ${base} + 1}]]
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "psu_cortexa53"]} {
		if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
			set temp $base
			set temp [string trimleft [string trimleft $temp 0] x]
			set len [string length $temp]
			set rem [expr {${len} - 8}]
			set high_base "0x[string range $temp $rem $len]"
			set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
			set low_base [format 0x%08x $low_base]
			if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
				set temp $size
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_size "0x[string range $temp $rem $len]"
				set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_size [format 0x%08x $low_size]
				set reg "$low_base $high_base $low_size $high_size"
			} else {
				set reg "$low_base $high_base 0x0 $size"
			}
		} else {
			set reg "0x0 $base 0x0 $size"
		}
	} else {
		set reg "$base $size"
	}
	set_drv_prop_if_empty $drv_handle reg $reg intlist
}

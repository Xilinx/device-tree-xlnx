#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Michal SIMEK <monstr@monstr.eu>
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

    set ip [get_cells -hier $drv_handle]
    set clk ""
    set clkhandle [get_pins -of_objects $ip "CLK"]
    if { [string compare -nocase $clkhandle ""] != 0 } {
        set clk [get_property CLK_FREQ $clkhandle]
    }
    if { [llength $ip]  } {
        set_property CONFIG.clock-frequency    "$clk" $drv_handle
        set_property CONFIG.timebase-frequency "$clk" $drv_handle
    }

    set icache_size [hsi::utils::get_ip_param_value $ip "C_CACHE_BYTE_SIZE"]
    set isize  [check_64bit $icache_size]
    set icache_base [hsi::utils::get_ip_param_value $ip "C_ICACHE_BASEADDR"]
    set ibase  [check_64bit $icache_base]
    set icache_high [hsi::utils::get_ip_param_value $ip "C_ICACHE_HIGHADDR"]
    set ihigh_base  [check_64bit $icache_high]
    set dcache_size [hsi::utils::get_ip_param_value $ip "C_DCACHE_BYTE_SIZE"]
    set dsize  [check_64bit $dcache_size]
    set dcache_base [hsi::utils::get_ip_param_value $ip "C_DCACHE_BASEADDR"]
    set dbase  [check_64bit $dcache_base]
    set dcache_high [hsi::utils::get_ip_param_value $ip "C_DCACHE_HIGHADDR"]
    set dhigh_base  [check_64bit $dcache_high]
    set icache_line_size [expr 4*[hsi::utils::get_ip_param_value $ip "C_ICACHE_LINE_LEN"]]
    set dcache_line_size [expr 4*[hsi::utils::get_ip_param_value $ip "C_DCACHE_LINE_LEN"]]


    if { [llength $icache_size] != 0 } {
        set_property CONFIG.i-cache-baseaddr  "$ibase"      $drv_handle
        set_property CONFIG.i-cache-highaddr  "$ihigh_base" $drv_handle
        set_property CONFIG.i-cache-size      "$isize"      $drv_handle
        set_property CONFIG.i-cache-line-size "$icache_line_size" $drv_handle
    }
    if { [llength $dcache_size] != 0 } {
        set_property CONFIG.d-cache-baseaddr  "$dbase"      $drv_handle
        set_property CONFIG.d-cache-highaddr  "$dhigh_base" $drv_handle
        set_property CONFIG.d-cache-size      "$dsize"      $drv_handle
        set_property CONFIG.d-cache-line-size "$dcache_line_size" $drv_handle
    }

    set model "[get_property IP_NAME $ip],[hsi::utils::get_ip_version $ip]"
    set_property CONFIG.model $model $drv_handle

    # create root node
    set master_root_node [gen_root_node $drv_handle]
    set nodes [gen_cpu_nodes $drv_handle]
}

proc check_64bit {base} {
	if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		set temp $base
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_base "0x[string range $temp $rem $len]"
		set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_base [format 0x%08x $low_base]
		if {$low_base == 0x0} {
			set reg "$high_base"
		} else {
			set reg "$low_base $high_base"
		}
	} else {
		set reg "$base"
	}
	return $reg
}

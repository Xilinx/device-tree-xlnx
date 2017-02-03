#
# (C) Copyright 2014-2015 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
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
    set consoleip [get_property CONFIG.console_device [get_os]]
    set port_number 0
    if {[string match -nocase "$ip" "$consoleip"] == 0} {
        set serial_count [hsi::utils::get_os_parameter_value "serial_count"]
        if { [llength $serial_count]  == 0 } {
            set serial_count 0
        }
        incr serial_count
        hsi::utils::set_os_parameter_value "serial_count" $serial_count
        set port_number $serial_count
    } else {
        #adding os console property if this is console ip
        set avail_param [list_property [get_cells -hier $drv_handle]]
        # This check is needed because BAUDRATE parameter for psuart is available from
        # 2017.1 onwards
        if {[lsearch -nocase $avail_param "CONFIG.C_BAUDRATE"] >= 0} {
            set baud [get_property CONFIG.C_BAUDRATE [get_cells -hier $drv_handle]]
        } else {
            set baud "115200"
        }
        hsi::utils::set_os_parameter_value "console" "ttyPS0,$baud"
    }
    set_property CONFIG.port-number $port_number $drv_handle
    set uboot_prop [get_property IP_NAME [get_cells -hier $drv_handle]]
    if {[string match -nocase $uboot_prop "psu_uart"]} {
        set_drv_prop $drv_handle "u-boot,dm-pre-reloc" "" boolean
    }
}

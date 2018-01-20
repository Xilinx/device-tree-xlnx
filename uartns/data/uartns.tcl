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
    # try to source the common tcl procs
    # assuming the order of return is based on repo priority
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }

    set ip [get_cells -hier $drv_handle]
    set has_xin [hsi::utils::get_ip_param_value $ip C_HAS_EXTERNAL_XIN]
    set clock_port "S_AXI_ACLK"
    if { [string match -nocase "$has_xin" "1"] } {
        set_drv_conf_prop $drv_handle C_EXTERNAL_XIN_CLK_HZ clock-frequency
        # TODO: update the clock-names and clocks properties and create a
        # fixed clock node. Currently this is causing any issue as the
        # driver only uses clock-frequency property

    } else {
        set freq [hsi::utils::get_clk_pin_freq $ip "$clock_port"]
        set_property clock-frequency $freq $drv_handle
    }

    set consoleip [get_property CONFIG.console_device [get_os]]
    if { [string match -nocase $consoleip $ip] } {
        hsi::utils::set_os_parameter_value "console" "ttyS0,115200"
    }

    set proc_type [get_sw_proc_prop IP_NAME]
    switch $proc_type {
            "psu_cortexa53" {
                 update_clk_node $drv_handle "s_axi_aclk"
            } "microblaze"   {
                 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
            } "ps7_cortexa9" {
                 update_zynq_clk_node $drv_handle "s_axi_aclk"
            } default {
                 error "Unknown arch"
            }
    }
}

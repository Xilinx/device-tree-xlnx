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
    # try to source the common tcl procs
    # assuming the order of return is based on repo priority
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }
    set compatible [get_comp_str $drv_handle]
    set compatible [append compatible " " "xlnx,xps-timer-1.00.a"]
    set_drv_prop $drv_handle compatible "$compatible" stringlist
    #adding clock frequency
    set ip [get_cells -hier $drv_handle]
    set clk [get_pins -of_objects $ip "S_AXI_ACLK"]
    if {[llength $clk] } {
        set freq [get_property CLK_FREQ $clk]
        set_property clock-frequency "$freq" $drv_handle
    }
    set proc_type [get_sw_proc_prop IP_NAME]
    switch $proc_type {
          "microblaze"   {
                 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
          }
    }
}

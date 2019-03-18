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
    set compatible [append compatible " " "xlnx,axi-can-1.00.a"]
    set_drv_prop $drv_handle compatible "$compatible" stringlist
    set ip_name [get_property IP_NAME [get_cells -hier $drv_handle]]
    set version [string tolower [common::get_property VLNV $drv_handle]]
    if {[string match -nocase $ip_name "canfd"]} {
        if {[string compare -nocase "xilinx.com:ip:canfd:1.0" $version] == 0} {
            hsi::utils::add_new_property $drv_handle "compatible" stringlist "xlnx,canfd-1.0"
        } else {
            hsi::utils::add_new_property $drv_handle "compatible" stringlist "xlnx,canfd-2.0"
        }
        set_drv_conf_prop $drv_handle NUM_OF_TX_BUF tx-mailbox-count hexint
        set_drv_conf_prop $drv_handle NUM_OF_TX_BUF rx-fifo-depth hexint
    } else {
        set_drv_conf_prop $drv_handle c_can_tx_dpth tx-fifo-depth hexint
        set_drv_conf_prop $drv_handle c_can_rx_dpth rx-fifo-depth hexint
    }

    set proc_type [get_sw_proc_prop IP_NAME]
    switch $proc_type {
         "microblaze" {
            gen_dev_ccf_binding $drv_handle "s_axi_aclk"
	}
    }
}

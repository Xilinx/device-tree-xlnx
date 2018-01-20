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
    set ip_name [get_property IP_NAME [get_cells -hier $drv_handle]]
    if {[string match -nocase $ip_name "canfd"]} {
        hsi::utils::add_new_property $drv_handle "compatible" stringlist "xlnx,canfd-1.0"
        set_drv_conf_prop $drv_handle NUM_OF_TX_BUF tx-fifo-depth hexint
        set_drv_conf_prop $drv_handle NUM_OF_TX_BUF rx-fifo-depth hexint
    } else {
        set_drv_conf_prop $drv_handle c_can_tx_dpth tx-fifo-depth hexint
        set_drv_conf_prop $drv_handle c_can_rx_dpth rx-fifo-depth hexint
    }

    set proc_type [get_sw_proc_prop IP_NAME]
    switch $proc_type {
        "ps7_cortexa9" {
             update_zynq_clk_node $drv_handle "can_clk s_axi_aclk"
        } "psu_cortexa53" {
             update_clk_node $drv_handle "can_clk s_axi_aclk"
        } "microblaze" {
            gen_dev_ccf_binding $drv_handle "s_axi_aclk"
	}
        default {
            error "Unknown arch"
        }
    }
}

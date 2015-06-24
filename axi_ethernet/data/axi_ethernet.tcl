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

    update_eth_mac_addr $drv_handle

    #adding stream connectivity
    set eth_ip [get_cells $drv_handle]
    # search for a valid bus interface name
    # This is required to work with Vivado 2015.1 due to IP PIN naming change
    foreach n "AXI_STR_RXD m_axis_rxd" {
        set intf [get_intf_pins -of_objects $eth_ip ${n}]
        if {[string_is_empty ${intf}] != 1} {
            break
        }
    }
    if { [llength $intf] } {
        set intf_net [get_intf_nets -of_objects $intf ]
        if { [llength $intf_net]  } {
            set target_intf [lindex [get_intf_pins -of_objects $intf_net -filter "TYPE==TARGET" ] 0]
            if { [llength $target_intf] } {
                set connected_ip [get_cells -of_objects $target_intf]
                set_property axistream-connected "$connected_ip" $drv_handle
                set_property axistream-control-connected "$connected_ip" $drv_handle
            }
        }
    }

    #adding clock frequency
    set clk [get_pins -of_objects $eth_ip "S_AXI_ACLK"]
    if {[llength $clk] } {
        set freq [get_property CLK_FREQ $clk]
        set_property clock-frequency "$freq" $drv_handle
    }

    # node must be created before child node
    set node [gen_peripheral_nodes $drv_handle]
    set mdio_node [gen_mdio_node $drv_handle $node]

    gen_dev_ccf_binding $drv_handle "s_axi_aclk"
}


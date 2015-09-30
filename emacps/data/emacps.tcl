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

##############################################################################
variable phy_count 0
##############################################################################

proc is_gmii2rgmii_conv_present {slave} {
    set phy_addr -1
    set ipconv 0

    set ips [get_cells -hier -filter {IP_NAME == "gmii_to_rgmii"}]
    set ip_name [get_property NAME $slave]
    set slave_pins [get_pins -of_objects [get_cells -hier $slave]]

    foreach ip $ips {
        set ipconv2eth_pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $ip "gmii_txd"]]]
        foreach gmii_pin ${ipconv2eth_pins} {
            # check if it is connected to the slave IP
            if { [lsearch ${slave_pins} $gmii_pin] >= 0 } {
                set ipconv $ip
                set phy_addr [get_property "CONFIG.C_PHYADDR" $ipconv]
                break
            }
        }
        if { $phy_addr >= 0 } {
            break
        }
    }
    return "$phy_addr $ipconv"
}

proc gen_phy_node args {
    set mdio_node [lindex $args 0]
    set phy_name [lindex $args 1]
    set phya [lindex $args 2]

    set phy_node [add_or_get_dt_node -l ${phy_name} -n phy -u $phya -p $mdio_node]
    hsi::utils::add_new_dts_param "${phy_node}" "reg" $phya int
    hsi::utils::add_new_dts_param "${phy_node}" "device_type" "ethernet-phy" string
    if {[llength $args] >= 4} {
        hsi::utils::add_new_dts_param "${phy_node}" "compatible" [lindex $args 3] stringlist
    }
    return $phy_node
}

proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }

    update_eth_mac_addr $drv_handle

    set slave [get_cells -hier $drv_handle]
    set phymode [hsi::utils::get_ip_param_value $slave "C_ETH_MODE"]
    if { $phymode == 0 } {
        set_property CONFIG.phy-mode "gmii" $drv_handle
    } else {
        set_property CONFIG.phy-mode "rgmii-id" $drv_handle
    }

    set hwproc [get_cells -hier [get_sw_processor]]
    if { [llength [get_sw_processor] ] && [llength $hwproc] } {
        set ps7_cortexa9_1x_clk [hsi::utils::get_ip_param_value $hwproc "C_CPU_1X_CLK_FREQ_HZ"]
        set_property CONFIG.xlnx,ptp-enet-clock "$ps7_cortexa9_1x_clk" $drv_handle
    }
    ps7_reset_handle $drv_handle CONFIG.C_ENET_RESET CONFIG.enet-reset

    # only generate the mdio node if it has mdio
    set has_mdio [get_property CONFIG.C_HAS_MDIO $slave]
    if { $has_mdio == "0" } {
        return 0
    }

    # node must be created before child node
    set node [gen_peripheral_nodes $drv_handle]

    # check if gmii2rgmii converter is used.
    set conv_data [is_gmii2rgmii_conv_present $slave]
    set phya [lindex $conv_data 0]
    if { $phya != "-1" } {
        set phy_name "[lindex $conv_data 1]"
        set_drv_prop $drv_handle gmii2rgmii-phy-handle "$phy_name" reference
        set mdio_node [gen_mdio_node $drv_handle $node]
        gen_phy_node $mdio_node $phy_name $phya
    }
}

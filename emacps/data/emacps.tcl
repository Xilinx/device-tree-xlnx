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
    } elseif { $phymode == 2 } {
        set_property CONFIG.phy-mode "sgmii" $drv_handle
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
    set proc_type [get_sw_proc_prop IP_NAME]
    if {[string match -nocase $proc_type "psu_cortexa53"] } {
        set zynq_periph [get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
        set avail_param [list_property [get_cells -hier $zynq_periph]]
        if {[lsearch -nocase $avail_param "CONFIG.PSU__GEM__TSU__ENABLE"] >= 0} {
            set val [get_property CONFIG.PSU__GEM__TSU__ENABLE [get_cells -hier $zynq_periph]]
            if {$val == 1} {
                set default_dts [get_property CONFIG.pcw_dts [get_os]]
                set root_node [add_or_get_dt_node -n / -d ${default_dts}]
                set tsu_node [add_or_get_dt_node -n "tsu_ext_clk" -l "tsu_ext_clk" -d $default_dts -p $root_node]
                hsi::utils::add_new_dts_param "${tsu_node}" "compatible" "fixed-clock" stringlist
                hsi::utils::add_new_dts_param "${tsu_node}" "#clock-cells" 0 int
                set tsu-clk-freq [get_property CONFIG.C_ENET_TSU_CLK_FREQ_HZ [get_cells -hier $drv_handle]]
                hsi::utils::add_new_dts_param "${tsu_node}" "tsu-clk-freq" ${tsu-clk-freq} int
                set_drv_prop_if_empty $drv_handle "clock-names" "pclk hclk tx_clk rx_clk tsu_clk" stringlist
                set_drv_prop_if_empty $drv_handle "clocks" "clk 31>, <&clk 52>, <&clk 48>, <&clk 52>, <&tsu_ext_clk" reference
            }
        }
    }

    # check if gmii2rgmii converter is used.
    set conv_data [is_gmii2rgmii_conv_present $slave]
    set phya [lindex $conv_data 0]
    if { $phya != "-1" } {
        set phy_name "[lindex $conv_data 1]"
        set_drv_prop $drv_handle gmii2rgmii-phy-handle "$phy_name" reference
        set mdio_node [gen_mdio_node $drv_handle $node]
        gen_phy_node $mdio_node $phy_name $phya
    }
    set is_pcspma [get_cells -hier -filter {IP_NAME == gig_ethernet_pcs_pma}]
    if {![string_is_empty ${is_pcspma}] && $phymode == 2} {
        # if eth mode is sgmii and no external pcs/pma found
        hsi::utils::add_new_property $drv_handle "is-internal-pcspma" boolean ""
    }
}

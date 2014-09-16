##############################################################################
variable phy_count 0
##############################################################################

proc gen_mdio_node {drv_handle} {
    set mdio_child_name "mdio"
    set mdio [hsm::utils::add_new_child_node $drv_handle $mdio_child_name]
    hsm::utils::add_new_property $mdio "#address-cells" int 1
    hsm::utils::add_new_property  $mdio "#size-cells" int 0
    return $mdio
}

proc ps7_reset_handle {drv_handle reset_pram conf_prop} {
    set ip [get_cells $drv_handle]
    set value [get_property CONFIG.${reset_pram} $ip]
    # workaround for reset not been selected
    regsub -all "<Select>" $value "" value
    if { [llength $value] } {
        regsub -all "MIO( |)" $value "" value
        if { $value != "-1" && [llength $value] !=0  } {
            set_property CONFIG.${conf_prop} "ps7_gpio_0 $value 0" $drv_handle
        }
    }
}

proc is_gmii2rgmii_conv_present {slave} {
    set phy_addr -1
    set ipconv 0

    set ips [get_cells -filter {IP_NAME == "gmii_to_rgmii"}]
    set ip_name [get_property NAME $slave]
    set slave_pins [get_pins -of_objects [get_cells $slave]]

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

    set phy_node [hsm::utils::add_new_child_node $mdio_node "${phy_name}"]
    hsm::utils::add_new_property  $phy_node "reg" int $phya
    hsm::utils::add_new_property  $phy_node "device_type" string "ethernet-phy"
    if {[llength $args] >= 4} {
        hsm::utils::add_new_property  $phy_node "compatible" stringlist [lindex $args 3]
    }
    return $phy_node
}

proc generate {drv_handle} {
    set mdio_node [gen_mdio_node $drv_handle]

    set slave [get_cells $drv_handle]
    set phymode [get_ip_param_value $slave "C_ETH_MODE"]
    if { $phymode == 0 } {
        set_property CONFIG.phy-mode "gmii" $drv_handle
    } else {
        set_property CONFIG.phy-mode "rgmii-id" $drv_handle
    }

    set hwproc [get_cells [get_sw_processor]]
    if { [llength [get_sw_processor] ] && [llength $hwproc] } {
        set ps7_cortexa9_1x_clk [get_ip_param_value $hwproc "C_CPU_1X_CLK_FREQ_HZ"]
        set_property CONFIG.xlnx,ptp-enet-clock "$ps7_cortexa9_1x_clk" $drv_handle
    }
    ps7_reset_handle $drv_handle C_ENET_RESET enet-reset

    # check if gmii2rgmii converter is used.
    set conv_data [is_gmii2rgmii_conv_present $slave]
    set phya [lindex $conv_data 0]
    if { $phya != "-1" } {
        set phy_name "[lindex $conv_data 1]"
        hsm::utils::add_new_property $drv_handle gmii2rgmii-phy-handle reference "$phy_name"
        gen_phy_node $mdio_node $phy_name $phya
    }
}

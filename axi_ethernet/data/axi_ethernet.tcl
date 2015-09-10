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
    set eth_ip [get_cells -hier $drv_handle]
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

    set ip_name [get_property IP_NAME $eth_ip]
    if {$ip_name == "axi_ethernet"} {
	set txcsum [get_property CONFIG.TXCSUM $eth_ip]
	set txcsum [get_checksum $txcsum]
	set rxcsum [get_property CONFIG.RXCSUM $eth_ip]
	set rxcsum [get_checksum $rxcsum]
	set phytype [get_property CONFIG.PHY_TYPE $eth_ip]
	set phytype [get_phytype $phytype]
	set phyaddr [get_property CONFIG.PHYADDR $eth_ip]
	set phyaddr [::hsi::utils::convert_binary_to_decimal $phyaddr]
	set rxmem [get_property CONFIG.RXMEM $eth_ip]
	set rxmem [get_memrange $rxmem]
	set_property xlnx,txcsum "$txcsum" $drv_handle
	set_property xlnx,rxcsum "$rxcsum" $drv_handle
	set_property xlnx,phy-type "$phytype" $drv_handle
	set_property xlnx,phyaddr "$phyaddr" $drv_handle
	set_property xlnx,rxmem "$rxmem" $drv_handle
    }

    #adding clock frequency
    set clk [get_pins -of_objects $eth_ip "S_AXI_ACLK"]
    if {[llength $clk] } {
        set freq [get_property CLK_FREQ $clk]
        set_property clock-frequency "$freq" $drv_handle
    }

    # node must be created before child node
    set node [gen_peripheral_nodes $drv_handle]
    if {$ip_name == "axi_ethernet"} {
	set hier_params [gen_hierip_params $drv_handle]
    }
    set mdio_node [gen_mdio_node $drv_handle $node]

    gen_dev_ccf_binding $drv_handle "s_axi_aclk"
}

proc get_checksum {value} {
        if {[string compare -nocase $value "None"] == 0} {
                set value 0
        } elseif {[string compare -nocase $value "Partial"] == 0} {
                set value 1
        } else {
                set value 2
        }

        return $value
}

proc get_memrange {value} {
	set values [split $value "k"]
	lassign $values value1 value2

	return [expr $value1 * 1024]
}

proc get_phytype {value} {
        if {[string compare -nocase $value "MII"] == 0} {
                set value 0
        } elseif {[string compare -nocase $value "GMII"] == 0} {
                set value 1
        } elseif {[string compare -nocase $value "RGMII"] == 0} {
                set value 3
        } elseif {[string compare -nocase $value "SGMII"] == 0} {
                set value 4
        } else {
                set value 5
        }

        return $value
}

proc gen_hierip_params {drv_handle} {
	set prop_name_list [deault_parameters $drv_handle]
        foreach prop_name ${prop_name_list} {
                ip2drv_prop $drv_handle $prop_name
        }
}

proc deault_parameters {ip_handle {dont_generate ""}} {
        set par_handles [get_ip_conf_prop_list $ip_handle "CONFIG.*"]
        set valid_prop_names {}
        foreach par $par_handles {
                regsub -all {CONFIG.} $par {} tmp_par
                # Ignore some parameters that are always handled specially
                switch -glob $tmp_par {
                        $dont_generate - \
                        "Component_Name" - \
			"DIFFCLK_BOARD_INTERFACE" - \
			"EDK_IPTYPE" - \
			"ETHERNET_BOARD_INTERFACE" - \
			"Include_IO" - \
			"PHY_TYPE" - \
			"RXCSUM" - \
			"TXCSUM" - \
			"TXMEM" - \
			"RXMEM" - \
			"PHYADDR" - \
			"USE_BOARD_FLOW" - \
                        "HW_VER" { } \
                        default {
                                lappend valid_prop_names $par
                        }
                }
        }
        return $valid_prop_names
}

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

set rxethmem 0

proc generate {drv_handle} {
    global rxethmem
    set rxethmem 0
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
    set hasbuf [get_property CONFIG.processor_mode $eth_ip]
    set ip_name [get_property IP_NAME $eth_ip]

    if {$hasbuf == "true" || $hasbuf == "" && $ip_name != "axi_10g_ethernet" && $ip_name != "ten_gig_eth_mac"} {
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
   } else {
    foreach n "AXI_STR_RXD m_axis_rx" {
        set intf [get_intf_pins -of_objects $eth_ip ${n}]
        if {[string_is_empty ${intf}] != 1} {
            break
        }
    }

    if { [llength $intf] } {
        set connected_ip [get_connectedip $intf]
    }

    foreach n "AXI_STR_RXD m_axis_tx_ts" {
        set intf [get_intf_pins -of_objects $eth_ip ${n}]
        if {[string_is_empty ${intf}] != 1} {
            break
        }
    }

    if {[string_is_empty ${intf}] != 1} {
        set tx_tsip [get_connectedip $intf]
        set_property axififo-connected "$tx_tsip" $drv_handle
    }
      set_property axistream-connected "$connected_ip" $drv_handle
      set_property axistream-control-connected "$connected_ip" $drv_handle
      set_property xlnx,rxmem "$rxethmem" $drv_handle
   }

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


    if { $hasbuf == "false"} {
	    set ip_prop CONFIG.processor_mode
	    add_cross_property $eth_ip $ip_prop $drv_handle "xlnx,eth-hasnobuf" boolean
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


    set phytype [string tolower [get_property CONFIG.PHY_TYPE $eth_ip]]
    set_property phy-mode "$phytype" $drv_handle
    if {$phytype == "sgmii" || $phytype == "1000basex"} {
	  set phytype "sgmii"
      set_property phy-mode "$phytype" $drv_handle
	  set phynode [pcspma_phy_node $eth_ip]
	  set phya [lindex $phynode 0]
	  if { $phya != "-1"} {
		set phy_name "[lindex $phynode 1]"
	        set_drv_prop $drv_handle phy-handle "$phy_name" reference
		gen_phy_node $mdio_node $phy_name $phya
	  }
    }
    if {$ip_name == "axi_10g_ethernet"} {
       set phytype [string tolower [get_property CONFIG.base_kr $eth_ip]]
       set_property phy-mode "$phytype" $drv_handle
       set compatstring "xlnx,ten-gig-eth-mac"
       set_property compatible "$compatstring" $drv_handle
    }

    gen_dev_ccf_binding $drv_handle "s_axi_aclk"
}

proc pcspma_phy_node {slave} {
	set phyaddr [get_property CONFIG.PHYADDR $slave]
	set phyaddr [::hsi::utils::convert_binary_to_decimal $phyaddr]
	set phymode "phy$phyaddr"

	return "$phyaddr $phymode"
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
			"C_BASEADDR" - \
			"C_HIGHADDR" - \
			"processor_mode" - \
			"ENABLE_AVB" - \
			"ENABLE_LVDS" - \
			"Enable_1588_1step" - \
			"Enable_1588" - \
			"speed_1_2p5" - \
			"lvdsclkrate" - \
			"gtrefclkrate" - \
			"drpclkrate" - \
			"Enable_Pfc" - \
			"Frame_Filter" - \
			"MCAST_EXTEND" - \
			"MDIO_BOARD_INTERFACE" - \
			"Number_of_Table_Entries" - \
			"PHYRST_BOARD_INTERFACE" - \
			"RXVLAN_STRP" - \
			"RXVLAN_TAG" - \
			"RXVLAN_TRAN" - \
			"TXVLAN_STRP" - \
			"TXVLAN_TAG" - \
			"TXVLAN_TRAN" - \
			"SIMULATION_MODE" - \
			"Statistics_Counters" - \
			"Statistics_Reset" - \
			"Statistics_Width" - \
			"SupportLevel" - \
			"TIMER_CLK_PERIOD" - \
			"Timer_Format" - \
			"SupportLevel" - \
			"TransceiverControl" - \
			"USE_BOARD_FLOW" - \
                        "HW_VER" { } \
                        default {
                                lappend valid_prop_names $par
                        }
                }
        }
        return $valid_prop_names
}

proc gen_phy_node args {
    set mdio_node [lindex $args 0]
    set phy_name [lindex $args 1]
    set phya [lindex $args 2]

    set phy_node [add_or_get_dt_node -l ${phy_name} -n phy -u $phya -p $mdio_node]
    hsi::utils::add_new_dts_param "${phy_node}" "reg" $phya int
    hsi::utils::add_new_dts_param "${phy_node}" "device_type" "ethernet-phy" string
    hsi::utils::add_new_dts_param "${phy_node}" "compatible" "Xilinx PCS/PMA PHY" string

    return $phy_node
}

proc is_ethsupported_target {connected_ip} {
   set connected_ipname [get_property IP_NAME $connected_ip]
   if {$connected_ipname == "axi_dma" || $connected_ipname == "axi_fifo_mm_s"} {
      return "true"
   } else {
      return "false"
   }
}

proc get_targetip {ip} {
   set p2p_busifs_i [get_intf_pins -of_objects $ip -filter "TYPE==INITIATOR || TYPE==MASTER"]
   foreach p2p_busif $p2p_busifs_i {
      set busif_name [string toupper [get_property NAME  $p2p_busif]]
      set conn_busif_handle [::hsi::utils::get_connected_intf $ip $busif_name]
      set target_periph [get_cells -of_objects $conn_busif_handle]
   }
   return $target_periph
}

proc get_connectedip {intf} {
   global rxethmem
   if { [llength $intf]} {
      set intf_net [get_intf_nets -of_objects $intf ]
      if { [llength $intf_net]  } {
         set target_intf [lindex [get_intf_pins -of_objects $intf_net -filter "TYPE==TARGET" ] 0]
         if { [llength $target_intf] } {
            set connected_ip [get_cells -of_objects $target_intf]
            set target_ipname [get_property IP_NAME $connected_ip]
            if {$target_ipname == "axis_data_fifo"} {
               set rxethmem [get_property CONFIG.FIFO_DEPTH $connected_ip]
            } else {
	       # In 10G MAC case if the rx_stream interface is not connected to
	       # a Stream-fifo set the rxethmem value to a default jumbo MTU size
	       set rxethmem 9600
	    }
         }
         set target_ip [is_ethsupported_target $connected_ip]
         if { $target_ip == "true"} {
            return $connected_ip
         } else {
             set i 0
             set retries 5
             # When AXI Ethernet Configured in Non-Buf mode or In case of 10G MAC
             # The Ethernet MAC won't directly got connected to fifo or dma
             # We need to traverse through stream data fifo's and axi interconnects
             # Inorder to find the target IP(AXI DMA or AXI FIFO)
             while {$i < $retries} {
                set target_periph [get_targetip $connected_ip]
                set target_ip [is_ethsupported_target $target_periph]
                if { $target_ip == "true"} {
                  return $target_periph
                }
                set connected_ip $target_periph
                incr i
             }
             set error "Couldn't find a valid target_ip Please cross check hw design"
             return $error
         }
      }
   }
}

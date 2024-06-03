#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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
    global ddrv_handle
    set ddrv_handle $drv_handle
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }
    set remove_pl [get_property CONFIG.remove_pl [get_os]]
    if {[is_pl_ip $drv_handle] && $remove_pl} {
              return 0
    }

    set node [gen_peripheral_nodes $drv_handle]
    set hw_design [hsi::current_hw_design]
    set board_name ""
    if {[llength $hw_design]} {
        set board [split [get_property BOARD $hw_design] ":"]
        set board_name [lindex $board 1]
    }
    update_eth_mac_addr $drv_handle
    set compatible [get_comp_str $drv_handle]
    set compatible [append compatible " " "xlnx,axi-ethernet-1.00.a"]
    set_drv_prop $drv_handle compatible "$compatible" stringlist
    set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
    set default_dts [set_drv_def_dts $drv_handle]

    #adding stream connectivity
    set eth_ip [get_cells -hier $drv_handle]
    # search for a valid bus interface name
    # This is required to work with Vivado 2015.1 due to IP PIN naming change
    set hasbuf [get_property CONFIG.processor_mode $eth_ip]
    set ip_name [get_property IP_NAME $eth_ip]
    set num_cores 1
    if {($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")} {
        set ip_mem_handles [hsi::utils::get_ip_mem_ranges [get_cells -hier $drv_handle]]
        set num 0
        set base [string tolower [get_property BASE_VALUE [lindex $ip_mem_handles $num]]]
        set high [string tolower [get_property HIGH_VALUE [lindex $ip_mem_handles $num]]]
        set reg [generate_reg_property $base $high]
        hsi::utils::add_new_dts_param "${node}" "reg" $reg inthexlist
        set num_cores [get_property CONFIG.NUM_OF_CORES [get_cells -hier $drv_handle]]
    }
    set new_label ""
    set clk_label ""
    set connected_ip ""
    set eth_node ""
    for {set core 0} {$core < $num_cores} {incr core} {
          if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core != 0)} {
               if {$dt_overlay} {
                     set bus_node "amba"
               } else {
                    set bus_node "amba_pl"
               }
               set dts_file [current_dt_tree]
	       set ipmem_len [llength $ip_mem_handles]
	       if {$ipmem_len > 1} {
                  set base_addr [string tolower [get_property BASE_VALUE [lindex $ip_mem_handles $core]]]
                  regsub -all {^0x} $base_addr {} base_addr
                  append new_label $drv_handle "_" $core
                  append clk_label $drv_handle "_" $core
                  set eth_node [add_or_get_dt_node -n "ethernet" -l "$new_label" -u $base_addr -d $dts_file -p $bus_node]
                  set base [string tolower [get_property BASE_VALUE [lindex $ip_mem_handles $core]]]
                  set high [string tolower [get_property HIGH_VALUE [lindex $ip_mem_handles $core]]]
                  set reg [generate_reg_property $base $high]
                  hsi::utils::add_new_dts_param "${eth_node}" "reg" $reg inthexlist
	       }
          }
    if {(($hasbuf == "true") || ($hasbuf == "")) && ($ip_name != "axi_10g_ethernet") && ($ip_name != "ten_gig_eth_mac") && ($ip_name != "xxv_ethernet") && ($ip_name != "usxgmii") && ($ip_name != "ethernet_1_10_25g")} {

    foreach n "AXI_STR_RXD m_axis_rxd" {
        set intf [get_intf_pins -of_objects $eth_ip ${n}]
        if {[string_is_empty ${intf}] != 1} {
            break
        }
    }
    if { [llength $intf] } {
        set intf_net [get_intf_nets -of_objects $intf ]
        if { [llength $intf_net]  } {
            set target_intf [::hsi::utils::get_other_intf_pin $intf_net $intf]
            if { [llength $target_intf] } {
                set connected_ip [get_connectedip $intf]
		if {[llength $connected_ip]} {
			set_property axistream-connected "$connected_ip" $drv_handle
			set_property axistream-control-connected "$connected_ip" $drv_handle
			set ip_prop CONFIG.c_include_mm2s_dre
			add_cross_property $connected_ip $ip_prop $drv_handle "xlnx,include-dre" boolean
		} else {
			dtg_warning "$drv_handle connected ip is NULL for the interface $intf"
		}
                set ip_prop CONFIG.Enable_1588
                add_cross_property $eth_ip $ip_prop $drv_handle "xlnx,eth-hasptp" boolean
            }
        }
    }
    foreach n "AXI_STR_RXD m_axis_tx_ts" {
        set intf [get_intf_pins -of_objects $eth_ip ${n}]
        if {[string_is_empty ${intf}] != 1} {
            break
        }
    }

    if {[string_is_empty ${intf}] != 1} {
        set tx_tsip [get_connectedip $intf]
        set_drv_prop $drv_handle axififo-connected "$tx_tsip" reference
    }
   } else {
    foreach n "AXI_STR_RXD m_axis_rx" {
        set intf [get_intf_pins -of_objects $eth_ip ${n}]
        if {[string_is_empty ${intf}] != 1} {
            break
        }
    }

    if {($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g") || ($ip_name == "usxgmii")} {
    	foreach n "AXI_STR_RXD axis_rx_0" {
           set intf [get_intf_pins -of_objects $eth_ip ${n}]
           if {[string_is_empty ${intf}] != 1} {
               break
          }
       }
    }

    if { [llength $intf] } {
        set connected_ip [get_connectedip $intf]
    } else {
        set connected_ip ""
    }

    foreach n "AXI_STR_RXD m_axis_tx_ts" {
        set intf [get_intf_pins -of_objects $eth_ip ${n}]
        if {[string_is_empty ${intf}] != 1} {
            break
        }
    }

    if {[string_is_empty ${intf}] != 1} {
        set tx_tsip [get_connectedip $intf]
	if {[llength $tx_tsip]} {
           set_drv_prop $drv_handle axififo-connected "$tx_tsip" reference
	}
     } else {
        set port_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $eth_ip] "tx_ptp_tag_field_in_0"]]
	if {[llength $port_pins]} {
            set periph [::hsi::get_cells -of_objects $port_pins]
            if {[llength $periph]} {
                if {[string match -nocase [get_property IP_NAME $periph] "xlslice"]} {
                     set intf "Din"
                     set in1_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intf"]
                     set sink_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $periph] $in1_pin]]
		     if {[llength $sink_pins]} {
                          set per [::hsi::get_cells -of_objects $sink_pins]
                          if {[llength $per] && [string match -nocase [get_property IP_NAME $per] "axis_clock_converter"]} {
                              set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $per] "s_axis_tdata"]]
                              if {[llength $pins]} {
                                  set txfifo [get_cells -of_objects $pins]
                                  if {[llength $txfifo]} {
                                      set_drv_prop $drv_handle axififo-connected "$txfifo" reference
                                  }
                              }
                          }
                     }
                }
            }
        }
    }
    set rxfifo_port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $eth_ip] "rx_ptp_tstamp_out_0"]]
    if {[llength $rxfifo_port_pins]} {
        set periph [::hsi::get_cells -of_objects $rxfifo_port_pins]
        if {[llength $periph]} {
            if {[string match -nocase [get_property IP_NAME $periph] "xlconcat"]} {
                set intf "dout"
                set in1_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intf"]
                set sink_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $periph] $in1_pin]]
                if {[llength $sink_pins]} {
                    set per [::hsi::get_cells -of_objects $sink_pins]
                    if {[llength $per] && [string match -nocase [get_property IP_NAME $per] "axis_dwidth_converter"]} {
                        set con_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $per] "M_AXIS"]
                        if {[llength $con_ip]} {
                            if {[string match -nocase [get_property IP_NAME $con_ip] "axis_clock_converter"]} {
                                set rxtsfifo_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $con_ip] "M_AXIS"]
                                if {[llength $rxtsfifo_ip]} {
                                    set_drv_prop $drv_handle xlnx,rxtsfifo "$rxtsfifo_ip" reference
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if {![string_is_empty $connected_ip]} {
      set_property axistream-connected "$connected_ip" $drv_handle
      set_property axistream-control-connected "$connected_ip" $drv_handle
      set ip_prop CONFIG.c_include_mm2s_dre
      add_cross_property $connected_ip $ip_prop $drv_handle "xlnx,include-dre" boolean
    }
      set_property xlnx,rxmem "$rxethmem" $drv_handle
      if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core != 0)} {
          set intf [get_intf_pins -of_objects $eth_ip "axis_rx_${core}"]
          if {[llength $intf] && [llength $eth_node]} {
                set connected_ip [get_connectedip $intf]
                if {![string_is_empty $connected_ip]} {
                      hsi::utils::add_new_dts_param $eth_node "axistream-connected" "$connected_ip" reference
                      hsi::utils::add_new_dts_param $eth_node "axistream-control-connected" "$connected_ip" reference
                }
                hsi::utils::add_new_dts_param $eth_node "xlnx,include-dre" "" boolean
                hsi::utils::add_new_dts_param $eth_node "xlnx,rxmem" "$rxethmem" hex
         }
      }
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
	set_property xlnx,phyaddr "$phyaddr" $drv_handle
	set_property xlnx,rxmem "$rxmem" $drv_handle
    }

    set is_nobuf 0
    if {$ip_name == "axi_ethernet"} {
        set avail_param [list_property [get_cells -hier $drv_handle]]
        if {[lsearch -nocase $avail_param "CONFIG.speed_1_2p5"] >= 0} {
            if {[get_property CONFIG.speed_1_2p5 [get_cells -hier $drv_handle]] == "2p5G"} {
                set is_nobuf 1
                set_property compatible "xlnx,axi-2_5-gig-ethernet-1.0" $drv_handle
            }
        }
    }

    if { $hasbuf == "false" && $is_nobuf == 0} {
	    set ip_prop CONFIG.processor_mode
	    add_cross_property $eth_ip $ip_prop $drv_handle "xlnx,eth-hasnobuf" boolean
    }

    #adding clock frequency
    set clk [get_pins -of_objects $eth_ip "S_AXI_ACLK"]
    if {[llength $clk] } {
        set freq [get_property CLK_FREQ $clk]
        set_property clock-frequency "$freq" $drv_handle
        if {$ip_name == "xxv_ethernet" && [llength $eth_node]} {
             hsi::utils::add_new_dts_param $eth_node "clock-frequency" "$freq" int
        }
    }

    # node must be created before child node
    set node [gen_peripheral_nodes $drv_handle]
    if {$ip_name == "axi_ethernet"} {
	set hier_params [gen_hierip_params $drv_handle]
    }
    set mdio_node [gen_mdio_node $drv_handle $node]


    set phytype [string tolower [get_property CONFIG.PHY_TYPE $eth_ip]]
    if {$phytype == "rgmii" && $board_name == "kc705"} {
        set phytype "rgmii-rxid"
    } elseif {$phytype == "1000basex"} {
        set phytype "1000base-x"
    }
    set_property phy-mode "$phytype" $drv_handle
    if {$phytype == "sgmii" || $phytype == "1000base-x"} {
      set_property phy-mode "$phytype" $drv_handle
	  set phynode [pcspma_phy_node $eth_ip]
	  set phya [lindex $phynode 0]
	  if { $phya != "-1"} {
		set phy_name "[lindex $phynode 1]"
	        set_drv_prop $drv_handle pcs-handle "$drv_handle$phy_name" reference
		gen_phy_node $mdio_node $phy_name $phya $drv_handle
		if {[llength $node]} {
			hsi::utils::add_new_dts_param $node "managed" "in-band-status" string
			hsi::utils::add_new_dts_param $node "xlnx,switch-x-sgmii" "" boolean
		}
	  }
    }
    if {$ip_name == "xxv_ethernet" && $core != 0 && [llength $eth_node]} {
        append new_label "_" mdio
        set mdionode [add_or_get_dt_node -l "$new_label" -n mdio -p $eth_node]
        hsi::utils::add_new_dts_param "${mdionode}" "#address-cells" 1 int ""
        hsi::utils::add_new_dts_param "${mdionode}" "#size-cells" 0 int ""
        set new_label ""
    }
    if {$ip_name == "axi_10g_ethernet"} {
       set phytype [string tolower [get_property CONFIG.base_kr $eth_ip]]
       set_property phy-mode "$phytype" $drv_handle
       set compatible [get_comp_str $drv_handle]
       set compatible [append compatible " " "xlnx,ten-gig-eth-mac"]
       set_property compatible "$compatible" $drv_handle
    }
    if {$ip_name == "xxv_ethernet"} {
       set phytype [string tolower [get_property CONFIG.BASE_R_KR $eth_ip]]
       set linerate [get_property CONFIG.LINE_RATE $eth_ip]
       set_property phy-mode "${linerate}g${phytype}" $drv_handle
       set compatible [get_comp_str $drv_handle]
       set compatible [append compatible " " "xlnx,xxv-ethernet-1.0"]
       set_property compatible "$compatible" $drv_handle
       set_property "managed" "in-band-status" $drv_handle
       if { $core!= 0 && [llength $eth_node]} {
           hsi::utils::add_new_dts_param $eth_node "compatible" $compatible stringlist
           hsi::utils::add_new_dts_param $eth_node "phy-mode" "${linerate}g${phytype}" string
           hsi::utils::add_new_dts_param $eth_node "managed" "in-band-status" string
       }
    }
    if {$ip_name == "usxgmii"} {
       set compatible [get_comp_str $drv_handle]
       set compatible [append compatible " " "xlnx,xxv-usxgmii-ethernet-1.0"]
       set_property compatible $compatible $drv_handle
       # phy-mode is usxgmii in this case ip_name also same
       set_property phy-mode "$ip_name" $drv_handle
       hsi::utils::add_new_dts_param $node "xlnx,usxgmii-rate" 1000 int
   }
    set ips [get_cells -hier $drv_handle]
    foreach ip [get_drivers] {
        if {[string compare -nocase $ip $connected_ip] == 0} {
            set target_handle $ip
        }
    }
    set hsi_version [get_hsi_version]
    set ver [split $hsi_version "."]
    set version [lindex $ver 0]
    if {![string_is_empty $connected_ip]} {
        set connected_ipname [get_property IP_NAME $connected_ip]
        if {$connected_ipname == "axi_mcdma" || $connected_ipname == "axi_dma"} {
            set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
            set num_queues [get_property CONFIG.c_num_mm2s_channels $connected_ip]
            set inhex [format %x $num_queues]
            set numqueues "/bits/ 16 <0x$inhex>"
            hsi::utils::add_new_dts_param $node "xlnx,num-queues" $numqueues noformating
            if {$version < 2018} {
                dtg_warning "quotes to be removed or use 2018.1 version for $node param xlnx,num-queues"
            }
            set id 1
            for {set i 2} {$i <= $num_queues} {incr i} {
                set i [format "%x" $i]
                append id "\""
                append id ",\"" $i
                set i [expr 0x$i]
            }
            set_drv_prop $drv_handle "xlnx,channel-ids" $id stringlist
            if {$ip_name == "xxv_ethernet"  && $core!= 0 && [llength $eth_node]} {
                  hsi::utils::add_new_dts_param $eth_node "xlnx,num-queues" $numqueues noformating
                  hsi::utils::add_new_dts_param $eth_node "xlnx,channel-ids" $id stringlist
            }
            set intr_val [get_property CONFIG.interrupts $target_handle]
            set intr_parent [get_property CONFIG.interrupt-parent $target_handle]
            set int_names  [get_property CONFIG.interrupt-names $target_handle]
            if { $hasbuf == "true" && $ip_name == "axi_ethernet"} {
                set intr_val1 [get_property CONFIG.interrupts $drv_handle]
                lappend intr_val1 $intr_val
		set intr_name [get_property CONFIG.interrupt-names $drv_handle]
		append intr_names " " $intr_name " " $int_names
		if {![string match -nocase $proctype "microblaze"]} {
		     set null ""
	             set_property "interrupt-names" $null $drv_handle
	             set_property "interrupts" $null $drv_handle
		}
            } else {
		set intr_names $int_names
	    }
            if {![string_is_empty $intr_parent]} {
                if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core!= 0) && [llength $eth_node]} {
                     hsi::utils::add_new_dts_param "${eth_node}" "interrupts" $intr_val int
                     hsi::utils::add_new_dts_param "${eth_node}" "interrupt-parent" $intr_parent reference
                     hsi::utils::add_new_dts_param "${eth_node}" "interrupt-names" $intr_names stringlist
                } else {
			if { $hasbuf == "true" && $ip_name == "axi_ethernet"} {
				regsub -all "\{||\t" $intr_val1 {} intr_val1
				regsub -all "\}||\t" $intr_val1 {} intr_val1
				if {![string match -nocase $proctype "microblaze"]} {
				     set_property "interrupts" $intr_val1 $drv_handle
				     set_property "interrupt-names" $intr_names $drv_handle
				}
				hsi::utils::add_new_dts_param "${node}" "interrupts" $intr_val1 int
			} else {
				hsi::utils::add_new_dts_param "${node}" "interrupts" $intr_val int
			}
			hsi::utils::add_new_dts_param "${node}" "interrupt-parent" $intr_parent reference
			hsi::utils::add_new_dts_param "${node}" "interrupt-names" $intr_names stringlist
		}
            }
        }
        if {$connected_ipname == "axi_dma" || $connected_ipname == "axi_mcdma"} {
	    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	    if {![string match -nocase $proctype "microblaze"]} {
                set eth_clk_names [get_property CONFIG.clock-names $drv_handle]
                set eth_clks [get_property CONFIG.clocks $drv_handle]
		if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core == 0)} {
			set_property "zclocks" $eth_clks $drv_handle
			set_drv_prop $drv_handle "zclock-names" $eth_clk_names stringlist
		}
		if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core != 0)} {
			set eth_clks [get_property CONFIG.zclocks $drv_handle]
			set eth_clk_names [get_property CONFIG.zclock-names $drv_handle]
		}
                set eth_clkname_len [llength $eth_clk_names]
                set i 0
                set dclk ""
                while {$i < $eth_clkname_len} {
                   set clkname [lindex $eth_clk_names $i]
                   for {set corenum 0} {$corenum < $num_cores} {incr corenum} {
                            if {[string match -nocase $clkname "rx_core_clk_$corenum"]} {
                                     set core_clk_$corenum "rx_core_clk"
                                     set index_$corenum $i
                            }
                            if {[string match -nocase $clkname "s_axi_aclk_$corenum"]} {
                                     set axi_aclk_$corenum "s_axi_aclk"
                                     set axi_index_$corenum $i
                            }
                            if {[string match -nocase $clkname "dclk"]} {
                                     set dclk "dclk"
                                     set dclk_index $i
                            }
                  }
                  incr i
              }
              set eth_clk_len [expr {[llength [split $eth_clks ","]]}]
              set clk_list [split $eth_clks ","]
              set clk_names [get_property CONFIG.clock-names $target_handle]
              set clks [get_property CONFIG.clocks $target_handle]
              append names "$eth_clk_names" "$clk_names"
              set names ""
              append clk  "$eth_clks>," "<&$clks"
              set null ""
              set_property "clock-names" $null $drv_handle
              set_property "clocks" $null $drv_handle
              if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core== 0)} {
		    if {[llength $dclk]} {
                    lappend clknames "$core_clk_0" "$dclk" "$axi_aclk_0"
		    } else {
                    lappend clknames "$core_clk_0" "$axi_aclk_0"
		    }
                    append clknames1 "$clknames" "$clk_names"
                    set index0 [lindex $clk_list $axi_index_0]
                    regsub -all "\>||\t" $index0 {} index0
		    set ini0 [lindex $clk_list $index_0]
		    regsub -all " " $ini0 "" ini0
		    regsub -all "\<&||\t" $ini0 {} ini0
		    if {[llength $dclk]} {
			set dclk_ini [lindex $clk_list $dclk_index]
			set dclk_ini [string trim $dclk_ini]
			if {![string match -nocase "<&*" "$dclk_ini"]} {
				set dclk_ini "<&$dclk_ini"
			}
			append clkvals  "$ini0, $dclk_ini, $index0>, <&$clks"
		    } else {
			append clkvals  "$ini0, $index0>, <&$clks"
		    }
                    set_property "clocks" $clkvals $drv_handle
                    set_property "clock-names" $clknames1 $drv_handle
                    set clknames1 ""
             }
             if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core == 1) && [llength $eth_node]} {
		   if {[llength $dclk]} {
                   lappend clknames1 "$core_clk_1" "$dclk" "$axi_aclk_1"
		   } else {
                   lappend clknames1 "$core_clk_1" "$axi_aclk_1"
		   }
                   append clk_names1 "$clknames1" "$clk_names"
                   set index1 [lindex $clk_list $axi_index_1]
                   regsub -all "\>||\t" $index1 {} index1
                   set ini1 [lindex $clk_list $index_1]
                   regsub -all " " $ini1 "" ini1
                   regsub -all "\<&||\t" $ini1 {} ini1
		   if {[llength $dclk]} {
			set dclk_ini1 [lindex $clk_list $dclk_index]
			set dclk_ini1 [string trim $dclk_ini1]
			if {![string match -nocase "<&*" "$dclk_ini1"]} {
				set dclk_ini1 "<&$dclk_ini1"
			}
			append clkvals1  "$ini1, $dclk_ini1, $index1>, <&$clks"
		   } else {
			append clkvals1  "$ini1, $index1>, <&$clks"
		   }
                   hsi::utils::add_new_dts_param "${eth_node}" "clocks" $clkvals1 reference
                   hsi::utils::add_new_dts_param "${eth_node}" "clock-names" $clk_names1 stringlist
                   set clk_names1 ""
                   set clkvals1 ""
             }
             if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core == 2) && [llength $eth_node]} {
		  if {[llength $dclk]} {
                  lappend clknames2 "$core_clk_2" "$dclk" "$axi_aclk_2"
		  } else {
                  lappend clknames2 "$core_clk_2" "$axi_aclk_2"
		  }
                  append clk_names2 "$clknames2" "$clk_names"
                  set index2 [lindex $clk_list $axi_index_2]
                  regsub -all "\>||\t" $index2 {} index2
                  set ini2 [lindex $clk_list $index_2]
                  regsub -all " " $ini2 "" ini2
                  regsub -all "\<&||\t" $ini2 {} ini2
		  if {[llength $dclk]} {
			set dclk_ini2 [lindex $clk_list $dclk_index]
			set dclk_ini2 [string trim $dclk_ini2]
			if {![string match -nocase "<&*" "$dclk_ini2"]} {
				set dclk_ini2 "<&$dclk_ini2"
			}
			append clkvals2  "$ini2, $dclk_ini2, $index2>, <&$clks"
		  } else {
			append clkvals2  "$ini2, $index2>, <&$clks"
		  }
                  append clk_label2 $drv_handle "_" $core
                  hsi::utils::add_new_dts_param "${eth_node}" "clocks" $clkvals2 reference
                  hsi::utils::add_new_dts_param "${eth_node}" "clock-names" $clk_names2 stringlist
                  set clk_names2 ""
                  set clkvals2 ""
             }
             if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core == 3) && [llength $eth_node]} {
		 if {[llength $dclk]} {
                 lappend clknames3 "$core_clk_3" "$dclk" "$axi_aclk_3"
		 } else {
                 lappend clknames3 "$core_clk_3" "$axi_aclk_3"
		 }
                 append  clk_names3 "$clknames3" "$clk_names"
                 set index3 [lindex $clk_list $axi_index_3]
                 regsub -all "\>||\t" $index3 {} index3
                 set ini [lindex $clk_list $index_3]
                 regsub -all " " $ini "" ini
                 regsub -all "\<&||\t" $ini {} ini
		 if {[llength $dclk]} {
			set dclk_ini3 [lindex $clk_list $dclk_index]
			set dclk_ini3 [string trim $dclk_ini3]
			if {![string match -nocase "<&*" "$dclk_ini3"]} {
				set dclk_ini3 "<&$dclk_ini3"
			}
			append clkvals3 "$ini, $dclk_ini3, $index3>, <&$clks"
		 } else {
			append clkvals3 "$ini, $index3>, <&$clks"
		 }
                 append clk_label3 $drv_handle "_" $core
                 hsi::utils::add_new_dts_param "${eth_node}" "clocks" $clkvals3 reference
                 hsi::utils::add_new_dts_param "${eth_node}" "clock-names" $clk_names3 stringlist
                 set clk_names3 ""
                 set clkvals3 ""
             }
	  }
        }
    }
    if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && ($core!= 0) && [llength $eth_node]} {
              gen_drv_prop_eth_ip $drv_handle $eth_node
    }
    gen_dev_ccf_binding $drv_handle "s_axi_aclk"
 }
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {![string match -nocase $proctype "microblaze"]} {
        set null "NULL"
        set_property "zclock-names" $null $drv_handle
        set_property "zclocks" "$null" $drv_handle
    }
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
    set drv  [lindex $args 3]

    set phy_node [add_or_get_dt_node -l $drv$phy_name -n phy -u $phya -p $mdio_node]
    hsi::utils::add_new_dts_param "${phy_node}" "reg" $phya int
    hsi::utils::add_new_dts_param "${phy_node}" "device_type" "ethernet-phy" string

    return $phy_node
}

proc is_ethsupported_target {connected_ip} {
   set connected_ipname [get_property IP_NAME $connected_ip]
   if {$connected_ipname == "axi_dma" || $connected_ipname == "axi_fifo_mm_s" || $connected_ipname == "axi_mcdma"} {
      return "true"
   } else {
      return "false"
   }
}

proc get_targetip {ip} {
   global ddrv_handle
   if {[string_is_empty $ip] != 0} {
       return
   }
   set p2p_busifs_i [get_intf_pins -of_objects $ip -filter "TYPE==INITIATOR || TYPE==MASTER"]
   set target_periph ""
   foreach p2p_busif $p2p_busifs_i {
      set busif_name [string toupper [get_property NAME  $p2p_busif]]
      set conn_busif_handle [::hsi::utils::get_connected_intf $ip $busif_name]
      if {[string_is_empty $conn_busif_handle] != 0} {
          continue
      }
      set target_periph [get_cells -of_objects $conn_busif_handle]
      set cell_name [get_cells -hier $target_periph]
      set target_name [get_property IP_NAME [get_cells -hier $target_periph]]
      if {$target_name == "axis_data_fifo" || $target_name == "Ethernet_filter"} {
          #set target_periph [get_cells -of_objects $conn_busif_handle]
          set master_slaves [get_intf_pins -of [get_cells -hier $cell_name]]
          if {[llength $master_slaves] == 0} {
              return
          }
          set master_intf ""
          foreach periph_intf $master_slaves {
              set prop [get_property TYPE $periph_intf]
              if {$prop == "INITIATOR"} {
                  set master_intf $periph_intf
              }
          }
          if {[llength $master_intf] == 0} {
              return
          }
          set intf [get_intf_pins -of_objects $cell_name $master_intf]
          set intf_net [get_intf_nets -of_objects $intf]
          set intf_pins [::hsi::utils::get_other_intf_pin $intf_net $intf]
          foreach intf $intf_pins {
              set target_intf [get_intf_pins -of_objects $intf_net -filter "TYPE==TARGET" $intf]
              if {[llength $target_intf]} {
                   set connected_ip [get_cells -of_objects $target_intf]
                   if {[llength $connected_ip]} {
                         set cell [get_cells -hier $connected_ip]
                         set target_name [get_property IP_NAME [get_cells -hier $cell]]
                         if {$target_name == "axis_data_fifo"} {
                                  return [get_targetip $connected_ip]
                         }
                         if {![string_is_empty $connected_ip] && [is_ethsupported_target $connected_ip] == "true"} {
                                  return $connected_ip
                         }
                   } else {
                          dtg_warning "$ddrv_handle connected ip is NULL for the target intf $target_intf"
                   }
              } else {
                      dtg_warning "$ddrv_handle target interface is NULL for the intf pin $intf"
              }
         }
      }
   }
   return $target_periph
}

proc get_connectedip {intf} {
   global rxethmem
   if { [llength $intf]} {
      set connected_ip ""
      set intf_net [get_intf_nets -of_objects $intf ]
      if { [llength $intf_net]  } {
         set target_intf [::hsi::utils::get_other_intf_pin $intf_net $intf]
         if { [llength $target_intf] } {
            set connected_ip [get_cells -of_objects $target_intf]
            if {[llength $connected_ip]} {
                  set target_ipname [get_property IP_NAME $connected_ip]
                  if {$target_ipname == "ila"} {
                         return
                  }
                  if {$target_ipname == "axis_data_fifo"} {
                        set fifo_width_bytes [get_property CONFIG.TDATA_NUM_BYTES $connected_ip]
                        if {[string_is_empty $fifo_width_bytes]} {
                              set fifo_width_bytes 1
                        }
                        set rxethmem [get_property CONFIG.FIFO_DEPTH $connected_ip]
                        # FIFO can be other than 8 bits, and we need the rxmem in bytes
                        set rxethmem [expr $rxethmem * $fifo_width_bytes]
                 } else {
	                # In 10G MAC case if the rx_stream interface is not connected to
	                # a Stream-fifo set the rxethmem value to a default jumbo MTU size
	                set rxethmem 9600
	         }
            } else {
                    dtg_warning "$drv_handle connected_ip is NULL for the target_intf $target_intf"
            }
         }
	if {[string_is_empty $connected_ip]} {
		return ""
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
                set target_ip "false"
                set target_periph [get_targetip $connected_ip]
                if {[string_is_empty $target_periph] == 0} {
                    set target_ip [is_ethsupported_target $target_periph]
                }
                if { $target_ip == "true"} {
                  return $target_periph
                }
                set connected_ip $target_periph
                incr i
             }
             dtg_warning "Couldn't find a valid target_ip Please cross check hw design"
         }
      }
   }
}

proc gen_drv_prop_eth_ip {drv_handle ipname} {
        set prop_name_list [default_parameters $drv_handle]
        foreach prop_name ${prop_name_list} {
             ip2_prop $ipname $prop_name $drv_handle
        }
}

proc ip2_prop {ip_name ip_prop_name drv_handle} {
        set drv_prop_name $ip_prop_name
        regsub -all {CONFIG.C_} $drv_prop_name {xlnx,} drv_prop_name
        regsub -all {_} $drv_prop_name {-} drv_prop_name
        set drv_prop_name [string tolower $drv_prop_name]
        set value [get_property ${ip_prop_name} [get_cells -hier $drv_handle]]
        if {[llength $value]} {
               if {$value != "-1" && [llength $value] !=0} {
                     set type "hex"
                     if {[string equal -nocase $type "boolean"]} {
                             if {[expr $value < 1]} {
                                    return 0
                             }
                             set value ""
                     }
                     if {[regexp "(int|hex).*" $type match]} {
                             regsub -all {"} $value "" value
                     }
                     hsi::utils::add_new_dts_param "$ip_name" "$drv_prop_name" $value $type
                     return 0
               }
        }
}

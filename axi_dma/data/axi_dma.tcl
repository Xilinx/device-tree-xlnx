#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
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
set connected_ip 0

proc generate {drv_handle} {
    global connected_ip
    # try to source the common tcl procs
    # assuming the order of return is based on repo priority
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }

    set node [gen_peripheral_nodes $drv_handle]
    if {$node == 0} {
           return
    }
    set compatible [get_comp_str $drv_handle]
    set compatible [append compatible " " "xlnx,axi-dma-1.00.a"]
    set_drv_prop $drv_handle compatible "$compatible" stringlist
    set dma_ip [get_cells -hier $drv_handle]
    set dma_count [hsi::utils::get_os_parameter_value "dma_count"]
    if { [llength $dma_count] == 0 } {
        set dma_count 0
    }
    set axiethernetfound 0
    set connected_ip [hsi::utils::get_connected_stream_ip $dma_ip "M_AXIS_MM2S"]
    if { [llength $connected_ip] } {
        set connected_ip_type [get_property IP_NAME $connected_ip]
        if { [string match -nocase $connected_ip_type axi_ethernet ]
            || [string match -nocase $connected_ip_type axi_ethernet_buffer ] } {
                set axiethernetfound 1
        }
    } else {
        dtg_warning "$drv_handle connected ip is NULL for the pin M_AXIS_MM2S"
    }
    set is_xxv [get_connected_ip $drv_handle "M_AXIS_MM2S"]

    if { $axiethernetfound || $is_xxv == 1} {
        set compatstring "xlnx,eth-dma"
        set_property compatible "$compatstring" $drv_handle
    }
    set tx_chan 0
    set rx_chan 0
    if { $axiethernetfound != 1 && $is_xxv != 1} {
        set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
        set_drv_conf_prop $drv_handle C_SG_INCLUDE_STSCNTRL_STRM xlnx,sg-include-stscntrl-strm boolean
        set_drv_conf_prop $drv_handle c_enable_multi_channel xlnx,multichannel-dma boolean
        set_drv_conf_prop $drv_handle c_addr_width xlnx,addrwidth
        set_drv_conf_prop $drv_handle c_sg_length_width xlnx,sg-length-width

        set baseaddr [get_baseaddr $dma_ip no_prefix]
        set tx_chan [hsi::utils::get_ip_param_value $dma_ip C_INCLUDE_MM2S]
        if { $tx_chan == 1 } {
            set connected_ip [hsi::utils::get_connected_stream_ip $dma_ip "M_AXIS_MM2S"]
            set tx_chan_node [add_dma_channel $drv_handle $node "axi-dma" $baseaddr "MM2S" $dma_count ]
            set intr_info [get_intr_id $drv_handle "mm2s_introut"]
            #set intc [hsi::utils::get_interrupt_parent $dma_ip "mm2s_introut"]
            if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
		    hsi::utils::add_new_dts_param $tx_chan_node "interrupts" $intr_info intlist
            } else {
		    dtg_warning "ERROR: ${drv_handle}: mm2s_introut port is not connected"
            }
            add_dma_coherent_prop $drv_handle "M_AXI_MM2S"
        }
        set rx_chan [hsi::utils::get_ip_param_value $dma_ip C_INCLUDE_S2MM]
        if { $rx_chan ==1 } {
            set connected_ip [hsi::utils::get_connected_stream_ip $dma_ip "S_AXIS_S2MM"]
            set rx_bassaddr [format %08x [expr 0x$baseaddr + 0x30]]
            set rx_chan_node [add_dma_channel $drv_handle $node "axi-dma" $rx_bassaddr "S2MM" $dma_count]
            set intr_info [get_intr_id $drv_handle "s2mm_introut"]
            #set intc [hsi::utils::get_interrupt_parent $dma_ip "s2mm_introut"]
            if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
		    hsi::utils::add_new_dts_param $rx_chan_node "interrupts" $intr_info intlist
            } else {
		    dtg_warning "ERROR: ${drv_handle}: s2mm_introut port is not connected"
            }
            add_dma_coherent_prop $drv_handle "M_AXI_S2MM"
        }
    } else {
	set proc_type [get_sw_proc_prop IP_NAME]
	if {[string match -nocase $proc_type "ps7_cortexa9"] || [string match -nocase $proc_type "microblaze"] } {
		set_drv_property $drv_handle axistream-connected "$connected_ip" reference
		set_drv_property $drv_handle axistream-control-connected "$connected_ip" reference
	}
	set ip_prop CONFIG.c_include_mm2s_dre
	add_cross_property $drv_handle $ip_prop $drv_handle "xlnx,include-dre" boolean
	set addr_width [get_property CONFIG.c_addr_width $dma_ip]
	set inhex [format %x $addr_width]
	append addrwidth "/bits/ 8 <0x$inhex>"
	hsi::utils::add_new_dts_param "$node" "xlnx,addrwidth" $addrwidth noformating
	set num_queues [get_property CONFIG.c_num_mm2s_channels $dma_ip]
	set inhex [format %x $num_queues]
	append numqueues "/bits/ 16 <0x$inhex>"
	hsi::utils::add_new_dts_param $node "xlnx,num-queues" $numqueues noformating
    }
    incr dma_count
    hsi::utils::set_os_parameter_value "dma_count" $dma_count
    set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
    if {[string match -nocase $mainline_ker "none"]} {
          set proc_type [get_sw_proc_prop IP_NAME]
          if {[string match -nocase $proc_type "microblaze"]} {
                generate_clk_nodes $drv_handle $axiethernetfound $tx_chan $rx_chan
          }
    } else {
                generate_clk_nodes $drv_handle $axiethernetfound $tx_chan $rx_chan
    }
}

proc add_dma_channel {drv_handle parent_node xdma addr mode devid} {
    set modellow [string tolower $mode]
    set modeIndex [string index $mode 0]
    set dma_channel [add_or_get_dt_node -n "dma-channel" -u $addr -p $parent_node]
    hsi::utils::add_new_dts_param $dma_channel "compatible" [format "xlnx,%s-%s-channel" $xdma $modellow] stringlist
    hsi::utils::add_new_dts_param $dma_channel "xlnx,device-id" $devid hexint


    add_cross_property_to_dtnode $drv_handle [format "CONFIG.C_INCLUDE_%s_DRE" $mode] $dma_channel "xlnx,include-dre" boolean
    if {[string match -nocase $mode "MM2S"]} {
         set datawidth  [get_property CONFIG.C_M_AXI_MM2S_DATA_WIDTH [get_cells -hier $drv_handle]]
    }
    if {[string match -nocase $mode "S2MM"]} {
         set datawidth  [get_property CONFIG.C_S_AXIS_S2MM_TDATA_WIDTH [get_cells -hier $drv_handle]]
    }
    hsi::utils::add_new_dts_param $dma_channel "xlnx,datawidth" $datawidth hexint

    set num_channles [get_property CONFIG.c_num_mm2s_channels [get_cells -hier $drv_handle]]
    hsi::utils::add_new_dts_param $dma_channel "dma-channels" $num_channles hexint

    return $dma_channel
}

proc add_dma_coherent_prop {drv_handle intf} {
    set ip_name [::hsi::get_cells -hier -filter "NAME==$drv_handle"]
    set connectedip [hsi::utils::get_connected_stream_ip $drv_handle $intf]
    if {[llength $connectedip] == 0} {
          return
    }
    set intrconnect [get_property IP_NAME [get_cells -hier $connectedip]]
    set num_master [get_property CONFIG.NUM_MI $connectedip]
    set done 0
    # check whether dma connected to interconnect ip, loop until you get the
    # port name ACP or HP
    while {[string match -nocase $intrconnect "axi_interconnect"]} {
        # loop over number of master interfaces
        set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectedip] -filter {TYPE==MASTER}]
        if {[llength $master_intf] == 0} {
                break
        }
        foreach interface ${master_intf} {
            set intf_port [hsi::utils::get_connected_intf $connectedip $interface]
            set intrconnect [hsi::utils::get_connected_stream_ip $connectedip $interface]
            if {![string_is_empty $intf_port] && [string match -nocase $intf_port "S_AXI_ACP"]} {
                hsi::utils::add_new_property $drv_handle "dma-coherent" boolean ""
                # here dma connected to ACP port
                set done 1
                break;
            }
            if {$done} {
                break
            }
        }
    }
}

proc generate_clk_nodes {drv_handle axiethernetfound tx_chan rx_chan} {
	set proc_type [get_sw_proc_prop IP_NAME]
	set clocknames "s_axi_lite_aclk"
	switch $proc_type {
		"ps7_cortexa9" {
			set clocks "clkc 15"
			if { $axiethernetfound != 1 } {
				append clocknames " " "m_axi_sg_aclk"
				append clocks "" ">, <&clkc 15"
			}
			if { $tx_chan ==1 } {
				append clocknames " " "m_axi_mm2s_aclk"
				append clocks "" ">, <&clkc 15"
			}
			if { $rx_chan ==1 } {
				append clocknames " " "m_axi_s2mm_aclk"
				append clocks "" ">, <&clkc 15"
			}
			set_drv_prop_if_empty $drv_handle "clocks" $clocks reference
			set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
		} "psu_cortexa53" {
			foreach i [get_sw_cores device_tree] {
				set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
				if {[file exists $common_tcl_file]} {
					source $common_tcl_file
					break
				}
			}
			set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "s_axi_lite_aclk"]
			if {![string equal $clk_freq ""]} {
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
			}
			set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
			set dts_file [current_dt_tree]
			set bus_node [add_or_get_bus_node $drv_handle $dts_file]
			set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
				-d ${dts_file} -p ${bus_node}]
			hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
			hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
			hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
			set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
			set clocks "$clk_refs"
			if { $axiethernetfound != 1 } {
				append clocknames " " "m_axi_sg_aclk"
				append clocks "" ">, <&$clk_refs"
			}
			if { $tx_chan ==1 } {
				append clocknames " " "m_axi_mm2s_aclk"
				append clocks "" ">, <&$clk_refs"
			}
			if { $rx_chan ==1 } {
				append clocknames " " "m_axi_s2mm_aclk"
				append clocks "" ">, <&$clk_refs"
			}
			set_drv_prop_if_empty $drv_handle "clocks" "$clocks" reference
			set_drv_prop_if_empty $drv_handle "clock-names" "$clocknames" stringlist
		} "microblaze" {
			if { $axiethernetfound != 1 } {
				append clocknames " " "m_axi_sg_aclk"
			}
			if { $tx_chan ==1 } {
				append clocknames " " "m_axi_mm2s_aclk"
			}
			if { $rx_chan ==1 } {
				append clocknames " " "m_axi_s2mm_aclk"
			}
			gen_dev_ccf_binding $drv_handle "$clocknames"
			set_drv_prop_if_empty $drv_handle "clock-names" "$clocknames" stringlist
		}
		default {
			error "Unknown arch"
		}
	}
}

proc get_connected_ip {drv_handle dma_pin} {
    global connected_ip
    # Check whether dma is connected to 10G/25G MAC
    # currently we are handling only data fifo
    set intf [::hsi::get_intf_pins -of_objects [get_cells -hier $drv_handle] $dma_pin]
    set valid_eth_list "xxv_ethernet axi_ethernet axi_10g_ethernet usxgmii"
    if {[string_is_empty ${intf}]} {
        return 0
    }
    set connected_ip [::hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] $intf]

    if {[string_is_empty ${connected_ip}]} {
	dtg_warning "$drv_handle connected ip is NULL for the pin $intf"
        return 0
    }
    set iptype [get_property IP_NAME [get_cells -hier $connected_ip]]
    if {[string match -nocase $iptype "axis_data_fifo"] } {
        # here dma connected to data fifo
        set dma_pin "M_AXIS"
        get_connected_ip $connected_ip $dma_pin
    } elseif {[lsearch -nocase $valid_eth_list $iptype] >= 0 } {
        # dma connected to 10G/25G MAC, 1G or 10G
        return 1
    } elseif {[string match -nocase $iptype "axis_add_tuser"]|| [string match -nocase $iptype "axis_duplicate_master_out"]} {
		set dma_pin "mas_0"
		get_connected_ip $connected_ip $dma_pin
    } elseif {[string match -nocase $iptype "axis_switch"]} {
		set dma_pin "M00_AXIS"
		get_connected_ip $connected_ip $dma_pin
    } else {
        # dma connected via interconnects
        set dma_pin "M_AXIS"
        get_connected_ip $connected_ip $dma_pin
    }
}

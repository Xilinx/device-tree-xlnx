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
    }

    if { $axiethernetfound } {
	set compatstring "xlnx,eth-dma"
        set_property compatible "$compatstring" $drv_handle
    }

    if { $axiethernetfound != 1 } {
        set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
        set_drv_conf_prop $drv_handle C_SG_INCLUDE_STSCNTRL_STRM xlnx,sg-include-stscntrl-strm boolean
        set_drv_conf_prop $drv_handle c_enable_multi_channel xlnx,multichannel-dma boolean

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
		    puts "WARNING: ${drv_handle}: mm2s_introut port is not connected"
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
		    puts "WARNING: ${drv_handle}: s2mm_introut port is not connected"
            }
            add_dma_coherent_prop $drv_handle "M_AXI_S2MM"
        }
    } else {
        set_drv_property $drv_handle axistream-connected "$connected_ip" reference
        set_drv_property $drv_handle axistream-control-connected "$connected_ip" reference
    }
    incr dma_count
    hsi::utils::set_os_parameter_value "dma_count" $dma_count
}

proc add_dma_channel {drv_handle parent_node xdma addr mode devid} {
    set modellow [string tolower $mode]
    set modeIndex [string index $mode 0]
    set dma_channel [add_or_get_dt_node -n "dma-channel" -u $addr -p $parent_node]
    hsi::utils::add_new_dts_param $dma_channel "compatible" [format "xlnx,%s-%s-channel" $xdma $modellow] stringlist
    hsi::utils::add_new_dts_param $dma_channel "xlnx,device-id" $devid hexint


    add_cross_property_to_dtnode $drv_handle [format "CONFIG.C_INCLUDE_%s_DRE" $mode] $dma_channel "xlnx,include-dre" boolean
    # detection based on two property
    set datawidth_list "[format "CONFIG.C_%s_AXIS_%s_DATA_WIDTH" $modeIndex $mode] [format "CONFIG.C_%s_AXIS_%s_TDATA_WIDTH" $modeIndex $mode]"
    add_cross_property_to_dtnode $drv_handle $datawidth_list $dma_channel "xlnx,datawidth"

    set num_channles [get_property CONFIG.c_num_mm2s_channels [get_cells $drv_handle]]
    hsi::utils::add_new_dts_param $dma_channel "dma-channels" $num_channles hexint

    return $dma_channel
}

proc add_dma_coherent_prop {drv_handle intf} {
    set ip_name [::hsi::get_cells -hier -filter "NAME==$drv_handle"]
    set connectedip [hsi::utils::get_connected_stream_ip $drv_handle $intf]
    set intrconnect [get_property IP_NAME [get_cells -hier $connectedip]]
    set num_master [get_property CONFIG.NUM_MI $connectedip]
    set done 0
    # check whether dma connected to interconnect ip, loop until you get the
    # port name ACP or HP
    while {[string match -nocase $intrconnect "axi_interconnect"]} {
        # loop over number of master interfaces
        set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectedip] -filter {TYPE==MASTER}]
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

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

    set dma_ip [get_cells $drv_handle]
    set dma_count [hsm::utils::get_os_parameter_value "dma_count"]
    if { [llength $dma_count] == 0 } {
        set dma_count 0
    }
    set axiethernetfound 0
    set connected_ip [hsm::utils::get_connected_stream_ip $dma_ip "M_AXIS_MM2S"]
    if { [llength $connected_ip] } {
        set connected_ip_type [get_property IP_NAME $connected_ip]
        if { [string match -nocase $connected_ip_type axi_ethernet ]
            || [string match -nocase $connected_ip_type axi_ethernet_buffer ] } {
                set axiethernetfound 1
        }
    }
    if { $axiethernetfound != 1 } {
        set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
        set_drv_conf_prop $drv_handle C_SG_INCLUDE_STSCNTRL_STRM xlnx,sg-include-stscntrl-strm boolean

        set mem_range  [lindex [xget_ip_mem_ranges $dma_ip] 0 ]
        set baseaddr   [get_property BASE_VALUE $mem_range]
        set highaddr   [get_property HIGH_VALUE $mem_range]
        set tx_chan [get_ip_param_value $dma_ip C_INCLUDE_MM2S]
        if { $tx_chan == 1 } {
            set connected_ip [hsm::utils::get_connected_stream_ip $dma_ip "M_AXIS_MM2S"]
            set tx_chan [add_dma_channel $drv_handle "axi-dma" $baseaddr "MM2S" $dma_count ]
            set intr_info [get_intr_id $dma_ip "mm2s_introut" ]
            set intc [hsm::utils::get_interrupt_parent $dma_ip "mm2s_introut"]
            if { [llength $intr_info] } {
                hsm::utils::add_new_property $tx_chan "interrupts" int $intr_info
            }
        }
        set rx_chan [get_ip_param_value $dma_ip C_INCLUDE_S2MM]
        if { $rx_chan ==1 } {
            set connected_ip [hsm::utils::get_connected_stream_ip $dma_ip "S_AXIS_S2MM"]
            set rx_chan [add_dma_channel $drv_handle "axi-dma" [expr $baseaddr + 0x30] "S2MM" $dma_count]
            set intr_info [get_intr_id $dma_ip "s2mm_introut"]
            set intc [hsm::utils::get_interrupt_parent $dma_ip "s2mm_introut"]
            if { [llength $intr_info] } {
                hsm::utils::add_new_property $rx_chan "interrupts" int $intr_info
            }
        }
    } else {
        set_property axistream-connected "$connected_ip" $drv_handle
        set_property axistream-control-connected "$connected_ip" $drv_handle
    }
    incr dma_count
    hsm::utils::set_os_parameter_value "dma_count" $dma_count
}

proc add_dma_channel { drv_handle xdma addr mode devid} {
    set ip [get_cells $drv_handle]
    set modellow [string tolower $mode]
    set modeIndex [string index $mode 0]
    set node_name [format "dma-channel@%x" $addr]
    set dma_channel [hsm::utils::add_new_child_node $drv_handle $node_name]
    hsm::utils::add_new_property $dma_channel "compatible" stringlist [format "xlnx,%s-%s-channel" $xdma $modellow]
    hsm::utils::add_new_property $dma_channel "xlnx,device-id" hexint $devid
    add_cross_property $drv_handle [format "CONFIG.C_INCLUDE_%s_DRE" $mode] $dma_channel "xlnx,include-dre" boolean
    # detection based on two property
    set datawidth_list "[format "CONFIG.C_%s_AXIS_%s_DATA_WIDTH" $modeIndex $mode] [format "CONFIG.C_%s_AXIS_%s_TDATA_WIDTH" $modeIndex $mode]"
    add_cross_property $drv_handle $datawidth_list $dma_channel "xlnx,datawidth"

    return $dma_channel
}

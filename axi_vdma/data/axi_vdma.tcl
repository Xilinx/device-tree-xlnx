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
	set vdma_count [hsm::utils::get_os_parameter_value "vdma_count"]
	if { [llength $vdma_count] == 0 } {
		set vdma_count 0
	}

	# check for C_ENABLE_DEBUG parameters
	# C_ENABLE_DEBUG_INFO_15 - Enable S2MM Frame Count Interrupt bit
	# C_ENABLE_DEBUG_INFO_14 - Enable S2MM Delay Counter Interrupt bit
	# C_ENABLE_DEBUG_INFO_7 - Enable MM2S Frame Count Interrupt bit
	# C_ENABLE_DEBUG_INFO_6 - Enable MM2S Delay Counter Interrupt bit
	set dbg15 [get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_15]
	set dbg14 [get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_14]
	set dbg07 [get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_7]
	set dbg06 [get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_6]

	if { $dbg15 != 1 || $dbg14 != 1 || $dbg07 != 1 || $dbg06 != 1 } {
		puts "ERROR: Failed to generate AXI VDMA node,"
		puts "ERROR: Essential VDMA Debug parameters for driver are not enabled in IP"
		return;
	}

	set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
	set_drv_conf_prop $drv_handle C_NUM_FSTORES xlnx,num-fstores
	set_drv_conf_prop $drv_handle C_USE_FSYNC xlnx,flush-fsync

	set mem_range [lindex [xget_ip_mem_ranges $dma_ip] 0 ]
	set baseaddr [get_property BASE_VALUE $mem_range]
	set highaddr [get_property HIGH_VALUE $mem_range]
	set tx_chan [get_ip_param_value $dma_ip C_INCLUDE_MM2S]
	if { $tx_chan == 1 } {
		set connected_ip [hsm::utils::get_connected_stream_ip $dma_ip "M_AXIS_MM2S"]
		set tx_chan [add_dma_channel $drv_handle "axi-vdma" $baseaddr "MM2S" $vdma_count ]
		set intr_info [get_intr_id $dma_ip "mm2s_introut" ]
		set intc [hsm::utils::get_interrupt_parent $dma_ip "mm2s_introut"]
		if { [llength $intr_info] } {
			hsm::utils::add_new_property $tx_chan "interrupts" int $intr_info
		}
	}
	set rx_chan [get_ip_param_value $dma_ip C_INCLUDE_S2MM]
	if { $rx_chan ==1 } {
		set connected_ip [hsm::utils::get_connected_stream_ip $dma_ip "S_AXIS_S2MM"]
		set rx_chan [add_dma_channel $drv_handle "axi-vdma" [expr $baseaddr + 0x30] "S2MM" $vdma_count]
		set intr_info [get_intr_id $dma_ip "s2mm_introut"]
		set intc [hsm::utils::get_interrupt_parent $dma_ip "s2mm_introut"]
		if { [llength $intr_info] } {
			hsm::utils::add_new_property $rx_chan "interrupts" int $intr_info
		}
	}
	incr vdma_count
	hsm::utils::set_os_parameter_value "vdma_count" $vdma_count
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
	add_cross_property $drv_handle [format "CONFIG.C_%s_GENLOCK_MODE" $mode] $dma_channel "xlnx,genlock-mode" boolean

	return $dma_channel
}

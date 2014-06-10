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
	set cdma_count [hsm::utils::get_os_parameter_value "cdma_count"]
	if { [llength $cdma_count] == 0 } {
		set cdma_count 0
	}

	set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
	set_drv_conf_prop $drv_handle C_NUM_FSTORES xlnx,num-fstores
	set_drv_conf_prop $drv_handle C_USE_FSYNC xlnx,flush-fsync

	set mem_range  [lindex [xget_ip_mem_ranges $dma_ip] 0 ]
	set baseaddr   [get_property BASE_VALUE $mem_range]
	set highaddr   [get_property HIGH_VALUE $mem_range]

	set tx_chan [add_dma_channel $drv_handle "axi-cdma" $baseaddr "MM2S" $cdma_count ]
	set intr_info [get_intr_id $dma_ip "cdma_introut" ]
	set intc [hsm::utils::get_interrupt_parent $dma_ip "cdma_introut"]
	if { [llength $intr_info] } {
		hsm::utils::add_new_property $tx_chan "interrupts" int $intr_info
	}
	incr cdma_count
	hsm::utils::set_os_parameter_value "cdma_count" $cdma_count
}

proc add_dma_channel { drv_handle xdma addr mode devid} {
	set ip [get_cells $drv_handle]
	set modellow [string tolower $mode]
	set modeIndex [string index $mode 0]
	set node_name [format "dma-channel@%x" $addr]
	set dma_channel [hsm::utils::add_new_child_node $drv_handle $node_name]
	hsm::utils::add_new_property $dma_channel "compatible" stringlist [format "xlnx,%s-channel" $xdma]
	hsm::utils::add_new_property $dma_channel "xlnx,device-id" hexint $devid
	add_cross_property $drv_handle "CONFIG.C_INCLUDE_DRE" $dma_channel "xlnx,include-dre" boolean
	add_cross_property $drv_handle "CONFIG.C_M_AXI_DATA_WIDTH" $dma_channel "xlnx,datawidth"
	add_cross_property $drv_handle "CONFIG.C_USE_DATAMOVER_LITE" $dma_channel "xlnx,lite-mode" boolean
	add_cross_property $drv_handle "CONFIG.C_M_AXI_MAX_BURST_LEN" $dma_channel "xlnx,max-burst-len"

	return $dma_channel
}

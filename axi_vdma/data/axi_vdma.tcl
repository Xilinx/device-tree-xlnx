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
	set vdma_count [hsi::utils::get_os_parameter_value "vdma_count"]
	if { [llength $vdma_count] == 0 } {
		set vdma_count 0
	}

	# check for C_ENABLE_DEBUG parameters
	# C_ENABLE_DEBUG_INFO_15 - Enable S2MM Frame Count Interrupt bit
	# C_ENABLE_DEBUG_INFO_14 - Enable S2MM Delay Counter Interrupt bit
	# C_ENABLE_DEBUG_INFO_7 - Enable MM2S Frame Count Interrupt bit
	# C_ENABLE_DEBUG_INFO_6 - Enable MM2S Delay Counter Interrupt bit
	set dbg15 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_15]
	set dbg14 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_14]
	set dbg07 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_7]
	set dbg06 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_6]

	if { $dbg15 != 1 || $dbg14 != 1 || $dbg07 != 1 || $dbg06 != 1 } {
		puts "ERROR: Failed to generate AXI VDMA node,"
		puts "ERROR: Essential VDMA Debug parameters for driver are not enabled in IP"
		return;
	}

	set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
	set_drv_conf_prop $drv_handle C_NUM_FSTORES xlnx,num-fstores
	set_drv_conf_prop $drv_handle C_USE_FSYNC xlnx,flush-fsync

	set baseaddr [get_baseaddr $dma_ip no_prefix]
	set tx_chan [hsi::utils::get_ip_param_value $dma_ip C_INCLUDE_MM2S]
	if { $tx_chan == 1 } {
		set connected_ip [hsi::utils::get_connected_stream_ip $dma_ip "M_AXIS_MM2S"]
		set tx_chan_node [add_dma_channel $drv_handle $node "axi-vdma" $baseaddr "MM2S" $vdma_count ]
		set intr_info [get_intr_id $drv_handle "mm2s_introut"]
		#set intc [hsi::utils::get_interrupt_parent $dma_ip "mm2s_introut"]
	        if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
			hsi::utils::add_new_dts_param $tx_chan_node "interrupts" $intr_info intlist
	        } else {
			error "ERROR: ${drv_handle}: mm2s_introut port is not connected"
		}
	}
	set rx_chan [hsi::utils::get_ip_param_value $dma_ip C_INCLUDE_S2MM]
	if { $rx_chan ==1 } {
		set connected_ip [hsi::utils::get_connected_stream_ip $dma_ip "S_AXIS_S2MM"]
		set rx_bassaddr [format %08x [expr 0x$baseaddr + 0x30]]
		set rx_chan_node [add_dma_channel $drv_handle $node "axi-vdma" $rx_bassaddr "S2MM" $vdma_count]
		set intr_info [get_intr_id $drv_handle "s2mm_introut"]
		#set intc [hsi::utils::get_interrupt_parent $dma_ip "s2mm_introut"]
	        if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
			hsi::utils::add_new_dts_param $rx_chan_node "interrupts" $intr_info intlist
	        } else {
			error "ERROR: ${drv_handle}: s2mm_introut port is not connected"
		}
	}
	incr vdma_count
	hsi::utils::set_os_parameter_value "vdma_count" $vdma_count
}

proc add_dma_channel {drv_handle parent_node xdma addr mode devid} {
	set ip [get_cells -hier $drv_handle]
	set modellow [string tolower $mode]
	set modeIndex [string index $mode 0]
	set dma_channel [add_or_get_dt_node -n "dma-channel" -u $addr -p $parent_node]
	hsi::utils::add_new_dts_param $dma_channel "compatible" [format "xlnx,%s-%s-channel" $xdma $modellow] stringlist
	hsi::utils::add_new_dts_param $dma_channel "xlnx,device-id" $devid hexint

	add_cross_property_to_dtnode $drv_handle [format "CONFIG.C_INCLUDE_%s_DRE" $mode] $dma_channel "xlnx,include-dre" boolean
	# detection based on two property
	set datawidth_list "[format "CONFIG.C_%s_AXIS_%s_DATA_WIDTH" $modeIndex $mode] [format "CONFIG.C_%s_AXIS_%s_TDATA_WIDTH" $modeIndex $mode]"
	add_cross_property_to_dtnode $drv_handle $datawidth_list $dma_channel "xlnx,datawidth"
	add_cross_property_to_dtnode $drv_handle [format "CONFIG.C_%s_GENLOCK_MODE" $mode] $dma_channel "xlnx,genlock-mode" boolean

	return $dma_channel
}

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

	set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
	set_drv_conf_prop $drv_handle C_NUM_FSTORES xlnx,num-fstores
	set_drv_conf_prop $drv_handle C_USE_FSYNC xlnx,flush-fsync
	set_drv_conf_prop $drv_handle C_ADDR_WIDTH xlnx,addrwidth

	set node [gen_peripheral_nodes $drv_handle]

	set dma_ip [get_cells -hier $drv_handle]
	set cdma_count [hsi::utils::get_os_parameter_value "cdma_count"]
	if { [llength $cdma_count] == 0 } {
		set cdma_count 0
	}

	set baseaddr [get_baseaddr $dma_ip no_prefix]
	set tx_chan [add_dma_channel $drv_handle $node "axi-cdma" $baseaddr "MM2S" $cdma_count ]
	incr cdma_count
	hsi::utils::set_os_parameter_value "cdma_count" $cdma_count
	set proc_type [get_sw_proc_prop IP_NAME]
	switch $proc_type {
		"psu_cortexa53" {
			update_clk_node $drv_handle "s_axi_lite_aclk m_axi_aclk"
		} "ps7_cortexa9" {
			update_zynq_clk_node $drv_handle "s_axi_lite_aclk m_axi_aclk"
		} "microblaze"  {
			gen_dev_ccf_binding $drv_handle "s_axi_lite_aclk m_axi_aclk"
			set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
		}
		default {
			error "Unknown arch"
		}
	}
}

proc add_dma_channel {drv_handle parent_node xdma addr mode devid} {
	#set ip [get_cells -hier $drv_handle]
	set modellow [string tolower $mode]
	set modeIndex [string index $mode 0]
	#set node_name [format "dma-channel@%x" $addr]
	set dma_channel [add_or_get_dt_node -n "dma-channel" -u $addr -p $parent_node]

	hsi::utils::add_new_dts_param $dma_channel "compatible" [format "xlnx,%s-channel" $xdma] stringlist
	hsi::utils::add_new_dts_param $dma_channel "xlnx,device-id" $devid hexint
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_INCLUDE_DRE" $dma_channel "xlnx,include-dre" boolean
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_M_AXI_DATA_WIDTH" $dma_channel "xlnx,datawidth"
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_USE_DATAMOVER_LITE" $dma_channel "xlnx,lite-mode" boolean
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_M_AXI_MAX_BURST_LEN" $dma_channel "xlnx,max-burst-len"

	set intr_info [get_intr_id $drv_handle "cdma_introut" ]
	if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
		hsi::utils::add_new_dts_param $dma_channel "interrupts" $intr_info intlist
	} else {
		dtg_warning "ERROR: ${drv_handle}: cdma_introut port is not connected"
	}
	return $dma_channel
}

proc generate_clk_nodes {drv_handle} {
    set proc_type [get_sw_proc_prop IP_NAME]
    switch $proc_type {
        "ps7_cortexa9" {
            set_drv_prop_if_empty $drv_handle "clocks" "clkc 15>, <&clkc 15" reference
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
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
            set_drv_prop_if_empty $drv_handle "clocks" "$clk_refs &$clk_refs" reference
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
        } "microblaze" {
            gen_dev_ccf_binding $drv_handle "s_axi_lite_aclk m_axi_aclk"
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
        }
        default {
            error "Unknown arch"
        }
    }
}

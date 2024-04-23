#
# (C) Copyright 2019-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
#
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
proc add_prop_ifexists {drv_handle hsi_prop dt_prop node {dt_prop_type "string"}} {
	if {[llength $drv_handle] && [llength $hsi_prop] && [llength $dt_prop] && [llength $node]} {
		set value [get_property $hsi_prop [get_cells -hier $drv_handle]]
		if {[llength $value]} {
			hsi::utils::add_new_dts_param "${node}" "$dt_prop" $value $dt_prop_type
		}
	}
}

proc fix_clockprop {s_clk rx_clk} {
	regsub -all "\<&" $s_clk {} s_clk
	regsub -all "\<&" $s_clk {} s_clk
	regsub -all " " $s_clk "" s_clk
	# if s_clk and rx_clk not matches and clock not starts
	# with <& add it.
	set rx_clk [string trim $rx_clk]
	if {![string match -nocase "$s_clk" $rx_clk] && \
		![string match -nocase "<&*" "$rx_clk"]} {
		set rx_clk "<&$rx_clk"
	}
	return "$s_clk $rx_clk"
}

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
	if {$node == 0} {
		return
	}
	set compatible [get_comp_str $drv_handle]
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "mrmac"]} {
		set compatible [append compatible " " "xlnx,mrmac-ethernet-1.0"]
	}
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set mrmac_ip [get_cells -hier $drv_handle]
	gen_mrmac_clk_property $drv_handle
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}
	set dts_file [current_dt_tree]
	set mem_ranges [hsi::utils::get_ip_mem_ranges [get_cells -hier $drv_handle]]
	dtg_verbose "mem_ranges:$mem_ranges"
	foreach mem_range $mem_ranges {
		set base_addr [string tolower [get_property BASE_VALUE $mem_range]]
		set base [format %x $base_addr]
		set high_addr [string tolower [get_property HIGH_VALUE $mem_range]]
		set slave_intf [get_property SLAVE_INTERFACE $mem_range]
		dtg_verbose "slave_intf:$slave_intf"
		set ptp_comp "xlnx,timer-syncer-1588-1.0"
		if {[string match -nocase $slave_intf "ptp_0_s_axi"]} {
			set ptp_0_node [add_or_get_dt_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
			hsi::utils::add_new_dts_param "$ptp_0_node" "compatible" "$ptp_comp" stringlist
			set reg [generate_reg_property $base_addr $high_addr]
			hsi::utils::add_new_dts_param "$ptp_0_node" "reg" $reg inthexlist
		}
		if {[string match -nocase $slave_intf "ptp_1_s_axi"]} {
			set ptp_1_node [add_or_get_dt_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
			hsi::utils::add_new_dts_param "$ptp_1_node" "compatible" "$ptp_comp" stringlist
			set reg [generate_reg_property $base_addr $high_addr]
			hsi::utils::add_new_dts_param "$ptp_1_node" "reg" $reg inthexlist
		}
		if {[string match -nocase $slave_intf "ptp_2_s_axi"]} {
			set ptp_2_node [add_or_get_dt_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
			hsi::utils::add_new_dts_param "$ptp_2_node" "compatible" "$ptp_comp" stringlist
			set reg [generate_reg_property $base_addr $high_addr]
			hsi::utils::add_new_dts_param "$ptp_2_node" "reg" $reg inthexlist
		}
		if {[string match -nocase $slave_intf "ptp_3_s_axi"]} {
			set ptp_3_node [add_or_get_dt_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
			hsi::utils::add_new_dts_param "$ptp_3_node" "compatible" "$ptp_comp" stringlist
			set reg [generate_reg_property $base_addr $high_addr]
			hsi::utils::add_new_dts_param "$ptp_3_node" "reg" $reg inthexlist
		}
		if {[string match -nocase $slave_intf "s_axi"]} {
			set mrmac0_highaddr_hex [format 0x%x [expr $base_addr + 0xFFF]]
			set reg [generate_reg_property $base_addr $mrmac0_highaddr_hex]
			hsi::utils::add_new_dts_param "$node" "reg" $reg inthexlist
		}
	}
	set connected_ip [get_connected_stream_ip $mrmac_ip "tx_axis_tdata0"]

	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE0_CFG_C0 "xlnx,flex-slice0-cfg-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE0_CFG_C1 "xlnx,flex-slice0-cfg-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT0_DATA_RATE_C0 "xlnx,flex-port0-data-rate-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT0_DATA_RATE_C1 "xlnx,flex-port0-data-rate-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT0_ENABLE_TIME_STAMPING_C0 "xlnx,flex-port0-enable-time-stamping-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT0_ENABLE_TIME_STAMPING_C1 "xlnx,flex-port0-enable-time-stamping-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT0_MODE_C0 "xlnx,flex-port0-mode-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT0_MODE_C1 "xlnx,flex-port0-mode-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.PORT0_1588v2_Clocking_C0 "xlnx,port0-1588v2-clocking-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.PORT0_1588v2_Clocking_C1 "xlnx,port0-1588v2-clocking-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.PORT0_1588v2_Operation_MODE_C0 "xlnx,port0-1588v2-operation-mode-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.PORT0_1588v2_Operation_MODE_C1 "xlnx,port0-1588v2-operation-mode-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_ENABLE_TIME_STAMPING_C0 "xlnx,mac-port0-enable-time-stamping-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_ENABLE_TIME_STAMPING_C1 "xlnx,mac-port0-enable-time-stamping-c1" ${node} int
	set MAC_PORT0_RATE_C0 [get_property CONFIG.MAC_PORT0_RATE_C0 [get_cells -hier $drv_handle]]
	if { [llength $MAC_PORT0_RATE_C0] } {
		if {[string match -nocase $MAC_PORT0_RATE_C0 "10GE"]} {
			set number 10000
			hsi::utils::add_new_dts_param "${node}" "xlnx,mrmac-rate" $number int
		} else {
			hsi::utils::add_new_dts_param "${node}" "xlnx,mrmac-rate" $MAC_PORT0_RATE_C0 string
		}
	}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RATE_C1 "xlnx,mac-port0-rate-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_GCP_C0 "xlnx,mac-port0-rx-etype-gcp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_GCP_C1 "xlnx,mac-port0-rx-etype-gcp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_GPP_C0 "xlnx,mac-port0-rx-etype-gpp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_GPP_C1 "xlnx,mac-port0-rx-etype-gpp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_PCP_C0 "xlnx,mac-port0-rx-etype-pcp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_PCP_C1 "xlnx,mac-port0-rx-etype-pcp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_PPP_C0 "xlnx,mac-port0-rx-etype-ppp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_ETYPE_PPP_C1 "xlnx,mac-port0-rx-etype-ppp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_FLOW_C0 "xlnx,mac-port0-rx-flow-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_FLOW_C1 "xlnx,mac-port0-rx-flow-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_GPP_C0 "xlnx,mac-port0-rx-opcode-gpp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_GPP_C1 "xlnx,mac-port0-rx-opcode-gpp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MAX_GCP_C0 "xlnx,mac-port0-rx-opcode-max-gcp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MAX_GCP_C1 "xlnx,mac-port0-rx-opcode-max-gcp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MAX_PCP_C0 "xlnx,mac-port0-rx-opcode-max-pcp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MAX_PCP_C1 "xlnx,mac-port0-rx-opcode-max-pcp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MIN_GCP_C0 "xlnx,mac-port0-rx-opcode-min-gcp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MIN_GCP_C1 "xlnx,mac-port0-rx-opcode-min-gcp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MIN_PCP_C0 "xlnx,mac-port0-rx-opcode-min-pcp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_MIN_PCP_C1 "xlnx,mac-port0-rx-opcode-min-pcp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_PPP_C0 "xlnx,mac-port0-rx-opcode-ppp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_RX_OPCODE_PPP_C1 "xlnx,mac-port0-rx-opcode-ppp-c1" ${node} int
	set MAC_PORT0_RX_PAUSE_DA_MCAST_C0 [get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_MCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT0_RX_PAUSE_DA_MCAST_C0 [check_size $MAC_PORT0_RX_PAUSE_DA_MCAST_C0 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-pause-da-mcast-c0" $MAC_PORT0_RX_PAUSE_DA_MCAST_C0 int
	set MAC_PORT0_RX_PAUSE_DA_MCAST_C1 [get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_MCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT0_RX_PAUSE_DA_MCAST_C1 [check_size $MAC_PORT0_RX_PAUSE_DA_MCAST_C1 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-pause-da-mcast-c1" $MAC_PORT0_RX_PAUSE_DA_MCAST_C1 int
	set MAC_PORT0_RX_PAUSE_DA_UCAST_C0 [get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_UCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT0_RX_PAUSE_DA_UCAST_C0 [check_size $MAC_PORT0_RX_PAUSE_DA_UCAST_C0 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-pause-da-ucast-c0" $MAC_PORT0_RX_PAUSE_DA_UCAST_C0 int
	set MAC_PORT0_RX_PAUSE_DA_UCAST_C1 [get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_UCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT0_RX_PAUSE_DA_UCAST_C1 [check_size $MAC_PORT0_RX_PAUSE_DA_UCAST_C1 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-pause-da-ucast-c1" $MAC_PORT0_RX_PAUSE_DA_UCAST_C1 int
	set MAC_PORT0_RX_PAUSE_SA_C0 [get_property CONFIG.MAC_PORT0_RX_PAUSE_SA_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT0_RX_PAUSE_SA_C0 [check_size $MAC_PORT0_RX_PAUSE_SA_C0 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-pause-sa-c0" $MAC_PORT0_RX_PAUSE_SA_C0 int
	set MAC_PORT0_RX_PAUSE_SA_C1 [get_property CONFIG.MAC_PORT0_RX_PAUSE_SA_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT0_RX_PAUSE_SA_C1 [check_size $MAC_PORT0_RX_PAUSE_SA_C1 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-pause-sa-c1" $MAC_PORT0_RX_PAUSE_SA_C1 int
	set MAC_PORT0_TX_DA_GPP_C0 [get_property CONFIG.MAC_PORT0_TX_DA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_DA_GPP_C0 [check_size $MAC_PORT0_TX_DA_GPP_C0 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-da-gpp-c0" $MAC_PORT0_TX_DA_GPP_C0 int
	set MAC_PORT0_TX_DA_GPP_C1 [get_property CONFIG.MAC_PORT0_TX_DA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_DA_GPP_C1 [check_size $MAC_PORT0_TX_DA_GPP_C1 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-da-gpp-c1" $MAC_PORT0_TX_DA_GPP_C1 int
	set MAC_PORT0_TX_DA_PPP_C0 [get_property CONFIG.MAC_PORT0_TX_DA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_DA_PPP_C0 [check_size $MAC_PORT0_TX_DA_PPP_C0 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-da-ppp-c0" $MAC_PORT0_TX_DA_PPP_C0 int
	set MAC_PORT0_TX_DA_PPP_C1 [get_property CONFIG.MAC_PORT0_TX_DA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_DA_PPP_C1 [check_size $MAC_PORT0_TX_DA_PPP_C1 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-da-ppp-c1" $MAC_PORT0_TX_DA_PPP_C1 int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_ETHERTYPE_GPP_C0 "xlnx,mac-port0-tx-ethertype-gpp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_ETHERTYPE_GPP_C1 "xlnx,mac-port0-tx-ethertype-gpp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_ETHERTYPE_PPP_C0 "xlnx,mac-port0-tx-ethertype-ppp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_ETHERTYPE_PPP_C1 "xlnx,mac-port0-tx-ethertype-ppp-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_FLOW_C0 "xlnx,mac-port0-tx-flow-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_FLOW_C1 "xlnx,mac-port0-tx-flow-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_OPCODE_GPP_C0 "xlnx,mac-port0-tx-opcode-gpp-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT0_TX_OPCODE_GPP_C1 "xlnx,mac-port0-tx-opcode-gpp-c1" ${node} int
	set MAC_PORT0_TX_SA_GPP_C0 [get_property CONFIG.MAC_PORT0_TX_SA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_SA_GPP_C0 [check_size $MAC_PORT0_TX_SA_GPP_C0 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-sa-gpp-c0" $MAC_PORT0_TX_SA_GPP_C0 int
	set MAC_PORT0_TX_SA_GPP_C1 [get_property CONFIG.MAC_PORT0_TX_SA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_SA_GPP_C1 [check_size $MAC_PORT0_TX_SA_GPP_C1 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-sa-gpp-c1" $MAC_PORT0_TX_SA_GPP_C1 int
	set MAC_PORT0_TX_SA_PPP_C0 [get_property CONFIG.MAC_PORT0_TX_SA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_SA_PPP_C0 [check_size $MAC_PORT0_TX_SA_PPP_C0 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-sa-ppp-c0" $MAC_PORT0_TX_SA_PPP_C0 int
	set MAC_PORT0_TX_SA_PPP_C1 [get_property CONFIG.MAC_PORT0_TX_SA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT0_TX_SA_PPP_C1 [check_size $MAC_PORT0_TX_SA_PPP_C1 $node]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-sa-ppp-c1" $MAC_PORT0_TX_SA_PPP_C1 int
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch0-rxprogdiv-freq-enable-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch0-rxprogdiv-freq-enable-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch0-rxprogdiv-freq-source-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch0-rxprogdiv-freq-source-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RXPROGDIV_FREQ_VAL_C0 "xlnx,gt-ch0-rxprogdiv-freq-val-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RXPROGDIV_FREQ_VAL_C1 "xlnx,gt-ch0-rxprogdiv-freq-val-c1" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_BUFFER_MODE_C0 "xlnx,gt-ch0-rx-buffer-mode-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_BUFFER_MODE_C1 "xlnx,gt-ch0-rx-buffer-mode-c1" ${node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_DATA_DECODING_C0 "xlnx,gt-ch0-rx-data-decoding-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_DATA_DECODING_C1 "xlnx,gt-ch0-rx-data-decoding-c1" ${node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_INT_DATA_WIDTH_C0 "xlnx,gt-ch0-rx-int-data-width-c0" ${node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_INT_DATA_WIDTH_C1 "xlnx,gt-ch0-rx-int-data-width-c1" ${node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_LINE_RATE_C0 "xlnx,gt-ch0-rx-line-rate-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_LINE_RATE_C1 "xlnx,gt-ch0-rx-line-rate-c1" ${node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_OUTCLK_SOURCE_C0 "xlnx,gt-ch0-rx-outclk-source-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_OUTCLK_SOURCE_C1 "xlnx,gt-ch0-rx-outclk-source-c1" ${node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_REFCLK_FREQUENCY_C0 "xlnx,gt-ch0-rx-refclk-frequency-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_REFCLK_FREQUENCY_C1 "xlnx,gt-ch0-rx-refclk-frequency-c1" ${node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_USER_DATA_WIDTH_C0 "xlnx,gt-ch0-rx-user-data-width-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_RX_USER_DATA_WIDTH_C1 "xlnx,gt-ch0-rx-user-data-width-c1" ${node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH0_TXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch0-txprogdiv-freq-enable-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_TXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch0-txprogdiv-freq-enable-c1" ${node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH0_TXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch0-txprogdiv-freq-source-c0" ${node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH0_TXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch0-txprogdiv-freq-source-c1" ${node}

	set mrmac_clk_names [get_property CONFIG.zclock-names1 $drv_handle]
	set mrmac_clks [get_property CONFIG.zclocks1 $drv_handle]
	set mrmac_clkname_len [llength $mrmac_clk_names]
	set mrmac_clk_len [expr {[llength [split $mrmac_clks ","]]}]
	set clk_list [split $mrmac_clks ","]
	set null ""
	set_drv_prop $drv_handle "zclock-names1" $null stringlist
	set refs ""
	set_drv_prop $drv_handle "zclocks1" "$refs" stringlist

	set i 0
	while {$i < $mrmac_clkname_len} {
		set clkname [lindex $mrmac_clk_names $i]
		if {[string match -nocase $clkname "s_axi_aclk"]} {
			set s_axi_aclk "s_axi_aclk"
			set s_axi_aclk_index0 $i
		}
		if {[string match -nocase $clkname "rx_macif_clk"]} {
			set rx_macif_clk "rx_macif_clk"
			set rx_macif_clk_index0 $i
		}
		if {[string match -nocase $clkname "tx_macif_clk"]} {
			set tx_macif_clk "tx_macif_clk"
			set tx_macif_clk_index0 $i
		}
		if {[string match -nocase $clkname "ts_clk0"]} {
			set ts_clk0 "ts_clk"
			set ts_clk_index0 $i
		}
		if {[string match -nocase $clkname "ts_clk1"]} {
			set ts_clk1 "ts_clk"
			set ts_clk_index1 $i
		}
		if {[string match -nocase $clkname "ts_clk2"]} {
			set ts_clk2 "ts_clk"
			set ts_clk_index2 $i
		}
		if {[string match -nocase $clkname "ts_clk3"]} {
			set ts_clk3 "ts_clk"
			set ts_clk_index3 $i
		}
		if {[string match -nocase $clkname "tx_serdes_clk0"]} {
			set tx_serdes_clk0 "tx_serdes_clk"
			set tx_serdes_clk_index0 $i
		}
		if {[string match -nocase $clkname "tx_serdes_clk1"]} {
			set tx_serdes_clk1 "tx_serdes_clk"
			set tx_serdes_clk_index1 $i
		}
		if {[string match -nocase $clkname "tx_serdes_clk2"]} {
			set tx_serdes_clk2 "tx_serdes_clk"
			set tx_serdes_clk_index2 $i
		}
		if {[string match -nocase $clkname "tx_serdes_clk3"]} {
			set tx_serdes_clk3 "tx_serdes_clk"
			set tx_serdes_clk_index3 $i
		}
		if {[string match -nocase $clkname "rx_axi_clk0"] || [string match -nocase $clkname "rx_axi_clk"]} {
			set rx_axi_clk0 "rx_axi_clk"
			set rx_axi_clk_index0 $i
		}
		if {[string match -nocase $clkname "rx_axi_clk1"]} {
			set rx_axi_clk1 "rx_axi_clk"
			set rx_axi_clk_index1 $i
		}
		if {[string match -nocase $clkname "rx_axi_clk2"]} {
			set rx_axi_clk2 "rx_axi_clk"
			set rx_axi_clk_index2 $i
		}
		if {[string match -nocase $clkname "rx_axi_clk3"]} {
			set rx_axi_clk3 "rx_axi_clk"
			set rx_axi_clk_index3 $i
		}
		if {[string match -nocase $clkname "rx_flexif_clk0"]} {
			set rx_flexif_clk0 "rx_flexif_clk"
			set rx_flexif_clk_index0 $i
		}
		if {[string match -nocase $clkname "rx_flexif_clk1"]} {
			set rx_flexif_clk1 "rx_flexif_clk"
			set rx_flexif_clk_index1 $i
		}
		if {[string match -nocase $clkname "rx_flexif_clk2"]} {
			set rx_flexif_clk2 "rx_flexif_clk"
			set rx_flexif_clk_index2 $i
		}
		if {[string match -nocase $clkname "rx_flexif_clk3"]} {
			set rx_flexif_clk3 "rx_flexif_clk"
			set rx_flexif_clk_index3 $i
		}
		if {[string match -nocase $clkname "rx_ts_clk0"]} {
			set rx_ts_clk0 "rx_ts_clk"
			set rx_ts_clk0_index0 $i
		}
		if {[string match -nocase $clkname "rx_ts_clk1"]} {
			set rx_ts_clk1 "rx_ts_clk"
			set rx_ts_clk1_index1 $i
		}
		if {[string match -nocase $clkname "rx_ts_clk2"]} {
			set rx_ts_clk2 "rx_ts_clk"
			set rx_ts_clk2_index2 $i
		}
		if {[string match -nocase $clkname "rx_ts_clk3"]} {
			set rx_ts_clk3 "rx_ts_clk"
			set rx_ts_clk3_index3 $i
		}
		if {[string match -nocase $clkname "tx_axi_clk0"] || [string match -nocase $clkname "tx_axi_clk"] } {
			set tx_axi_clk0 "tx_axi_clk"
			set tx_axi_clk_index0 $i
		}
		if {[string match -nocase $clkname "tx_axi_clk1"]} {
			set tx_axi_clk1 "tx_axi_clk"
			set tx_axi_clk_index1 $i
		}
		if {[string match -nocase $clkname "tx_axi_clk2"]} {
			set tx_axi_clk2 "tx_axi_clk"
			set tx_axi_clk_index2 $i
		}
		if {[string match -nocase $clkname "tx_axi_clk3"]} {
			set tx_axi_clk3 "tx_axi_clk"
			set tx_axi_clk_index3 $i
		}
		if {[string match -nocase $clkname "tx_flexif_clk0"]} {
			set tx_flexif_clk0 "tx_flexif_clk"
			set tx_flexif_clk_index0 $i
		}
		if {[string match -nocase $clkname "tx_flexif_clk1"]} {
			set tx_flexif_clk1 "tx_flexif_clk"
			set tx_flexif_clk_index1 $i
		}
		if {[string match -nocase $clkname "tx_flexif_clk2"]} {
			set tx_flexif_clk2 "tx_flexif_clk"
			set tx_flexif_clk_index2 $i
		}
		if {[string match -nocase $clkname "tx_flexif_clk3"]} {
			set tx_flexif_clk3 "tx_flexif_clk"
			set tx_flexif_clk_index3 $i
		}
		if {[string match -nocase $clkname "tx_ts_clk0"]} {
			set tx_ts_clk0 "tx_ts_clk"
			set tx_ts_clk_index0 $i
		}
		if {[string match -nocase $clkname "tx_ts_clk1"]} {
			set tx_ts_clk1 "tx_ts_clk"
			set tx_ts_clk_index1 $i
		}
		if {[string match -nocase $clkname "tx_ts_clk2"]} {
			set tx_ts_clk2 "tx_ts_clk"
			set tx_ts_clk_index2 $i
		}
		if {[string match -nocase $clkname "tx_ts_clk3"]} {
			set tx_ts_clk3 "tx_ts_clk"
			set tx_ts_clk_index3 $i
		}
		incr i
	}

	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "mrmac"]} {
		lappend clknames "$s_axi_aclk" "$rx_axi_clk0" "$rx_flexif_clk0" "$rx_ts_clk0" "$tx_axi_clk0" "$tx_flexif_clk0" "$tx_ts_clk0"
		set tmpclks0 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index0]"]
		set txindex0 [lindex $clk_list $tx_ts_clk_index0]
		regsub -all "\>" $txindex0 {} txindex0
		append clkvals0  "[lindex $tmpclks0 0], [lindex $tmpclks0 1], [lindex $clk_list $rx_flexif_clk_index0], [lindex $clk_list $rx_ts_clk0_index0], [lindex $clk_list $tx_axi_clk_index0], [lindex $clk_list $tx_flexif_clk_index0], $txindex0"
		hsi::utils::add_new_dts_param "${node}" "clocks" $clkvals0 reference
		hsi::utils::add_new_dts_param "${node}" "clock-names" $clknames stringlist
	}
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "dcmac"]} {
		lappend clknames "$s_axi_aclk" "$rx_axi_clk0" "$rx_flexif_clk0" "$tx_axi_clk0" "$tx_flexif_clk0" "$rx_macif_clk" "$ts_clk0" "$tx_macif_clk" "$tx_serdes_clk0"
		set tmpclks0 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index0]"]
		set txindex0 [lindex $clk_list $tx_serdes_clk_index0]
		regsub -all "\>" $txindex0 {} txindex0
		append clkvals0  "[lindex $tmpclks0 0], [lindex $tmpclks0 1], [lindex $clk_list $rx_flexif_clk_index0], [lindex $clk_list $tx_axi_clk_index0], [lindex $clk_list $tx_flexif_clk_index0], [lindex $clk_list $rx_macif_clk_index0], [lindex $clk_list $ts_clk_index0], [lindex $clk_list $tx_macif_clk_index0], $txindex0"
		hsi::utils::add_new_dts_param "${node}" "clocks" $clkvals0 reference
		hsi::utils::add_new_dts_param "${node}" "clock-names" $clknames stringlist
	}
	set port0_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_axis_tdata0"]]
	dtg_verbose "port0_pins:$port0_pins"
	foreach pin $port0_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph] "dcmac_intf_rx"]} {
				set sink_periph [hsi::utils::get_connected_stream_ip [get_cells -hier $sink_periph] "M_AXIS"]
			}
			if {[string match -nocase [get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
				set fifo_width_bytes [get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
				if {[string_is_empty $fifo_width_bytes]} {
					set fifo_width_bytes 1
				}
				set rxethmem [get_property CONFIG.FIFO_DEPTH $sink_periph]
				# FIFO can be other than 8 bits, and we need the rxmem in bytes
				set rxethmem [expr $rxethmem * $fifo_width_bytes]
				hsi::utils::add_new_dts_param "${node}" "xlnx,rxmem" $rxethmem int
				set fifo_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $sink_periph] "m_axis_tdata"]]
				set mux_per [::hsi::get_cells -of_objects $fifo_pin]
				set fiforx_connect_ip ""
				if {[llength $mux_per] && [string match -nocase [get_property IP_NAME $mux_per] "mrmac_10g_mux"]} {
					set data_fifo_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mux_per] "rx_m_axis_tdata"]]
					set data_fifo_per [::hsi::get_cells -of_objects $data_fifo_pin]
					if {[string match -nocase [get_property IP_NAME $data_fifo_per] "axis_data_fifo"]} {
						set fiforx_connect_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $data_fifo_per] "M_AXIS"]
						dtg_verbose "fiforx_connect_ip:$fiforx_connect_ip"
						set fiforx_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $data_fifo_per] "m_axis_tdata"]]
						if {[llength $fiforx_pin]} {
							set fiforx_per [::hsi::get_cells -of_objects $fiforx_pin]
						}
						if {[llength $fiforx_per]} {
							if {[string match -nocase [get_property IP_NAME $fiforx_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
								set fiforx_connect_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $fiforx_per] "M_AXIS"]
							}
						}
					}
				}
				if {[string match -nocase [get_property IP_NAME $mux_per] "axi_mcdma"]} {
					set fiforx_connect_ip $mux_per
				}
				if {[llength $fiforx_connect_ip]} {
					if {[string match -nocase [get_property IP_NAME $fiforx_connect_ip] "axi_mcdma"]} {
						hsi::utils::add_new_dts_param "$node" "axistream-connected" "$fiforx_connect_ip" reference
						set num_queues [get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip]
						set inhex [format %x $num_queues]
						append numqueues "/bits/ 16 <0x$inhex>"
						hsi::utils::add_new_dts_param $node "xlnx,num-queues" $numqueues noformating
						set id 1
						for {set i 2} {$i <= $num_queues} {incr i} {
							set i [format "%" $i]
							append id "\""
							append id ",\"" $i
							set i [expr 0x$i]
						}
						hsi::utils::add_new_dts_param $node "xlnx,num-queues" $numqueues noformating
						hsi::utils::add_new_dts_param $node "xlnx,channel-ids" $id stringlist
						generate_intr_info $drv_handle $node $fiforx_connect_ip
					}
				}
			}
		}
	}

	#set port0_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_timestamp_tod_0"]]
	set port0_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_0"]]
	dtg_verbose "port0_pins:$port0_pins"

	if {[llength $port0_pins]} {
		set sink_periph [::hsi::get_cells -of_objects $port0_pins]
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph] "mrmac_ptp_timestamp_if"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $sink_periph] "tx_timestamp_tod"]]
				set sink_periph [::hsi::get_cells -of_objects $port_pins]
			}
		}
		if {[llength $sink_periph] && [string match -nocase [get_property IP_NAME $sink_periph] "xlconcat"]} {
			set intf "dout"
			set intr1_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$intf"]
			set sink_pins [::hsi::utils::get_sink_pins $intr1_pin]
			set xl_per ""
			if {[llength $sink_pins]} {
				set xl_per [::hsi::get_cells -of_objects $sink_pins]
			}
			if {[llength $xl_per] && [string match -nocase [get_property IP_NAME $xl_per] "axis_dwidth_converter"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $xl_per] "m_axis_tdata"]]
				set axis_per [::hsi::get_cells -of_objects $port_pins]
				if {[string match -nocase [get_property IP_NAME $axis_per] "axis_clock_converter"]} {
					set tx_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $axis_per] "M_AXIS"]
					if {[llength $tx_ip]} {
						hsi::utils::add_new_dts_param "$node" "axififo-connected" $tx_ip reference
					}
				}
			}
		}
	} else {
		dtg_warning "tx_timestamp_tod_0 connected pins are NULL...please check the design..."
	}

	#set rxtod_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_timestamp_tod_0"]]
	set rxtod_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_ptp_tstamp_out_0"]]
	dtg_verbose "rxtod_pins:$rxtod_pins"
	if {[llength $rxtod_pins]} {
		set rx_periph [::hsi::get_cells -of_objects $rxtod_pins]
		if {[llength $rx_periph]} {
			if {[string match -nocase [get_property IP_NAME $rx_periph] "mrmac_ptp_timestamp_if"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rx_periph] "rx_timestamp_tod"]]
				set rx_periph [::hsi::get_cells -of_objects $port_pins]
			}
		}
		if {[llength $rx_periph] && [string match -nocase [get_property IP_NAME $rx_periph] "xlconcat"]} {
			set intf "dout"
			set in1_pin [::hsi::get_pins -of_objects $rx_periph -filter "NAME==$intf"]
			set sink_pins [::hsi::utils::get_sink_pins $in1_pin]
			set rxxl_per ""
			if {[llength $sink_pins]} {
				set rxxl_per [::hsi::get_cells -of_objects $sink_pins]
			}
			if {[llength $rxxl_per] && [string match -nocase [get_property IP_NAME $rxxl_per] "axis_dwidth_converter"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rxxl_per] "m_axis_tdata"]]
				set rx_axis_per [::hsi::get_cells -of_objects $port_pins]
				if {[string match -nocase [get_property IP_NAME $rx_axis_per] "axis_clock_converter"]} {
					set rx_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $rx_axis_per] "M_AXIS"]
					if {[llength $rx_ip]} {
						hsi::utils::add_new_dts_param "$node" "xlnx,rxtsfifo" $rx_ip reference
					}
				}
			}
		}
	} else {
		dtg_warning "rx_timestamp_tod_0 connected pins are NULL...please check the design..."
	}

	set handle ""
	set mask_handle ""
	set ips [get_cells -hier -filter {IP_NAME == "axi_gpio"}]
	foreach ip $ips {
		set mem_ranges [hsi::utils::get_ip_mem_ranges [get_cells -hier $ip]]
		foreach mem_range $mem_ranges {
			set base [string tolower [get_property BASE_VALUE $mem_range]]
			if {[string match -nocase $base "0xa4010000"]} {
				set handle $ip
				break
			}
		}
	}
	if {[llength $handle]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,gtctrl" $handle reference
	}
	# Workaround: For gtpll we might need to add the below code for v0.1 version.
	# We can remove this workaround for later versions.
	foreach ip $ips {
		set mem_ranges [hsi::utils::get_ip_mem_ranges [get_cells -hier $ip]]
		foreach mem_range $mem_ranges {
			set base [string tolower [get_property BASE_VALUE $mem_range]]
			if {[string match -nocase $base "0xa4000000"]} {
				set mask_handle $ip
				break
			}
		}
	}
	if {[llength $mask_handle]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,gtpll" $mask_handle reference
	}
	hsi::utils::add_new_dts_param "$node" "xlnx,phcindex" 0 int
	hsi::utils::add_new_dts_param "$node" "xlnx,gtlane" 0 int

	set gt_reset_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "gt_reset_all_in"]]
	dtg_verbose "gt_reset_pins:$gt_reset_pins"
	set gt_reset_per ""
	if {[llength $gt_reset_pins]} {
		set gt_reset_periph [::hsi::get_cells -of_objects $gt_reset_pins]
		if {[llength $gt_reset_periph] && [string match -nocase [get_property IP_NAME $gt_reset_periph] "xlconcat"]} {
			set intf "In0"
			set in1_pin [::hsi::get_pins -of_objects $gt_reset_periph -filter "NAME==$intf"]
			set sink_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $gt_reset_periph] $in1_pin]]
			set gt_per [::hsi::get_cells -of_objects $sink_pins]
			if {[string match -nocase [get_property IP_NAME $gt_per] "xlslice"]} {
				set intf "Din"
				set in1_pin [::hsi::get_pins -of_objects $gt_per -filter "NAME==$intf"]
				set sink_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $gt_per] $in1_pin]]
				set gt_reset_per [::hsi::get_cells -of_objects $sink_pins]
				dtg_verbose "gt_reset_per:$gt_reset_per"
				if {[llength $gt_reset_per]} {
					hsi::utils::add_new_dts_param "$node" "xlnx,gtctrl" $gt_reset_per reference
				}
			}
		}
	}

	set gt_pll_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "mst_rx_resetdone_in"]]
	dtg_verbose "gt_pll_pins:$gt_pll_pins"
	set gt_pll_per ""
        if {[llength $gt_pll_pins]} {
                set gt_pll_periph [::hsi::get_cells -of_objects $gt_pll_pins]
                if {[llength $gt_pll_periph] && [string match -nocase [get_property IP_NAME $gt_pll_periph] "xlconcat"]} {
                        set intf "dout"
                        set in1_pin [::hsi::get_pins -of_objects $gt_pll_periph -filter "NAME==$intf"]
                        set sink_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $gt_pll_periph] $in1_pin]]
                        foreach pin $sink_pins {
                                if {[string match -nocase $pin "In0"]} {
                                        set gt_per [::hsi::get_cells -of_objects $sink_pins]
                                        foreach per $gt_per {
                                                if {[string match -nocase [get_property IP_NAME $per] "xlconcat"]} {
                                                        set intf "dout"
                                                        set in1_pin [::hsi::get_pins -of_objects $per -filter "NAME==$intf"]
                                                        set sink_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $per] $in1_pin]]
                                                        if {[llength $sink_pins]} {
                                                                set gt_pll_per [::hsi::get_cells -of_objects $sink_pins]
                                                                dtg_verbose "gt_pll_per:$gt_pll_per"
                                                                if {[llength $gt_pll_per]} {
                                                                        hsi::utils::add_new_dts_param "$node" "xlnx,gtpll" $gt_pll_per reference
								}
							}
						}
					}
				}
			}
		}
	}
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}
	set dts_file [current_dt_tree]
	set mrmac1_base [format 0x%x [expr $base_addr + 0x1000]]
	set mrmac1_base_hex [format %x $mrmac1_base]
	set mrmac1_highaddr_hex [format 0x%x [expr $mrmac1_base + 0xFFF]]
	set port1 1
	append new_label $drv_handle "_" $port1
	set node_prefix [get_property IP_NAME [get_cells -hier $drv_handle]]
	set mrmac1_node [add_or_get_dt_node -n $node_prefix -l "$new_label" -u $mrmac1_base_hex -d $dts_file -p $bus_node]
	hsi::utils::add_new_dts_param "$mrmac1_node" "compatible" "$compatible" stringlist
	set mrmac1_reg [generate_reg_property $mrmac1_base $mrmac1_highaddr_hex]
	hsi::utils::add_new_dts_param "$mrmac1_node" "reg" $mrmac1_reg inthexlist
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "mrmac"]} {
		lappend clknames1 "$s_axi_aclk" "$rx_axi_clk1" "$rx_flexif_clk1" "$rx_ts_clk1" "$tx_axi_clk1" "$tx_flexif_clk1" "$tx_ts_clk1"
		set tmpclks1 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index1]"]
		set txindex1 [lindex $clk_list $tx_ts_clk_index1]
		regsub -all "\>" $txindex1 {} txindex1
		append clkvals  "[lindex $tmpclks1 0], [lindex $tmpclks1 1], [lindex $clk_list $rx_flexif_clk_index1], [lindex $clk_list $rx_ts_clk1_index1], [lindex $clk_list $tx_axi_clk_index1], [lindex $clk_list $tx_flexif_clk_index1], $txindex1"
		hsi::utils::add_new_dts_param "${mrmac1_node}" "clocks" $clkvals reference
		hsi::utils::add_new_dts_param "${mrmac1_node}" "clock-names" $clknames1 stringlist
	}
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "dcmac"]} {
		lappend clknames1 "$s_axi_aclk" "$rx_axi_clk0" "$rx_flexif_clk1" "$tx_axi_clk0" "$tx_flexif_clk1" "$rx_macif_clk" "$ts_clk1" "$tx_macif_clk" "$tx_serdes_clk1"
		set tmpclks1 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index0]"]
		set txindex1 [lindex $clk_list $tx_serdes_clk_index1]
		regsub -all "\>" $txindex1 {} txindex1
		append clkvals  "[lindex $tmpclks1 0], [lindex $tmpclks1 1], [lindex $clk_list $rx_flexif_clk_index1], [lindex $clk_list $tx_axi_clk_index0], [lindex $clk_list $tx_flexif_clk_index1], [lindex $clk_list $rx_macif_clk_index0], [lindex $clk_list $ts_clk_index1], [lindex $clk_list $tx_macif_clk_index0], $txindex1"
		hsi::utils::add_new_dts_param "${mrmac1_node}" "clocks" $clkvals reference
		hsi::utils::add_new_dts_param "${mrmac1_node}" "clock-names" $clknames1 stringlist
	}
	set port1_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_axis_tdata2"]]
	dtg_verbose "port1_pins:$port1_pins"
	foreach pin $port1_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph] "dcmac_intf_rx"]} {
				set sink_periph [hsi::utils::get_connected_stream_ip [get_cells -hier $sink_periph] "M_AXIS"]
			}
			if {[string match -nocase [get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
				set fifo_width_bytes [get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
				if {[string_is_empty $fifo_width_bytes]} {
					set fifo_width_bytes 1
				}
				set rxethmem [get_property CONFIG.FIFO_DEPTH $sink_periph]
				# FIFO can be other than 8 bits, and we need the rxmem in bytes
				set rxethmem [expr $rxethmem * $fifo_width_bytes]
				hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,rxmem" $rxethmem int
				set fifo1_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $sink_periph] "m_axis_tdata"]]
				set mux_per1 [::hsi::get_cells -of_objects $fifo1_pin]
				set fiforx_connect_ip1 ""
				if {[llength $mux_per1] && [string match -nocase [get_property IP_NAME $mux_per1] "mrmac_10g_mux"]} {
					set data_fifo_pin1 [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mux_per1] "rx_m_axis_tdata"]]
					set data_fifo_per1 [::hsi::get_cells -of_objects $data_fifo_pin1]
					if {[string match -nocase [get_property IP_NAME $data_fifo_per1] "axis_data_fifo"]} {
						set fiforx_connect_ip1 [hsi::utils::get_connected_stream_ip [get_cells -hier $data_fifo_per1] "M_AXIS"]
						set fiforx1_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $data_fifo_per1] "m_axis_tdata"]]
						if {[llength $fiforx1_pin]} {
							set fiforx1_per [::hsi::get_cells -of_objects $fiforx1_pin]
						}
						if {[llength $fiforx1_per]} {
							if {[string match -nocase [get_property IP_NAME $fiforx1_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
								set fiforx_connect_ip1 [hsi::utils::get_connected_stream_ip [get_cells -hier $fiforx1_per] "M_AXIS"]
							}
						}
					}
				}
				if {[string match -nocase [get_property IP_NAME $mux_per1] "axi_mcdma"]} {
					set fiforx_connect_ip1 $mux_per1
				}
				if {[llength $fiforx_connect_ip1]} {
					if {[string match -nocase [get_property IP_NAME $fiforx_connect_ip1] "axi_mcdma"]} {
						hsi::utils::add_new_dts_param "$mrmac1_node" "axistream-connected" "$fiforx_connect_ip1" reference
						set num_queues [get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip1]
						set inhex [format %x $num_queues]
						append numqueues1 "/bits/ 16 <0x$inhex>"
						hsi::utils::add_new_dts_param $mrmac1_node "xlnx,num-queues" $numqueues1 noformating
						set id 1
						for {set i 2} {$i <= $num_queues} {incr i} {
							set i [format "%" $i]
							append id "\""
							append id ",\"" $i
							set i [expr 0x$i]
						}
						hsi::utils::add_new_dts_param $mrmac1_node "xlnx,num-queues" $numqueues1 noformating
						hsi::utils::add_new_dts_param $mrmac1_node "xlnx,channel-ids" $id stringlist
						generate_intr_info $drv_handle $mrmac1_node $fiforx_connect_ip1
					}
				}
			}
		}
	}

	#set txtodport1_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_timestamp_tod_1"]]
	set txtodport1_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_1"]]
	dtg_verbose "txtodport1_pins:$txtodport1_pins"
	if {[llength $txtodport1_pins]} {
		set tod1_sink_periph [::hsi::get_cells -of_objects $txtodport1_pins]
		if {[llength $tod1_sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $tod1_sink_periph] "mrmac_ptp_timestamp_if"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $tod1_sink_periph] "tx_timestamp_tod"]]
				set tod1_sink_periph [::hsi::get_cells -of_objects $port_pins]
			}
		}
		if {[llength $tod1_sink_periph] && [string match -nocase [get_property IP_NAME $tod1_sink_periph] "xlconcat"]} {
			set intf "dout"
			set in1_pin [::hsi::get_pins -of_objects $tod1_sink_periph -filter "NAME==$intf"]
			set in1sink_pins [::hsi::utils::get_sink_pins $in1_pin]
			set xl_per1 ""
			if {[llength $in1sink_pins]} {
				set xl_per1 [::hsi::get_cells -of_objects $in1sink_pins]
			}
			if {[llength $xl_per1] && [string match -nocase [get_property IP_NAME $xl_per1] "axis_dwidth_converter"]} {
				set port1_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $xl_per1] "m_axis_tdata"]]
				set axis_per1 [::hsi::get_cells -of_objects $port1_pins]
				if {[string match -nocase [get_property IP_NAME $axis_per1] "axis_clock_converter"]} {
					set tx1_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $axis_per1] "M_AXIS"]
					if {[llength $tx1_ip]} {
						hsi::utils::add_new_dts_param "$mrmac1_node" "axififo-connected" $tx1_ip reference
					}
				}
			}
		}
	} else {
		dtg_warning "tx_timestamp_tod_1 connected pins are NULL...please check the design..."
	}


	#set rxtod1_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_timestamp_tod_1"]]
	set rxtod1_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_ptp_tstamp_out_1"]]
	dtg_verbose "rxtod1_pins:$rxtod1_pins"
	if {[llength $rxtod1_pins]} {
		set rx_periph1 [::hsi::get_cells -of_objects $rxtod1_pins]
		if {[llength $rx_periph1]} {
			if {[string match -nocase [get_property IP_NAME $rx_periph1] "mrmac_ptp_timestamp_if"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rx_periph1] "rx_timestamp_tod"]]
				set rx_periph1 [::hsi::get_cells -of_objects $port_pins]
			}
		}
		if {[llength $rx_periph1] && [string match -nocase [get_property IP_NAME $rx_periph1] "xlconcat"]} {
			set intf "dout"
			set inrx1_pin [::hsi::get_pins -of_objects $rx_periph1 -filter "NAME==$intf"]
			set rxtodsink_pins [::hsi::utils::get_sink_pins $inrx1_pin]
			set rx_per ""
			if {[llength $rxtodsink_pins]} {
				set rx_per [::hsi::get_cells -of_objects $rxtodsink_pins]
			}
			if {[llength $rx_per] && [string match -nocase [get_property IP_NAME $rx_per] "axis_dwidth_converter"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rx_per] "m_axis_tdata"]]
				set rx_axis_per [::hsi::get_cells -of_objects $port_pins]
				if {[string match -nocase [get_property IP_NAME $rx_axis_per] "axis_clock_converter"]} {
					set rx_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $rx_axis_per] "M_AXIS"]
					if {[llength $rx_ip]} {
						hsi::utils::add_new_dts_param "$mrmac1_node" "xlnx,rxtsfifo" $rx_ip reference
					}
				}
			}
		}
	} else {
		dtg_warning "rx_timestamp_tod_1 connected pins are NULL...please check the design..."
	}


	if {[llength $handle]} {
		hsi::utils::add_new_dts_param "$mrmac1_node" "xlnx,gtctrl" $handle reference
	}
	if {[llength $mask_handle]} {
		hsi::utils::add_new_dts_param "$mrmac1_node" "xlnx,gtpll" $mask_handle reference
	}
	if {[llength $gt_reset_per]} {
		hsi::utils::add_new_dts_param "$mrmac1_node" "xlnx,gtctrl" $gt_reset_per reference
	}
	if {[llength $gt_pll_per]} {
		hsi::utils::add_new_dts_param "$mrmac1_node" "xlnx,gtpll" $gt_pll_per reference
	}
	hsi::utils::add_new_dts_param "$mrmac1_node" "xlnx,phcindex" 1 int
	hsi::utils::add_new_dts_param "$mrmac1_node" "xlnx,gtlane" 1 int

	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE1_CFG_C0 "xlnx,flex-slice1-cfg-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE1_CFG_C1 "xlnx,flex-slice1-cfg-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT1_DATA_RATE_C0 "xlnx,flex-port1-data-rate-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT1_DATA_RATE_C1 "xlnx,flex-port1-data-rate-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT1_ENABLE_TIME_STAMPING_C0 "xlnx,flex-port1-enable-time-stamping-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT1_ENABLE_TIME_STAMPING_C1 "xlnx,flex-port1-enable-time-stamping-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT1_MODE_C0 "xlnx,flex-port1-mode-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT1_MODE_C1 "xlnx,flex-port1-mode-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.PORT1_1588v2_Clocking_C0 "xlnx,port1-1588v2-clocking-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.PORT1_1588v2_Clocking_C1 "xlnx,port1-1588v2-clocking-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.PORT1_1588v2_Operation_MODE_C0 "xlnx,port1-1588v2-operation-mode-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.PORT1_1588v2_Operation_MODE_C1 "xlnx,port1-1588v2-operation-mode-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_ENABLE_TIME_STAMPING_C0 "xlnx,mac-port1-enable-time-stamping-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_ENABLE_TIME_STAMPING_C1 "xlnx,mac-port1-enable-time-stamping-c1" ${mrmac1_node} int
	set MAC_PORT1_RATE_C0 [get_property CONFIG.MAC_PORT1_RATE_C0 [get_cells -hier $drv_handle]]
	if {[llength $MAC_PORT1_RATE_C0]} {
		if {[string match -nocase $MAC_PORT1_RATE_C0 "10GE"]} {
			set number 10000
			hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mrmac-rate" $number int
		} else {
			hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mrmac-rate" $MAC_PORT1_RATE_C0 string
		}
	}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RATE_C1 "xlnx,mac-port1-rate-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_GCP_C0 "xlnx,mac-port1-rx-etype-gcp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_GCP_C1 "xlnx,mac-port1-rx-etype-gcp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_GPP_C0 "xlnx,mac-port1-rx-etype-gpp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_GPP_C1 "xlnx,mac-port1-rx-etype-gpp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_PCP_C0 "xlnx,mac-port1-rx-etype-pcp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_PCP_C1 "xlnx,mac-port1-rx-etype-pcp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_PPP_C0 "xlnx,mac-port1-rx-etype-ppp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_ETYPE_PPP_C1 "xlnx,mac-port1-rx-etype-ppp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_FLOW_C0 "xlnx,mac-port1-rx-flow-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_FLOW_C1 "xlnx,mac-port1-rx-flow-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_GPP_C0 "xlnx,mac-port1-rx-opcode-gpp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_GPP_C1 "xlnx,mac-port1-rx-opcode-gpp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MAX_GCP_C0 "xlnx,mac-port1-rx-opcode-max-gcp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MAX_GCP_C1 "xlnx,mac-port1-rx-opcode-max-gcp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MAX_PCP_C0 "xlnx,mac-port1-rx-opcode-max-pcp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MAX_PCP_C1 "xlnx,mac-port1-rx-opcode-max-pcp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MIN_GCP_C0 "xlnx,mac-port1-rx-opcode-min-gcp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MIN_GCP_C1 "xlnx,mac-port1-rx-opcode-min-gcp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MIN_PCP_C0 "xlnx,mac-port1-rx-opcode-min-pcp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_MIN_PCP_C1 "xlnx,mac-port1-rx-opcode-min-pcp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_PPP_C0 "xlnx,mac-port1-rx-opcode-ppp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_RX_OPCODE_PPP_C1 "xlnx,mac-port1-rx-opcode-ppp-c1" ${mrmac1_node} int
	set MAC_PORT1_RX_PAUSE_DA_MCAST_C0 [get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_MCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT1_RX_PAUSE_DA_MCAST_C0 [check_size $MAC_PORT1_RX_PAUSE_DA_MCAST_C0 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-mcast-c0" $MAC_PORT1_RX_PAUSE_DA_MCAST_C0 int
	set MAC_PORT1_RX_PAUSE_DA_MCAST_C1 [get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_MCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT1_RX_PAUSE_DA_MCAST_C1 [check_size $MAC_PORT1_RX_PAUSE_DA_MCAST_C1 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-mcast-c1" $MAC_PORT1_RX_PAUSE_DA_MCAST_C1 int
	set MAC_PORT1_RX_PAUSE_DA_UCAST_C0 [get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_UCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT1_RX_PAUSE_DA_UCAST_C0 [check_size $MAC_PORT1_RX_PAUSE_DA_UCAST_C0 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-ucast-c0" $MAC_PORT1_RX_PAUSE_DA_UCAST_C0 int
	set MAC_PORT1_RX_PAUSE_DA_UCAST_C1 [get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_UCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT1_RX_PAUSE_DA_UCAST_C1 [check_size $MAC_PORT1_RX_PAUSE_DA_UCAST_C1 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-ucast-c1" $MAC_PORT1_RX_PAUSE_DA_UCAST_C1 int
	set MAC_PORT1_RX_PAUSE_SA_C0 [get_property CONFIG.MAC_PORT1_RX_PAUSE_SA_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT1_RX_PAUSE_SA_C0 [check_size $MAC_PORT1_RX_PAUSE_SA_C0 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-pause-sa-c0" $MAC_PORT1_RX_PAUSE_SA_C0 int
	set MAC_PORT1_RX_PAUSE_SA_C1 [get_property CONFIG.MAC_PORT1_RX_PAUSE_SA_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT1_RX_PAUSE_SA_C1 [check_size $MAC_PORT1_RX_PAUSE_SA_C1 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-pause-sa-c1" $MAC_PORT1_RX_PAUSE_SA_C1 int
	set MAC_PORT1_TX_DA_GPP_C0 [get_property CONFIG.MAC_PORT1_TX_DA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_DA_GPP_C0 [check_size $MAC_PORT1_TX_DA_GPP_C0 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-da-gpp-c0" $MAC_PORT1_TX_DA_GPP_C0 int
	set MAC_PORT1_TX_DA_GPP_C1 [get_property CONFIG.MAC_PORT1_TX_DA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_DA_GPP_C1 [check_size $MAC_PORT1_TX_DA_GPP_C1 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-da-gpp-c1" $MAC_PORT1_TX_DA_GPP_C1 int
	set MAC_PORT1_TX_DA_PPP_C0 [get_property CONFIG.MAC_PORT1_TX_DA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_DA_PPP_C0 [check_size $MAC_PORT1_TX_DA_PPP_C0 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-da-ppp-c0" $MAC_PORT1_TX_DA_PPP_C0 int
	set MAC_PORT1_TX_DA_PPP_C1 [get_property CONFIG.MAC_PORT1_TX_DA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_DA_PPP_C1 [check_size $MAC_PORT1_TX_DA_PPP_C1 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-da-ppp-c1" $MAC_PORT1_TX_DA_PPP_C1 int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_ETHERTYPE_GPP_C0 "xlnx,mac-port1-tx-ethertype-gpp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_ETHERTYPE_GPP_C1 "xlnx,mac-port1-tx-ethertype-gpp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_ETHERTYPE_PPP_C0 "xlnx,mac-port1-tx-ethertype-ppp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_ETHERTYPE_PPP_C1 "xlnx,mac-port1-tx-ethertype-ppp-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_FLOW_C0 "xlnx,mac-port1-tx-flow-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_FLOW_C1 "xlnx,mac-port1-tx-flow-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_OPCODE_GPP_C0 "xlnx,mac-port1-tx-opcode-gpp-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT1_TX_OPCODE_GPP_C1 "xlnx,mac-port1-tx-opcode-gpp-c1" ${mrmac1_node} int
	set MAC_PORT1_TX_SA_GPP_C0 [get_property CONFIG.MAC_PORT1_TX_SA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_SA_GPP_C0 [check_size $MAC_PORT1_TX_SA_GPP_C0 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-sa-gpp-c0" $MAC_PORT1_TX_SA_GPP_C0 int
	set MAC_PORT1_TX_SA_GPP_C1 [get_property CONFIG.MAC_PORT1_TX_SA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_SA_GPP_C1 [check_size $MAC_PORT1_TX_SA_GPP_C1 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-sa-gpp-c1" $MAC_PORT1_TX_SA_GPP_C1 int
	set MAC_PORT1_TX_SA_PPP_C0 [get_property CONFIG.MAC_PORT1_TX_SA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_SA_PPP_C0 [check_size $MAC_PORT1_TX_SA_PPP_C0 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-sa-ppp-c0" $MAC_PORT1_TX_SA_PPP_C0 int
	set MAC_PORT1_TX_SA_PPP_C1 [get_property CONFIG.MAC_PORT1_TX_SA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT1_TX_SA_PPP_C1 [check_size $MAC_PORT1_TX_SA_PPP_C1 $mrmac1_node]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-sa-ppp-c1" $MAC_PORT1_TX_SA_PPP_C1 int
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch1-rxprogdiv-freq-enable-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch1-rxprogdiv-freq-enable-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch1-rxprogdiv-freq-source-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch1-rxprogdiv-freq-source-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RXPROGDIV_FREQ_VAL_C0 "xlnx,gt-ch1-rxprogdiv-freq-val-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RXPROGDIV_FREQ_VAL_C1 "xlnx,gt-ch1-rxprogdiv-freq-val-c1" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_BUFFER_MODE_C0 "xlnx,gt-ch1-rx-buffer-mode-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_BUFFER_MODE_C1 "xlnx,gt-ch1-rx-buffer-mode-c1" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_DATA_DECODING_C0 "xlnx,gt-ch1-rx-data-decoding-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_DATA_DECODING_C1 "xlnx,gt-ch1-rx-data-decoding-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_INT_DATA_WIDTH_C0 "xlnx,gt-ch1-rx-int-data-width-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_INT_DATA_WIDTH_C1 "xlnx,gt-ch1-rx-int-data-width-c1" ${mrmac1_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_LINE_RATE_C0 "xlnx,gt-ch1-rx-line-rate-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_LINE_RATE_C1 "xlnx,gt-ch1-rx-line-rate-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_OUTCLK_SOURCE_C0 "xlnx,gt-ch1-rx-outclk-source-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_OUTCLK_SOURCE_C1 "xlnx,gt-ch1-rx-outclk-source-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_REFCLK_FREQUENCY_C0 "xlnx,gt-ch1-rx-refclk-frequency-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_REFCLK_FREQUENCY_C1 "xlnx,gt-ch1-rx-refclk-frequency-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_USER_DATA_WIDTH_C0 "xlnx,gt-ch1-rx-user-data-width-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_RX_USER_DATA_WIDTH_C1 "xlnx,gt-ch1-rx-user-data-width-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch1-txprogdiv-freq-enable-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch1-txprogdiv-freq-enable-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch1-txprogdiv-freq-source-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch1-txprogdiv-freq-source-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TXPROGDIV_FREQ_VAL_C0 "xlnx,gt-ch1-txprogdiv-freq-val-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TXPROGDIV_FREQ_VAL_C1 "xlnx,gt-ch1-txprogdiv-freq-val-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_BUFFER_MODE_C0 "xlnx,gt-ch1-tx-buffer-mode-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_BUFFER_MODE_C1 "xlnx,gt-ch1-tx-buffer-mode-c1" ${mrmac1_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_DATA_ENCODING_C0 "xlnx,gt-ch1-tx-data-encoding-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_DATA_ENCODING_C1 "xlnx,gt-ch1-tx-data-encoding-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_INT_DATA_WIDTH_C0 "xlnx,gt-ch1-int-data-width-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_INT_DATA_WIDTH_C1 "xlnx,gt-ch1-int-data-width-c1" ${mrmac1_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_LINE_RATE_C0 "xlnx,gt-ch1-tx-line-rate-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_LINE_RATE_C1 "xlnx,gt-ch1-tx-line-rate-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_OUTCLK_SOURCE_C0 "xlnx,gt-ch1-tx-outclk-source-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_OUTCLK_SOURCE_C1 "xlnx,gt-ch1-tx-outclk-source-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_PLL_TYPE_C0 "xlnx,gt-ch1-tx-pll-type-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_PLL_TYPE_C1 "xlnx,gt-ch1-tx-pll-type-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_REFCLK_FREQUENCY_C0 "xlnx,gt-ch1-tx-refclk-frequency-c0" ${mrmac1_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_REFCLK_FREQUENCY_C1 "xlnx,gt-ch1-tx-refclk-frequency-c1" ${mrmac1_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_USER_DATA_WIDTH_C0 "xlnx,gt-ch1-tx-user-data-width-c0" ${mrmac1_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH1_TX_USER_DATA_WIDTH_C1 "xlnx,gt-ch1-tx-user-data-width-c1" ${mrmac1_node} int

	set mrmac2_base [format 0x%x [expr $base_addr + 0x2000]]
	set mrmac2_base_hex [format %x $mrmac2_base]
	set mrmac2_highaddr_hex [format 0x%x [expr $mrmac2_base + 0xFFF]]
	set port2 2
	append label2 $drv_handle "_" $port2
	set node_prefix [get_property IP_NAME [get_cells -hier $drv_handle]]
	set mrmac2_node [add_or_get_dt_node -n $node_prefix -l "$label2" -u $mrmac2_base_hex -d $dts_file -p $bus_node]
	hsi::utils::add_new_dts_param "$mrmac2_node" "compatible" "$compatible" stringlist
	set mrmac2_reg [generate_reg_property $mrmac2_base $mrmac2_highaddr_hex]
	hsi::utils::add_new_dts_param "$mrmac2_node" "reg" $mrmac2_reg inthexlist

	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "mrmac"]} {
		lappend clknames2 "$s_axi_aclk" "$rx_axi_clk2" "$rx_flexif_clk2" "$rx_ts_clk2" "$tx_axi_clk2" "$tx_flexif_clk2" "$tx_ts_clk2"
		set tmpclks2 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index2]"]
		set txindex2 [lindex $clk_list $tx_ts_clk_index2]
		regsub -all "\>" $txindex2 {} txindex2
		append clkvals2  "[lindex $tmpclks2 0], [lindex $tmpclks2 1], [lindex $clk_list $rx_flexif_clk_index2], [lindex $clk_list $rx_ts_clk2_index2], [lindex $clk_list $tx_axi_clk_index2], [lindex $clk_list $tx_flexif_clk_index2], $txindex2"
		hsi::utils::add_new_dts_param "${mrmac2_node}" "clocks" $clkvals2 reference
		hsi::utils::add_new_dts_param "${mrmac2_node}" "clock-names" $clknames2 stringlist
	}
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "dcmac"]} {
		lappend clknames2 "$s_axi_aclk" "$rx_axi_clk0" "$rx_flexif_clk2" "$tx_axi_clk0" "$tx_flexif_clk2" "$rx_macif_clk" "$ts_clk2" "$tx_macif_clk" "$tx_serdes_clk2"
		set tmpclks2 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index0]"]
		set txindex2 [lindex $clk_list $tx_serdes_clk_index2]
		regsub -all "\>" $txindex2 {} txindex2
		append clkvals2  "[lindex $tmpclks2 0], [lindex $tmpclks2 1], [lindex $clk_list $rx_flexif_clk_index2], [lindex $clk_list $tx_axi_clk_index0], [lindex $clk_list $tx_flexif_clk_index2], [lindex $clk_list $rx_macif_clk_index0], [lindex $clk_list $ts_clk_index2], [lindex $clk_list $tx_macif_clk_index0], $txindex2"
		hsi::utils::add_new_dts_param "${mrmac2_node}" "clocks" $clkvals2 reference
		hsi::utils::add_new_dts_param "${mrmac2_node}" "clock-names" $clknames2 stringlist
	}

	set port2_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_axis_tdata4"]]
	foreach pin $port2_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph] "dcmac_intf_rx"]} {
				set sink_periph [hsi::utils::get_connected_stream_ip [get_cells -hier $sink_periph] "M_AXIS"]
			}
			if {[string match -nocase [get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
				set fifo_width_bytes [get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
				if {[string_is_empty $fifo_width_bytes]} {
					set fifo_width_bytes 1
				}
				set rxethmem [get_property CONFIG.FIFO_DEPTH $sink_periph]
				# FIFO can be other than 8 bits, and we need the rxmem in bytes
				set rxethmem [expr $rxethmem * $fifo_width_bytes]
				hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,rxmem" $rxethmem int
				set fifo2_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $sink_periph] "m_axis_tdata"]]
				set mux_per2 [::hsi::get_cells -of_objects $fifo2_pin]
				set fiforx_connect_ip2 ""
				if {[llength $mux_per2] && [string match -nocase [get_property IP_NAME $mux_per2] "mrmac_10g_mux"]} {
					set data_fifo_pin2 [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mux_per2] "rx_m_axis_tdata"]]
					set data_fifo_per2 [::hsi::get_cells -of_objects $data_fifo_pin2]
					if {[string match -nocase [get_property IP_NAME $data_fifo_per2] "axis_data_fifo"]} {
						set fiforx_connect_ip2 [hsi::utils::get_connected_stream_ip [get_cells -hier $data_fifo_per2] "M_AXIS"]
						set fiforx2_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $data_fifo_per2] "m_axis_tdata"]]
						set fiforx2_per [::hsi::get_cells -of_objects $fiforx2_pin]
						if {[string match -nocase [get_property IP_NAME $fiforx2_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
							set fiforx_connect_ip2 [hsi::utils::get_connected_stream_ip [get_cells -hier $fiforx2_per] "M_AXIS"]
						}
					}
				}
				if {[string match -nocase [get_property IP_NAME $mux_per2] "axi_mcdma"]} {
					set fiforx_connect_ip2 $mux_per2
				}
				if {[llength $fiforx_connect_ip2]} {
					if {[string match -nocase [get_property IP_NAME $fiforx_connect_ip2] "axi_mcdma"]} {
						hsi::utils::add_new_dts_param "$mrmac2_node" "axistream-connected" "$fiforx_connect_ip2" reference
						set num_queues [get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip2]
						set inhex [format %x $num_queues]
						append numqueues2 "/bits/ 16 <0x$inhex>"
						hsi::utils::add_new_dts_param $mrmac2_node "xlnx,num-queues" $numqueues2 noformating
						set id 1
						for {set i 2} {$i <= $num_queues} {incr i} {
							set i [format "%" $i]
							append id "\""
							append id ",\"" $i
							set i [expr 0x$i]
						}
						hsi::utils::add_new_dts_param $mrmac2_node "xlnx,num-queues" $numqueues2 noformating
						hsi::utils::add_new_dts_param $mrmac2_node "xlnx,channel-ids" $id stringlist
						generate_intr_info $drv_handle $mrmac2_node $fiforx_connect_ip2
					}
				}
			}
		}
	}

	#set txtodport2_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_timestamp_tod_2"]]
	set txtodport2_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_2"]]

	if {[llength $txtodport2_pins]} {
		set tod2_sink_periph [::hsi::get_cells -of_objects $txtodport2_pins]
		if {[string match -nocase [get_property IP_NAME $tod2_sink_periph] "mrmac_ptp_timestamp_if"]} {
			set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $tod2_sink_periph] "tx_timestamp_tod"]]
			set tod2_sink_periph [::hsi::get_cells -of_objects $port_pins]
		}
		if {[llength $tod2_sink_periph] && [string match -nocase [get_property IP_NAME $tod2_sink_periph] "xlconcat"]} {
			set intf "dout"
			set in2_pin [::hsi::get_pins -of_objects $tod2_sink_periph -filter "NAME==$intf"]
			set in2sink_pins [::hsi::utils::get_sink_pins $in2_pin]
			set xl_per2 ""
			if {[llength $in2sink_pins]} {
				set xl_per2 [::hsi::get_cells -of_objects $in2sink_pins]
			}
			if {[llength $xl_per2] && [string match -nocase [get_property IP_NAME $xl_per2] "axis_dwidth_converter"]} {
				set port2pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $xl_per2] "m_axis_tdata"]]
				set axis_per2 [::hsi::get_cells -of_objects $port2pins]
				if {[string match -nocase [get_property IP_NAME $axis_per2] "axis_clock_converter"]} {
					set tx2_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $axis_per2] "M_AXIS"]
					if {[llength $tx2_ip]} {
						hsi::utils::add_new_dts_param "$mrmac2_node" "axififo-connected" $tx2_ip reference
					}
				}
			}
		}
	} else {
		dtg_warning "tx_timestamp_tod_2 connected pins are NULL...please check the design..."
	}


	#set rxtod2_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_timestamp_tod_2"]]
	set rxtod2_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_ptp_tstamp_out_2"]]

	if {[llength $rxtod2_pins]} {
		set rx_periph2 [::hsi::get_cells -of_objects $rxtod2_pins]
		if {[string match -nocase [get_property IP_NAME $rx_periph2] "mrmac_ptp_timestamp_if"]} {
			set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rx_periph2] "rx_timestamp_tod"]]
			set rx_periph2 [::hsi::get_cells -of_objects $port_pins]
		}
		if {[llength $rx_periph2] && [string match -nocase [get_property IP_NAME $rx_periph2] "xlconcat"]} {
			set intf "dout"
			set inrx2_pin [::hsi::get_pins -of_objects $rx_periph2 -filter "NAME==$intf"]
			set rxtodsink_pins [::hsi::utils::get_sink_pins $inrx2_pin]
			set rx_per2 ""
			if {[llength $rxtodsink_pins]} {
				set rx_per2 [::hsi::get_cells -of_objects $rxtodsink_pins]
			}
			if {[llength $rx_per2] && [string match -nocase [get_property IP_NAME $rx_per2] "axis_dwidth_converter"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rx_per2] "m_axis_tdata"]]
				set rx_axis_per2 [::hsi::get_cells -of_objects $port_pins]
				if {[string match -nocase [get_property IP_NAME $rx_axis_per2] "axis_clock_converter"]} {
					set rx_ip2 [hsi::utils::get_connected_stream_ip [get_cells -hier $rx_axis_per2] "M_AXIS"]
					if {[llength $rx_ip2]} {
						hsi::utils::add_new_dts_param "$mrmac2_node" "xlnx,rxtsfifo" $rx_ip2 reference
					}
				}
			}
		}
	} else {
		dtg_warning "rx_timestamp_tod_2 connected pins are NULL...please check the design..."
	}

	if {[llength $handle]} {
		hsi::utils::add_new_dts_param "$mrmac2_node" "xlnx,gtctrl" $handle reference
	}
	if {[llength $mask_handle]} {
		hsi::utils::add_new_dts_param "$mrmac2_node" "xlnx,gtpll" $mask_handle reference
	}
	if {[llength $gt_reset_per]} {
		hsi::utils::add_new_dts_param "$mrmac2_node" "xlnx,gtctrl" $gt_reset_per reference
	}
	if {[llength $gt_pll_per]} {
		hsi::utils::add_new_dts_param "$mrmac2_node" "xlnx,gtpll" $gt_pll_per reference
	}
	hsi::utils::add_new_dts_param "$mrmac2_node" "xlnx,phcindex" 2 int
	hsi::utils::add_new_dts_param "$mrmac2_node" "xlnx,gtlane" 2 int

	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE2_CFG_C0 "xlnx,flex-slice2-cfg-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE2_CFG_C1 "xlnx,flex-slice2-cfg-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT2_DATA_RATE_C0 "xlnx,flex-port2-data-rate-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT2_DATA_RATE_C1 "xlnx,flex-port2-data-rate-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT2_ENABLE_TIME_STAMPING_C0 "xlnx,flex-port2-enable-time-stamping-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT2_ENABLE_TIME_STAMPING_C1 "xlnx,flex-port2-enable-time-stamping-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT2_MODE_C0 "xlnx,flex-port2-mode-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT2_MODE_C1 "xlnx,flex-port2-mode-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.PORT2_1588v2_Clocking_C0 "xlnx,port2-1588v2-clocking-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.PORT2_1588v2_Clocking_C1 "xlnx,port2-1588v2-clocking-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.PORT2_1588v2_Operation_MODE_C0 "xlnx,port2-1588v2-operation-mode-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.PORT2_1588v2_Operation_MODE_C1 "xlnx,port2-1588v2-operation-mode-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_ENABLE_TIME_STAMPING_C0 "xlnx,mac-port2-enable-time-stamping-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_ENABLE_TIME_STAMPING_C1 "xlnx,mac-port2-enable-time-stamping-c1" ${mrmac2_node} int

	set MAC_PORT2_RATE_C0 [get_property CONFIG.MAC_PORT2_RATE_C0 [get_cells -hier $drv_handle]]
	if {[llength ${MAC_PORT2_RATE_C0}]} {
		if {[string match -nocase $MAC_PORT2_RATE_C0 "10GE"]} {
			set number 10000
			hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mrmac-rate" $number int
		} else {
			hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mrmac-rate" $MAC_PORT2_RATE_C0 string
		}
	}

	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RATE_C1 "xlnx,mac-port2-rate-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_GCP_C0 "xlnx,mac-port2-rx-etype-gcp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_GCP_C1 "xlnx,mac-port2-rx-etype-gcp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_GPP_C0 "xlnx,mac-port2-rx-etype-gpp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_GPP_C1 "xlnx,mac-port2-rx-etype-gpp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_PCP_C0 "xlnx,mac-port2-rx-etype-pcp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_PCP_C1 "xlnx,mac-port2-rx-etype-pcp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_PPP_C0 "xlnx,mac-port2-rx-etype-ppp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_ETYPE_PPP_C1 "xlnx,mac-port2-rx-etype-ppp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_FLOW_C0 "xlnx,mac-port2-rx-flow-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_FLOW_C1 "xlnx,mac-port2-rx-flow-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_GPP_C0 "xlnx,mac-port2-rx-opcode-gpp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_GPP_C1 "xlnx,mac-port2-rx-opcode-gpp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MAX_GCP_C0 "xlnx,mac-port2-rx-opcode-max-gcp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MAX_GCP_C1 "xlnx,mac-port2-rx-opcode-max-gcp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MAX_PCP_C0 "xlnx,mac-port2-rx-opcode-max-pcp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MAX_PCP_C1 "xlnx,mac-port2-rx-opcode-max-pcp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MIN_GCP_C0 "xlnx,mac-port2-rx-opcode-min-gcp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MIN_GCP_C1 "xlnx,mac-port2-rx-opcode-min-gcp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MIN_PCP_C0 "xlnx,mac-port2-rx-opcode-min-pcp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_MIN_PCP_C1 "xlnx,mac-port2-rx-opcode-min-pcp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_PPP_C0 "xlnx,mac-port2-rx-opcode-ppp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_RX_OPCODE_PPP_C1 "xlnx,mac-port2-rx-opcode-ppp-c1" ${mrmac2_node} int
	set MAC_PORT2_RX_PAUSE_DA_MCAST_C0 [get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_MCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT2_RX_PAUSE_DA_MCAST_C0 [check_size $MAC_PORT2_RX_PAUSE_DA_MCAST_C0 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-mcast-c0" $MAC_PORT2_RX_PAUSE_DA_MCAST_C0 int
	set MAC_PORT2_RX_PAUSE_DA_MCAST_C1 [get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_MCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT2_RX_PAUSE_DA_MCAST_C1 [check_size $MAC_PORT2_RX_PAUSE_DA_MCAST_C1 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-mcast-c1" $MAC_PORT2_RX_PAUSE_DA_MCAST_C1 int
	set MAC_PORT2_RX_PAUSE_DA_UCAST_C0 [get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_UCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT2_RX_PAUSE_DA_UCAST_C0 [check_size $MAC_PORT2_RX_PAUSE_DA_UCAST_C0 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-ucast-c0" $MAC_PORT2_RX_PAUSE_DA_UCAST_C0 int
	set MAC_PORT2_RX_PAUSE_DA_UCAST_C1 [get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_UCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT2_RX_PAUSE_DA_UCAST_C1 [check_size $MAC_PORT2_RX_PAUSE_DA_UCAST_C1 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-ucast-c1" $MAC_PORT2_RX_PAUSE_DA_UCAST_C1 int
	set MAC_PORT2_RX_PAUSE_SA_C0 [get_property CONFIG.MAC_PORT2_RX_PAUSE_SA_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT2_RX_PAUSE_SA_C0 [check_size $MAC_PORT2_RX_PAUSE_SA_C0 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-pause-sa-c0" $MAC_PORT2_RX_PAUSE_SA_C0 int
	set MAC_PORT2_RX_PAUSE_SA_C1 [get_property CONFIG.MAC_PORT2_RX_PAUSE_SA_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT2_RX_PAUSE_SA_C1 [check_size $MAC_PORT2_RX_PAUSE_SA_C1 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-pause-sa-c1" $MAC_PORT2_RX_PAUSE_SA_C1 int
	set MAC_PORT2_TX_DA_GPP_C0 [get_property CONFIG.MAC_PORT2_TX_DA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_DA_GPP_C0 [check_size $MAC_PORT2_TX_DA_GPP_C0 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-da-gpp-c0" $MAC_PORT2_TX_DA_GPP_C0 int
	set MAC_PORT2_TX_DA_GPP_C1 [get_property CONFIG.MAC_PORT2_TX_DA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_DA_GPP_C1 [check_size $MAC_PORT2_TX_DA_GPP_C1 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-da-gpp-c1" $MAC_PORT2_TX_DA_GPP_C1 int
	set MAC_PORT2_TX_DA_PPP_C0 [get_property CONFIG.MAC_PORT2_TX_DA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_DA_PPP_C0 [check_size $MAC_PORT2_TX_DA_PPP_C0 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-da-ppp-c0" $MAC_PORT2_TX_DA_PPP_C0 int
	set MAC_PORT2_TX_DA_PPP_C1 [get_property CONFIG.MAC_PORT2_TX_DA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_DA_PPP_C1 [check_size $MAC_PORT2_TX_DA_PPP_C1 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-da-ppp-c1" $MAC_PORT2_TX_DA_PPP_C1 int

	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_ETHERTYPE_GPP_C0 "xlnx,mac-port2-tx-ethertype-gpp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_ETHERTYPE_GPP_C1 "xlnx,mac-port2-tx-ethertype-gpp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_ETHERTYPE_PPP_C0 "xlnx,mac-port2-tx-ethertype-ppp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_ETHERTYPE_PPP_C1 "xlnx,mac-port2-tx-ethertype-ppp-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_FLOW_C0 "xlnx,mac-port2-tx-flow-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_FLOW_C1 "xlnx,mac-port2-tx-flow-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_OPCODE_GPP_C0 "xlnx,mac-port2-tx-opcode-gpp-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT2_TX_OPCODE_GPP_C1 "xlnx,mac-port2-tx-opcode-gpp-c1" ${mrmac2_node} int

	set MAC_PORT2_TX_SA_GPP_C0 [get_property CONFIG.MAC_PORT2_TX_SA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_SA_GPP_C0 [check_size $MAC_PORT2_TX_SA_GPP_C0 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-sa-gpp-c0" $MAC_PORT2_TX_SA_GPP_C0 int
	set MAC_PORT2_TX_SA_GPP_C1 [get_property CONFIG.MAC_PORT2_TX_SA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_SA_GPP_C1 [check_size $MAC_PORT2_TX_SA_GPP_C1 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-sa-gpp-c1" $MAC_PORT2_TX_SA_GPP_C1 int
	set MAC_PORT2_TX_SA_PPP_C0 [get_property CONFIG.MAC_PORT2_TX_SA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_SA_PPP_C0 [check_size $MAC_PORT2_TX_SA_PPP_C0 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-sa-ppp-c0" $MAC_PORT2_TX_SA_PPP_C0 int
	set MAC_PORT2_TX_SA_PPP_C1 [get_property CONFIG.MAC_PORT2_TX_SA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT2_TX_SA_PPP_C1 [check_size $MAC_PORT2_TX_SA_PPP_C1 $mrmac2_node]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-sa-ppp-c1" $MAC_PORT2_TX_SA_PPP_C1 int

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch2-rxprogdiv-freq-enable-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch2-rxprogdiv-freq-enable-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch2-rxprogdiv-freq-source-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch2-rxprogdiv-freq-source-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RXPROGDIV_FREQ_VAL_C0 "xlnx,gt-ch2-rxprogdiv-freq-val-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RXPROGDIV_FREQ_VAL_C1 "xlnx,gt-ch2-rxprogdiv-freq-val-c1" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_BUFFER_MODE_C0 "xlnx,gt-ch2-rx-buffer-mode-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_BUFFER_MODE_C1 "xlnx,gt-ch2-rx-buffer-mode-c1" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_DATA_DECODING_C0 "xlnx,gt-ch2-rx-data-decoding-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_DATA_DECODING_C1 "xlnx,gt-ch2-rx-data-decoding-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_INT_DATA_WIDTH_C0 "xlnx,gt-ch2-rx-int-data-width-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_INT_DATA_WIDTH_C1 "xlnx,gt-ch2-rx-int-data-width-c1" ${mrmac2_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_LINE_RATE_C0 "xlnx,gt-ch2-rx-line-rate-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_LINE_RATE_C1 "xlnx,gt-ch2-rx-line-rate-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_OUTCLK_SOURCE_C0 "xlnx,gt-ch2-rx-outclk-source-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_OUTCLK_SOURCE_C1 "xlnx,gt-ch2-rx-outclk-source-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_REFCLK_FREQUENCY_C0 "xlnx,gt-ch2-rx-refclk-frequency-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_REFCLK_FREQUENCY_C1 "xlnx,gt-ch2-rx-refclk-frequency-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_USER_DATA_WIDTH_C0 "xlnx,gt-ch2-rx-user-data-width-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_RX_USER_DATA_WIDTH_C1 "xlnx,gt-ch2-rx-user-data-width-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch2-txprogdiv-freq-enable-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch2-txprogdiv-freq-enable-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch2-txprogdiv-freq-source-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch2-txprogdiv-freq-source-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_BUFFER_MODE_C0 "xlnx,gt-ch2-tx-buffer-mode-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_BUFFER_MODE_C1 "xlnx,gt-ch2-tx-buffer-mode-c1" ${mrmac2_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_DATA_ENCODING_C0 "xlnx,gt-ch2-tx-data-encoding-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_DATA_ENCODING_C1 "xlnx,gt-ch2-tx-data-encoding-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_INT_DATA_WIDTH_C0 "xlnx,gt-ch2-int-data-width-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_INT_DATA_WIDTH_C1 "xlnx,gt-ch2-int-data-width-c1" ${mrmac2_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_LINE_RATE_C0 "xlnx,gt-ch2-tx-line-rate-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_LINE_RATE_C1 "xlnx,gt-ch2-tx-line-rate-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_OUTCLK_SOURCE_C0 "xlnx,gt-ch2-tx-outclk-source-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_OUTCLK_SOURCE_C1 "xlnx,gt-ch2-tx-outclk-source-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_PLL_TYPE_C0 "xlnx,gt-ch2-tx-pll-type-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_PLL_TYPE_C1 "xlnx,gt-ch2-tx-pll-type-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_REFCLK_FREQUENCY_C0 "xlnx,gt-ch2-tx-refclk-frequency-c0" ${mrmac2_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_REFCLK_FREQUENCY_C1 "xlnx,gt-ch2-tx-refclk-frequency-c1" ${mrmac2_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_USER_DATA_WIDTH_C0 "xlnx,gt-ch2-tx-user-data-width-c0" ${mrmac2_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH2_TX_USER_DATA_WIDTH_C1 "xlnx,gt-ch2-tx-user-data-width-c1" ${mrmac2_node} int

	set mrmac3_base [format 0x%x [expr $base_addr + 0x3000]]
	set mrmac3_base_hex [format %x $mrmac3_base]
	set mrmac3_highaddr_hex [format 0x%x [expr $mrmac3_base + 0xFFF]]
	set port3 3
	append label3 $drv_handle "_" $port3
	set node_prefix [get_property IP_NAME [get_cells -hier $drv_handle]]
	set mrmac3_node [add_or_get_dt_node -n $node_prefix -l "$label3" -u $mrmac3_base_hex -d $dts_file -p $bus_node]
	hsi::utils::add_new_dts_param "$mrmac3_node" "compatible" "$compatible" stringlist
	set mrmac3_reg [generate_reg_property $mrmac3_base $mrmac3_highaddr_hex]
	hsi::utils::add_new_dts_param "$mrmac3_node" "reg" $mrmac3_reg inthexlist

	set port3_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_axis_tdata6"]]
	foreach pin $port3_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph] "dcmac_intf_rx"]} {
				set sink_periph [hsi::utils::get_connected_stream_ip [get_cells -hier $sink_periph] "M_AXIS"]
			}
			if {[string match -nocase [get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
				set fifo_width_bytes [get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
				if {[string_is_empty $fifo_width_bytes]} {
					set fifo_width_bytes 1
				}
				set rxethmem [get_property CONFIG.FIFO_DEPTH $sink_periph]
				# FIFO can be other than 8 bits, and we need the rxmem in bytes
				set rxethmem [expr $rxethmem * $fifo_width_bytes]
				hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,rxmem" $rxethmem int
				set fifo3_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $sink_periph] "m_axis_tdata"]]
				set mux_per3 [::hsi::get_cells -of_objects $fifo3_pin]
				set fiforx_connect_ip3 ""
				if {[llength $mux_per3] && [string match -nocase [get_property IP_NAME $mux_per3] "mrmac_10g_mux"]} {
					set data_fifo_pin3 [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mux_per3] "rx_m_axis_tdata"]]
					set data_fifo_per3 [::hsi::get_cells -of_objects $data_fifo_pin3]
					if {[string match -nocase [get_property IP_NAME $data_fifo_per3] "axis_data_fifo"]} {
						set fiforx_connect_ip3 [hsi::utils::get_connected_stream_ip [get_cells -hier $data_fifo_per3] "M_AXIS"]
						set fiforx3_pin [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $data_fifo_per3] "m_axis_tdata"]]
						set fiforx3_per [::hsi::get_cells -of_objects $fiforx3_pin]
						if {[string match -nocase [get_property IP_NAME $fiforx3_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
							set fiforx_connect_ip3 [hsi::utils::get_connected_stream_ip [get_cells -hier $fiforx3_per] "M_AXIS"]
						}
					}
				}
				if {[string match -nocase [get_property IP_NAME $mux_per3] "axi_mcdma"]} {
					set fiforx_connect_ip3 $mux_per3
				}
				if {[llength $fiforx_connect_ip3]} {
					if {[string match -nocase [get_property IP_NAME $fiforx_connect_ip3] "axi_mcdma"]} {
						hsi::utils::add_new_dts_param "$mrmac3_node" "axistream-connected" "$fiforx_connect_ip3" reference
						set num_queues [get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip3]
						set inhex [format %x $num_queues]
						append numqueues3 "/bits/ 16 <0x$inhex>"
						hsi::utils::add_new_dts_param $mrmac3_node "xlnx,num-queues" $numqueues3 noformating
						set id 1
						for {set i 2} {$i <= $num_queues} {incr i} {
							set i [format "%" $i]
							append id "\""
							append id ",\"" $i
							set i [expr 0x$i]
						}
						hsi::utils::add_new_dts_param $mrmac3_node "xlnx,num-queues" $numqueues3 noformating
						hsi::utils::add_new_dts_param $mrmac3_node "xlnx,channel-ids" $id stringlist
						generate_intr_info $drv_handle $mrmac3_node $fiforx_connect_ip3
					}
				}
			}
		}
	}
	#set txtodport3_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_timestamp_tod_3"]]
	set txtodport3_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_3"]]

	if {[llength $txtodport3_pins]} {
		set tod3_sink_periph [::hsi::get_cells -of_objects $txtodport3_pins]
		if {[string match -nocase [get_property IP_NAME $tod3_sink_periph] "mrmac_ptp_timestamp_if"]} {
			set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $tod3_sink_periph] "tx_timestamp_tod"]]
			set tod3_sink_periph [::hsi::get_cells -of_objects $port_pins]
		}
		if {[llength $tod3_sink_periph] && [string match -nocase [get_property IP_NAME $tod3_sink_periph] "xlconcat"]} {
			set intf "dout"
			set in3_pin [::hsi::get_pins -of_objects $tod3_sink_periph -filter "NAME==$intf"]
			set in3sink_pins [::hsi::utils::get_sink_pins $in3_pin]
			set xl_per3 ""
			if {[llength $in3sink_pins]} {
				set xl_per3 [::hsi::get_cells -of_objects $in3sink_pins]
			}
			if {[llength $xl_per3] && [string match -nocase [get_property IP_NAME $xl_per3] "axis_dwidth_converter"]} {
				set port3pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $xl_per3] "m_axis_tdata"]]
				set axis_per3 [::hsi::get_cells -of_objects $port3pins]
				if {[string match -nocase [get_property IP_NAME $axis_per3] "axis_clock_converter"]} {
					set tx3_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $axis_per3] "M_AXIS"]
					if {[llength $tx3_ip]} {
						hsi::utils::add_new_dts_param "$mrmac3_node" "axififo-connected" $tx3_ip reference
					}
				}
			}
		}
	} else {
		dtg_warning "tx_timestamp_tod_3 connected pins are NULL...please check the design..."
	}

	#set rxtod3_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_timestamp_tod_3"]]
	set rxtod3_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "rx_ptp_tstamp_out_3"]]

	if {[llength $rxtod3_pins]} {
		set rx_periph3 [::hsi::get_cells -of_objects $rxtod3_pins]
		if {[string match -nocase [get_property IP_NAME $rx_periph3] "mrmac_ptp_timestamp_if"]} {
			set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rx_periph3] "rx_timestamp_tod"]]
			set rx_periph3 [::hsi::get_cells -of_objects $port_pins]
		}
		if {[llength $rx_periph3] && [string match -nocase [get_property IP_NAME $rx_periph3] "xlconcat"]} {
			set intf "dout"
			set inrx3_pin [::hsi::get_pins -of_objects $rx_periph3 -filter "NAME==$intf"]
			set rxtodsink_pins [::hsi::utils::get_sink_pins $inrx3_pin]
			set rx_per3 ""
			if {[llength $rxtodsink_pins]} {
				set rx_per3 [::hsi::get_cells -of_objects $rxtodsink_pins]
			}
			if {[llength $rx_per3] && [string match -nocase [get_property IP_NAME $rx_per3] "axis_dwidth_converter"]} {
				set port_pins [::hsi::utils::get_sink_pins [get_pins -of_objects [get_cells -hier $rx_per3] "m_axis_tdata"]]
				set rx_axis_per3 [::hsi::get_cells -of_objects $port_pins]
				if {[string match -nocase [get_property IP_NAME $rx_axis_per3] "axis_clock_converter"]} {
					set rx_ip3 [hsi::utils::get_connected_stream_ip [get_cells -hier $rx_axis_per3] "M_AXIS"]
					if {[llength $rx_ip3]} {
						hsi::utils::add_new_dts_param "$mrmac3_node" "xlnx,rxtsfifo" $rx_ip3 reference
					}
				}
			}
		}
	} else {
		dtg_warning "rx_timestamp_tod_3 connected pins are NULL...please check the design..."
	}


	if {[llength $handle]} {
		hsi::utils::add_new_dts_param "$mrmac3_node" "xlnx,gtctrl" $handle reference
	}
	if {[llength $mask_handle]} {
		hsi::utils::add_new_dts_param "$mrmac3_node" "xlnx,gtpll" $mask_handle reference
	}
	if {[llength $gt_reset_per]} {
		hsi::utils::add_new_dts_param "$mrmac3_node" "xlnx,gtctrl" $gt_reset_per reference
	}
	if {[llength $gt_pll_per]} {
		hsi::utils::add_new_dts_param "$mrmac3_node" "xlnx,gtpll" $gt_pll_per reference
	}
	hsi::utils::add_new_dts_param "$mrmac3_node" "xlnx,phcindex" 3 int
	hsi::utils::add_new_dts_param "$mrmac3_node" "xlnx,gtlane" 3 int

	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "mrmac"]} {
		lappend clknames3 "$s_axi_aclk" "$rx_axi_clk3" "$rx_flexif_clk3" "$rx_ts_clk3" "$tx_axi_clk3" "$tx_flexif_clk3" "$tx_ts_clk3"
		set tmpclks3 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index3]"]
		set txindex3 [lindex $clk_list $tx_ts_clk_index3]
		regsub -all "\>" $txindex3 {} txindex3
		append clkvals3  "[lindex $tmpclks3 0], [lindex $tmpclks3 1], [lindex $clk_list $rx_flexif_clk_index3], [lindex $clk_list $rx_ts_clk3_index3], [lindex $clk_list $tx_axi_clk_index3], [lindex $clk_list $tx_flexif_clk_index3], $txindex3"
		hsi::utils::add_new_dts_param "${mrmac3_node}" "clocks" $clkvals3 reference
		hsi::utils::add_new_dts_param "${mrmac3_node}" "clock-names" $clknames3 stringlist
	}
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "dcmac"]} {
		lappend clknames3 "$s_axi_aclk" "$rx_axi_clk0" "$rx_flexif_clk3" "$tx_axi_clk0" "$tx_flexif_clk3" "$rx_macif_clk" "$ts_clk3" "$tx_macif_clk" "$tx_serdes_clk3"
		set tmpclks3 [fix_clockprop "[lindex $clk_list $s_axi_aclk_index0]" "[lindex $clk_list $rx_axi_clk_index0]"]
		set txindex3 [lindex $clk_list $tx_serdes_clk_index3]
		regsub -all "\>" $txindex3 {} txindex3
		append clkvals3  "[lindex $tmpclks3 0], [lindex $tmpclks3 1], [lindex $clk_list $rx_flexif_clk_index3], [lindex $clk_list $tx_axi_clk_index0], [lindex $clk_list $tx_flexif_clk_index3], [lindex $clk_list $rx_macif_clk_index0], [lindex $clk_list $ts_clk_index3], [lindex $clk_list $tx_macif_clk_index0], $txindex3"
		hsi::utils::add_new_dts_param "${mrmac3_node}" "clocks" $clkvals3 reference
		hsi::utils::add_new_dts_param "${mrmac3_node}" "clock-names" $clknames3 stringlist
	}

	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE3_CFG_C0 "xlnx,flex-slice3-cfg-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.C_FEC_SLICE3_CFG_C1 "xlnx,flex-slice3-cfg-c1" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT3_DATA_RATE_C0 "xlnx,flex-port3-data-rate-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT3_DATA_RATE_C1 "xlnx,flex-port3-data-rate-c1" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT3_ENABLE_TIME_STAMPING_C0 "xlnx,flex-port3-enable-time-stamping-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT3_ENABLE_TIME_STAMPING_C1 "xlnx,flex-port3-enable-time-stamping-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT3_MODE_C0 "xlnx,flex-port3-mode-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.C_FLEX_PORT3_MODE_C1 "xlnx,flex-port3-mode-c1" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.PORT3_1588v2_Clocking_C0 "xlnx,port3-1588v2-clocking-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.PORT3_1588v2_Clocking_C1 "xlnx,port3-1588v2-clocking-c1" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.PORT3_1588v2_Operation_MODE_C0 "xlnx,port3-1588v2-operation-mode-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.PORT3_1588v2_Operation_MODE_C1 "xlnx,port3-1588v2-operation-mode-c1" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_ENABLE_TIME_STAMPING_C0 "xlnx,mac-port3-enable-time-stamping-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_ENABLE_TIME_STAMPING_C1 "xlnx,mac-port3-enable-time-stamping-c1" ${mrmac3_node} int

	set MAC_PORT3_RATE_C0 [get_property CONFIG.MAC_PORT3_RATE_C0 [get_cells -hier $drv_handle]]
	if {[llength $MAC_PORT3_RATE_C0]} {
		if {[string match -nocase $MAC_PORT3_RATE_C0 "10GE"]} {
			set number 10000
			hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mrmac-rate" $number int
		} else {
			hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mrmac-rate" $MAC_PORT3_RATE_C0 string
		}
	}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RATE_C1 "xlnx,mac-port3-rate-c1" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_GCP_C0 "xlnx,mac-port3-rx-etype-gcp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_GCP_C1 "xlnx,mac-port3-rx-etype-gcp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_GPP_C0 "xlnx,mac-port3-rx-etype-gpp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_GPP_C1 "xlnx,mac-port3-rx-etype-gpp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_PCP_C0 "xlnx,mac-port3-rx-etype-pcp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_PCP_C1 "xlnx,mac-port3-rx-etype-pcp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_PPP_C0 "xlnx,mac-port3-rx-etype-ppp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_ETYPE_PPP_C1 "xlnx,mac-port3-rx-etype-ppp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_FLOW_C0 "xlnx,mac-port3-rx-flow-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_FLOW_C1 "xlnx,mac-port3-rx-flow-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_GPP_C0 "xlnx,mac-port3-rx-opcode-gpp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_GPP_C1 "xlnx,mac-port3-rx-opcode-gpp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MAX_GCP_C0 "xlnx,mac-port3-rx-opcode-max-gcp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MAX_GCP_C1 "xlnx,mac-port3-rx-opcode-max-gcp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MAX_PCP_C0 "xlnx,mac-port3-rx-opcode-max-pcp-c0" ${mrmac3_node} int

	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MAX_PCP_C1 "xlnx,mac-port3-rx-opcode-max-pcp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MIN_GCP_C0 "xlnx,mac-port3-rx-opcode-min-gcp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MIN_GCP_C1 "xlnx,mac-port3-rx-opcode-min-gcp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MIN_PCP_C0 "xlnx,mac-port3-rx-opcode-min-pcp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_MIN_PCP_C1 "xlnx,mac-port3-rx-opcode-min-pcp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_PPP_C0 "xlnx,mac-port3-rx-opcode-ppp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_RX_OPCODE_PPP_C1 "xlnx,mac-port3-rx-opcode-ppp-c1" ${mrmac3_node} int

	set MAC_PORT3_RX_PAUSE_DA_MCAST_C0 [get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_MCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT3_RX_PAUSE_DA_MCAST_C0 [check_size $MAC_PORT3_RX_PAUSE_DA_MCAST_C0 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-mcast-c0" $MAC_PORT3_RX_PAUSE_DA_MCAST_C0 int
	set MAC_PORT3_RX_PAUSE_DA_MCAST_C1 [get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_MCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT3_RX_PAUSE_DA_MCAST_C1 [check_size $MAC_PORT3_RX_PAUSE_DA_MCAST_C1 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-mcast-c1" $MAC_PORT3_RX_PAUSE_DA_MCAST_C1 int
	set MAC_PORT3_RX_PAUSE_DA_UCAST_C0 [get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_UCAST_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT3_RX_PAUSE_DA_UCAST_C0 [check_size $MAC_PORT3_RX_PAUSE_DA_UCAST_C0 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-ucast-c0" $MAC_PORT3_RX_PAUSE_DA_UCAST_C0 int
	set MAC_PORT3_RX_PAUSE_DA_UCAST_C1 [get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_UCAST_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT3_RX_PAUSE_DA_UCAST_C1 [check_size $MAC_PORT3_RX_PAUSE_DA_UCAST_C1 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-ucast-c1" $MAC_PORT3_RX_PAUSE_DA_UCAST_C1 int
	set MAC_PORT3_RX_PAUSE_SA_C0 [get_property CONFIG.MAC_PORT3_RX_PAUSE_SA_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT3_RX_PAUSE_SA_C0 [check_size $MAC_PORT3_RX_PAUSE_SA_C0 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-pause-sa-c0" $MAC_PORT3_RX_PAUSE_SA_C0 int
	set MAC_PORT3_RX_PAUSE_SA_C1 [get_property CONFIG.MAC_PORT3_RX_PAUSE_SA_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT3_RX_PAUSE_SA_C1 [check_size $MAC_PORT3_RX_PAUSE_SA_C1 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-pause-sa-c1" $MAC_PORT3_RX_PAUSE_SA_C1 int
	set MAC_PORT3_TX_DA_GPP_C0 [get_property CONFIG.MAC_PORT3_TX_DA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_DA_GPP_C0 [check_size $MAC_PORT3_TX_DA_GPP_C0 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-da-gpp-c0" $MAC_PORT3_TX_DA_GPP_C0 int
	set MAC_PORT3_TX_DA_GPP_C1 [get_property CONFIG.MAC_PORT3_TX_DA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_DA_GPP_C1 [check_size $MAC_PORT3_TX_DA_GPP_C1 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-da-gpp-c1" $MAC_PORT3_TX_DA_GPP_C1 int
	set MAC_PORT3_TX_DA_PPP_C0 [get_property CONFIG.MAC_PORT3_TX_DA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_DA_PPP_C0 [check_size $MAC_PORT3_TX_DA_PPP_C0 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-da-ppp-c0" $MAC_PORT3_TX_DA_PPP_C0 int
	set MAC_PORT3_TX_DA_PPP_C1 [get_property CONFIG.MAC_PORT3_TX_DA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_DA_PPP_C1 [check_size $MAC_PORT3_TX_DA_PPP_C1 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-da-ppp-c1" $MAC_PORT3_TX_DA_PPP_C1 int

	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_ETHERTYPE_GPP_C0 "xlnx,mac-port3-tx-ethertype-gpp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_ETHERTYPE_GPP_C1 "xlnx,mac-port3-tx-ethertype-gpp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_ETHERTYPE_PPP_C0 "xlnx,mac-port3-tx-ethertype-ppp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_ETHERTYPE_PPP_C1 "xlnx,mac-port3-tx-ethertype-ppp-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_FLOW_C0 "xlnx,mac-port3-tx-flow-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_FLOW_C1 "xlnx,mac-port3-tx-flow-c1" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_OPCODE_GPP_C0 "xlnx,mac-port3-tx-opcode-gpp-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.MAC_PORT3_TX_OPCODE_GPP_C1 "xlnx,mac-port3-tx-opcode-gpp-c1" ${mrmac3_node} int

	set MAC_PORT3_TX_SA_GPP_C0 [get_property CONFIG.MAC_PORT3_TX_SA_GPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_SA_GPP_C0 [check_size $MAC_PORT3_TX_SA_GPP_C0 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-sa-gpp-c0" $MAC_PORT3_TX_SA_GPP_C0 int
	set MAC_PORT3_TX_SA_GPP_C1 [get_property CONFIG.MAC_PORT3_TX_SA_GPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_SA_GPP_C1 [check_size $MAC_PORT3_TX_SA_GPP_C1 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-sa-gpp-c1" $MAC_PORT3_TX_SA_GPP_C1 int
	set MAC_PORT3_TX_SA_PPP_C0 [get_property CONFIG.MAC_PORT3_TX_SA_PPP_C0 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_SA_PPP_C0 [check_size $MAC_PORT3_TX_SA_PPP_C0 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-sa-ppp-c0" $MAC_PORT3_TX_SA_PPP_C0 int
	set MAC_PORT3_TX_SA_PPP_C1 [get_property CONFIG.MAC_PORT3_TX_SA_PPP_C1 [get_cells -hier $drv_handle]]
	set MAC_PORT3_TX_SA_PPP_C1 [check_size $MAC_PORT3_TX_SA_PPP_C1 $mrmac3_node]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-sa-ppp-c1" $MAC_PORT3_TX_SA_PPP_C1 int

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch3-rxprogdiv-freq-enable-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch3-rxprogdiv-freq-enable-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch3-rxprogdiv-freq-source-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch3-rxprogdiv-freq-source-c1" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RXPROGDIV_FREQ_VAL_C0 "xlnx,gt-ch3-rxprogdiv-freq-val-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RXPROGDIV_FREQ_VAL_C1 "xlnx,gt-ch3-rxprogdiv-freq-val-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_BUFFER_MODE_C0 "xlnx,gt-ch3-rx-buffer-mode-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_BUFFER_MODE_C1 "xlnx,gt-ch3-rx-buffer-mode-c1" ${mrmac3_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_DATA_DECODING_C0 "xlnx,gt-ch3-rx-data-decoding-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_DATA_DECODING_C1 "xlnx,gt-ch3-rx-data-decoding-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_INT_DATA_WIDTH_C0 "xlnx,gt-ch3-rx-int-data-width-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_INT_DATA_WIDTH_C1 "xlnx,gt-ch3-rx-int-data-width-c1" ${mrmac3_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_LINE_RATE_C0 "xlnx,gt-ch3-rx-line-rate-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_LINE_RATE_C1 "xlnx,gt-ch3-rx-line-rate-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_OUTCLK_SOURCE_C0 "xlnx,gt-ch3-rx-outclk-source-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_OUTCLK_SOURCE_C1 "xlnx,gt-ch3-rx-outclk-source-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_REFCLK_FREQUENCY_C0 "xlnx,gt-ch3-rx-refclk-frequency-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_REFCLK_FREQUENCY_C1 "xlnx,gt-ch3-rx-refclk-frequency-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_USER_DATA_WIDTH_C0 "xlnx,gt-ch3-rx-user-data-width-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_RX_USER_DATA_WIDTH_C1 "xlnx,gt-ch3-rx-user-data-width-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TXPROGDIV_FREQ_ENABLE_C0 "xlnx,gt-ch3-txprogdiv-freq-enable-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TXPROGDIV_FREQ_ENABLE_C1 "xlnx,gt-ch3-txprogdiv-freq-enable-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TXPROGDIV_FREQ_SOURCE_C0 "xlnx,gt-ch3-txprogdiv-freq-source-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TXPROGDIV_FREQ_SOURCE_C1 "xlnx,gt-ch3-txprogdiv-freq-source-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_BUFFER_MODE_C0 "xlnx,gt-ch3-tx-buffer-mode-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_BUFFER_MODE_C1 "xlnx,gt-ch3-tx-buffer-mode-c1" ${mrmac3_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_DATA_ENCODING_C0 "xlnx,gt-ch3-tx-data-encoding-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_DATA_ENCODING_C1 "xlnx,gt-ch3-tx-data-encoding-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_INT_DATA_WIDTH_C0 "xlnx,gt-ch3-int-data-width-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_INT_DATA_WIDTH_C1 "xlnx,gt-ch3-int-data-width-c1" ${mrmac3_node} int

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_LINE_RATE_C0 "xlnx,gt-ch3-tx-line-rate-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_LINE_RATE_C1 "xlnx,gt-ch3-tx-line-rate-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_OUTCLK_SOURCE_C0 "xlnx,gt-ch3-tx-outclk-source-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_OUTCLK_SOURCE_C1 "xlnx,gt-ch3-tx-outclk-source-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_PLL_TYPE_C0 "xlnx,gt-ch3-tx-pll-type-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_PLL_TYPE_C1 "xlnx,gt-ch3-tx-pll-type-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_REFCLK_FREQUENCY_C0 "xlnx,gt-ch3-tx-refclk-frequency-c0" ${mrmac3_node}
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_REFCLK_FREQUENCY_C1 "xlnx,gt-ch3-tx-refclk-frequency-c1" ${mrmac3_node}

	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_USER_DATA_WIDTH_C0 "xlnx,gt-ch3-tx-user-data-width-c0" ${mrmac3_node} int
	add_prop_ifexists $drv_handle CONFIG.GT_CH3_TX_USER_DATA_WIDTH_C1 "xlnx,gt-ch3-tx-user-data-width-c1" ${mrmac3_node} int
}

proc generate_intr_info {drv_handle node fifo_ip} {
	set ips [get_cells -hier $drv_handle]
	foreach ip [get_drivers] {
		if {[string compare -nocase $ip $fifo_ip] == 0} {
			set target_handle $ip
		}
	}
	set intr_val [get_property CONFIG.interrupts $target_handle]
	set intr_parent [get_property CONFIG.interrupt-parent $target_handle]
	set int_names  [get_property CONFIG.interrupt-names $target_handle]
	hsi::utils::add_new_dts_param "${node}" "interrupts" $intr_val int
	hsi::utils::add_new_dts_param "${node}" "interrupt-parent" $intr_parent reference
	hsi::utils::add_new_dts_param "${node}" "interrupt-names" $int_names stringlist
}

proc check_size {base node} {
	if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		set temp $base
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_base "0x[string range $temp $rem $len]"
		set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_base [format 0x%08x $low_base]
		set reg "$low_base $high_base"
	} else {
		set reg "$base"
	}
	return $reg
}

proc gen_mrmac_clk_property {drv_handle} {
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "microblaze"]} {
		return
	}
	set clocks ""
	set axi 0
	set is_clk_wiz 0
	set is_pl_clk 0
	set updat ""
	global bus_clk_list
	set clocknames ""
	set clk_pins [get_pins -of_objects [get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I || TYPE==gt_usrclk&&DIRECTION==I}]
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set port_width [::hsi::utils::get_port_width $clk]
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] $clk]]
		if {$port_width >= 2} {
			for {set i 0} { $i < $port_width} {incr i} {
				set peri [::hsi::get_cells -of_objects $pins]
				set mrclk "$clk$i"
				if {[llength $peri]} {
					if {[string match -nocase [common::get_property IP_NAME $peri] "xlconcat"]} {
						set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects [get_cells $peri] In$i]] -filter "DIRECTION==O"]
						set clk_peri [::hsi::get_cells -of_objects $pins]
					}
				}
				set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
				set pl_clk ""
				set clkout ""
				foreach pin $pins {
					if {[lsearch $valid_clk_list $pin] >= 0} {
						set clkout $pin
						set is_clk_wiz 1
						set periph [::hsi::get_cells -of_objects $pin]
					}
				}
				if {[llength $clkout]} {
					set number [regexp -all -inline -- {[0-9]+} $clkout]
					set clk_wiz [get_pins -of_objects [get_cells -hier $periph] -filter TYPE==clk]
					set axi_clk "s_axi_aclk"
					foreach clk1 $clk_wiz {
						if {[regexp $axi_clk $clk1 match]} {
							set axi 1
						}
				}

				if {[string match -nocase $axi "0"]} {
					dtg_warning "no s_axi_aclk for clockwizard"
					set pins [get_pins -of_objects [get_cells -hier $periph] -filter TYPE==clk]
					set clk_list "pl_clk*"
					set clk_pl ""
					set num ""
					foreach clk_wiz_pin $pins {
							set clk_wiz_pins [get_pins -of_objects [get_nets -of_objects $clk_wiz_pin]]
							foreach pin $clk_wiz_pins {
								if {[regexp $clk_list $pin match]} {
									set clk_pl $pin
								}
							}
					}
					if {[llength $clk_pl]} {
						set num [regexp -all -inline -- {[0-9]+} $clk_pl]
					}
					if {[string match -nocase $proctype "psu_cortexa53"]} {
							switch $num {
									"0" {
										set def_dts [get_property CONFIG.pcw_dts [get_os]]
										set fclk_node [add_or_get_dt_node -n "&fclk0" -d $def_dts]
										hsi::utils::add_new_dts_param "${fclk_node}" "status" "okay" string
										}
									"1" {
										set def_dts [get_property CONFIG.pcw_dts [get_os]]
										 set fclk_node [add_or_get_dt_node -n "&fclk1" -d $def_dts]
										hsi::utils::add_new_dts_param "${fclk_node}" "status" "okay" string
										}
									"2" {
										set def_dts [get_property CONFIG.pcw_dts [get_os]]
										set fclk_node [add_or_get_dt_node -n "&fclk2" -d $def_dts]
										hsi::utils::add_new_dts_param "${fclk_node}" "status" "okay" string
									}
									"3" {
										set def_dts [get_property CONFIG.pcw_dts [get_os]]
										set fclk_node [add_or_get_dt_node -n "&fclk3" -d $def_dts]
										hsi::utils::add_new_dts_param "${fclk_node}" "status" "okay" string
									}
							}
					}
					set dts_file "pl.dtsi"
					set bus_node [add_or_get_bus_node $drv_handle $dts_file]
					set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
					if {[llength $clk_freq] == 0} {
						dtg_warning "clock frequency for the $clk is NULL"
						continue
					}
					set clk_freq [expr int($clk_freq)]
					set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
					if {![string equal $clk_freq ""]} {
						if {[lsearch $bus_clk_list $clk_freq] < 0} {
							set bus_clk_list [lappend bus_clk_list $clk_freq]
						}
						set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
						set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
						set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
						set updat [lappend updat misc_clk_${bus_clk_cnt}]
						hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
						hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
						hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
					}
				}
				if {![string match -nocase $axi "0"]} {
						switch $number {
								"1" {
									set peri "$periph 0"
									set clocks [lappend clocks $peri]
									set updat [lappend updat $peri]
								}
								"2" {
									set peri "$periph 1"
									set clocks [lappend clocks $peri]
									set updat [lappend updat $peri]
								}
								"3" {
									set peri "$periph 2"
									set clocks [lappend clocks $peri]
									set updat [lappend updat $peri]
								}
								"4" {
									set peri "$periph 3"
									set clocks [lappend clocks $peri]
									set updat [lappend updat $peri]
								}
								"5" {
									set peri "$periph 4"
									set clocks [lappend clocks $peri]
									set updat [lappend updat $peri]
								}
								"6" {
									set peri "$periph 5"
									set clocks [lappend clocks $peri]
									set updat [lappend updat $peri]
								}
								"7" {
									set peri "$periph 6"
									set clocks [lappend clocks $peri]
									set updat [lappend updat $peri]
								}
						}
				}
			}
			if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
				set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
			} elseif {[string match -nocase $proctype "ps7_cortexa9"]} {
				set clklist "FCLK_CLK0 FCLK_CLK1 FCLK_CLK2 FCLK_CLK3"
			}
			foreach pin $pins {
				if {[lsearch $clklist $pin] >= 0} {
					set pl_clk $pin
					set is_pl_clk 1
				}
			}
			if {[string match -nocase $proctype "psv_cortexa72"]} {
				switch $pl_clk {
						"pl_clk0" {
								set pl_clk0 "versal_clk 65"
								set clocks [lappend clocks $pl_clk0]
								set updat  [lappend updat $pl_clk0]
						}
						"pl_clk1" {
								set pl_clk1 "versal_clk 66"
								set clocks [lappend clocks $pl_clk1]
								set updat  [lappend updat $pl_clk1]
						}
						"pl_clk2" {
								set pl_clk2 "versal_clk 67"
								set clocks [lappend clocks $pl_clk2]
								set updat [lappend updat $pl_clk2]
						}
						"pl_clk3" {
								set pl_clk3 "versal_clk 68"
								set clocks [lappend clocks $pl_clk3]
								set updat [lappend updat $pl_clk3]
						}
						default {
								dtg_debug "not supported pl_clk:$pl_clk"
						}
					}
			}
			if {[string match -nocase $proctype "psu_cortexa53"]} {
					switch $pl_clk {
							"pl_clk0" {
									set pl_clk0 "zynqmp_clk 71"
									set clocks [lappend clocks $pl_clk0]
									set updat  [lappend updat $pl_clk0]
							}
							"pl_clk1" {
									set pl_clk1 "zynqmp_clk 72"
									set clocks [lappend clocks $pl_clk1]
									set updat  [lappend updat $pl_clk1]
							}
							"pl_clk2" {
									set pl_clk2 "zynqmp_clk 73"
									set clocks [lappend clocks $pl_clk2]
									set updat [lappend updat $pl_clk2]
							}
							"pl_clk3" {
									set pl_clk3 "zynqmp_clk 74"
									set clocks [lappend clocks $pl_clk3]
									set updat [lappend updat $pl_clk3]
							}
							default {
									dtg_debug "not supported pl_clk:$pl_clk"
							}
					}
			}
			if {[string match -nocase $proctype "ps7_cortexa9"]} {
						switch $pl_clk {
							"FCLK_CLK0" {
									set pl_clk0 "clkc 15"
									set clocks [lappend clocks $pl_clk0]
									set updat  [lappend updat $pl_clk0]
							}
							"FCLK_CLK1" {
									set pl_clk1 "clkc 16"
									set clocks [lappend clocks $pl_clk1]
									set updat  [lappend updat $pl_clk1]
							}
							"FCLK_CLK2" {
									set pl_clk2 "clkc 17"
									set clocks [lappend clocks $pl_clk2]
									set updat [lappend updat $pl_clk2]
							}
							"FCLK_CLK3" {
									set pl_clk3 "clkc 18"
									set clocks [lappend clocks $pl_clk3]
									set updat [lappend updat $pl_clk3]
							}
							default {
									dtg_debug "not supported pl_clk:$pl_clk"
							}
						}
			}
			if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
					set dts_file "pl.dtsi"
					set bus_node [add_or_get_bus_node $drv_handle $dts_file]
					set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
					if {[llength $clk_freq] == 0} {
						dtg_warning "clock frequency for the $clk is NULL"
						continue
					}
					set clk_freq [expr int($clk_freq)]
					set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
					if {![string equal $clk_freq ""]} {
						if {[lsearch $bus_clk_list $clk_freq] < 0} {
							set bus_clk_list [lappend bus_clk_list $clk_freq]
						}
						set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
						set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
						set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
						set updat [lappend updat misc_clk_${bus_clk_cnt}]
						hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
						hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
						hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
					}
			}
			append clocknames " " "$mrclk"
			set is_pl_clk 0
			set is_clk_wiz 0
			set axi 0
		}
	} else {
		set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
		set pl_clk ""
		set clkout ""
		foreach pin $pins {
			if {[lsearch $valid_clk_list $pin] >= 0} {
				set clkout $pin
				set is_clk_wiz 1
				set periph [::hsi::get_cells -of_objects $pin]
			}
		}
		if {[llength $clkout]} {
			set number [regexp -all -inline -- {[0-9]+} $clkout]
			set clk_wiz [get_pins -of_objects [get_cells -hier $periph] -filter TYPE==clk]
			set axi_clk "s_axi_aclk"
			foreach clk1 $clk_wiz {
				if {[regexp $axi_clk $clk1 match]} {
					set axi 1
				}
			}
			if {[string match -nocase $axi "0"]} {
				dtg_warning "no s_axi_aclk for clockwizard"
				set pins [get_pins -of_objects [get_cells -hier $periph] -filter TYPE==clk]
				set clk_list "pl_clk*"
				set clk_pl ""
				set num ""
				foreach clk_wiz_pin $pins {
					set clk_wiz_pins [get_pins -of_objects [get_nets -of_objects $clk_wiz_pin]]
					foreach pin $clk_wiz_pins {
						if {[regexp $clk_list $pin match]} {
							set clk_pl $pin
						}
					}
				}
				if {[llength $clk_pl]} {
					set num [regexp -all -inline -- {[0-9]+} $clk_pl]
				}
				set dts_file "pl.dtsi"
				set bus_node [add_or_get_bus_node $drv_handle $dts_file]
				set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
				if {[llength $clk_freq] == 0} {
					dtg_warning "clock frequency for the $clk is NULL"
					continue
				}
				set clk_freq [expr int($clk_freq)]
				set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
				if {![string equal $clk_freq ""]} {
					if {[lsearch $bus_clk_list $clk_freq] < 0} {
						set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
					-d ${dts_file} -p ${bus_node}]
					set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
					set updat [lappend updat misc_clk_${bus_clk_cnt}]
					hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
					hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
				}
			}
			if {![string match -nocase $axi "0"]} {
				switch $number {
					"1" {
						set peri "$periph 0"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"2" {
						set peri "$periph 1"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"3" {
						set peri "$periph 2"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"4" {
						set peri "$periph 3"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"5" {
						set peri "$periph 4"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"6" {
						set peri "$periph 5"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"7" {
						set peri "$periph 6"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
				}
			}
		}
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
			set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
		} elseif {[string match -nocase $proctype "ps7_cortexa9"]} {
			set clklist "FCLK_CLK0 FCLK_CLK1 FCLK_CLK2 FCLK_CLK3"
		}
		foreach pin $pins {
			if {[lsearch $clklist $pin] >= 0} {
				set pl_clk $pin
				set is_pl_clk 1
			}
		}
		if {[string match -nocase $proctype "psv_cortexa72"]} {
			switch $pl_clk {
				"pl_clk0" {
						set pl_clk0 "versal_clk 65"
						set clocks [lappend clocks $pl_clk0]
						set updat  [lappend updat $pl_clk0]
				}
				"pl_clk1" {
						set pl_clk1 "versal_clk 66"
						set clocks [lappend clocks $pl_clk1]
						set updat  [lappend updat $pl_clk1]
				}
				"pl_clk2" {
						set pl_clk2 "versal_clk 67"
						set clocks [lappend clocks $pl_clk2]
						set updat [lappend updat $pl_clk2]
				}
				"pl_clk3" {
						set pl_clk3 "versal_clk 68"
						set clocks [lappend clocks $pl_clk3]
						set updat [lappend updat $pl_clk3]
				}
				default {
						dtg_warning "not supported pl_clk:$pl_clk"
				}
			}
		}
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			switch $pl_clk {
				"pl_clk0" {
						set pl_clk0 "zynqmp_clk 71"
						set clocks [lappend clocks $pl_clk0]
						set updat  [lappend updat $pl_clk0]
				}
				"pl_clk1" {
						set pl_clk1 "zynqmp_clk 72"
						set clocks [lappend clocks $pl_clk1]
						set updat  [lappend updat $pl_clk1]
				}
				"pl_clk2" {
						set pl_clk2 "zynqmp_clk 73"
						set clocks [lappend clocks $pl_clk2]
						set updat [lappend updat $pl_clk2]
				}
				"pl_clk3" {
						set pl_clk3 "zynqmp_clk 74"
						set clocks [lappend clocks $pl_clk3]
						set updat [lappend updat $pl_clk3]
				}
				default {
						dtg_warning "not supported pl_clk:$pl_clk"
				}
			}
		}
		if {[string match -nocase $proctype "ps7_cortexa9"]} {
			switch $pl_clk {
				"FCLK_CLK0" {
						set pl_clk0 "clkc 15"
						set clocks [lappend clocks $pl_clk0]
						set updat  [lappend updat $pl_clk0]
				}
				"FCLK_CLK1" {
						set pl_clk1 "clkc 16"
						set clocks [lappend clocks $pl_clk1]
						set updat  [lappend updat $pl_clk1]
				}
				"FCLK_CLK2" {
						set pl_clk2 "clkc 17"
						set clocks [lappend clocks $pl_clk2]
						set updat [lappend updat $pl_clk2]
				}
				"FCLK_CLK3" {
						set pl_clk3 "clkc 18"
						set clocks [lappend clocks $pl_clk3]
						set updat [lappend updat $pl_clk3]
				}
				default {
						dtg_warning "not supported pl_clk:$pl_clk"
				}
			}
		}
		if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
			set dts_file "pl.dtsi"
			set bus_node [add_or_get_bus_node $drv_handle $dts_file]
			set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
			if {[llength $clk_freq] == 0} {
				dtg_warning "clock frequency for the $clk is NULL"
				continue
			}
			set clk_freq [expr int($clk_freq)]
			set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
			if {![string equal $clk_freq ""]} {
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
				set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
				set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
				-d ${dts_file} -p ${bus_node}]
				set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
				set updat [lappend updat misc_clk_${bus_clk_cnt}]
				hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
				hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
				hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
			}
		}
		append clocknames " " "$clk"
		set is_pl_clk 0
		set is_clk_wiz 0
		set axi 0
	}
	}
	set_drv_prop_if_empty $drv_handle "zclock-names1" $clocknames stringlist
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	set refs [lindex $updat 0]
	for {set clk_count 1} {$clk_count < [llength $updat]} {incr clk_count +1} {
		append refs ">, <&[lindex $updat $clk_count]"
	}
	set_drv_prop $drv_handle "zclocks1" "$refs" reference
}

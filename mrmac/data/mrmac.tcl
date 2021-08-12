#
# (C) Copyright 2019-2020 Xilinx, Inc.
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
	set compatible [append compatible " " "xlnx,mrmac-ethernet-1.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set mrmac_ip [get_cells -hier $drv_handle]
	gen_mrmac_clk_property $drv_handle
	set mem_ranges [hsi::utils::get_ip_mem_ranges [get_cells -hier $drv_handle]]
	set connected_ip [hsi::utils::get_connected_stream_ip $mrmac_ip "tx_axis_tdata0"]

	set FEC_SLICE0_CFG_C0 [get_property CONFIG.C_FEC_SLICE0_CFG_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-slice0-cfg-c0" $FEC_SLICE0_CFG_C0 string
	set FEC_SLICE0_CFG_C1 [get_property CONFIG.C_FEC_SLICE0_CFG_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-slice0-cfg-c1" $FEC_SLICE0_CFG_C1 string
	set FLEX_PORT0_DATA_RATE_C0 [get_property CONFIG.C_FLEX_PORT0_DATA_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-port0-data-rate-c0" $FLEX_PORT0_DATA_RATE_C0 string
	set FLEX_PORT0_DATA_RATE_C1 [get_property CONFIG.C_FLEX_PORT0_DATA_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-port0-data-rate-c1" $FLEX_PORT0_DATA_RATE_C1 string
	set FLEX_PORT0_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.C_FLEX_PORT0_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-port0-enable-time-stamping-c0" $FLEX_PORT0_ENABLE_TIME_STAMPING_C0 int
	set FLEX_PORT0_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.C_FLEX_PORT0_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-port0-enable-time-stamping-c1" $FLEX_PORT0_ENABLE_TIME_STAMPING_C1 int
	set FLEX_PORT0_MODE_C0 [get_property CONFIG.C_FLEX_PORT0_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-port0-mode-c0" $FLEX_PORT0_MODE_C0 string
	set FLEX_PORT0_MODE_C1 [get_property CONFIG.C_FLEX_PORT0_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,flex-port0-mode-c1" $FLEX_PORT0_MODE_C1 string
	set PORT0_1588v2_Clocking_C0 [get_property CONFIG.PORT0_1588v2_Clocking_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,port0-1588v2-clocking-c0" $PORT0_1588v2_Clocking_C0 string
	set PORT0_1588v2_Clocking_C1 [get_property CONFIG.PORT0_1588v2_Clocking_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,port0-1588v2-clocking-c1" $PORT0_1588v2_Clocking_C1 string
	set PORT0_1588v2_Operation_MODE_C0 [get_property CONFIG.PORT0_1588v2_Operation_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,port0-1588v2-operation-mode-c0" $PORT0_1588v2_Operation_MODE_C0 string
	set PORT0_1588v2_Operation_MODE_C1 [get_property CONFIG.PORT0_1588v2_Operation_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,port0-1588v2-operation-mode-c1" $PORT0_1588v2_Operation_MODE_C1 string
	set MAC_PORT0_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.MAC_PORT0_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-enable-time-stamping-c0" $MAC_PORT0_ENABLE_TIME_STAMPING_C0 int
	set MAC_PORT0_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.MAC_PORT0_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-enable-time-stamping-c1" $MAC_PORT0_ENABLE_TIME_STAMPING_C1 int
	set MAC_PORT0_RATE_C0 [get_property CONFIG.MAC_PORT0_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rate-c0" $MAC_PORT0_RATE_C0 string
	set MAC_PORT0_RATE_C1 [get_property CONFIG.MAC_PORT0_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rate-c1" $MAC_PORT0_RATE_C1 string
	set MAC_PORT0_RX_ETYPE_GCP_C0 [get_property CONFIG.MAC_PORT0_RX_ETYPE_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-gcp-c0" $MAC_PORT0_RX_ETYPE_GCP_C0 int
	set MAC_PORT0_RX_ETYPE_GCP_C1 [get_property CONFIG.MAC_PORT0_RX_ETYPE_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-gcp-c1" $MAC_PORT0_RX_ETYPE_GCP_C1 int
	set MAC_PORT0_RX_ETYPE_GPP_C0 [get_property CONFIG.MAC_PORT0_RX_ETYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-gpp-c0" $MAC_PORT0_RX_ETYPE_GPP_C0 int
	set MAC_PORT0_RX_ETYPE_GPP_C1 [get_property CONFIG.MAC_PORT0_RX_ETYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-gpp-c1" $MAC_PORT0_RX_ETYPE_GPP_C1 int
	set MAC_PORT0_RX_ETYPE_PCP_C0 [get_property CONFIG.MAC_PORT0_RX_ETYPE_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-pcp-c0" $MAC_PORT0_RX_ETYPE_PCP_C0 int
	set MAC_PORT0_RX_ETYPE_PCP_C1 [get_property CONFIG.MAC_PORT0_RX_ETYPE_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-pcp-c1" $MAC_PORT0_RX_ETYPE_PCP_C1 int
	set MAC_PORT0_RX_ETYPE_PPP_C0 [get_property CONFIG.MAC_PORT0_RX_ETYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-ppp-c0" $MAC_PORT0_RX_ETYPE_PPP_C0 int
	set MAC_PORT0_RX_ETYPE_PPP_C1 [get_property CONFIG.MAC_PORT0_RX_ETYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-etype-ppp-c1" $MAC_PORT0_RX_ETYPE_PPP_C1 int
	set MAC_PORT0_RX_FLOW_C0 [get_property CONFIG.MAC_PORT0_RX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-flow-c0" $MAC_PORT0_RX_FLOW_C0 int
	set MAC_PORT0_RX_FLOW_C1 [get_property CONFIG.MAC_PORT0_RX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-flow-c1" $MAC_PORT0_RX_FLOW_C1 int
	set MAC_PORT0_RX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT0_RX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-gpp-c0" $MAC_PORT0_RX_OPCODE_GPP_C0 int
	set MAC_PORT0_RX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT0_RX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-gpp-c1" $MAC_PORT0_RX_OPCODE_GPP_C1 int
	set MAC_PORT0_RX_OPCODE_MAX_GCP_C0 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-max-gcp-c0" $MAC_PORT0_RX_OPCODE_MAX_GCP_C0 int
	set MAC_PORT0_RX_OPCODE_MAX_GCP_C1 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-max-gcp-c1" $MAC_PORT0_RX_OPCODE_MAX_GCP_C1 int
	set MAC_PORT0_RX_OPCODE_MAX_PCP_C0 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-max-pcp-c0" $MAC_PORT0_RX_OPCODE_MAX_PCP_C0 int

	set MAC_PORT0_RX_OPCODE_MAX_PCP_C1 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-max-pcp-c1" $MAC_PORT0_RX_OPCODE_MAX_PCP_C1 int
	set MAC_PORT0_RX_OPCODE_MIN_GCP_C0 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-min-gcp-c0" $MAC_PORT0_RX_OPCODE_MIN_GCP_C0 int
	set MAC_PORT0_RX_OPCODE_MIN_GCP_C1 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-min-gcp-c1" $MAC_PORT0_RX_OPCODE_MIN_GCP_C1 int
	set MAC_PORT0_RX_OPCODE_MIN_PCP_C0 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-min-pcp-c0" $MAC_PORT0_RX_OPCODE_MIN_PCP_C0 int
	set MAC_PORT0_RX_OPCODE_MIN_PCP_C1 [get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-min-pcp-c1" $MAC_PORT0_RX_OPCODE_MIN_PCP_C1 int
	set MAC_PORT0_RX_OPCODE_PPP_C0 [get_property CONFIG.MAC_PORT0_RX_OPCODE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-ppp-c0" $MAC_PORT0_RX_OPCODE_PPP_C0 int
	set MAC_PORT0_RX_OPCODE_PPP_C1 [get_property CONFIG.MAC_PORT0_RX_OPCODE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-rx-opcode-ppp-c1" $MAC_PORT0_RX_OPCODE_PPP_C1 int
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
	set MAC_PORT0_TX_ETHERTYPE_GPP_C0 [get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-ethertype-gpp-c0" $MAC_PORT0_TX_ETHERTYPE_GPP_C0 int
	set MAC_PORT0_TX_ETHERTYPE_GPP_C1 [get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-ethertype-gpp-c1" $MAC_PORT0_TX_ETHERTYPE_GPP_C1 int
	set MAC_PORT0_TX_ETHERTYPE_PPP_C0 [get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-ethertype-ppp-c0" $MAC_PORT0_TX_ETHERTYPE_PPP_C0 int
	set MAC_PORT0_TX_ETHERTYPE_PPP_C1 [get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-ethertype-ppp-c1" $MAC_PORT0_TX_ETHERTYPE_PPP_C1 int
	set MAC_PORT0_TX_FLOW_C0 [get_property CONFIG.MAC_PORT0_TX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-flow-c0" $MAC_PORT0_TX_FLOW_C0 int
	set MAC_PORT0_TX_FLOW_C1 [get_property CONFIG.MAC_PORT0_TX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-flow-c1" $MAC_PORT0_TX_FLOW_C1 int
	set MAC_PORT0_TX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT0_TX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-opcode-gpp-c0" $MAC_PORT0_TX_OPCODE_GPP_C0 int
	set MAC_PORT0_TX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT0_TX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,mac-port0-tx-opcode-gpp-c1" $MAC_PORT0_TX_OPCODE_GPP_C1 int
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
	set GT_CH0_RXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rxprogdiv-freq-enable-c0" $GT_CH0_RXPROGDIV_FREQ_ENABLE_C0 string

	set GT_CH0_RXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rxprogdiv-freq-enable-c1" $GT_CH0_RXPROGDIV_FREQ_ENABLE_C1 string
	set GT_CH0_RXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rxprogdiv-freq-source-c0" $GT_CH0_RXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH0_RXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rxprogdiv-freq-source-c1" $GT_CH0_RXPROGDIV_FREQ_SOURCE_C1 string
	set GT_CH0_RXPROGDIV_FREQ_VAL_C0 [get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_VAL_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rxprogdiv-freq-val-c0" $GT_CH0_RXPROGDIV_FREQ_VAL_C0 string
	set GT_CH0_RXPROGDIV_FREQ_VAL_C1 [get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_VAL_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rxprogdiv-freq-val-c1" $GT_CH0_RXPROGDIV_FREQ_VAL_C1 string
	set GT_CH0_RX_BUFFER_MODE_C0 [get_property CONFIG.GT_CH0_RX_BUFFER_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-buffer-mode-c0" $GT_CH0_RX_BUFFER_MODE_C0 int
	set GT_CH0_RX_BUFFER_MODE_C1 [get_property CONFIG.GT_CH0_RX_BUFFER_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-buffer-mode-c1" $GT_CH0_RX_BUFFER_MODE_C1 int
	set GT_CH0_RX_DATA_DECODING_C0 [get_property CONFIG.GT_CH0_RX_DATA_DECODING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-data-decoding-c0" $GT_CH0_RX_DATA_DECODING_C0 string
	set GT_CH0_RX_DATA_DECODING_C1 [get_property CONFIG.GT_CH0_RX_DATA_DECODING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-data-decoding-c1" $GT_CH0_RX_DATA_DECODING_C1 string


	set GT_CH0_RX_INT_DATA_WIDTH_C0 [get_property CONFIG.GT_CH0_RX_INT_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-int-data-width-c0" $GT_CH0_RX_INT_DATA_WIDTH_C0 int
	set GT_CH0_RX_INT_DATA_WIDTH_C1 [get_property CONFIG.GT_CH0_RX_INT_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-int-data-width-c1" $GT_CH0_RX_INT_DATA_WIDTH_C1 int


	set GT_CH0_RX_LINE_RATE_C0 [get_property CONFIG.GT_CH0_RX_LINE_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-line-rate-c0" $GT_CH0_RX_LINE_RATE_C0 string
	set GT_CH0_RX_LINE_RATE_C1 [get_property CONFIG.GT_CH0_RX_LINE_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-line-rate-c1" $GT_CH0_RX_LINE_RATE_C1 string


	set GT_CH0_RX_OUTCLK_SOURCE_C0 [get_property CONFIG.GT_CH0_RX_OUTCLK_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-outclk-source-c0" $GT_CH0_RX_OUTCLK_SOURCE_C0 string
	set GT_CH0_RX_OUTCLK_SOURCE_C1 [get_property CONFIG.GT_CH0_RX_OUTCLK_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-outclk-source-c1" $GT_CH0_RX_OUTCLK_SOURCE_C1 string


	set GT_CH0_RX_REFCLK_FREQUENCY_C0 [get_property CONFIG.GT_CH0_RX_REFCLK_FREQUENCY_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-refclk-frequency-c0" $GT_CH0_RX_REFCLK_FREQUENCY_C0 string
	set GT_CH0_RX_REFCLK_FREQUENCY_C1 [get_property CONFIG.GT_CH0_RX_REFCLK_FREQUENCY_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-refclk-frequency-c1" $GT_CH0_RX_REFCLK_FREQUENCY_C1 string


	set GT_CH0_RX_USER_DATA_WIDTH_C0 [get_property CONFIG.GT_CH0_RX_USER_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-user-data-width-c0" $GT_CH0_RX_USER_DATA_WIDTH_C0 string
	set GT_CH0_RX_USER_DATA_WIDTH_C1 [get_property CONFIG.GT_CH0_RX_USER_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-rx-user-data-width-c1" $GT_CH0_RX_USER_DATA_WIDTH_C1 string

	set GT_CH0_TXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-txprogdiv-freq-enable-c0" $GT_CH0_TXPROGDIV_FREQ_ENABLE_C0 string
	set GT_CH0_TXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-txprogdiv-freq-enable-c1" $GT_CH0_TXPROGDIV_FREQ_ENABLE_C1 string


	set GT_CH0_TXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-txprogdiv-freq-source-c0" $GT_CH0_TXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH0_TXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,gt-ch0-txprogdiv-freq-source-c1" $GT_CH0_TXPROGDIV_FREQ_SOURCE_C1 string

	set base_addr [string tolower [get_property BASE_VALUE $mem_ranges]]
	set base_addr 0xa4090000
	set high_addr [string tolower [get_property HIGH_VALUE $mem_ranges]]
	set mrmac0_highaddr_hex [format 0x%x [expr $base_addr + 0xFFF]]
	generate_reg_property $node $base_addr $mrmac0_highaddr_hex
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
		if {[string match -nocase $clkname "rx_axi_clk0"]} {
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
		if {[string match -nocase $clkname "tx_axi_clk0"]} {
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

	lappend clknames "$s_axi_aclk" "$rx_axi_clk0" "$rx_flexif_clk0" "$rx_ts_clk0" "$tx_axi_clk0" "$tx_flexif_clk0" "$tx_ts_clk0"
	set index0 [lindex $clk_list $s_axi_aclk_index0]
	regsub -all "\<&" $index0 {} index0
	regsub -all "\<&" $index0 {} index0
	set txindex0 [lindex $clk_list $tx_ts_clk_index0]
	regsub -all "\>" $txindex0 {} txindex0
	append clkvals0  "$index0, [lindex $clk_list $rx_axi_clk_index0], [lindex $clk_list $rx_flexif_clk_index0], [lindex $clk_list $rx_ts_clk0_index0], [lindex $clk_list $tx_axi_clk_index0], [lindex $clk_list $tx_flexif_clk_index0], $txindex0"
	hsi::utils::add_new_dts_param "${node}" "clocks" $clkvals0 reference
	hsi::utils::add_new_dts_param "${node}" "clock-names" $clknames stringlist

	set port0_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_axis_tdata0"]]
	foreach pin $port0_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph]  "mrmac_10g_mux"]} {
				set mux_ip [hsi::utils::get_connected_stream_ip $sink_periph "s_axis"]
				if {[llength $mux_ip]} {
					if {[string match -nocase [get_property IP_NAME $mux_ip] "axis_data_fifo"]} {
						set fifo_ip [hsi::utils::get_connected_stream_ip $mux_ip "S_AXIS"]
					}
				}
			}
			if {![llength $mux_ip]} {
				set fifo_ip [hsi::utils::get_connected_stream_ip $sink_periph "S_AXIS"]
			}
			if {[llength $fifo_ip]} {
				set fifo_ipname [get_property IP_NAME $fifo_ip]
				if {[string match -nocase $fifo_ipname "axi_mcdma"]} {
					hsi::utils::add_new_dts_param "$node" "axistream-connected" "$fifo_ip" reference
					set num_queues [get_property CONFIG.c_num_mm2s_channels $fifo_ip]
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
					hsi::utils::add_new_dts_param $node "xlnx,channel-ids" $id intlist
				}
				generate_intr_info $drv_handle $node $fifo_ip
			}
		}
	}

	set bus_node "amba_pl"
	set dts_file [current_dt_tree]
	set mrmac1_base [format 0x%x [expr $base_addr + 0x1000]]
	set mrmac1_base_hex [format %x $mrmac1_base]
	set mrmac1_highaddr_hex [format 0x%x [expr $mrmac1_base + 0xFFF]]
	set port1 1
	append new_label $drv_handle "_" $port1
	set mrmac1_node [add_or_get_dt_node -n "mrmac" -l "$new_label" -u $mrmac1_base_hex -d $dts_file -p $bus_node]
	hsi::utils::add_new_dts_param "$mrmac1_node" "compatible" "$compatible" stringlist
	generate_reg_property $mrmac1_node $mrmac1_base $mrmac1_highaddr_hex
	lappend clknames1 "$s_axi_aclk" "$rx_axi_clk1" "$rx_flexif_clk1" "$rx_ts_clk1" "$tx_axi_clk1" "$tx_flexif_clk1" "$tx_ts_clk1"
	set index1 [lindex $clk_list $s_axi_aclk_index0]
	regsub -all "\<&" $index1 {} index1
	regsub -all "\<&" $index1 {} index1
	set txindex1 [lindex $clk_list $tx_ts_clk_index1]
	regsub -all "\>" $txindex1 {} txindex1
	append clkvals  "$index1, [lindex $clk_list $rx_axi_clk_index1], [lindex $clk_list $rx_flexif_clk_index1], [lindex $clk_list $rx_ts_clk1_index1], [lindex $clk_list $tx_axi_clk_index1], [lindex $clk_list $tx_flexif_clk_index1], $txindex1"
	hsi::utils::add_new_dts_param "${mrmac1_node}" "clocks" $clkvals reference
	hsi::utils::add_new_dts_param "${mrmac1_node}" "clock-names" $clknames1 stringlist
	set port1_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_axis_tdata2"]]
	foreach pin $port1_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph]  "mrmac_10g_mux"]} {
				set mux_ip [hsi::utils::get_connected_stream_ip $sink_periph "s_axis"]
				if {[llength $mux_ip]} {
					if {[string match -nocase [get_property IP_NAME $mux_ip] "axis_data_fifo"]} {
						set fifo_ip [hsi::utils::get_connected_stream_ip $mux_ip "S_AXIS"]
					}
				}
			}
			if {![llength $mux_ip]} {
				set fifo_ip [hsi::utils::get_connected_stream_ip $sink_periph "S_AXIS"]
			}
			if {[llength $fifo_ip]} {
				set fifo_ipname [get_property IP_NAME $fifo_ip]
				if {[string match -nocase $fifo_ipname "axi_mcdma"]} {
					hsi::utils::add_new_dts_param "$mrmac1_node" "axistream-connected" "$fifo_ip" reference
					set num_queues [get_property CONFIG.c_num_mm2s_channels $fifo_ip]
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
					hsi::utils::add_new_dts_param $mrmac1_node "xlnx,channel-ids" $id intlist
				}
				generate_intr_info $drv_handle $mrmac1_node $fifo_ip
			}
		}
	}


	set FEC_SLICE1_CFG_C0 [get_property CONFIG.C_FEC_SLICE1_CFG_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-slice1-cfg-c0" $FEC_SLICE1_CFG_C0 string
	set FEC_SLICE1_CFG_C1 [get_property CONFIG.C_FEC_SLICE1_CFG_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-slice1-cfg-c1" $FEC_SLICE1_CFG_C1 string
	set FLEX_PORT1_DATA_RATE_C0 [get_property CONFIG.C_FLEX_PORT1_DATA_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-port1-data-rate-c0" $FLEX_PORT1_DATA_RATE_C0 string
	set FLEX_PORT1_DATA_RATE_C1 [get_property CONFIG.C_FLEX_PORT1_DATA_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-port1-data-rate-c1" $FLEX_PORT1_DATA_RATE_C1 string
	set FLEX_PORT1_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.C_FLEX_PORT1_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-port1-enable-time-stamping-c0" $FLEX_PORT1_ENABLE_TIME_STAMPING_C0 int
	set FLEX_PORT1_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.C_FLEX_PORT1_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-port1-enable-time-stamping-c1" $FLEX_PORT1_ENABLE_TIME_STAMPING_C1 int
	set FLEX_PORT1_MODE_C0 [get_property CONFIG.C_FLEX_PORT1_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-port1-mode-c0" $FLEX_PORT1_MODE_C0 string
	set FLEX_PORT1_MODE_C1 [get_property CONFIG.C_FLEX_PORT1_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,flex-port1-mode-c1" $FLEX_PORT1_MODE_C1 string
	set PORT1_1588v2_Clocking_C0 [get_property CONFIG.PORT1_1588v2_Clocking_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,port1-1588v2-clocking-c0" $PORT1_1588v2_Clocking_C0 string
	set PORT1_1588v2_Clocking_C1 [get_property CONFIG.PORT1_1588v2_Clocking_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,port1-1588v2-clocking-c1" $PORT1_1588v2_Clocking_C1 string
	set PORT1_1588v2_Operation_MODE_C0 [get_property CONFIG.PORT1_1588v2_Operation_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,port1-1588v2-operation-mode-c0" $PORT1_1588v2_Operation_MODE_C0 string
	set PORT1_1588v2_Operation_MODE_C1 [get_property CONFIG.PORT1_1588v2_Operation_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,port1-1588v2-operation-mode-c1" $PORT1_1588v2_Operation_MODE_C1 string
	set MAC_PORT1_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.MAC_PORT1_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-enable-time-stamping-c0" $MAC_PORT1_ENABLE_TIME_STAMPING_C0 int
	set MAC_PORT1_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.MAC_PORT1_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-enable-time-stamping-c1" $MAC_PORT1_ENABLE_TIME_STAMPING_C1 int
	set MAC_PORT1_RATE_C0 [get_property CONFIG.MAC_PORT1_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rate-c0" $MAC_PORT1_RATE_C0 string
	set MAC_PORT1_RATE_C1 [get_property CONFIG.MAC_PORT1_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rate-c1" $MAC_PORT1_RATE_C1 string
	set MAC_PORT1_RX_ETYPE_GCP_C0 [get_property CONFIG.MAC_PORT1_RX_ETYPE_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gcp-c0" $MAC_PORT1_RX_ETYPE_GCP_C0 int
	set MAC_PORT1_RX_ETYPE_GCP_C1 [get_property CONFIG.MAC_PORT1_RX_ETYPE_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gcp-c1" $MAC_PORT1_RX_ETYPE_GCP_C1 int
	set MAC_PORT1_RX_ETYPE_GPP_C0 [get_property CONFIG.MAC_PORT1_RX_ETYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gpp-c0" $MAC_PORT1_RX_ETYPE_GPP_C0 int
	set MAC_PORT1_RX_ETYPE_GPP_C1 [get_property CONFIG.MAC_PORT1_RX_ETYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gpp-c1" $MAC_PORT1_RX_ETYPE_GPP_C1 int
	set MAC_PORT1_RX_ETYPE_PCP_C0 [get_property CONFIG.MAC_PORT1_RX_ETYPE_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-pcp-c0" $MAC_PORT1_RX_ETYPE_PCP_C0 int
	set MAC_PORT1_RX_ETYPE_PCP_C1 [get_property CONFIG.MAC_PORT1_RX_ETYPE_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-pcp-c1" $MAC_PORT1_RX_ETYPE_PCP_C1 int
	set MAC_PORT1_RX_ETYPE_PPP_C0 [get_property CONFIG.MAC_PORT1_RX_ETYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-ppp-c0" $MAC_PORT1_RX_ETYPE_PPP_C0 int
	set MAC_PORT1_RX_ETYPE_PPP_C1 [get_property CONFIG.MAC_PORT1_RX_ETYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-etype-ppp-c1" $MAC_PORT1_RX_ETYPE_PPP_C1 int
	set MAC_PORT1_RX_FLOW_C0 [get_property CONFIG.MAC_PORT1_RX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-flow-c0" $MAC_PORT1_RX_FLOW_C0 int
	set MAC_PORT1_RX_FLOW_C1 [get_property CONFIG.MAC_PORT1_RX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-flow-c1" $MAC_PORT1_RX_FLOW_C1 int
	set MAC_PORT1_RX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT1_RX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-gpp-c0" $MAC_PORT1_RX_OPCODE_GPP_C0 int
	set MAC_PORT1_RX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT1_RX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-gpp-c1" $MAC_PORT1_RX_OPCODE_GPP_C1 int
	set MAC_PORT1_RX_OPCODE_MAX_GCP_C0 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-gcp-c0" $MAC_PORT1_RX_OPCODE_MAX_GCP_C0 int
	set MAC_PORT1_RX_OPCODE_MAX_GCP_C1 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-gcp-c1" $MAC_PORT1_RX_OPCODE_MAX_GCP_C1 int
	set MAC_PORT1_RX_OPCODE_MAX_PCP_C0 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-pcp-c0" $MAC_PORT1_RX_OPCODE_MAX_PCP_C0 int
	set MAC_PORT1_RX_OPCODE_MAX_PCP_C1 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-pcp-c1" $MAC_PORT1_RX_OPCODE_MAX_PCP_C1 int
	set MAC_PORT1_RX_OPCODE_MIN_GCP_C0 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-gcp-c0" $MAC_PORT1_RX_OPCODE_MIN_GCP_C0 int
	set MAC_PORT1_RX_OPCODE_MIN_GCP_C1 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-gcp-c1" $MAC_PORT1_RX_OPCODE_MIN_GCP_C1 int
	set MAC_PORT1_RX_OPCODE_MIN_PCP_C0 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-pcp-c0" $MAC_PORT1_RX_OPCODE_MIN_PCP_C0 int
	set MAC_PORT1_RX_OPCODE_MIN_PCP_C1 [get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-pcp-c1" $MAC_PORT1_RX_OPCODE_MIN_PCP_C1 int
	set MAC_PORT1_RX_OPCODE_PPP_C0 [get_property CONFIG.MAC_PORT1_RX_OPCODE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-ppp-c0" $MAC_PORT1_RX_OPCODE_PPP_C0 int
	set MAC_PORT1_RX_OPCODE_PPP_C1 [get_property CONFIG.MAC_PORT1_RX_OPCODE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-ppp-c1" $MAC_PORT1_RX_OPCODE_PPP_C1 int
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
	set MAC_PORT1_TX_ETHERTYPE_GPP_C0 [get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-gpp-c0" $MAC_PORT1_TX_ETHERTYPE_GPP_C0 int
	set MAC_PORT1_TX_ETHERTYPE_GPP_C1 [get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-gpp-c1" $MAC_PORT1_TX_ETHERTYPE_GPP_C1 int
	set MAC_PORT1_TX_ETHERTYPE_PPP_C0 [get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-ppp-c0" $MAC_PORT1_TX_ETHERTYPE_PPP_C0 int
	set MAC_PORT1_TX_ETHERTYPE_PPP_C1 [get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-ppp-c1" $MAC_PORT1_TX_ETHERTYPE_PPP_C1 int
	set MAC_PORT1_TX_FLOW_C0 [get_property CONFIG.MAC_PORT1_TX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-flow-c0" $MAC_PORT1_TX_FLOW_C0 int
	set MAC_PORT1_TX_FLOW_C1 [get_property CONFIG.MAC_PORT1_TX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-flow-c1" $MAC_PORT1_TX_FLOW_C1 int
	set MAC_PORT1_TX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT1_TX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-opcode-gpp-c0" $MAC_PORT1_TX_OPCODE_GPP_C0 int
	set MAC_PORT1_TX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT1_TX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,mac-port1-tx-opcode-gpp-c1" $MAC_PORT1_TX_OPCODE_GPP_C1 int
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
	set GT_CH1_RXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-enable-c0" $GT_CH1_RXPROGDIV_FREQ_ENABLE_C0 string
	set GT_CH1_RXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-enable-c1" $GT_CH1_RXPROGDIV_FREQ_ENABLE_C1 string
	set GT_CH1_RXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-source-c0" $GT_CH1_RXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH1_RXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-source-c1" $GT_CH1_RXPROGDIV_FREQ_SOURCE_C1 string
	set GT_CH1_RXPROGDIV_FREQ_VAL_C0 [get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_VAL_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-val-c0" $GT_CH1_RXPROGDIV_FREQ_VAL_C0 string
	set GT_CH1_RXPROGDIV_FREQ_VAL_C1 [get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_VAL_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-val-c1" $GT_CH1_RXPROGDIV_FREQ_VAL_C1 string
	set GT_CH1_RX_BUFFER_MODE_C0 [get_property CONFIG.GT_CH1_RX_BUFFER_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-buffer-mode-c0" $GT_CH1_RX_BUFFER_MODE_C0 int
	set GT_CH1_RX_BUFFER_MODE_C1 [get_property CONFIG.GT_CH1_RX_BUFFER_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-buffer-mode-c1" $GT_CH1_RX_BUFFER_MODE_C1 int
	set GT_CH1_RX_DATA_DECODING_C0 [get_property CONFIG.GT_CH1_RX_DATA_DECODING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-data-decoding-c0" $GT_CH1_RX_DATA_DECODING_C0 string
	set GT_CH1_RX_DATA_DECODING_C1 [get_property CONFIG.GT_CH1_RX_DATA_DECODING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-data-decoding-c1" $GT_CH1_RX_DATA_DECODING_C1 string


	set GT_CH1_RX_INT_DATA_WIDTH_C0 [get_property CONFIG.GT_CH1_RX_INT_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-int-data-width-c0" $GT_CH1_RX_INT_DATA_WIDTH_C0 int
	set GT_CH1_RX_INT_DATA_WIDTH_C1 [get_property CONFIG.GT_CH1_RX_INT_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-int-data-width-c1" $GT_CH1_RX_INT_DATA_WIDTH_C1 int


	set GT_CH1_RX_LINE_RATE_C0 [get_property CONFIG.GT_CH1_RX_LINE_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-line-rate-c0" $GT_CH1_RX_LINE_RATE_C0 string
	set GT_CH1_RX_LINE_RATE_C1 [get_property CONFIG.GT_CH1_RX_LINE_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-line-rate-c1" $GT_CH1_RX_LINE_RATE_C1 string


	set GT_CH1_RX_OUTCLK_SOURCE_C0 [get_property CONFIG.GT_CH1_RX_OUTCLK_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-outclk-source-c0" $GT_CH1_RX_OUTCLK_SOURCE_C0 string
	set GT_CH1_RX_OUTCLK_SOURCE_C1 [get_property CONFIG.GT_CH1_RX_OUTCLK_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-outclk-source-c1" $GT_CH1_RX_OUTCLK_SOURCE_C1 string


	set GT_CH1_RX_REFCLK_FREQUENCY_C0 [get_property CONFIG.GT_CH1_RX_REFCLK_FREQUENCY_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-refclk-frequency-c0" $GT_CH1_RX_REFCLK_FREQUENCY_C0 string
	set GT_CH1_RX_REFCLK_FREQUENCY_C1 [get_property CONFIG.GT_CH1_RX_REFCLK_FREQUENCY_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-refclk-frequency-c1" $GT_CH1_RX_REFCLK_FREQUENCY_C1 string


	set GT_CH1_RX_USER_DATA_WIDTH_C0 [get_property CONFIG.GT_CH1_RX_USER_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-user-data-width-c0" $GT_CH1_RX_USER_DATA_WIDTH_C0 string
	set GT_CH1_RX_USER_DATA_WIDTH_C1 [get_property CONFIG.GT_CH1_RX_USER_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-rx-user-data-width-c1" $GT_CH1_RX_USER_DATA_WIDTH_C1 string

	set GT_CH1_TXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-enable-c0" $GT_CH1_TXPROGDIV_FREQ_ENABLE_C0 string
	set GT_CH1_TXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-enable-c1" $GT_CH1_TXPROGDIV_FREQ_ENABLE_C1 string


	set GT_CH1_TXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-source-c0" $GT_CH1_TXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH1_TXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-source-c1" $GT_CH1_TXPROGDIV_FREQ_SOURCE_C1 string


	set GT_CH1_TXPROGDIV_FREQ_VAL_C0 [get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_VAL_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-val-c0" $GT_CH1_TXPROGDIV_FREQ_VAL_C0 string
	set GT_CH1_TXPROGDIV_FREQ_VAL_C1 [get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_VAL_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-val-c1" $GT_CH1_TXPROGDIV_FREQ_VAL_C1 string


	set GT_CH1_TX_BUFFER_MODE_C0 [get_property CONFIG.GT_CH1_TX_BUFFER_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-buffer-mode-c0" $GT_CH1_TX_BUFFER_MODE_C0 int
	set GT_CH1_TX_BUFFER_MODE_C1 [get_property CONFIG.GT_CH1_TX_BUFFER_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-buffer-mode-c1" $GT_CH1_TX_BUFFER_MODE_C1 int


	set GT_CH1_TX_DATA_ENCODING_C0 [get_property CONFIG.GT_CH1_TX_DATA_ENCODING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-data-encoding-c0" $GT_CH1_TX_DATA_ENCODING_C0 string
	set GT_CH1_TX_DATA_ENCODING_C1 [get_property CONFIG.GT_CH1_TX_DATA_ENCODING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-data-encoding-c1" $GT_CH1_TX_DATA_ENCODING_C1 string

	set GT_CH1_TX_INT_DATA_WIDTH_C0 [get_property CONFIG.GT_CH1_TX_INT_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-int-data-width-c0" $GT_CH1_TX_INT_DATA_WIDTH_C0 int
	set GT_CH1_TX_INT_DATA_WIDTH_C1 [get_property CONFIG.GT_CH1_TX_INT_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-int-data-width-c1" $GT_CH1_TX_INT_DATA_WIDTH_C1 int

	set GT_CH1_TX_LINE_RATE_C0 [get_property CONFIG.GT_CH1_TX_LINE_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-line-rate-c0" $GT_CH1_TX_LINE_RATE_C0 string
	set GT_CH1_TX_LINE_RATE_C1 [get_property CONFIG.GT_CH1_TX_LINE_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-line-rate-c1" $GT_CH1_TX_LINE_RATE_C1 string


	set GT_CH1_TX_OUTCLK_SOURCE_C0 [get_property CONFIG.GT_CH1_TX_OUTCLK_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-outclk-source-c0" $GT_CH1_TX_OUTCLK_SOURCE_C0 string
	set GT_CH1_TX_OUTCLK_SOURCE_C1 [get_property CONFIG.GT_CH1_TX_OUTCLK_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-outclk-source-c1" $GT_CH1_TX_OUTCLK_SOURCE_C1 string


	set GT_CH1_TX_PLL_TYPE_C0 [get_property CONFIG.GT_CH1_TX_PLL_TYPE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-pll-type-c0" $GT_CH1_TX_PLL_TYPE_C0 string
	set GT_CH1_TX_PLL_TYPE_C1 [get_property CONFIG.GT_CH1_TX_PLL_TYPE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-pll-type-c1" $GT_CH1_TX_PLL_TYPE_C1 string


	set GT_CH1_TX_REFCLK_FREQUENCY_C0 [get_property CONFIG.GT_CH1_TX_REFCLK_FREQUENCY_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-refclk-frequency-c0" $GT_CH1_TX_REFCLK_FREQUENCY_C0 string
	set GT_CH1_TX_REFCLK_FREQUENCY_C1 [get_property CONFIG.GT_CH1_TX_REFCLK_FREQUENCY_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-refclk-frequency-c1" $GT_CH1_TX_REFCLK_FREQUENCY_C1 string


	set GT_CH1_TX_USER_DATA_WIDTH_C0 [get_property CONFIG.GT_CH1_TX_USER_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-user-data-width-c0" $GT_CH1_TX_USER_DATA_WIDTH_C0 int
	set GT_CH1_TX_USER_DATA_WIDTH_C1 [get_property CONFIG.GT_CH1_TX_USER_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch1-tx-user-data-width-c1" $GT_CH1_TX_USER_DATA_WIDTH_C1 int

	set mrmac2_base [format 0x%x [expr $base_addr + 0x2000]]
	set mrmac2_base_hex [format %x $mrmac2_base]
	set mrmac2_highaddr_hex [format 0x%x [expr $mrmac2_base + 0xFFF]]
	set port2 2
	append label2 $drv_handle "_" $port2
	set mrmac2_node [add_or_get_dt_node -n "mrmac" -l "$label2" -u $mrmac2_base_hex -d $dts_file -p $bus_node]
	hsi::utils::add_new_dts_param "$mrmac2_node" "compatible" "$compatible" stringlist
	generate_reg_property $mrmac2_node $mrmac2_base $mrmac2_highaddr_hex

	lappend clknames2 "$s_axi_aclk" "$rx_axi_clk2" "$rx_flexif_clk2" "$rx_ts_clk2" "$tx_axi_clk2" "$tx_flexif_clk2" "$tx_ts_clk2"
	set index2 [lindex $clk_list $s_axi_aclk_index0]
	regsub -all "\<&" $index2 {} index2
	regsub -all "\<&" $index2 {} index2
	set txindex2 [lindex $clk_list $tx_ts_clk_index2]
	regsub -all "\>" $txindex2 {} txindex2
	append clkvals2  "$index2,[lindex $clk_list $rx_axi_clk_index2], [lindex $clk_list $rx_flexif_clk_index2], [lindex $clk_list $rx_ts_clk2_index2], [lindex $clk_list $tx_axi_clk_index2], [lindex $clk_list $tx_flexif_clk_index2], $txindex2"
	hsi::utils::add_new_dts_param "${mrmac2_node}" "clocks" $clkvals2 reference
	hsi::utils::add_new_dts_param "${mrmac2_node}" "clock-names" $clknames2 stringlist
	set port2_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_axis_tdata4"]]
	foreach pin $port2_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph]  "mrmac_10g_mux"]} {
				set mux_ip [hsi::utils::get_connected_stream_ip $sink_periph "s_axis"]
				if {[llength $mux_ip]} {
					if {[string match -nocase [get_property IP_NAME $mux_ip] "axis_data_fifo"]} {
						set fifo_ip [hsi::utils::get_connected_stream_ip $mux_ip "S_AXIS"]
					}
				}
			}
			if {![llength $mux_ip]} {
				set fifo_ip [hsi::utils::get_connected_stream_ip $sink_periph "S_AXIS"]
			}
			if {[llength $fifo_ip]} {
				set fifo_ipname [get_property IP_NAME $fifo_ip]
				if {[string match -nocase $fifo_ipname "axi_mcdma"]} {
					hsi::utils::add_new_dts_param "$mrmac2_node" "axistream-connected" "$fifo_ip" reference
					set num_queues [get_property CONFIG.c_num_mm2s_channels $fifo_ip]
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
					hsi::utils::add_new_dts_param $mrmac2_node "xlnx,channel-ids" $id intlist
				}
				generate_intr_info $drv_handle $mrmac2_node $fifo_ip
			}
		}
	}

	set FEC_SLICE2_CFG_C0 [get_property CONFIG.C_FEC_SLICE2_CFG_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-slice2-cfg-c0" $FEC_SLICE2_CFG_C0 string
	set FEC_SLICE2_CFG_C1 [get_property CONFIG.C_FEC_SLICE2_CFG_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-slice2-cfg-c1" $FEC_SLICE2_CFG_C1 string
	set FLEX_PORT2_DATA_RATE_C0 [get_property CONFIG.C_FLEX_PORT2_DATA_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-port2-data-rate-c0" $FLEX_PORT2_DATA_RATE_C0 string
	set FLEX_PORT2_DATA_RATE_C1 [get_property CONFIG.C_FLEX_PORT2_DATA_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-port2-data-rate-c1" $FLEX_PORT2_DATA_RATE_C1 string
	set FLEX_PORT2_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.C_FLEX_PORT2_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-port2-enable-time-stamping-c0" $FLEX_PORT2_ENABLE_TIME_STAMPING_C0 int
	set FLEX_PORT2_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.C_FLEX_PORT2_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-port2-enable-time-stamping-c1" $FLEX_PORT2_ENABLE_TIME_STAMPING_C1 int
	set FLEX_PORT2_MODE_C0 [get_property CONFIG.C_FLEX_PORT2_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-port2-mode-c0" $FLEX_PORT2_MODE_C0 string
	set FLEX_PORT2_MODE_C1 [get_property CONFIG.C_FLEX_PORT2_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,flex-port2-mode-c1" $FLEX_PORT2_MODE_C1 string
	set PORT2_1588v2_Clocking_C0 [get_property CONFIG.PORT2_1588v2_Clocking_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,port2-1588v2-clocking-c0" $PORT2_1588v2_Clocking_C0 string
	set PORT2_1588v2_Clocking_C1 [get_property CONFIG.PORT2_1588v2_Clocking_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,port2-1588v2-clocking-c1" $PORT2_1588v2_Clocking_C1 string
	set PORT2_1588v2_Operation_MODE_C0 [get_property CONFIG.PORT2_1588v2_Operation_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,port2-1588v2-operation-mode-c0" $PORT2_1588v2_Operation_MODE_C0 string
	set PORT2_1588v2_Operation_MODE_C1 [get_property CONFIG.PORT2_1588v2_Operation_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,port2-1588v2-operation-mode-c1" $PORT2_1588v2_Operation_MODE_C1 string
	set MAC_PORT2_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.MAC_PORT2_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-enable-time-stamping-c0" $MAC_PORT2_ENABLE_TIME_STAMPING_C0 int
	set MAC_PORT2_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.MAC_PORT2_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-enable-time-stamping-c1" $MAC_PORT2_ENABLE_TIME_STAMPING_C1 int
	set MAC_PORT2_RATE_C0 [get_property CONFIG.MAC_PORT2_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rate-c0" $MAC_PORT2_RATE_C0 string
	set MAC_PORT2_RATE_C1 [get_property CONFIG.MAC_PORT2_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rate-c1" $MAC_PORT2_RATE_C1 string
	set MAC_PORT2_RX_ETYPE_GCP_C0 [get_property CONFIG.MAC_PORT2_RX_ETYPE_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gcp-c0" $MAC_PORT2_RX_ETYPE_GCP_C0 int
	set MAC_PORT2_RX_ETYPE_GCP_C1 [get_property CONFIG.MAC_PORT2_RX_ETYPE_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gcp-c1" $MAC_PORT2_RX_ETYPE_GCP_C1 int
	set MAC_PORT2_RX_ETYPE_GPP_C0 [get_property CONFIG.MAC_PORT2_RX_ETYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gpp-c0" $MAC_PORT1_RX_ETYPE_GPP_C0 int
	set MAC_PORT2_RX_ETYPE_GPP_C1 [get_property CONFIG.MAC_PORT2_RX_ETYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gpp-c1" $MAC_PORT2_RX_ETYPE_GPP_C1 int
	set MAC_PORT2_RX_ETYPE_PCP_C0 [get_property CONFIG.MAC_PORT2_RX_ETYPE_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-pcp-c0" $MAC_PORT2_RX_ETYPE_PCP_C0 int
	set MAC_PORT2_RX_ETYPE_PCP_C1 [get_property CONFIG.MAC_PORT2_RX_ETYPE_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-pcp-c1" $MAC_PORT2_RX_ETYPE_PCP_C1 int
	set MAC_PORT2_RX_ETYPE_PPP_C0 [get_property CONFIG.MAC_PORT2_RX_ETYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-ppp-c0" $MAC_PORT2_RX_ETYPE_PPP_C0 int
	set MAC_PORT2_RX_ETYPE_PPP_C1 [get_property CONFIG.MAC_PORT2_RX_ETYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-etype-ppp-c1" $MAC_PORT2_RX_ETYPE_PPP_C1 int
	set MAC_PORT2_RX_FLOW_C0 [get_property CONFIG.MAC_PORT2_RX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-flow-c0" $MAC_PORT2_RX_FLOW_C0 int
	set MAC_PORT2_RX_FLOW_C1 [get_property CONFIG.MAC_PORT2_RX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-flow-c1" $MAC_PORT2_RX_FLOW_C1 int
	set MAC_PORT2_RX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT2_RX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-gpp-c0" $MAC_PORT2_RX_OPCODE_GPP_C0 int
	set MAC_PORT2_RX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT2_RX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-gpp-c1" $MAC_PORT2_RX_OPCODE_GPP_C1 int
	set MAC_PORT2_RX_OPCODE_MAX_GCP_C0 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-gcp-c0" $MAC_PORT2_RX_OPCODE_MAX_GCP_C0 int
	set MAC_PORT2_RX_OPCODE_MAX_GCP_C1 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-gcp-c1" $MAC_PORT2_RX_OPCODE_MAX_GCP_C1 int
	set MAC_PORT2_RX_OPCODE_MAX_PCP_C0 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-pcp-c0" $MAC_PORT2_RX_OPCODE_MAX_PCP_C0 int
	set MAC_PORT2_RX_OPCODE_MAX_PCP_C1 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-pcp-c1" $MAC_PORT2_RX_OPCODE_MAX_PCP_C1 int
	set MAC_PORT2_RX_OPCODE_MIN_GCP_C0 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-gcp-c0" $MAC_PORT2_RX_OPCODE_MIN_GCP_C0 int
	set MAC_PORT2_RX_OPCODE_MIN_GCP_C1 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-gcp-c1" $MAC_PORT2_RX_OPCODE_MIN_GCP_C1 int
	set MAC_PORT2_RX_OPCODE_MIN_PCP_C0 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-pcp-c0" $MAC_PORT2_RX_OPCODE_MIN_PCP_C0 int
	set MAC_PORT2_RX_OPCODE_MIN_PCP_C1 [get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-pcp-c1" $MAC_PORT2_RX_OPCODE_MIN_PCP_C1 int
	set MAC_PORT2_RX_OPCODE_PPP_C0 [get_property CONFIG.MAC_PORT2_RX_OPCODE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-ppp-c0" $MAC_PORT2_RX_OPCODE_PPP_C0 int
	set MAC_PORT2_RX_OPCODE_PPP_C1 [get_property CONFIG.MAC_PORT2_RX_OPCODE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-ppp-c1" $MAC_PORT2_RX_OPCODE_PPP_C1 int
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
	set MAC_PORT2_TX_ETHERTYPE_GPP_C0 [get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-gpp-c0" $MAC_PORT2_TX_ETHERTYPE_GPP_C0 int
	set MAC_PORT2_TX_ETHERTYPE_GPP_C1 [get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-gpp-c1" $MAC_PORT2_TX_ETHERTYPE_GPP_C1 int
	set MAC_PORT2_TX_ETHERTYPE_PPP_C0 [get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-ppp-c0" $MAC_PORT2_TX_ETHERTYPE_PPP_C0 int
	set MAC_PORT2_TX_ETHERTYPE_PPP_C1 [get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-ppp-c1" $MAC_PORT2_TX_ETHERTYPE_PPP_C1 int
	set MAC_PORT2_TX_FLOW_C0 [get_property CONFIG.MAC_PORT2_TX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-flow-c0" $MAC_PORT2_TX_FLOW_C0 int
	set MAC_PORT2_TX_FLOW_C1 [get_property CONFIG.MAC_PORT2_TX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-flow-c1" $MAC_PORT2_TX_FLOW_C1 int
	set MAC_PORT2_TX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT2_TX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-opcode-gpp-c0" $MAC_PORT2_TX_OPCODE_GPP_C0 int
	set MAC_PORT2_TX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT2_TX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,mac-port2-tx-opcode-gpp-c1" $MAC_PORT2_TX_OPCODE_GPP_C1 int
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
	set GT_CH2_RXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-enable-c0" $GT_CH2_RXPROGDIV_FREQ_ENABLE_C0 string
	set GT_CH2_RXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-enable-c1" $GT_CH2_RXPROGDIV_FREQ_ENABLE_C1 string

	set GT_CH2_RXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-source-c0" $GT_CH2_RXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH2_RXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-source-c1" $GT_CH2_RXPROGDIV_FREQ_SOURCE_C1 string
	set GT_CH2_RXPROGDIV_FREQ_VAL_C0 [get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_VAL_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-val-c0" $GT_CH2_RXPROGDIV_FREQ_VAL_C0 string
	set GT_CH2_RXPROGDIV_FREQ_VAL_C1 [get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_VAL_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-val-c1" $GT_CH2_RXPROGDIV_FREQ_VAL_C1 string
	set GT_CH2_RX_BUFFER_MODE_C0 [get_property CONFIG.GT_CH2_RX_BUFFER_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-buffer-mode-c0" $GT_CH2_RX_BUFFER_MODE_C0 int
	set GT_CH2_RX_BUFFER_MODE_C1 [get_property CONFIG.GT_CH2_RX_BUFFER_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-buffer-mode-c1" $GT_CH2_RX_BUFFER_MODE_C1 int
	set GT_CH2_RX_DATA_DECODING_C0 [get_property CONFIG.GT_CH2_RX_DATA_DECODING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-data-decoding-c0" $GT_CH2_RX_DATA_DECODING_C0 string
	set GT_CH2_RX_DATA_DECODING_C1 [get_property CONFIG.GT_CH2_RX_DATA_DECODING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-data-decoding-c1" $GT_CH2_RX_DATA_DECODING_C1 string

	set GT_CH2_RX_INT_DATA_WIDTH_C0 [get_property CONFIG.GT_CH2_RX_INT_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-int-data-width-c0" $GT_CH2_RX_INT_DATA_WIDTH_C0 int
	set GT_CH2_RX_INT_DATA_WIDTH_C1 [get_property CONFIG.GT_CH2_RX_INT_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-int-data-width-c1" $GT_CH2_RX_INT_DATA_WIDTH_C1 int

	set GT_CH2_RX_LINE_RATE_C0 [get_property CONFIG.GT_CH2_RX_LINE_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-line-rate-c0" $GT_CH2_RX_LINE_RATE_C0 string
	set GT_CH2_RX_LINE_RATE_C1 [get_property CONFIG.GT_CH2_RX_LINE_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-line-rate-c1" $GT_CH2_RX_LINE_RATE_C1 string

	set GT_CH2_RX_OUTCLK_SOURCE_C0 [get_property CONFIG.GT_CH2_RX_OUTCLK_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-outclk-source-c0" $GT_CH2_RX_OUTCLK_SOURCE_C0 string
	set GT_CH2_RX_OUTCLK_SOURCE_C1 [get_property CONFIG.GT_CH2_RX_OUTCLK_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-outclk-source-c1" $GT_CH2_RX_OUTCLK_SOURCE_C1 string

	set GT_CH2_RX_REFCLK_FREQUENCY_C0 [get_property CONFIG.GT_CH2_RX_REFCLK_FREQUENCY_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-refclk-frequency-c0" $GT_CH2_RX_REFCLK_FREQUENCY_C0 string
	set GT_CH2_RX_REFCLK_FREQUENCY_C1 [get_property CONFIG.GT_CH2_RX_REFCLK_FREQUENCY_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-refclk-frequency-c1" $GT_CH2_RX_REFCLK_FREQUENCY_C1 string

	set GT_CH2_RX_USER_DATA_WIDTH_C0 [get_property CONFIG.GT_CH2_RX_USER_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-user-data-width-c0" $GT_CH2_RX_USER_DATA_WIDTH_C0 string
	set GT_CH2_RX_USER_DATA_WIDTH_C1 [get_property CONFIG.GT_CH2_RX_USER_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-rx-user-data-width-c1" $GT_CH2_RX_USER_DATA_WIDTH_C1 string

	set GT_CH2_TXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-txprogdiv-freq-enable-c0" $GT_CH2_TXPROGDIV_FREQ_ENABLE_C0 string
	set GT_CH2_TXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac1_node}" "xlnx,gt-ch2-txprogdiv-freq-enable-c1" $GT_CH2_TXPROGDIV_FREQ_ENABLE_C1 string

	set GT_CH2_TXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-txprogdiv-freq-source-c0" $GT_CH2_TXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH2_TXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-txprogdiv-freq-source-c1" $GT_CH2_TXPROGDIV_FREQ_SOURCE_C1 string

	set GT_CH2_TX_BUFFER_MODE_C0 [get_property CONFIG.GT_CH2_TX_BUFFER_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-buffer-mode-c0" $GT_CH2_TX_BUFFER_MODE_C0 int
	set GT_CH2_TX_BUFFER_MODE_C1 [get_property CONFIG.GT_CH2_TX_BUFFER_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-buffer-mode-c1" $GT_CH2_TX_BUFFER_MODE_C1 int

	set GT_CH2_TX_DATA_ENCODING_C0 [get_property CONFIG.GT_CH2_TX_DATA_ENCODING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-data-encoding-c0" $GT_CH2_TX_DATA_ENCODING_C0 string
	set GT_CH2_TX_DATA_ENCODING_C1 [get_property CONFIG.GT_CH2_TX_DATA_ENCODING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-data-encoding-c1" $GT_CH2_TX_DATA_ENCODING_C1 string

	set GT_CH2_TX_INT_DATA_WIDTH_C0 [get_property CONFIG.GT_CH2_TX_INT_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-int-data-width-c0" $GT_CH2_TX_INT_DATA_WIDTH_C0 int
	set GT_CH2_TX_INT_DATA_WIDTH_C1 [get_property CONFIG.GT_CH2_TX_INT_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-int-data-width-c1" $GT_CH2_TX_INT_DATA_WIDTH_C1 int

	set GT_CH2_TX_LINE_RATE_C0 [get_property CONFIG.GT_CH2_TX_LINE_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-line-rate-c0" $GT_CH2_TX_LINE_RATE_C0 string
	set GT_CH2_TX_LINE_RATE_C1 [get_property CONFIG.GT_CH2_TX_LINE_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-line-rate-c1" $GT_CH2_TX_LINE_RATE_C1 string

	set GT_CH2_TX_OUTCLK_SOURCE_C0 [get_property CONFIG.GT_CH2_TX_OUTCLK_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-outclk-source-c0" $GT_CH2_TX_OUTCLK_SOURCE_C0 string
	set GT_CH2_TX_OUTCLK_SOURCE_C1 [get_property CONFIG.GT_CH2_TX_OUTCLK_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-outclk-source-c1" $GT_CH2_TX_OUTCLK_SOURCE_C1 string

	set GT_CH2_TX_PLL_TYPE_C0 [get_property CONFIG.GT_CH2_TX_PLL_TYPE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-pll-type-c0" $GT_CH2_TX_PLL_TYPE_C0 string
	set GT_CH2_TX_PLL_TYPE_C1 [get_property CONFIG.GT_CH2_TX_PLL_TYPE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-pll-type-c1" $GT_CH2_TX_PLL_TYPE_C1 string

	set GT_CH2_TX_REFCLK_FREQUENCY_C0 [get_property CONFIG.GT_CH2_TX_REFCLK_FREQUENCY_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-refclk-frequency-c0" $GT_CH2_TX_REFCLK_FREQUENCY_C0 string
	set GT_CH2_TX_REFCLK_FREQUENCY_C1 [get_property CONFIG.GT_CH2_TX_REFCLK_FREQUENCY_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-refclk-frequency-c1" $GT_CH2_TX_REFCLK_FREQUENCY_C1 string

        set GT_CH2_TX_USER_DATA_WIDTH_C0 [get_property CONFIG.GT_CH2_TX_USER_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-user-data-width-c0" $GT_CH2_TX_USER_DATA_WIDTH_C0 int
	set GT_CH2_TX_USER_DATA_WIDTH_C1 [get_property CONFIG.GT_CH2_TX_USER_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac2_node}" "xlnx,gt-ch2-tx-user-data-width-c1" $GT_CH2_TX_USER_DATA_WIDTH_C1 int

	set mrmac3_base [format 0x%x [expr $base_addr + 0x3000]]
	set mrmac3_base_hex [format %x $mrmac3_base]
	set mrmac3_highaddr_hex [format 0x%x [expr $mrmac3_base + 0xFFF]]
	set port3 3
	append label3 $drv_handle "_" $port3
	set mrmac3_node [add_or_get_dt_node -n "mrmac" -l "$label3" -u $mrmac3_base_hex -d $dts_file -p $bus_node]
	hsi::utils::add_new_dts_param "$mrmac3_node" "compatible" "$compatible" stringlist
	generate_reg_property $mrmac3_node $mrmac3_base $mrmac3_highaddr_hex
	set port3_pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $mrmac_ip] "tx_axis_tdata6"]]
	foreach pin $port3_pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		set mux_ip ""
		set fifo_ip ""
		if {[llength $sink_periph]} {
			if {[string match -nocase [get_property IP_NAME $sink_periph]  "mrmac_10g_mux"]} {
				set mux_ip [hsi::utils::get_connected_stream_ip $sink_periph "s_axis"]
				if {[llength $mux_ip]} {
					if {[string match -nocase [get_property IP_NAME $mux_ip] "axis_data_fifo"]} {
						set fifo_ip [hsi::utils::get_connected_stream_ip $mux_ip "S_AXIS"]
					}
				}
			}
				if {![llength $mux_ip]} {
					set fifo_ip [hsi::utils::get_connected_stream_ip $sink_periph "S_AXIS"]
				}
				if {[llength $fifo_ip]} {
					set fifo_ipname [get_property IP_NAME $fifo_ip]
					if {[string match -nocase $fifo_ipname "axi_mcdma"]} {
						hsi::utils::add_new_dts_param "$mrmac3_node" "axistream-connected" "$fifo_ip" reference
						set num_queues [get_property CONFIG.c_num_mm2s_channels $fifo_ip]
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
						hsi::utils::add_new_dts_param $mrmac3_node "xlnx,channel-ids" $id intlist
					}
					generate_intr_info $drv_handle $mrmac3_node $fifo_ip
				}
		}
	}
	lappend clknames3 "$s_axi_aclk" "$rx_axi_clk3" "$rx_flexif_clk3" "$rx_ts_clk3" "$tx_axi_clk3" "$tx_flexif_clk3" "$tx_ts_clk3"
	set index3 [lindex $clk_list $s_axi_aclk_index0]
	regsub -all "\<&" $index3 {} index3
	regsub -all "\<&" $index3 {} index3
	set txindex3 [lindex $clk_list $tx_ts_clk_index3]
	regsub -all "\>" $txindex3 {} txindex3
	append clkvals3  "$index3,[lindex $clk_list $rx_axi_clk_index3], [lindex $clk_list $rx_flexif_clk_index3], [lindex $clk_list $rx_ts_clk3_index3], [lindex $clk_list $tx_axi_clk_index3], [lindex $clk_list $tx_flexif_clk_index3], $txindex3"
	hsi::utils::add_new_dts_param "${mrmac3_node}" "clocks" $clkvals3 reference
	hsi::utils::add_new_dts_param "${mrmac3_node}" "clock-names" $clknames3 stringlist


	set FEC_SLICE3_CFG_C0 [get_property CONFIG.C_FEC_SLICE3_CFG_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-slice3-cfg-c0" $FEC_SLICE3_CFG_C0 string
	set FEC_SLICE3_CFG_C1 [get_property CONFIG.C_FEC_SLICE3_CFG_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-slice3-cfg-c1" $FEC_SLICE3_CFG_C1 string
	set FLEX_PORT3_DATA_RATE_C0 [get_property CONFIG.C_FLEX_PORT3_DATA_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-port3-data-rate-c0" $FLEX_PORT3_DATA_RATE_C0 string
	set FLEX_PORT3_DATA_RATE_C1 [get_property CONFIG.C_FLEX_PORT3_DATA_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-port3-data-rate-c1" $FLEX_PORT3_DATA_RATE_C1 string
	set FLEX_PORT3_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.C_FLEX_PORT3_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-port3-enable-time-stamping-c0" $FLEX_PORT3_ENABLE_TIME_STAMPING_C0 int
	set FLEX_PORT3_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.C_FLEX_PORT3_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-port3-enable-time-stamping-c1" $FLEX_PORT3_ENABLE_TIME_STAMPING_C1 int
	set FLEX_PORT3_MODE_C0 [get_property CONFIG.C_FLEX_PORT3_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-port3-mode-c0" $FLEX_PORT3_MODE_C0 string
	set FLEX_PORT3_MODE_C1 [get_property CONFIG.C_FLEX_PORT3_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,flex-port3-mode-c1" $FLEX_PORT3_MODE_C1 string
	set PORT3_1588v2_Clocking_C0 [get_property CONFIG.PORT3_1588v2_Clocking_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,port3-1588v2-clocking-c0" $PORT3_1588v2_Clocking_C0 string
	set PORT3_1588v2_Clocking_C1 [get_property CONFIG.PORT3_1588v2_Clocking_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,port3-1588v2-clocking-c1" $PORT3_1588v2_Clocking_C1 string
	set PORT3_1588v2_Operation_MODE_C0 [get_property CONFIG.PORT3_1588v2_Operation_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,port3-1588v2-operation-mode-c0" $PORT3_1588v2_Operation_MODE_C0 string
	set PORT3_1588v2_Operation_MODE_C1 [get_property CONFIG.PORT3_1588v2_Operation_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,port3-1588v2-operation-mode-c1" $PORT3_1588v2_Operation_MODE_C1 string
	set MAC_PORT3_ENABLE_TIME_STAMPING_C0 [get_property CONFIG.MAC_PORT3_ENABLE_TIME_STAMPING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-enable-time-stamping-c0" $MAC_PORT3_ENABLE_TIME_STAMPING_C0 int
	set MAC_PORT3_ENABLE_TIME_STAMPING_C1 [get_property CONFIG.MAC_PORT3_ENABLE_TIME_STAMPING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-enable-time-stamping-c1" $MAC_PORT3_ENABLE_TIME_STAMPING_C1 int
	set MAC_PORT3_RATE_C0 [get_property CONFIG.MAC_PORT3_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rate-c0" $MAC_PORT3_RATE_C0 string
	set MAC_PORT3_RATE_C1 [get_property CONFIG.MAC_PORT3_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rate-c1" $MAC_PORT3_RATE_C1 string
	set MAC_PORT3_RX_ETYPE_GCP_C0 [get_property CONFIG.MAC_PORT3_RX_ETYPE_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gcp-c0" $MAC_PORT3_RX_ETYPE_GCP_C0 int
	set MAC_PORT3_RX_ETYPE_GCP_C1 [get_property CONFIG.MAC_PORT3_RX_ETYPE_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gcp-c1" $MAC_PORT3_RX_ETYPE_GCP_C1 int
	set MAC_PORT3_RX_ETYPE_GPP_C0 [get_property CONFIG.MAC_PORT3_RX_ETYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gpp-c0" $MAC_PORT3_RX_ETYPE_GPP_C0 int
	set MAC_PORT3_RX_ETYPE_GPP_C1 [get_property CONFIG.MAC_PORT3_RX_ETYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gpp-c1" $MAC_PORT3_RX_ETYPE_GPP_C1 int
	set MAC_PORT3_RX_ETYPE_PCP_C0 [get_property CONFIG.MAC_PORT3_RX_ETYPE_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-pcp-c0" $MAC_PORT3_RX_ETYPE_PCP_C0 int
	set MAC_PORT3_RX_ETYPE_PCP_C1 [get_property CONFIG.MAC_PORT3_RX_ETYPE_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-pcp-c1" $MAC_PORT3_RX_ETYPE_PCP_C1 int
	set MAC_PORT3_RX_ETYPE_PPP_C0 [get_property CONFIG.MAC_PORT3_RX_ETYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-ppp-c0" $MAC_PORT3_RX_ETYPE_PPP_C0 int
	set MAC_PORT3_RX_ETYPE_PPP_C1 [get_property CONFIG.MAC_PORT3_RX_ETYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-etype-ppp-c1" $MAC_PORT3_RX_ETYPE_PPP_C1 int
	set MAC_PORT3_RX_FLOW_C0 [get_property CONFIG.MAC_PORT3_RX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-flow-c0" $MAC_PORT3_RX_FLOW_C0 int
	set MAC_PORT3_RX_FLOW_C1 [get_property CONFIG.MAC_PORT3_RX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-flow-c1" $MAC_PORT3_RX_FLOW_C1 int
	set MAC_PORT3_RX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT3_RX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-gpp-c0" $MAC_PORT3_RX_OPCODE_GPP_C0 int
	set MAC_PORT3_RX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT3_RX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-gpp-c1" $MAC_PORT3_RX_OPCODE_GPP_C1 int
	set MAC_PORT3_RX_OPCODE_MAX_GCP_C0 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-gcp-c0" $MAC_PORT3_RX_OPCODE_MAX_GCP_C0 int
	set MAC_PORT3_RX_OPCODE_MAX_GCP_C1 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-gcp-c1" $MAC_PORT3_RX_OPCODE_MAX_GCP_C1 int
	set MAC_PORT3_RX_OPCODE_MAX_PCP_C0 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-pcp-c0" $MAC_PORT3_RX_OPCODE_MAX_PCP_C0 int

	set MAC_PORT3_RX_OPCODE_MAX_PCP_C1 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-pcp-c1" $MAC_PORT3_RX_OPCODE_MAX_PCP_C1 int
	set MAC_PORT3_RX_OPCODE_MIN_GCP_C0 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_GCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-gcp-c0" $MAC_PORT3_RX_OPCODE_MIN_GCP_C0 int
	set MAC_PORT3_RX_OPCODE_MIN_GCP_C1 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_GCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-gcp-c1" $MAC_PORT3_RX_OPCODE_MIN_GCP_C1 int
	set MAC_PORT3_RX_OPCODE_MIN_PCP_C0 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_PCP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-pcp-c0" $MAC_PORT3_RX_OPCODE_MIN_PCP_C0 int
	set MAC_PORT3_RX_OPCODE_MIN_PCP_C1 [get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_PCP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-pcp-c1" $MAC_PORT3_RX_OPCODE_MIN_PCP_C1 int
	set MAC_PORT3_RX_OPCODE_PPP_C0 [get_property CONFIG.MAC_PORT3_RX_OPCODE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-ppp-c0" $MAC_PORT3_RX_OPCODE_PPP_C0 int
	set MAC_PORT3_RX_OPCODE_PPP_C1 [get_property CONFIG.MAC_PORT3_RX_OPCODE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-ppp-c1" $MAC_PORT3_RX_OPCODE_PPP_C1 int
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
	set MAC_PORT3_TX_ETHERTYPE_GPP_C0 [get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-gpp-c0" $MAC_PORT3_TX_ETHERTYPE_GPP_C0 int
	set MAC_PORT3_TX_ETHERTYPE_GPP_C1 [get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-gpp-c1" $MAC_PORT3_TX_ETHERTYPE_GPP_C1 int
	set MAC_PORT3_TX_ETHERTYPE_PPP_C0 [get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_PPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-ppp-c0" $MAC_PORT3_TX_ETHERTYPE_PPP_C0 int
	set MAC_PORT3_TX_ETHERTYPE_PPP_C1 [get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_PPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-ppp-c1" $MAC_PORT3_TX_ETHERTYPE_PPP_C1 int
	set MAC_PORT3_TX_FLOW_C0 [get_property CONFIG.MAC_PORT3_TX_FLOW_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-flow-c0" $MAC_PORT3_TX_FLOW_C0 int
	set MAC_PORT3_TX_FLOW_C1 [get_property CONFIG.MAC_PORT3_TX_FLOW_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-flow-c1" $MAC_PORT3_TX_FLOW_C1 int
	set MAC_PORT3_TX_OPCODE_GPP_C0 [get_property CONFIG.MAC_PORT3_TX_OPCODE_GPP_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-opcode-gpp-c0" $MAC_PORT3_TX_OPCODE_GPP_C0 int
	set MAC_PORT3_TX_OPCODE_GPP_C1 [get_property CONFIG.MAC_PORT3_TX_OPCODE_GPP_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,mac-port3-tx-opcode-gpp-c1" $MAC_PORT2_TX_OPCODE_GPP_C1 int
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
	set GT_CH3_RXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-enable-c0" $GT_CH3_RXPROGDIV_FREQ_ENABLE_C0 string
	set GT_CH3_RXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-enable-c1" $GT_CH3_RXPROGDIV_FREQ_ENABLE_C1 string

	set GT_CH3_RXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-source-c0" $GT_CH3_RXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH3_RXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-source-c1" $GT_CH3_RXPROGDIV_FREQ_SOURCE_C1 string
	set GT_CH3_RXPROGDIV_FREQ_VAL_C0 [get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_VAL_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-val-c0" $GT_CH3_RXPROGDIV_FREQ_VAL_C0 string
	set GT_CH3_RXPROGDIV_FREQ_VAL_C1 [get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_VAL_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-val-c1" $GT_CH3_RXPROGDIV_FREQ_VAL_C1 string
	set GT_CH3_RX_BUFFER_MODE_C0 [get_property CONFIG.GT_CH3_RX_BUFFER_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-buffer-mode-c0" $GT_CH3_RX_BUFFER_MODE_C0 int
	set GT_CH3_RX_BUFFER_MODE_C1 [get_property CONFIG.GT_CH3_RX_BUFFER_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-buffer-mode-c1" $GT_CH3_RX_BUFFER_MODE_C1 int
	set GT_CH3_RX_DATA_DECODING_C0 [get_property CONFIG.GT_CH3_RX_DATA_DECODING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-data-decoding-c0" $GT_CH3_RX_DATA_DECODING_C0 string
	set GT_CH3_RX_DATA_DECODING_C1 [get_property CONFIG.GT_CH3_RX_DATA_DECODING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-data-decoding-c1" $GT_CH3_RX_DATA_DECODING_C1 string


	set GT_CH3_RX_INT_DATA_WIDTH_C0 [get_property CONFIG.GT_CH3_RX_INT_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-int-data-width-c0" $GT_CH3_RX_INT_DATA_WIDTH_C0 int
	set GT_CH3_RX_INT_DATA_WIDTH_C1 [get_property CONFIG.GT_CH3_RX_INT_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-int-data-width-c1" $GT_CH3_RX_INT_DATA_WIDTH_C1 int


	set GT_CH3_RX_LINE_RATE_C0 [get_property CONFIG.GT_CH3_RX_LINE_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-line-rate-c0" $GT_CH3_RX_LINE_RATE_C0 string
	set GT_CH3_RX_LINE_RATE_C1 [get_property CONFIG.GT_CH3_RX_LINE_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-line-rate-c1" $GT_CH3_RX_LINE_RATE_C1 string


	set GT_CH3_RX_OUTCLK_SOURCE_C0 [get_property CONFIG.GT_CH3_RX_OUTCLK_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-outclk-source-c0" $GT_CH3_RX_OUTCLK_SOURCE_C0 string
	set GT_CH3_RX_OUTCLK_SOURCE_C1 [get_property CONFIG.GT_CH3_RX_OUTCLK_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-outclk-source-c1" $GT_CH3_RX_OUTCLK_SOURCE_C1 string


	set GT_CH3_RX_REFCLK_FREQUENCY_C0 [get_property CONFIG.GT_CH3_RX_REFCLK_FREQUENCY_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-refclk-frequency-c0" $GT_CH3_RX_REFCLK_FREQUENCY_C0 string
	set GT_CH3_RX_REFCLK_FREQUENCY_C1 [get_property CONFIG.GT_CH3_RX_REFCLK_FREQUENCY_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-refclk-frequency-c1" $GT_CH3_RX_REFCLK_FREQUENCY_C1 string


	set GT_CH3_RX_USER_DATA_WIDTH_C0 [get_property CONFIG.GT_CH3_RX_USER_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-user-data-width-c0" $GT_CH3_RX_USER_DATA_WIDTH_C0 string
	set GT_CH3_RX_USER_DATA_WIDTH_C1 [get_property CONFIG.GT_CH3_RX_USER_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-rx-user-data-width-c1" $GT_CH3_RX_USER_DATA_WIDTH_C1 string

	set GT_CH3_TXPROGDIV_FREQ_ENABLE_C0 [get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_ENABLE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-enable-c0" $GT_CH3_TXPROGDIV_FREQ_ENABLE_C0 string
	set GT_CH3_TXPROGDIV_FREQ_ENABLE_C1 [get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_ENABLE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-enable-c1" $GT_CH3_TXPROGDIV_FREQ_ENABLE_C1 string


	set GT_CH3_TXPROGDIV_FREQ_SOURCE_C0 [get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-source-c0" $GT_CH3_TXPROGDIV_FREQ_SOURCE_C0 string
	set GT_CH3_TXPROGDIV_FREQ_SOURCE_C1 [get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-source-c1" $GT_CH3_TXPROGDIV_FREQ_SOURCE_C1 string
	
	set GT_CH3_TX_BUFFER_MODE_C0 [get_property CONFIG.GT_CH3_TX_BUFFER_MODE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-buffer-mode-c0" $GT_CH3_TX_BUFFER_MODE_C0 int
	set GT_CH3_TX_BUFFER_MODE_C1 [get_property CONFIG.GT_CH3_TX_BUFFER_MODE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-buffer-mode-c1" $GT_CH3_TX_BUFFER_MODE_C1 int


	set GT_CH3_TX_DATA_ENCODING_C0 [get_property CONFIG.GT_CH3_TX_DATA_ENCODING_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-data-encoding-c0" $GT_CH3_TX_DATA_ENCODING_C0 string
	set GT_CH3_TX_DATA_ENCODING_C1 [get_property CONFIG.GT_CH3_TX_DATA_ENCODING_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-data-encoding-c1" $GT_CH3_TX_DATA_ENCODING_C1 string

	set GT_CH3_TX_INT_DATA_WIDTH_C0 [get_property CONFIG.GT_CH3_TX_INT_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-int-data-width-c0" $GT_CH3_TX_INT_DATA_WIDTH_C0 int
	set GT_CH3_TX_INT_DATA_WIDTH_C1 [get_property CONFIG.GT_CH3_TX_INT_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-int-data-width-c1" $GT_CH3_TX_INT_DATA_WIDTH_C1 int

	set GT_CH3_TX_LINE_RATE_C0 [get_property CONFIG.GT_CH3_TX_LINE_RATE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-line-rate-c0" $GT_CH3_TX_LINE_RATE_C0 string
	set GT_CH3_TX_LINE_RATE_C1 [get_property CONFIG.GT_CH3_TX_LINE_RATE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-line-rate-c1" $GT_CH3_TX_LINE_RATE_C1 string


	set GT_CH3_TX_OUTCLK_SOURCE_C0 [get_property CONFIG.GT_CH3_TX_OUTCLK_SOURCE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-outclk-source-c0" $GT_CH3_TX_OUTCLK_SOURCE_C0 string
	set GT_CH3_TX_OUTCLK_SOURCE_C1 [get_property CONFIG.GT_CH3_TX_OUTCLK_SOURCE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-outclk-source-c1" $GT_CH3_TX_OUTCLK_SOURCE_C1 string


	set GT_CH3_TX_PLL_TYPE_C0 [get_property CONFIG.GT_CH3_TX_PLL_TYPE_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-pll-type-c0" $GT_CH3_TX_PLL_TYPE_C0 string
	set GT_CH3_TX_PLL_TYPE_C1 [get_property CONFIG.GT_CH3_TX_PLL_TYPE_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-pll-type-c1" $GT_CH3_TX_PLL_TYPE_C1 string


	set GT_CH3_TX_REFCLK_FREQUENCY_C0 [get_property CONFIG.GT_CH3_TX_REFCLK_FREQUENCY_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-refclk-frequency-c0" $GT_CH3_TX_REFCLK_FREQUENCY_C0 string
	set GT_CH3_TX_REFCLK_FREQUENCY_C1 [get_property CONFIG.GT_CH3_TX_REFCLK_FREQUENCY_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-refclk-frequency-c1" $GT_CH3_TX_REFCLK_FREQUENCY_C1 string


	set GT_CH3_TX_USER_DATA_WIDTH_C0 [get_property CONFIG.GT_CH3_TX_USER_DATA_WIDTH_C0 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-user-data-width-c0" $GT_CH3_TX_USER_DATA_WIDTH_C0 int
	set GT_CH3_TX_USER_DATA_WIDTH_C1 [get_property CONFIG.GT_CH3_TX_USER_DATA_WIDTH_C1 [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${mrmac3_node}" "xlnx,gt-ch3-tx-user-data-width-c1" $GT_CH3_TX_USER_DATA_WIDTH_C1 int
}

proc generate_reg_property {node base high} {
	set size [format 0x%x [expr {${high} - ${base} + 1}]]

	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
		if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
			set temp $base
			set temp [string trimleft [string trimleft $temp 0] x]
			set len [string length $temp]
			set rem [expr {${len} - 8}]
			set high_base "0x[string range $temp $rem $len]"
			set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
			set low_base [format 0x%08x $low_base]
			if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
				set temp $size
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_size "0x[string range $temp $rem $len]"
				set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_size [format 0x%08x $low_size]
				set reg "$low_base $high_base $low_size $high_size"
			} else {
				set reg "$low_base $high_base 0x0 $size"
			}
		} else {
			set reg "0x0 $base 0x0 $size"
		}
	} else {
		set reg "$base $size"
	}
	hsi::utils::add_new_dts_param "${node}" "reg" $reg inthexlist
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
	set clk_pins [get_pins -of_objects [get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set port_width [::hsi::utils::get_port_width $clk]
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] $clk]]
		if {$port_width >= 2} {
			for {set i 0} { $i < $port_width} {incr i} {
				set peri [::hsi::get_cells -of_objects $pins]
				set mrclk "$clk$i"
				if {[string match -nocase [common::get_property IP_NAME $peri] "xlconcat"]} {
					set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects [get_cells $peri] In$i]] -filter "DIRECTION==O"]
					set clk_peri [::hsi::get_cells -of_objects $pins]
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
					set clk_freq [get_clk_frequency [get_cells -hier $drv_handle] "$clk"]
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
					set clk_freq [get_clk_frequency [get_cells -hier $drv_handle] "$clk"]
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
				set clk_freq [get_clk_frequency [get_cells -hier $drv_handle] "$clk"]
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
			set clk_freq [get_clk_frequency [get_cells -hier $drv_handle] "$clk"]
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
	set len [llength $updat]
	switch $len {
		"1" {
			set refs [lindex $updat 0]
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"2" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"3" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"4" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"5" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"6" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"7" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"8" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"9" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"10" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"11" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"12" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"13" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"14" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"15" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"16" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"17" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"18" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"19" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"20" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"21" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"22" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"23" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"24" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"25" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"26" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"27" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"28" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]>,<&[lindex $updat 27]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"29" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]>,<&[lindex $updat 27]>, <&[lindex $updat 28]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
		"30" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]>,<&[lindex $updat 27]>, <&[lindex $updat 28]>, <&[lindex $updat 29]"
			set_drv_prop $drv_handle "zclocks1" "$refs" reference
		}
	}
}

proc get_clk_frequency {ip_handle portname} {
	set clk ""
	set clkhandle [get_pins -of_objects $ip_handle $portname]
	set width [::hsi::utils::get_port_width $clkhandle]
	if {[string compare -nocase $clkhandle ""] != 0} {
		if {$width >= 2} {
			set clk [get_property CLK_FREQ $clkhandle ]
			regsub -all ":" $clk { } clk
			set clklen [llength $clk]
			if {$clklen > 1} {
				set clk [lindex $clk 0]
			}
		} else {
			set clk [get_property CLK_FREQ $clkhandle ]
		}
	}
	return $clk
}

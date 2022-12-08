#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
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
	set err_irq_en [get_property CONFIG.C_Err_Irq_En [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,err-irq-en" $err_irq_en int
	set tx_frl_refclk_sel [get_property CONFIG.C_TX_FRL_REFCLK_SEL [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,tx-frl-refclk-sel" $tx_frl_refclk_sel int
	set rx_frl_refclk_sel [get_property CONFIG.C_RX_FRL_REFCLK_SEL [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,rx-frl-refclk-sel" $rx_frl_refclk_sel int
	set input_pixels_per_clock [get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,input-pixels-per-clock" $input_pixels_per_clock int
	set nidru [get_property CONFIG.C_NIDRU [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,nidru" $nidru int
	set use_gt_ch4_hdmi [get_property CONFIG.C_Use_GT_CH4_HDMI [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,use-gt-ch4-hdmi" $use_gt_ch4_hdmi int
	set nidru_refclk_sel [get_property CONFIG.C_NIDRU_REFCLK_SEL [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,nidru-refclk-sel" $nidru_refclk_sel int
	set Rx_No_Of_Channels [get_property CONFIG.C_Rx_No_Of_Channels [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,rx-no-of-channels" $Rx_No_Of_Channels int
	set rx_pll_selection [get_property CONFIG.C_RX_PLL_SELECTION [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,rx-pll-selection" $rx_pll_selection int
	set rx_protocol [get_property CONFIG.C_Rx_Protocol [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,rx-protocol" $rx_protocol int
	set rx_refclk_sel [get_property CONFIG.C_RX_REFCLK_SEL [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,rx-refclk-sel" $rx_refclk_sel int
	set tx_pll_selection [get_property CONFIG.C_TX_PLL_SELECTION [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,tx-pll-selection" $tx_pll_selection int
	set tx_protocol [get_property CONFIG.C_Tx_Protocol [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,tx-protocol" $tx_protocol int
	set tx_refclk_sel [get_property CONFIG.C_TX_REFCLK_SEL [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,tx-refclk-sel" $tx_refclk_sel int
	set tx_no_of_channels [get_property CONFIG.C_Tx_No_Of_Channels [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,tx-no-of-channels" $tx_no_of_channels int
	set tx_buffer_bypass [get_property CONFIG.Tx_Buffer_Bypass [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,tx-buffer-bypass" $tx_buffer_bypass int
	set transceiver_width [get_property CONFIG.Transceiver_Width [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-width" $transceiver_width int
	set hdmi_fast_switch [get_property CONFIG.C_Hdmi_Fast_Switch [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,hdmi-fast-switch" $hdmi_fast_switch int
	for {set ch 0} {$ch < $tx_no_of_channels} {incr ch} {
		set phy_node [add_or_get_dt_node -n "vphy_lane@$ch" -l vphy_lane$ch -p $node]
		hsi::utils::add_new_dts_param "$phy_node" "#phy-cells" 4 int
	}
	set transceiver [get_property CONFIG.Transceiver [get_cells -hier $drv_handle]]
	switch $transceiver {
			"GTXE2" {
			        hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-type" 1 int
			}
			"GTHE2" {
			        hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-type" 2 int
			}
			"GTPE2" {
			        hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-type" 3 int
			}
			"GTHE3" {
			        hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-type" 4 int
			}
			"GTHE4" {
			        hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-type" 5 int
			}
			"GTYE4" {
			        hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-type" 6 int
			}
			"GTYE5" {
			        hsi::utils::add_new_dts_param "${node}" "xlnx,transceiver-type" 7 int
			}
	}
	set gt_direction [get_property CONFIG.C_GT_DIRECTION [get_cells -hier $drv_handle]]
	switch $gt_direction {
			"SIMPLEX_TX" {
				hsi::utils::add_new_dts_param "${node}" "xlnx,gt-direction" 1  int
			}
			"SIMPLEX_RX" {
				hsi::utils::add_new_dts_param "${node}" "xlnx,gt-direction" 2  int
			}
			"DUPLEX" {
				hsi::utils::add_new_dts_param "${node}" "xlnx,gt-direction" 3  int
			}
	}
}

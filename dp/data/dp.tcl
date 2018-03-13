#
# (C) Copyright 2014-2015 Xilinx, Inc.
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
	generate_dp_param $drv_handle
}

proc generate_dp_param {drv_handle} {
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
	set zynq_ultra_ps [get_property IP_NAME $periph]
		if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
			set dp_sel [get_property CONFIG.PSU__DP__LANE_SEL [get_cells -hier $periph]]
			set mode [lindex $dp_sel 0]
			set lan_sel [lindex $dp_sel 1]
			set dp_freq [get_property CONFIG.PSU__DP__REF_CLK_FREQ [get_cells -hier $periph]]
			set dp_freq "${dp_freq}000000"
			set ref_clk_list [get_property CONFIG.PSU__DP__REF_CLK_SEL [get_cells -hier $periph]]
			regsub -all {[^0-9]} [lindex $ref_clk_list 1] "" val
			if {[string match -nocase $mode "Single"]} {
				if {[string match -nocase $lan_sel "Lower"]} {
					set lan_name "dp-phy0"
					set lan_phy_type "lane1 5 0 $val $dp_freq"
					set_drv_prop $drv_handle phy-names "$lan_name" stringlist
					set_drv_prop $drv_handle phys "$lan_phy_type" reference
				} else {
					set lan_name "dp-phy0"
					set lan_phy_type "lane3 5 0 $val $dp_freq"
					set_drv_prop $drv_handle phy-names "$lan_name" stringlist
					set_drv_prop $drv_handle phys "$lan_phy_type" reference
				}
				set_drv_prop $drv_handle xlnx,max-lanes 1 int
			} elseif {[string match -nocase $mode "Dual"]} {
				set tab "\n\t\t"
				if {[string match -nocase $lan_sel "Lower"]} {
					set lan0_phy_type "lane1 5 0 $val $dp_freq"
					set lan1_phy_type "lane0 5 1 $val $dp_freq"
					set_drv_prop $drv_handle phy-names "dp-phy0\",\"dp-phy1" stringlist
					set phy_ids "$lan0_phy_type>,${tab}<&$lan1_phy_type"
					set_drv_prop $drv_handle phys "$phy_ids" reference
				} else {
					set lan0_phy_type "lane3 5 0 $val $dp_freq"
					set lan1_phy_type "lane2 5 1 $val $dp_freq"
					set_drv_prop $drv_handle phy-names "dp-phy0\",\"dp-phy1" stringlist
					set phy_ids "$lan0_phy_type>,${tab}<&$lan1_phy_type"
					set_drv_prop $drv_handle phys "$phy_ids" reference
				}
				set_drv_prop $drv_handle xlnx,max-lanes 2 int
			}
		}
	}
	set dp_list "zynqmp_dp_snd_pcm0 zynqmp_dp_snd_pcm1 zynqmp_dp_snd_card0 zynqmp_dp_snd_codec0"
	set dts_file [get_property CONFIG.pcw_dts [get_os]]
	foreach dp_name ${dp_list} {
		set dp_node [add_or_get_dt_node -n "&${dp_name}" -d $dts_file]
		hsi::utils::add_new_dts_param "${dp_node}" "status" "okay" string
	}

}

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

	set check_list "enable-profile enable-trace num-monitor-slots enable-event-count enable-event-log have-sampled-metric-cnt num-of-counters metric-count-width metrics-sample-count-width global-count-width metric-count-scale"
	foreach p ${check_list} {
		set ip_conf [string toupper "c_${p}"]
		regsub -all {\-} $ip_conf {_} ip_conf
		set_drv_conf_prop $drv_handle ${ip_conf} xlnx,${p} hexint
	}
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "psu_cortexa53"] } {
		update_clk_node $drv_handle "s_axi_aclk"
	} elseif {[string match -nocase $proctype "ps7_cortexa9"] } {
		update_zynq_clk_node $drv_handle "s_axi_aclk"
	}
}

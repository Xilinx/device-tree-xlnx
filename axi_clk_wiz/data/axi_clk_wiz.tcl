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
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,clocking-wizard"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ip [get_cells -hier $drv_handle]
	gen_speedgrade $drv_handle
	set output_names "clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7"
	set_property CONFIG.clock-output-names $output_names $drv_handle

	gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
	set sw_proc [get_sw_processor]
	set proc_ip [get_cells -hier $sw_proc]
	set proctype [get_property IP_NAME $proc_ip]
	if {[string match -nocase $proctype "microblaze"] } {
		gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
	}
}

proc gen_speedgrade {drv_handle} {
	set speedgrade [get_property SPEEDGRADE [get_hw_designs]]
	set num [regexp -all -inline -- {[0-9]} $speedgrade]
	if {![string equal $num ""]} {
		hsi::utils::add_new_property $drv_handle "speed-grade" int $num
	}
}

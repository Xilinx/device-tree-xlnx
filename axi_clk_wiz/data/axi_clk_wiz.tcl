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

	set ip [get_cells -hier $drv_handle]
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "ps7_cortexa9"] } {
		set speedgrade "([get_property SPEEDGRADE [get_hw_designs]])"
		if {![string equal $speedgrade "()"]} {
			hsi::utils::add_new_property $drv_handle "speed-grade" int $speedgrade
		}
	}

	set output_names "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7"
	set_property CONFIG.clock-output-names $output_names $drv_handle

	gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
	set sw_proc [get_sw_processor]
	set proc_ip [get_cells -hier $sw_proc]
	set proctype [get_property IP_NAME $proc_ip]
	if {[string match -nocase $proctype "psu_cortexa53"] } {
		update_clk_wiz_node $drv_handle "clk_in1 s_axi_aclk"
	} elseif {[string match -nocase $proctype "ps7_cortexa9"] } {
		update_zynq_clk_wiz_node $drv_handle "clk_in1 s_axi_aclk"
	} elseif {[string match -nocase $proctype "microblaze"] } {
		gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
	}
}
proc update_clk_wiz_node args {
	set drv_handle [lindex $args 0]
	set clk_pins   [lindex $args 1]
	set clocks ""
	set bus_clk_list ""

	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $ip $clk]]]
		set clk_list "pl_clk*"
		set clkk " "
		foreach pin $pins {
			if {[regexp $clk_list $pin match]} {
				set clkk $pin
			}
		}

		switch $clkk {
			"pl_clk0" {
					set pl_clk0 "clk 71"
					set clocks [lappend clocks $pl_clk0]
				}
			"pl_clk1" {
					set pl_clk1 "clk 72"
					set clocks [lappend clocks $pl_clk1]
				}
			"pl_clk2" {
					set pl_clk2 "clk 73"
					set clocks [lappend clocks $pl_clk2]
				}
			"pl_clk3" {
					set pl_clk3 "clk 74"
					set clocks [lappend clocks $pl_clk3]
				}
			default  {
					dtg_warning "clk_wiz:not supported pl_clk:$clkk"
					set dts_file [current_dt_tree]
					set bus_node [add_or_get_bus_node $drv_handle $dts_file]
					set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
					if {![string equal $clk_freq ""]} {
						if {[lsearch $bus_clk_list $clk_freq] < 0} {
							set bus_clk_list [lappend bus_clk_list $clk_freq]
						}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
					set clocks [lappend clocks misc_clk_${bus_clk_cnt}]
					hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
					hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
				}
			}
		}

		append clocknames " " "$clk_pins"
		set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
	}
		set len [llength $clocks]
		switch $len {
			"1" {
				set clk_refs [lindex $clocks 0]
				set_drv_prop $drv_handle "clocks" "$clk_refs" reference
			}
			"2" {
				set clk_refs [lindex $clocks 0]
				append clk_refs ">, <&[lindex $clocks 1]"
				set_drv_prop $drv_handle "clocks" "$clk_refs" reference
			}
		}
}

proc update_zynq_clk_wiz_node args {
	set drv_handle [lindex $args 0]
	set clk_pins   [lindex $args 1]
	set clocks ""

	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $ip $clk]]]
		set clk_list "FCLK_CLK*"
		foreach pin $pins {
			if {[regexp $clk_list $pin match]} {
				set clkk $pin
			}
		}

		switch $clkk {
			"FCLK_CLK0" {
					set fclk_clk0 "clkc 15"
					set clocks [lappend clocks $fclk_clk0]
			}
			"FCLK_CLK1" {
					set fclk_clk1 "clkc 16"
					set clocks [lappend clocks $fclk_clk1]
			}
			"FCLK_CLK2" {
					set fclk_clk2 "clkc 17"
					set clocks [lappend clocks $fclk_clk2]
			}
			"FCLK_CLK3" {
					set fclk_clk3 "clkc 18"
					set clocks [lappend clocks $fclk_clk3]
			}
			default  {
					dtg_warning "clk_wiz:not supported pl_clk:$clkk"
					set dts_file [current_dt_tree]
					set bus_node [add_or_get_bus_node $drv_handle $dts_file]
					set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
					if {![string equal $clk_freq ""]} {
						if {[lsearch $bus_clk_list $clk_freq] < 0} {
							set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
					set clocks [lappend clocks misc_clk_${bus_clk_cnt}]
					hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
					hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
					}
			}
		}
		append clocknames " " "$clk_pins"
		set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
	}

	set len [llength $clocks]
	switch $len {
		"1" {
			set clk_refs [lindex $clocks 0]
			set_drv_prop $drv_handle "clocks" "$clk_refs" reference
		}
		"2" {
			set clk_refs [lindex $clocks 0]
			append clk_refs ">, <&[lindex $clocks 1]"
			set_drv_prop $drv_handle "clocks" "$clk_refs" reference
		}
	}
}

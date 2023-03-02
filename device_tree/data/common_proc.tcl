#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
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

#
# common procedures
#

# global variables
global def_string zynq_soc_dt_tree bus_clk_list pl_ps_irq1 pl_ps_irq0 intrpin_width
set pl_ps_irq1 0
set pl_ps_irq0 0
set intrpin_width 0
set def_string "__def_none"
set zynq_soc_dt_tree "dummy.dtsi"
set bus_clk_list ""
global or_id
global or_cnt
set or_id 0
set or_cnt 0
global set drv_handlers_mapping [dict create]
global set end_mappings [dict create]
global set remote_mappings [dict create]
global set port1_end_mappings [dict create]
global set port2_end_mappings [dict create]
global set port3_end_mappings [dict create]
global set port4_end_mappings [dict create]
global set axis_port1_remo_mappings [dict create]
global set axis_port2_remo_mappings [dict create]
global set axis_port3_remo_mappings [dict create]
global set axis_port4_remo_mappings [dict create]
global set port1_broad_end_mappings [dict create]
global set port2_broad_end_mappings [dict create]
global set port3_broad_end_mappings [dict create]
global set port4_broad_end_mappings [dict create]
global set port5_broad_end_mappings [dict create]
global set port6_broad_end_mappings [dict create]
global set broad_port1_remo_mappings [dict create]
global set broad_port2_remo_mappings [dict create]
global set broad_port3_remo_mappings [dict create]
global set broad_port4_remo_mappings [dict create]
global set broad_port5_remo_mappings [dict create]
global set broad_port6_remo_mappings [dict create]
global set axis_switch_in_end_mappings [dict create]
global set axis_switch_port1_end_mappings [dict create]
global set axis_switch_port2_end_mappings [dict create]
global set axis_switch_port3_end_mappings [dict create]
global set axis_switch_port4_end_mappings [dict create]
global set axis_switch_in_remo_mappings [dict create]
global set axis_switch_port1_remo_mappings [dict create]
global set axis_switch_port2_remo_mappings [dict create]
global set axis_switch_port3_remo_mappings [dict create]
global set axis_switch_port4_remo_mappings [dict create]


proc get_clock_frequency {ip_handle portname} {
	set clk ""
	set clkhandle [get_pins -of_objects $ip_handle $portname]
	if {[string compare -nocase $clkhandle ""] != 0} {
		set clk [get_property CLK_FREQ $clkhandle ]
	}
	return $clk
}

proc set_drv_property args {
	set drv_handle [lindex $args 0]
	set conf_prop [lindex $args 1]
	set value [lindex $args 2]
	if {[llength $value] !=0} {
		if {$value != "-1" && [llength $value] !=0} {
			set type "hexint"
			if {[llength $args] >= 4} {
				set type [lindex $args 3]
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
			}
			# remove CONFIG. as add_new_property does not work with CONFIG.
			regsub -all {^CONFIG.} $conf_prop {} conf_prop
			hsi::utils::add_new_property $drv_handle $conf_prop $type $value
		}
	}
}

# set driver property based on IP property
proc set_drv_conf_prop args {
	set drv_handle [lindex $args 0]
	set pram [lindex $args 1]
	set conf_prop [lindex $args 2]
	set ip [get_cells -hier $drv_handle]
	set value [get_property CONFIG.${pram} $ip]
	if {[llength $value] !=0} {
		regsub -all "MIO( |)" $value "" value
		if {$value != "-1" && [llength $value] !=0} {
			set type "hexint"
			if {[llength $args] >= 4} {
				set type [lindex $args 3]
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
			}
			regsub -all {^CONFIG.} $conf_prop {} conf_prop
			hsi::utils::add_new_property $drv_handle $conf_prop $type $value
		}
	}
}

# set driver property based on other IP's property
proc add_cross_property args {
	set src_handle [lindex $args 0]
	set src_prams [lindex $args 1]
	set dest_handle [lindex $args 2]
	set dest_prop [lindex $args 3]
	set ip [get_cells -hier $src_handle]
	set ipname [get_property IP_NAME $ip]

	foreach conf_prop $src_prams {
		set value [get_property ${conf_prop} $ip]
		if {$conf_prop == "CONFIG.processor_mode"} {
			set value "true"
		}
		if {$ipname == "axi_ethernet"} {
			set value [is_property_set $value]
		}
		if {[llength $value]} {
			if {$value != "-1" && [llength $value] !=0} {
				set type "hexint"
				if {[llength $args] >= 5} {
					set type [lindex $args 4]
				}
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
				if {[regexp "(int|hex).*" $type match]} {
					regsub -all {"} $value "" value
				}
				set ipname [get_property IP_NAME [get_cells -hier $ip]]
				if {[string match -nocase $ipname "axi_mcdma"] && [string match -nocase $dest_prop "xlnx,include-sg"] } {
					set type "boolean"
					set value ""
				}
				if {[regexp -nocase {0x([0-9a-f]{9})} "$value" match]} {
					set temp $value
					set temp [string trimleft [string trimleft $temp 0] x]
					set len [string length $temp]
					set rem [expr {${len} - 8}]
					set high_base "0x[string range $temp $rem $len]"
					set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
					set low_base [format 0x%08x $low_base]
					set value "$low_base $high_base"
				}
				hsi::utils::add_new_property $dest_handle $dest_prop $type $value
				return 0
			}
		}
	}
}

# TODO: merge to add_cross_property by detecting if dest_node is dt node or driver
proc add_cross_property_to_dtnode args {
	set src_handle [lindex $args 0]
	set src_prams [lindex $args 1]
	set dest_node [lindex $args 2]
	set dest_prop [lindex $args 3]
	set ip [get_cells -hier $src_handle]
	foreach conf_prop $src_prams {
		set value [get_property ${conf_prop} $ip]
		if {[llength $value]} {
			if {$value != "-1" && [llength $value] !=0} {
				set type "hexint"
				if {[llength $args] >= 5} {
					set type [lindex $args 4]
				}
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
				if {[regexp "(int|hex).*" $type match]} {
					regsub -all {"} $value "" value
				}
				hsi::utils::add_new_dts_param $dest_node $dest_prop $value $type
				return 0
			}
		}
	}
}

proc get_ip_property {drv_handle parameter} {
	set ip [get_cells -hier $drv_handle]
	return [get_property ${parameter} $ip]
}

proc is_it_in_pl {ip} {
	# FIXME: This is a workaround to check if IP that's in PL however,
	# this is not entirely correct, it is a hack and only works for
	# IP_NAME that does not matches ps7_*
	# better detection is required

	# handles interrupt that coming from get_drivers only
	if {[llength [get_drivers $ip]] < 1} {
		return -1
	}
	set ip_type [get_property IP_NAME $ip]
	if {![regexp "ps*" "$ip_type" match]} {
		return 1
	}
	return -1
}

proc get_intr_id {drv_handle intr_port_name} {
	set slave [get_cells -hier $drv_handle]
	set intr_info ""
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	foreach pin ${intr_port_name} {
		set intc [::hsi::utils::get_interrupt_parent $drv_handle $pin]
		if {[string_is_empty $intc] == 1} {continue}
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			if {[llength $intc] > 1} {
				foreach intr_cntr $intc {
					if { [::hsi::utils::is_ip_interrupting_current_proc $intr_cntr] } {
						set intc $intr_cntr
					}
				}
			}
			if {[string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "psu_cortexa53"] && [string match -nocase $intc "axi_intc"] } {
				set intc [::hsi::utils::get_interrupt_parent $drv_handle $pin]
			}
			if {[string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "psv_cortexa72"] && [string match -nocase $intc "axi_intc"] } {
				set intc [::hsi::utils::get_interrupt_parent $drv_handle $pin]
			}
			if {[string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "psx_cortexa78"] && [string match -nocase $intc "axi_intc"] } {
				set intc [::hsi::utils::get_interrupt_parent $drv_handle $pin]
			}
		}
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			set intr_id [get_psu_interrupt_id $drv_handle $pin]
		} else {
			set intr_id [::hsi::utils::get_interrupt_id $drv_handle $pin]
		}
		if {[string match -nocase $intr_id "-1"]} {continue}
		set intr_type [get_intr_type $intc $slave $pin]
		if {[string match -nocase $intr_type "-1"]} {
			continue
		}

		set cur_intr_info ""
		if { [string match -nocase $proctype "ps7_cortexa9"] }  {
			if {[string match "[get_property IP_NAME $intc]" "ps7_scugic"] } {
				if {$intr_id > 32} {
					set intr_id [expr $intr_id - 32]
				}
				set cur_intr_info "0 $intr_id $intr_type"
			} elseif {[string match "[get_property IP_NAME $intc]" "axi_intc"] } {
				set cur_intr_info "$intr_id $intr_type"
			}
		} elseif {[string match -nocase $intc "psu_acpu_gic"]|| [string match -nocase [get_property IP_NAME $intc] "psv_acpu_gic"]} {
		    set cur_intr_info "0 $intr_id $intr_type"
		} else {
			set cur_intr_info "$intr_id $intr_type"
		}

		if {[string_is_empty $intr_info]} {
			set intr_info "$cur_intr_info"
		} else {
			append intr_info " " $cur_intr_info
		}
	}

	if {[string_is_empty $intr_info]} {
		set intr_info -1
	}

	return $intr_info
}

proc dtg_debug msg {
	return
	puts "# [lindex [info level -1] 0] #>> $msg"
}

proc dtg_verbose msg {
	set verbose [get_property CONFIG.dt_verbose [get_os]]
	if {$verbose} {
		puts "VERBOSE: $msg"
	}
}

proc dtg_warning msg {
	puts "WARNING: $msg"
}

proc proc_called_by {} {
	return
	puts "# [lindex [info level -1] 0] #>> called by [lindex [info level -2] 0]"
}

proc Pop {varname {nth 0}} {
	upvar $varname args
	set r [lindex $args $nth]
	set args [lreplace $args $nth $nth]
	return $r
}

proc string_is_empty {input} {
	if {[string compare -nocase $input ""] != 0} {
		return 0
	}
	return 1
}

proc gen_dt_node_search_pattern args {
	proc_called_by
	# generates device tree node search pattern and return it

	global def_string
	foreach var {node_name node_label node_unit_addr} {
		set ${var} ${def_string}
	}
	while {[string match -* [lindex $args 0]]} {
		switch -glob -- [lindex $args 0] {
			-n* {set node_name [Pop args 1]}
			-l* {set node_label [Pop args 1]}
			-u* {set node_unit_addr [Pop args 1]}
			-- {Pop args ; break}
			default {
				error "gen_dt_node_search_pattern bad option - [lindex $args 0]"
			}
		}
		Pop args
	}
	set pattern ""
	# TODO: is these search patterns correct
	# TODO: check if pattern in the list or not
	if {![string equal -nocase ${node_label} ${def_string}] && \
		![string equal -nocase ${node_name} ${def_string}] && \
		![string equal -nocase ${node_unit_addr} ${def_string}]} {
		lappend pattern "^${node_label}:${node_name}@${node_unit_addr}$"
		lappend pattern "^${node_name}@${node_unit_addr}$"
	}

	if {![string equal -nocase ${node_label} ${def_string}] && \
		![string equal -nocase ${node_name} ${def_string}]} {
		lappend pattern "^${node_label}:${node_name}"
	}

	if {![string equal -nocase ${node_name} ${def_string}] && \
		![string equal -nocase ${node_unit_addr} ${def_string}]} {
		lappend pattern "^${node_name}@${node_unit_addr}$"
	}

	if {![string equal -nocase ${node_label} ${def_string}]} {
		lappend pattern "^&${node_label}$"
		lappend pattern "^${node_label}:"
	}

	return $pattern
}

proc set_cur_working_dts {{dts_file ""}} {
	# set current working device tree
	# return the tree object
	proc_called_by
	if {[string_is_empty ${dts_file}] == 1} {
		return [current_dt_tree]
	}
	set dt_idx [lsearch [get_dt_trees] ${dts_file}]
	if {$dt_idx >= 0} {
		set dt_tree_obj [current_dt_tree [lindex [get_dt_trees] $dt_idx]]
	} else {
		set dt_tree_obj [create_dt_tree -dts_file $dts_file]
	}
	return $dt_tree_obj
}

proc get_baseaddr {slave_ip {no_prefix ""}} {
	# only returns the first addr
	set ip_mem_handle [lindex [hsi::utils::get_ip_mem_ranges [get_cells -hier $slave_ip]] 0]
	if { [string_is_empty $ip_mem_handle] } {
		return -1
	}
	set addr [string tolower [get_property BASE_VALUE $ip_mem_handle]]
	if {![string_is_empty $no_prefix]} {
		regsub -all {^0x} $addr {} addr
	}
	return $addr
}

proc get_highaddr {slave_ip {no_prefix ""}} {
	set ip_mem_handle [lindex [hsi::utils::get_ip_mem_ranges [get_cells -hier $slave_ip]] 0]
	set addr [string tolower [get_property HIGH_VALUE $ip_mem_handle]]
	if {![string_is_empty $no_prefix]} {
		regsub -all {^0x} $addr {} addr
	}
	return $addr
}

proc get_all_tree_nodes {dts_file} {
	# Workaround for -hier not working with -of_objects
	# get all the nodes presented in a dt_tree and return node list
	proc_called_by
	set cur_dts [current_dt_tree]
	current_dt_tree $dts_file
	set all_nodes [get_dt_nodes -hier]
	current_dt_tree $cur_dts
	return $all_nodes
}

proc check_node_in_dts {node_name dts_file_list} {
	# check if the node is in the device-tree file
	# return 1 if found
	# return 0 if not found
	proc_called_by
	foreach tmp_dts_file ${dts_file_list} {
		set dts_nodes [get_all_tree_nodes $tmp_dts_file]
		# TODO: better detection here
		foreach pattern ${node_name} {
			foreach node ${dts_nodes} {
				if {[regexp $pattern $node match]} {
					dtg_debug "Node $node ($pattern) found in $tmp_dts_file"
					return 1
				}
			}
		}
	}
	return 0
}

proc get_node_object {lu_node {dts_files ""} {error_out "yes"}} {
	# get the node object based on the args
	# returns the dt node object
	proc_called_by
	if [string_is_empty $dts_files] {
		set dts_files [get_dt_trees]
	}
	set cur_dts [current_dt_tree]
	foreach dts_file ${dts_files} {
		set dts_nodes [get_all_tree_nodes $dts_file]
		foreach node ${dts_nodes} {
			if {[regexp $lu_node $node match]} {
				set node_data [split $node ":"]
				set node_label [lindex $node_data 0]
				set lu_node_data [split $lu_node ":"]
				set lu_node_label [lindex $lu_node_data 0]
				if {![string match -nocase "$node_label" "$lu_node_label"]} {
					continue
				}
				# workaround for -hier not working with -of_objects
				current_dt_tree $dts_file
				set node_obj [get_dt_nodes -hier $node]
				current_dt_tree $cur_dts
				return $node_obj
			}
		}
	}
	if {[string_is_empty $error_out]} {
		return ""
	} else {
		error "Failed to find $lu_node node !!!"
	}
}

proc update_dt_parent args {
	# update device tree node's parent
	# return the node name
	proc_called_by
	global def_string
	set node [lindex $args 0]
	set new_parent [lindex $args 1]
	if {[llength $args] >= 3} {
		set dts_file [lindex $args 2]
	} else {
		set dts_file [current_dt_tree]
	}
	set node [get_node_object $node $dts_file]
	# Skip if node is a reference node (start with &) or amba
	if {[regexp "^&.*" "$node" match] || [regexp "amba_apu" "$node" match] || [regexp "amba" "$node" match]} {
		return $node
	}

	if {[string_is_empty $new_parent] || \
		[string equal ${def_string} "$new_parent"]} {
		return $node
	}

	# Currently the PARENT node must within the same dt tree
	if {![check_node_in_dts $new_parent $dts_file]} {
		error "Node '$node' is not in $dts_file tree"
	}

	set cur_parent [get_property PARENT $node]
	# set new parent if required
	if {![string equal -nocase ${cur_parent} ${new_parent}] && [string_is_empty ${new_parent}] == 0} {
		dtg_debug "Update parent to $new_parent"
		set_property PARENT "${new_parent}" $node
	}
	return $node
}

proc get_all_dt_labels {{dts_files ""}} {
	# get all dt node labels
	set cur_dts [current_dt_tree]
	set labels ""
	if [string_is_empty $dts_files] {
		set dts_files [get_dt_trees]
	}
	foreach dts_file ${dts_files} {
		set dts_nodes [get_all_tree_nodes $dts_file]
		foreach node ${dts_nodes} {
			set node_label [get_property "NODE_LABEL" $node]
			if {[string_is_empty $node_label]} {
				continue
			}
			lappend labels $node_label
		}
	}
	current_dt_tree $cur_dts
	return $labels
}

proc list_remove_element {cur_list elements} {
	foreach e ${elements} {
		set rm_idx [lsearch $cur_list $e]
		set cur_list [lreplace $cur_list $rm_idx $rm_idx]
	}
	return $cur_list
}

proc update_overlay_custom_dts_include {include_file overlay_custom_dts} {
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	set overlay_custom_dts_obj [get_dt_trees ${overlay_custom_dts}]
	if {[string_is_empty $overlay_custom_dts_obj] == 1} {
		set overlay_custom_dts_obj [set_cur_working_dts ${overlay_custom_dts}]
	}
	if {[string equal ${include_file} ${overlay_custom_dts_obj}]} {
		return 0
	}
	set cur_inc_list [get_property INCLUDE_FILES $overlay_custom_dts_obj]
	set tmp_list [split $cur_inc_list ","]
	if { [lsearch $tmp_list $include_file] < 0} {
		if {[string_is_empty $cur_inc_list]} {
			set cur_inc_list $include_file
		} else {
			append cur_inc_list "," $include_file
			set field [split $cur_inc_list ","]
			set cur_inc_list [lsort -decreasing $field]
			set cur_inc_list [join $cur_inc_list ","]
		}
		set_property INCLUDE_FILES ${cur_inc_list} $overlay_custom_dts_obj
	}
}

proc update_system_dts_include {include_file} {
	# where should we get master_dts data
	set master_dts [get_property CONFIG.master_dts [get_os]]
	set cur_dts [current_dt_tree]
	set master_dts_obj [get_dt_trees ${master_dts}]
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "microblaze"]} {
		set overrides [get_property CONFIG.periph_type_overrides [get_os]]
		set dtsi_file " "
		foreach override $overrides {
			if {[lindex $override 0] == "BOARD"} {
				set dtsi_file [lindex $override 1]
			}
		}
	}

	if {[string_is_empty $master_dts_obj] == 1} {
		set master_dts_obj [set_cur_working_dts ${master_dts}]
	}
	if {[string equal ${include_file} ${master_dts_obj}]} {
		return 0
	}
	set cur_inc_list [get_property INCLUDE_FILES $master_dts_obj]
	set tmp_list [split $cur_inc_list ","]
	if { [lsearch $tmp_list $include_file] < 0} {
		if {[string_is_empty $cur_inc_list]} {
			set cur_inc_list $include_file
		} else {
			if {[string match -nocase $proctype "microblaze"]} {
				append cur_inc_list "," $include_file
				set field [split $cur_inc_list ","]
				if {[regexp $dtsi_file $include_file match]} {
				} else {
					set cur_inc_list [lsort -decreasing $field]
					set cur_inc_list [join $cur_inc_list ","]
				}
			} else {
				append cur_inc_list "," $include_file
				set field [split $cur_inc_list ","]
				set cur_inc_list [lsort -decreasing $field]
				set cur_inc_list [join $cur_inc_list ","]
			}
		}
		set_property INCLUDE_FILES ${cur_inc_list} $master_dts_obj
	}

	# set dts version
	set dts_ver [get_property DTS_VERSION $master_dts_obj]
	if {[string_is_empty $dts_ver]} {
		set_property DTS_VERSION "/dts-v1/" $master_dts_obj
	}

	set_cur_working_dts $cur_dts
}

proc get_rp_rm_for_drv {drv_handle} {
	set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
	set rmName ""
	foreach pr_region $pr_regions {
		set is_dfx [get_property CONFIG.ENABLE_DFX [hsi::get_cells -hier $pr_region]]
		if {[llength $is_dfx] && $is_dfx == 0} {
			return ""
		}
		set rmName [get_property RECONFIG_MODULE_NAME [hsi::get_cells -hier $pr_region]]
		set inst [hsi::current_hw_instance [hsi::get_cells -hier $pr_region]]
		set drv [hsi::get_cells $drv_handle]
		::hsi::current_hw_instance
		if {[llength $drv] != 0} {
			append rpName "$inst" "_" "$rmName"
			return $rpName

		}
	}
}

proc get_rm_names {pr} {
        set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
        set rm_names {}
        foreach pr_region $pr_regions {
		if {[regexp $pr $pr_region match]} {
			set rm_name [get_property RECONFIG_MODULE_NAME [hsi::get_cells -hier $pr_region]]
		}
        }
        return $rm_name
}

proc set_drv_def_dts {drv_handle} {
	# optional dts control by adding the following line in mdd file
	# PARAMETER name = def_dts, default = ps.dtsi, type = string;
	set default_dts [get_property CONFIG.def_dts $drv_handle]
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	set partial_image [get_property CONFIG.partial_image [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return
	}
	global bus_clk_list
	if {[string_is_empty $default_dts]} {
		if {[is_pl_ip $drv_handle]} {
			set RpRm [get_rp_rm_for_drv $drv_handle]
			regsub -all { } $RpRm "" RpRm
			if {[llength $RpRm]} {
				set default_dts "pl-partial-$RpRm.dtsi"
			} else {
				set default_dts "pl.dtsi"
			}
		} else {
			# PS IP, read pcw_dts property
			set default_dts [get_property CONFIG.pcw_dts [get_os]]
		}
	}
	set default_dts [set_cur_working_dts $default_dts]
	if {$dt_overlay } {
		set RpRm [get_rp_rm_for_drv $drv_handle]
		if {[llength $RpRm]} {
			if {$partial_image} {
				regsub -all { } $RpRm "" RpRm
				set partial_imag imag
				append RpRm1 $RpRm $partial_imag
				set defaultdts1 "pl-partial-$RpRm1.dtsi"
				set defdt [create_dt_tree -dts_file $defaultdts1]
				set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
				set_property DTS_VERSION "/dts-v1/;\n/plugin/" $defdt
				if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
					set targets "fpga"
				} else {
					set targets "fpga_full"
				}
				set fpga_node [add_or_get_dt_node -n "&$targets" -d ${defdt}]
				set child_node1 "$fpga_node"
				set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
				if {[llength $pr_regions]} {
					set pr_len [llength $pr_regions]
					for {set pr 0} {$pr < $pr_len} {incr pr} {
						set pr1 [lindex $pr_regions $pr]
						if {[regexp $pr1 $RpRm match]} {
							set targets "fpga_PR$pr"
							hsi::utils::add_new_dts_param $fpga_node target "$targets" reference
							break
						}
					}
				}
				set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
				hsi::utils::add_new_dts_param "${child_node1}" "#address-cells" 2 int
				hsi::utils::add_new_dts_param "${child_node1}" "#size-cells" 2 int
				if {[string match -nocase $proctype "psu_cortexa53"]} {
					set hw_name [::hsi::get_hw_files -filter "TYPE == partial_bit"]
				} else {
					set hw_name [::hsi::get_hw_files -filter "TYPE == partial_pdi"]
				}
				hsi::utils::add_new_dts_param "${child_node1}" "firmware-name" "$hw_name.bin" string
				if {[string match -nocase $default_dts "pl-partial-$RpRm.dtsi"]} {
					set_property DTS_VERSION "/dts-v1/;\n/plugin/" $default_dts
					set child_node " "
				}
			}
		}

	if {![llength $RpRm]} {
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		set default_dt "pl.dtsi"
		set defaultdts [set_cur_working_dts $default_dt]
		set master_dts [get_dt_trees ${defaultdts}]
		set_property DTS_VERSION "/dts-v1/;\n/plugin/" $master_dts
		if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			set targets "fpga"
		} else {
			set targets "fpga_full"
		}
		set fpga_node [add_or_get_dt_node -n "&$targets" -d ${defaultdts}]
		set child_node $fpga_node
		if 0 {
		set ips [get_cells -hier -filter {IP_NAME == "dfx_decoupler"}]
		set dfx_node ""
		foreach ip $ips {
			if {[llength $ip]} {
				set dfx_ip [get_property IP_NAME $ip]
				set unit_addr [get_baseaddr ${ip} no_prefix]
				if { [string equal $unit_addr "-1"] } {
					break
				}
				set label $ip
				set dev_type [get_property IP_NAME [get_cell -hier [get_cells -hier $ip]]]
				set dfx_node [add_or_get_dt_node -n ${dev_type} -l ${label} -u $unit_addr -d ${defaultdts} -p $child_node -auto_ref_parent]
				set compatible [get_comp_str $ip]
				hsi::utils::add_new_dts_param "$dfx_node" "compatible" "$compatible" string
				set xdevice_family [get_property CONFIG.C_XDEVICEFAMILY [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_node" "xlnx,xdevicefamily" $xdevice_family string
				gen_dfx_reg_property $ip $dfx_node
				gen_dfx_clk_property $ip $defaultdts $child_node $dfx_node
				set intf [::hsi::get_intf_pins -of_objects $ip "rp_intf_0"]
				set intf_net [::hsi::get_intf_pins -of_objects [::hsi::get_intf_nets -of_objects $intf]]
				set pr [get_cells -of_objects [lindex $intf_net 1]]
				set pr_type [get_property BD_TYPE [get_cells -hier $pr]]
				set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
				if {[llength $pr_regions]} {
					set prlen [llength $pr_regions]
					for {set dfx 0} {$dfx < $prlen} {incr dfx} {
						if {[string match -nocase "[lindex $pr_regions $dfx]" "$pr"]} {
							set prnode [add_or_get_dt_node -l "fpga_PR$dfx" -n "fpga-PR$dfx" -p $dfx_node]
							hsi::utils::add_new_dts_param  "${prnode}" "compatible"  "fpga-region" string
			                                hsi::utils::add_new_dts_param "${prnode}" "#address-cells" 2 int
							hsi::utils::add_new_dts_param "${prnode}" "#size-cells" 2 int
							hsi::utils::add_new_dts_param "${prnode}" "ranges" "" boolean
						}
					}
				}
			}
		}
		set ips [get_cells -hier -filter {IP_NAME == "dfx_axi_shutdown_manager"}]
		set dfx_sm_node ""
		foreach ip $ips {
			if {[llength $ip]} {
				set dfx_sm_ip [get_property IP_NAME $ip]
				set unit_addr [get_baseaddr ${ip} no_prefix]
				if { [string equal $unit_addr "-1"] } {
					break
				}
				set label $ip
				set dev_type [get_property IP_NAME [get_cell -hier [get_cells -hier $ip]]]
				set dfx_sm_node [add_or_get_dt_node -n ${dev_type} -l ${label} -u $unit_addr -d ${defaultdts} -p $child_node -auto_ref_parent]
				set compatible [get_comp_str $ip]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "compatible" "$compatible" string
				set ctrl_addr_width [get_property CONFIG.C_CTRL_ADDR_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,ctrl-addr-width" $ctrl_addr_width int
				set ctrl_data_width [get_property CONFIG.C_CTRL_DATA_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,ctrl-data-width" $ctrl_data_width int
				set ctrl_interface_type [get_property CONFIG.C_CTRL_INTERFACE_TYPE [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,ctrl-interface-type" $ctrl_interface_type int
				set dp_axi_addr_width [get_property CONFIG.C_DP_AXI_ADDR_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-addr-width" $dp_axi_addr_width int
				set dp_axi_aruser_width [get_property CONFIG.C_DP_AXI_ARUSER_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-aruser-width" $dp_axi_aruser_width int
				set dp_axi_awuser_width [get_property CONFIG.C_DP_AXI_AWUSER_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-awuser-width" $dp_axi_awuser_width int
				set dp_axi_buser_width [get_property CONFIG.C_DP_AXI_BUSER_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-buser-width" $dp_axi_buser_width int
				set dp_axi_data_width [get_property CONFIG.C_DP_AXI_DATA_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-data-width" $dp_axi_data_width int
				set dp_axi_id_width [get_property CONFIG.C_DP_AXI_ID_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-id-width" $dp_axi_id_width int
				set dp_axi_resp [get_property CONFIG.C_DP_AXI_RESP [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-resp" $dp_axi_resp int
				set dp_axi_ruser_width [get_property CONFIG.C_DP_AXI_RUSER_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-ruser-width" $dp_axi_ruser_width int
				set dp_axi_wuser_width [get_property CONFIG.C_DP_AXI_WUSER_WIDTH [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-axi-wuser-width" $dp_axi_wuser_width int
				set dp_protocol [get_property CONFIG.C_DP_PROTOCOL [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,dp-protocol" $dp_protocol string
				set reset_active_level [get_property CONFIG.C_RESET_ACTIVE_LEVEL [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,reset-active-level" $reset_active_level int
				set rp_is_master [get_property CONFIG.C_RP_IS_MASTER [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,rp-is-master" $rp_is_master int
				set family [get_property CONFIG.C_FAMILY [get_cells -hier $ip]]
				hsi::utils::add_new_dts_param "$dfx_sm_node" "xlnx,family" $family string
				gen_dfx_reg_property $ip $dfx_sm_node
				gen_dfx_clk_property $ip $defaultdts $child_node $dfx_sm_node
				set intf [::hsi::get_intf_pins -of_objects $ip "M_AXI"]
				set intf_net [::hsi::get_intf_pins -of_objects [::hsi::get_intf_nets -of_objects $intf]]
				set pr [get_cells -of_objects [lindex $intf_net 1]]
				set pr_type [get_property BD_TYPE [get_cells -hier $pr]]
				set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
				if {[llength $pr_regions]} {
                                        set prlen [llength $pr_regions]
					for {set dfx 0} {$dfx < $prlen} {incr dfx} {
						if {[string match -nocase "[lindex $pr_regions $dfx]" "$pr"]} {
							set prnode [add_or_get_dt_node -l "fpga_PR$dfx" -n "fpga-PR$dfx" -p $dfx_sm_node]
							hsi::utils::add_new_dts_param  "${prnode}" "compatible"  "fpga-region" string
							hsi::utils::add_new_dts_param "${prnode}" "#address-cells" 2 int
							hsi::utils::add_new_dts_param "${prnode}" "#size-cells" 2 int
							hsi::utils::add_new_dts_param "${prnode}" "ranges" "" boolean
						}
					}
				}
			}
		}

		if {![llength $dfx_node] && ![llength $dfx_sm_node]} {
		}
		}
		set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
		set classic_soc [get_property CONFIG.classic_soc [get_os]]
		if {[llength $pr_regions]} {
			set pr_len [llength $pr_regions]
			for {set pr 0} {$pr < $pr_len} {incr pr} {
				set pr_node [add_or_get_dt_node -l "fpga_PR$pr" -n "fpga-PR$pr" -p $child_node]
				hsi::utils::add_new_dts_param  "${pr_node}" "compatible"  "fpga-region" string
				hsi::utils::add_new_dts_param "${pr_node}" "#address-cells" 2 int
				hsi::utils::add_new_dts_param "${pr_node}" "#size-cells" 2 int
				hsi::utils::add_new_dts_param "${pr_node}" "ranges" "" boolean
			}
		}
		set hw_name [get_property CONFIG.firmware_name [get_os]]
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "ps7_cortexa9"]} {
			if {![llength $hw_name]} {
				set hw_name [::hsi::get_hw_files -filter "TYPE == bit"]
			}
			hsi::utils::add_new_dts_param "${child_node}" "firmware-name" "$hw_name.bin" string
		}
		set UID [get_property HW_DESIGN_ID [hsi::current_hw_design]]
		set PID [get_property HW_PARENT_ID [hsi::current_hw_design]]
		if {[string match -nocase $proctype "psv_cortexa72"]} {
			if {![llength $hw_name]} {
				set hw_name [::hsi::get_hw_files -filter "TYPE == pdi"]
			}
			if {!$classic_soc} {
				hsi::utils::add_new_dts_param "${child_node}" "external-fpga-config" "" boolean
			}
		}
		if {[llength $UID]} {
			hsi::utils::add_new_dts_param "${child_node}" "uid" $UID int
		}
		if {[llength $PID]} {
			hsi::utils::add_new_dts_param "${child_node}" "pid" $PID int
		}
		}
	}

	if {[is_pl_ip $drv_handle] && $dt_overlay} {
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			set targets "fpga"
		} else {
			set targets "fpga_full"
		}
		set hw_name [::hsi::get_hw_files -filter "TYPE == pl_pdi"]
		if {[llength $hw_name]} {
			hsi::utils::add_new_dts_param "${child_node}" "#address-cells" 2 int
			hsi::utils::add_new_dts_param "${child_node}" "#size-cells" 2 int
			hsi::utils::add_new_dts_param "${child_node}" "firmware-name" "$hw_name" string
		}
		set RpRm [get_rp_rm_for_drv $drv_handle]
		regsub -all { } $RpRm "" RpRm
		if {[llength $RpRm]} {
			if {$partial_image} {
                                puts "frag0 ret"
			} else {
				set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
				set default_dts "pl-partial-$RpRm.dtsi"
				set master_dts_obj [get_dt_trees ${default_dts}]
				set_property DTS_VERSION "/dts-v1/;\n/plugin/" $master_dts_obj
				set fpga_node [add_or_get_dt_node -n "&$targets" -d ${default_dts}]
				set child_node2 "$fpga_node"
				set classic_soc [get_property CONFIG.classic_soc [get_os]]
				if {$classic_soc} {
					hsi::utils::add_new_dts_param "${child_node2}" "#address-cells" 2 int
					hsi::utils::add_new_dts_param "${child_node2}" "#size-cells" 2 int
				}
				set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
				if {[llength $pr_regions]} {
					set pr_len [llength $pr_regions]
					for {set pr 0} {$pr < $pr_len} {incr pr} {
						set pr1 [lindex $pr_regions $pr]
						if {[regexp $pr1 $RpRm match]} {
							set targets "fpga_PR$pr"
							if {$classic_soc} {
								set targets "fpga"
							}
							break
						}
					}
				}
				if {!$classic_soc} {
					hsi::utils::add_new_dts_param $child_node2 "partial-fpga-config" "" boolean
				}
				if {[llength $pr_regions]} {
					set pr_len [llength $pr_regions]
					for {set pr 0} {$pr < $pr_len} {incr pr} {
						set pr0 [lindex $pr_regions $pr]
						if {[regexp $pr0 $RpRm match]} {
							set intf_pins [::hsi::get_intf_pins -of_objects $pr0]
							foreach intf $intf_pins {
								set connectip [get_connected_stream_ip [get_cells -hier $pr0] $intf]
								if {[llength $connectip]} {
									if {[string match -nocase [get_property IP_NAME $connectip] "dfx_decoupler"]} {
										hsi::utils::add_new_dts_param $child_node2 "fpga-bridges" "$connectip" reference
									}
								}
							}
						}
					}
				}
				set hw_name [get_property CONFIG.firmware_name [get_os]]
				set rprmpartial $hw_name
				if {![llength $hw_name]} {
					if {[llength $pr_regions]} {
						set pr_len [llength $pr_regions]
						for {set pr 0} {$pr < $pr_len} {incr pr} {
							set pr0 [lindex $pr_regions $pr]
							if {[regexp $pr0 $RpRm match]} {
								set RmName_prop [get_rm_names $pr0]
								if {[string match -nocase $proctype "psu_cortexa53"]} {
									append pdi_name ${RmName_prop} "_" "BIT_FILE"
								} else {
									append pdi_name ${RmName_prop} "_" "PDI_FILE"
								}
								set rprmpartial [file tail [get_property $pdi_name [hsi::current_hw_design]]]
								if {[llength $rprmpartial]} {
									hsi::utils::add_new_dts_param "${child_node2}" "firmware-name" "$rprmpartial" string
								}
								append uid_prop ${RmName_prop} "_" "HW_DESIGN_ID"
								set UID [get_property $uid_prop [hsi::current_hw_design]]
								append pid_prop ${RmName_prop} "_" "HW_PARENT_ID"
								set PID [get_property $pid_prop [hsi::current_hw_design]]
								if {[llength $UID]} {
									hsi::utils::add_new_dts_param "${child_node2}" "uid" $UID int
								}
								if {[llength $PID]} {
									hsi::utils::add_new_dts_param "${child_node2}" "pid" $PID int
								}
							}
						}
					}
					set RpRm1 [get_rp_rm_for_drv $drv_handle]
					regsub -all { } $RpRm1 "_" RpRm
					if {[llength $RpRm]} {
						set bitfiles_len [llength $hw_name]
						for {set i 0} {$i < $bitfiles_len} {incr i} {
							set rprm_bit_file_name [lindex $hw_name $i]
							if {[regexp [lindex $RpRm1 1] $rprm_bit_file_name match]} {
								set rprmpartial [lindex $hw_name $i]
								hsi::utils::add_new_dts_param "${child_node2}" "firmware-name" "$rprmpartial" string
								break
							}
						}
					}
				}
				if {[llength $hw_name]} {
					puts "rprmpartial:$hw_name"
					hsi::utils::add_new_dts_param "${child_node2}" "firmware-name" "$hw_name" string
				}
			}
		} else {
			set child_node $fpga_node
			set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
			if {[string match -nocase $proctype "psv_cortexa72"]} {
				set targets "fpga"
			}
			if {[string match -nocase $proctype "psu_cortexa53"]} {
				set targets "fpga_full"
			}
			set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
			if {[llength $pr_regions]} {
				set pr_len [llength $pr_regions]
				for {set pr 0} {$pr < $pr_len} {incr pr} {
					set pr_node [add_or_get_dt_node -l "fpga_PR$pr" -n "fpga-PR$pr" -p $child_node]
					hsi::utils::add_new_dts_param  "${pr_node}" "compatible"  "fpga-region" string
					hsi::utils::add_new_dts_param "${pr_node}" "#address-cells" 2 int
					hsi::utils::add_new_dts_param "${pr_node}" "#size-cells" 2 int
					hsi::utils::add_new_dts_param "${pr_node}" "ranges" "" boolean
				}
			}
                }
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			set zynq_periph [get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
			set avail_param [list_property [get_cells -hier $zynq_periph]]
			if {![llength $RpRm]} {
				if {[lsearch -nocase $avail_param "CONFIG.PSU__USE__FABRIC__RST"] >= 0} {
					set val [get_property CONFIG.PSU__USE__FABRIC__RST [get_cells -hier $zynq_periph]]
					if {$val == 1} {
						if {[lsearch -nocase $avail_param "CONFIG.C_NUM_FABRIC_RESETS"] >= 0} {
							set val [get_property CONFIG.C_NUM_FABRIC_RESETS [get_cells -hier $zynq_periph]]
							switch $val {
								"1" {
									set resets "zynqmp_reset 116"
								} "2" {
									set resets "zynqmp_reset 116>,<&zynqmp_reset 117"
								} "3" {
									set resets "zynqmp_reset 116>, <&zynqmp_reset 117>, <&zynqmp_reset 118"
								} "4" {
									set resets "zynqmp_reset 116>, <&zynqmp_reset 117>, <&zynqmp_reset 118>, <&zynqmp_reset 119"
								}
							}
							if {$val != 0} {
								hsi::utils::add_new_dts_param "${child_node}" "resets" "$resets" reference
							}
						}
					}
				}
			}
		}
		if 0 {
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			hsi::utils::add_new_dts_param "${child_node}" "#address-cells" 2 int
			hsi::utils::add_new_dts_param "${child_node}" "#size-cells" 2 int
		} else {
			hsi::utils::add_new_dts_param "${child_node}" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "${child_node}" "#size-cells" 1 int
		}
		set hw_name [get_property CONFIG.firmware_name [get_os]]
		set rprmpartial ""
		if {![llength $hw_name]} {
			if {[string match -nocase $proctype "psu_cortexa53"]} {
				set hw_name [::hsi::get_hw_files -filter "TYPE == partial_bit"]
			} else {
				set hw_name [::hsi::get_hw_files -filter "TYPE == partial_pdi"]
			}
                        set RpRm1 [get_rp_rm_for_drv $drv_handle]
			regsub -all { } $RpRm1 "_" RpRm
			if {[llength $RpRm]} {
				set bitfiles_len [llength $hw_name]
				for {set i 0} {$i < $bitfiles_len} {incr i} {
					set rprm_bit_file_name [lindex $hw_name $i]
					if {[regexp [lindex $RpRm1 1] $rprm_bit_file_name match]} {
						set rprmpartial [lindex $hw_name $i]
						break
					}
				}
			}
		}
		if {[llength $rprmpartial]} {
			hsi::utils::add_new_dts_param "${child_node}" "firmware-name" "$rprmpartial.bin" string
		}
		if {![llength $RpRm]} {
			if {[string match -nocase $proctype "psu_cortexa53"]} {
				set hw_name [::hsi::get_hw_files -filter "TYPE == bit"]
			} else {
				set hw_name [::hsi::get_hw_files -filter "TYPE == pdi"]
			}
			hsi::utils::add_new_dts_param "${child_node}" "firmware-name" "$hw_name.bin" string
		}
		}
		set overlay_custom_dts [get_property CONFIG.overlay_custom_dts [get_os]]
		if {[llength $overlay_custom_dts] && ![llength $RpRm]} {
			update_overlay_custom_dts_include $default_dts $overlay_custom_dts
			set dts_file pl-custom.dtsi
			set root_node [add_or_get_dt_node -n / -d ${dts_file}]
			update_overlay_custom_dts_include $dts_file $overlay_custom_dts
		}
		set partial_overlay_custom_dts [get_property CONFIG.partial_overlay_custom_dts [get_os]]
		if {[llength $partial_overlay_custom_dts] && [llength $RpRm]} {
			append partial_overlay_dts $partial_overlay_custom_dts "-" $RpRm ".dts"
			update_overlay_custom_dts_include $default_dts $partial_overlay_dts
			set dts_file pl-partial-custom-$RpRm.dtsi
			set root_node [add_or_get_dt_node -n / -d ${dts_file}]
			update_overlay_custom_dts_include $dts_file $partial_overlay_dts
		}
	} else {
		update_system_dts_include $default_dts
	}

	return $default_dts
}

proc dt_node_def_checking {node_label node_name node_ua node_obj} {
	# check if the node_object has matching label, name and unit_address properties
	global def_string
	if {[string equal -nocase $node_label $def_string]} {
		set node_label ""
	}
	if {[string equal -nocase $node_ua $def_string]} {
		set node_ua ""
	}
	if {[string match -nocase "data_source" $node_label]} {
		return 1
	}
	# ignore reference node as it does not have label and unit_addr
	if {![regexp "^&.*" "$node_obj" match]} {
		set old_label [get_property "NODE_LABEL" $node_obj]
		set old_name [get_property "NODE_NAME" $node_obj]
		set old_ua [get_property "UNIT_ADDRESS" $node_obj]
		set config_prop [list_property -regexp $node_obj "CONFIG.*"]
		if {[string_is_empty $old_ua]} {
			return 1
		}
		if {![string equal -nocase -length [string length $node_label] $node_label $old_label] || \
			![string equal -nocase $node_ua $old_ua] || \
			![string equal -nocase -length [string length $node_name] $node_name $old_name]} {
			if {[string compare -nocase $config_prop ""]} {
				dtg_debug "dt_node_def_checking($node_obj): label: ${node_label} - ${old_label}, name: ${node_name} - ${old_name}, unit addr: ${node_ua} - ${old_ua}"
				return 0
			}
		}
	}
	return 1
}

proc add_or_get_dt_node args {
	# Creates the dt node or the parent node if required
	# return dt node
	proc_called_by
	global def_string
	foreach var {node_name node_label node_unit_addr parent_obj dts_file} {
		set ${var} ${def_string}
	}
	set auto_ref 1
	set auto_ref_parent 0
	set force_create 0
	while {[string match -* [lindex $args 0]]} {
		switch -glob -- [lindex $args 0] {
			-force {set force_create 1}
			-disable_auto_ref {set auto_ref 0}
			-auto_ref_parent {set auto_ref_parent 1}
			-n* {set node_name [Pop args 1]}
			-l* {set node_label [Pop args 1]}
			-u* {set node_unit_addr [Pop args 1]}
			-p* {set parent_obj [Pop args 1]}
			-d* {set dts_file [Pop args 1]}
			--  {Pop args ; break}
			default {
				error "add_or_get_dt_node bad option - [lindex $args 0]"
			}
		}
		Pop args
	}

	# if no dts_file provided
	if {[string equal -nocase ${dts_file} ${def_string}]} {
		set dts_file [current_dt_tree]
	}

	# node_name sanity checking
	if {[string equal -nocase ${node_name} ${def_string}]} {
		error "Node name must be provided..."
	}

	# Generate unique label name to prevent issue caused by static dtsi
	# better way of handling this issue is required
	set label_list [get_all_dt_labels]
	# TODO: This only handle label duplication once. if multiple IP has
	# the same label, it will not work. Better handling required.
	if {[lsearch $label_list $node_label] >= 0} {
		set tmp_node [get_node_object ${node_label}]
		# rename if the node default properties differs
		if {[dt_node_def_checking $node_label $node_name $node_unit_addr $tmp_node] == 0} {
			dtg_warning "label '$node_label' found in existing tree"
		}
	}

	set search_pattern [gen_dt_node_search_pattern -n ${node_name} -l ${node_label} -u ${node_unit_addr}]

	dtg_debug ""
	dtg_debug "node_name: ${node_name}"
	dtg_debug "node_label: ${node_label}"
	dtg_debug "node_unit_addr: ${node_unit_addr}"
	dtg_debug "search_pattern: ${search_pattern}"
	dtg_debug "parent_obj: ${parent_obj}"
	dtg_debug "dts_file: ${dts_file}"

	# save the current working dt_tree first
	set cur_working_dts [current_dt_tree]
	# tree switch the target tree
	set_cur_working_dts ${dts_file}
	set parent_dts_file ${dts_file}

	# Set correct parent object
	#  Check if the parent object in other dt_trees or not. If yes, update
	#  parent node with reference node (&parent_obj).
	#  Check if parent is / and see if it in the target dts file
	#  if not /, then check if parent is created (FIXME: is right???)
	set tmp_dts_list [list_remove_element [get_dt_trees] ${dts_file}]
	set node_in_dts [check_node_in_dts ${parent_obj} ${tmp_dts_list}]
	if {${node_in_dts} ==  1 && \
		 ![string equal ${parent_obj} "/" ]} {
		set parent_obj [get_node_object ${parent_obj} ${tmp_dts_list}]
		set parent_label [get_property "NODE_LABEL" $parent_obj]
		if {[string_is_empty $parent_label]} {
			set parent_label [get_property "NODE_NAME" $parent_obj]
		}
		if {[string_is_empty $parent_label]} {
			error "no parent node name/label"
		}
		if {[regexp "^&.*" "$parent_label" match]} {
			set ref_node "${parent_label}"
		} else {
			set ref_node "&${parent_label}"
		}
		set parent_ref_in_dts [check_node_in_dts "${ref_node}" ${dts_file}]
		if {${parent_ref_in_dts} != 1} {
			if {$auto_ref_parent} {
				set_cur_working_dts ${dts_file}
				set parent_obj [create_dt_node -n "${ref_node}"]
			}
		} else {
			set parent_obj [get_node_object ${ref_node} ${dts_file}]
		}
	}

	# if dt node in the target dts file
	# get the nodes in the current dts file
	set dts_nodes [get_all_tree_nodes $dts_file]
	foreach pattern ${search_pattern} {
		foreach node ${dts_nodes} {
			if {[regexp $pattern $node match]} {
				if {[dt_node_def_checking $node_label $node_name $node_unit_addr $node] == 0} {
					dtg_warning "$pattern :: $node_label : $node_name @ $node_unit_addr, is differ to the node object $node"
				}
				set node [update_dt_parent ${node} ${parent_obj} ${dts_file}]
				set_cur_working_dts ${cur_working_dts}
				return $node
			}
		}
	}
	# clean up required
	# special search pattern for name only node
	set_cur_working_dts ${dts_file}
	foreach pattern "^${node_name}$" {
		foreach node ${dts_nodes} {
			# As there was cpu timer node already in dtsi file skipping to add ttc timer
			# to pcw.dtsi even if ip available. This check will skip that.
			if {[regexp $pattern $node match] && ![string match -nocase ${node_name} "timer"]} {
				set_cur_working_dts ${dts_file}
				set node [update_dt_parent ${node} ${parent_obj} ${dts_file}]
				set_cur_working_dts ${cur_working_dts}
				return $node
			}
		}
	}
	# if dt node in other target dts files
	# create a reference node if required
	set found_node 0
	set tmp_dts_list [list_remove_element [get_dt_trees] ${dts_file}]
	foreach tmp_dts_file ${tmp_dts_list} {
		set dts_nodes [get_all_tree_nodes $tmp_dts_file]
		# TODO: better detection here
		foreach pattern ${search_pattern} {
			foreach node ${dts_nodes} {
				if {[regexp $pattern $node match]} {
					if {[string match -nocase $node "port@0"] || [string match -nocase $node "port@1"]
						|| [string match -nocase $node "port@2"]} {
						continue
					}
					# create reference node
					set found_node 1
					set found_node_obj [get_node_object ${node} $tmp_dts_file]
					break
				}
			}
		}
	}
	if {$found_node == 1 && $force_create == 0} {
		if {$auto_ref == 0} {
			# return the object found on other dts files
			set_cur_working_dts ${cur_working_dts}
			return $found_node_obj
		}
		dtg_debug "INFO: Found node and create it as reference node &${node_label}"
		if {[string equal -nocase ${node_label} ${def_string}]} {
			error "Unable to create reference node as reference label is not provided"
		}

		set node [create_dt_node -n "&${node_label}"]
		set_cur_working_dts ${cur_working_dts}
		return $node
	}

	# Others - create the dt node
	set cmd ""
	if {![string equal -nocase ${node_name} ${def_string}]} {
		set cmd "${cmd} -name ${node_name}"
	}
	if {![string equal -nocase ${node_label} ${def_string}]} {
		set cmd "${cmd} -label ${node_label}"
	}
	if {![string equal -nocase ${node_unit_addr} ${def_string}]} {
		set cmd "${cmd} -unit_addr ${node_unit_addr}"
	}
	if {![string equal -nocase ${parent_obj} ${def_string}] && \
		![string_is_empty ${parent_obj}]} {
		# temp solution for getting the right node object
		#set cmd "${cmd} -objects \[get_node_object ${parent_obj} $dts_file\]"
		#report_property [get_node_object ${parent_obj} $dts_file]
		set cmd "${cmd} -objects \[get_node_object ${parent_obj} $parent_dts_file\]"
	}

	dtg_debug "create node command: create_dt_node ${cmd}"
	# FIXME: create_dt_node fail detection here
	set node [eval "create_dt_node ${cmd}"]
	set_cur_working_dts ${cur_working_dts}
	return $node
}

proc is_pl_ip {ip_inst} {
	# check if the IP is a soft IP (not PS7)
	# return 1 if it is soft ip
	# return 0 if not
	set ip_obj [get_cells -hier $ip_inst]
	if {[llength [get_cells -hier $ip_inst]] < 1} {
		return 0
	}
	set ip_name [get_property IP_NAME $ip_obj]
	set nochk_list "ai_engine noc_mc_ddr4"
	if {[lsearch $nochk_list $ip_name] >= 0} {
		return 1
	}
	if {[catch {set proplist [list_property [hsi::get_cells -hier $ip_inst]]} msg]} {
	} else {
		if {[lsearch -nocase $proplist "IS_PL"] >= 0} {
			set prop [get_property IS_PL [hsi::get_cells -hier $ip_inst]]
			if {$prop} {
				return 1
			} else {
				return 0
			}
		}
	}
        set ip_name [get_property IP_NAME $ip_obj]
        if {![regexp "ps._*" "$ip_name" match]} {
                return 1
        }
        return 0

}

proc is_ps_ip {ip_inst} {
	# check if the IP is a soft IP (not PS7)
	# return 1 if it is soft ip
	# return 0 if not
	set ip_obj [hsi::get_cells -hier $ip_inst]
	if {[catch {set proplist [list_property [hsi::get_cells -hier $ip_inst]]} msg]} {
	} else {
	if {[lsearch -nocase $proplist "IS_PL"] >= 0} {
		set prop [get_property IS_PL [hsi::get_cells -hier $ip_inst]]
		if {$prop} {
			return 0
		}
	}
	}
	if {[llength [hsi::get_cells -hier $ip_inst]] < 1} {
		return 0
	}

	set ip_name [get_property IP_NAME $ip_obj]
	if {[string match -nocase $ip_name "axi_noc"] || [string match -nocase $ip_name "axi_noc2"]} {
		return 0
	}
	if {[regexp "ps._*" "$ip_name" match]} {
		return 1
	}
	return 0
}

proc get_node_name {drv_handle} {
	# FIXME: handle node that is not an ip
	# what about it is a bus node
	set ip [get_cells -hier $drv_handle]
	# node that is not a ip
	if {[string_is_empty $ip]} {
		error "$drv_handle is not a valid IP"
	}
	set unit_addr [get_baseaddr ${ip}]
	set dev_type [get_property CONFIG.dev_type $drv_handle]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type $drv_handle
	}
	set dt_node [add_or_get_dt_node -n ${dev_type} -l ${drv_handle} -u ${unit_addr}]
	return $dt_node
}

proc get_driver_conf_list {drv_handle} {
	# Assuming the driver property starts with CONFIG.<xyz>
	# Returns all the property name that should be add to the node
	set dts_conf_list ""
	# handle no CONFIG parameter
	if {[catch {set rt [report_property -return_string -regexp $drv_handle "CONFIG\\..*"]} msg]} {
		return ""
	}
	foreach line [split $rt "\n"] {
		regsub -all {\s+} $line { } line
		if {[regexp "CONFIG\\..*\\.dts(i|)" $line matched]} {
			continue
		}
		if {[regexp "CONFIG\\..*" $line matched]} {
			lappend dts_conf_list [lindex [split $line " "] 0]
		}
	}
	# Remove config based properties
	# currently it is not possible to different by type: Pending on HSI implementation
	# this is currently hard coded to remove CONFIG.def_dts CONFIG.dev_type CONFIG.dtg.alias CONFIG.dtg.ip_params
	set dts_conf_list [list_remove_element $dts_conf_list "CONFIG.def_dts CONFIG.dev_type CONFIG.dtg.alias CONFIG.dtg.ip_params"]
	return $dts_conf_list
}

proc add_driver_prop {drv_handle dt_node prop} {
	# driver property to DT node
	set value [get_property ${prop} $drv_handle]
	if {[string_is_empty ${prop}] != 0} {
		return -1
	}
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return
	}
	regsub -all {CONFIG.} $prop {} prop
	set conf_prop [lindex [get_comp_params ${prop} $drv_handle] 0 ]
	if {[string_is_empty ${conf_prop}] == 0} {
		set type [lindex [get_property CONFIG.TYPE $conf_prop] 0]
	} else {
		error "Unable to add the $prop property for $drv_handle due to missing valid type"
	}
	set ipname [get_property IP_NAME [get_cells -hier $drv_handle]]
	if {[string match -nocase $ipname "axi_mcdma"] && [string match -nocase $conf_prop "xlnx,sg-include-stscntrl-strm"]&& [string match -nocase $type "boolean"]} {
		set type "hexint"
	}
	dtg_debug "${dt_node} - ${prop} - ${value} - ${type}"

	# only boolean allows empty string
	if {[string_is_empty ${value}] == 1 && ![regexp {boolean*} ${type} matched]} {
		dtg_warning "Only boolean type can have empty value. Fail to add driver($drv_handle) property($prop) type($type) value($value)"
		dtg_warning "Please add the property manually"
		return 1
	}
	# TODO: sanity check is missing
	hsi::utils::add_new_dts_param "${dt_node}" "${prop}" "${value}" "${type}"
}

proc create_dt_tree_from_dts_file {} {
	global def_string dtsi_fname
	set kernel_dtsi ""
	set mainline_dtsi ""
	set kernel_ver [get_property CONFIG.kernel_version [get_os]]
	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
        if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		foreach i [get_sw_cores device_tree] {
			set mainline_dtsi [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${mainline_ker}/${dtsi_fname}"]
			if {[file exists $mainline_dtsi]} {
				foreach file [glob [file normalize [file dirname ${mainline_dtsi}]/*]] {
					# NOTE: ./ works only if we did not change our directory
					file copy -force $file ./
				}
				break
			}
		}
	} else {
		foreach i [get_sw_cores device_tree] {
			set kernel_dtsi [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/${dtsi_fname}"]
			if {[file exists $kernel_dtsi]} {
				foreach file [glob [file normalize [file dirname ${kernel_dtsi}]/*]] {
					# NOTE: ./ works only if we did not change our directory
					file copy -force $file ./
				}
				break
			}
		}

		if {![file exists $kernel_dtsi] || [string_is_empty $kernel_dtsi]} {
			error "Unable to find the dts file $kernel_dtsi"
		}
	}

	global zynq_soc_dt_tree
	set default_dts [create_dt_tree -dts_file $zynq_soc_dt_tree]
        set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
        if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		set fp [open $mainline_dtsi r]
		set file_data [read $fp]
		set data [split $file_data "\n"]
	} else {
		set fp [open $kernel_dtsi r]
		set file_data [read $fp]
		set data [split $file_data "\n"]
	}

	set node_level -1
	foreach line $data {
		set node_start_regexp "\{(\\s+|\\s|)$"
		set node_end_regexp "\}(\\s+|\\s|);(\\s+|\\s|)$"
		if {[regexp $node_start_regexp $line matched]} {
			regsub -all "\{| |\t" $line {} line
			incr node_level
			set cur_node [line_to_node $line $node_level $default_dts]
		} elseif {[regexp $node_end_regexp $line matched]} {
			set node_level [expr "$node_level - 1"]
		}
		# TODO (MAYBE): convert every property into dt node
		set status_regexp "status(|\\s+)="
		set value ""
		if {[regexp $status_regexp $line matched]} {
			regsub -all "\{| |\t|;|\"" $line {} line
			set line_data [split $line "="]
			set value [lindex $line_data 1]
			hsi::utils::add_new_dts_param "${cur_node}" "status" $value string
		}
		set status_regexp "compatible(|\\s+)="
		set value ""
		if {[regexp $status_regexp $line matched]} {
			regsub -all "\{| |\t|;|\"" $line {} line
			set line_data [split $line "="]
			set value [lindex $line_data 1]
			hsi::utils::add_new_dts_param "${cur_node}" "compatible" $value stringlist
		}
	}
}

proc line_to_node {line node_level default_dts} {
	# TODO: make dt_node_dict as global
	global dt_node_dict
	global def_string
	regsub -all "\{| |\t" $line {} line
	set parent_node $def_string
	set node_label $def_string
	set node_name $def_string
	set node_unit_addr $def_string

	set node_data [split $line ":"]
	set node_data_size [llength $node_data]
	if {$node_data_size == 2} {
		set node_label [lindex $node_data 0]
		set tmp_data [split [lindex $node_data 1] "@"]
		set node_name [lindex $tmp_data 0]
		if {[llength $tmp_data] >= 2} {
			set node_unit_addr [lindex $tmp_data 1]
		}
	} elseif {$node_data_size == 1} {
		set node_name [lindex $node_data 0]
	} else {
		error "invalid node found - $line"
	}

	if {$node_level > 0} {
		set parent_node [dict get $dt_node_dict [expr $node_level - 1] parent_node]
	}

	set cur_node [add_or_get_dt_node -n ${node_name} -l ${node_label} -u ${node_unit_addr} -d ${default_dts} -p ${parent_node}]
	dict set dt_node_dict $node_level parent_node $cur_node
	return $cur_node
}

proc gen_ps7_mapping {} {
	# TODO: check if it is target cpu is cortex a9

	# TODO: remove def_ps7_mapping
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]

	set def_ps_mapping [dict create]
	if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
		dict set def_ps_mapping f9000000 label gic
		dict set def_ps_mapping fd4b0000 label gpu
		dict set def_ps_mapping ffa80000 label adma0
		dict set def_ps_mapping ffa90000 label adma1
		dict set def_ps_mapping ffaa0000 label adma2
		dict set def_ps_mapping ffab0000 label adma3
		dict set def_ps_mapping ffac0000 label adma4
		dict set def_ps_mapping ffad0000 label adma5
		dict set def_ps_mapping ffae0000 label adma6
		dict set def_ps_mapping ffaf0000 label adma7
		dict set def_ps_mapping ff100000 label nand0
		dict set def_ps_mapping ff0c0000 label gem0
		dict set def_ps_mapping ff0d0000 label gem1
		dict set def_ps_mapping ff0b0000 label gpio
		dict set def_ps_mapping ff020000 label i2c0
		dict set def_ps_mapping ff030000 label i2c1
		dict set def_ps_mapping f06f0000 label qspi
		dict set def_ps_mapping f1100000 label rtc
		dict set def_ps_mapping fd0c0000 label sata
		dict set def_ps_mapping f0760000 label sdhci0
		dict set def_ps_mapping f0770000 label sdhci1
		dict set def_ps_mapping fd800000 label smmu
		dict set def_ps_mapping ff040000 label spi0
		dict set def_ps_mapping ff050000 label spi1
		dict set def_ps_mapping ff0e0000 label ttc0
		dict set def_ps_mapping ff0f0000 label ttc1
		dict set def_ps_mapping ff100000 label ttc2
		dict set def_ps_mapping ff110000 label ttc3
		dict set def_ps_mapping ff000000 label uart0
		dict set def_ps_mapping ff010000 label uart1
		dict set def_ps_mapping fe200000 label usb0
		dict set def_ps_mapping ff120000 label watchdog0
		dict set def_ps_mapping fe5f0000 label dpdma
		dict set def_ps_mapping fd0e0000 label pcie
		dict set def_ps_mapping ff060000 label can0
		dict set def_ps_mapping ff070000 label can1
	} elseif {[string match -nocase $proctype "psu_cortexa53"]} {
		dict set def_ps_mapping f9010000 label gic
		dict set def_ps_mapping ff060000 label can0
		dict set def_ps_mapping ff070000 label can1
		dict set def_ps_mapping fd500000 label gdma0
		dict set def_ps_mapping fd510000 label gdma1
		dict set def_ps_mapping fd520000 label gdma2
		dict set def_ps_mapping fd530000 label gdma3
		dict set def_ps_mapping fd540000 label gdma4
		dict set def_ps_mapping fd550000 label gdma5
		dict set def_ps_mapping fd560000 label gdma6
		dict set def_ps_mapping fd570000 label gdma7
		dict set def_ps_mapping fd4b0000 label gpu
		dict set def_ps_mapping ffa80000 label adma0
		dict set def_ps_mapping ffa90000 label adma0
		dict set def_ps_mapping ffaa0000 label adma2
		dict set def_ps_mapping ffab0000 label adma3
		dict set def_ps_mapping ffac0000 label adma4
		dict set def_ps_mapping ffad0000 label adma5
		dict set def_ps_mapping ffae0000 label adma6
		dict set def_ps_mapping ffaf0000 label adma7
		dict set def_ps_mapping ff100000 label nand0
		dict set def_ps_mapping ff0b0000 label gem0
		dict set def_ps_mapping ff0c0000 label gem1
		dict set def_ps_mapping ff0d0000 label gem2
		dict set def_ps_mapping ff0e0000 label gem3
		dict set def_ps_mapping ff0a0000 label gpio
		dict set def_ps_mapping ff020000 label i2c0
		dict set def_ps_mapping ff030000 label i2c1
		dict set def_ps_mapping ff0f0000 label qspi
		dict set def_ps_mapping ffa60000 label rtc
		dict set def_ps_mapping fd0c0000 label sata
		dict set def_ps_mapping ff160000 label sdhci0
		dict set def_ps_mapping ff170000 label sdhci1
		dict set def_ps_mapping fd800000 label smmu
		dict set def_ps_mapping ff040000 label spi0
		dict set def_ps_mapping ff050000 label spi1
		dict set def_ps_mapping ff110000 label ttc0
		dict set def_ps_mapping ff120000 label ttc1
		dict set def_ps_mapping ff130000 label ttc2
		dict set def_ps_mapping ff140000 label ttc3
		dict set def_ps_mapping ff000000 label uart0
		dict set def_ps_mapping ff010000 label uart1
		dict set def_ps_mapping fe200000 label usb0
		dict set def_ps_mapping fe300000 label usb1
		dict set def_ps_mapping fd4d0000 label watchdog0
		dict set def_ps_mapping 43c00000 label dp
		dict set def_ps_mapping 43c0a000 label dpsub
		dict set def_ps_mapping fd4c0000 label dpdma
		dict set def_ps_mapping fd0e0000 label pcie
	} else {
		dict set def_ps_mapping f8891000 label pmu
		dict set def_ps_mapping f8007100 label adc
		dict set def_ps_mapping e0008000 label can0
		dict set def_ps_mapping e0009000 label can1
		dict set def_ps_mapping e000a000 label gpio0
		dict set def_ps_mapping e0004000 label i2c0
		dict set def_ps_mapping e0005000 label i2c1
		dict set def_ps_mapping f8f01000 label intc
		dict set def_ps_mapping f8f00100 label intc
		dict set def_ps_mapping f8f02000 label L2
		dict set def_ps_mapping f8006000 label memory-controller
		dict set def_ps_mapping f800c000 label ocmc
		dict set def_ps_mapping e0000000 label uart0
		dict set def_ps_mapping e0001000 label uart1
		dict set def_ps_mapping e0006000 label spi0
		dict set def_ps_mapping e0007000 label spi1
		dict set def_ps_mapping e000d000 label qspi
		dict set def_ps_mapping e000e000 label smcc
		dict set def_ps_mapping e1000000 label nand0
		dict set def_ps_mapping e2000000 label nor
		dict set def_ps_mapping e000b000 label gem0
		dict set def_ps_mapping e000c000 label gem1
		dict set def_ps_mapping e0100000 label sdhci0
		dict set def_ps_mapping e0101000 label sdhci1
		dict set def_ps_mapping f8000000 label slcr
		dict set def_ps_mapping f8003000 label dmac_s
		dict set def_ps_mapping f8007000 label devcfg
		dict set def_ps_mapping f8f00200 label global_timer
		dict set def_ps_mapping f8001000 label ttc0
		dict set def_ps_mapping f8002000 label ttc1
		dict set def_ps_mapping f8f00600 label scutimer
		dict set def_ps_mapping f8005000 label watchdog0
		dict set def_ps_mapping f8f00620 label scuwatchdog
		dict set def_ps_mapping e0002000 label usb0
		dict set def_ps_mapping e0003000 label usb1
	}

	set ps_mapping [dict create]
	global zynq_soc_dt_tree
	if {[lsearch [get_dt_trees] $zynq_soc_dt_tree] >= 0} {
		# get nodes under bus
		foreach node [get_all_tree_nodes $zynq_soc_dt_tree] {
			# only care about the device with parent ambe
			set parent [get_property PARENT  $node]
			set ignore_parent_list {(/|cpu)}
			if {[regexp $ignore_parent_list $parent matched]} {
				continue
			}
			set unit_addr [get_property UNIT_ADDRESS $node]
			if {[string length $unit_addr] <= 1} {
				set unit_addr ""
			}
			set node_name [get_property NODE_NAME $node]
			set node_label [get_property NODE_LABEL $node]
			if {[catch {set status_prop [get_property CONFIG.status $node]} msg]} {
				set status_prop "enable"
			}
			if {[string_is_empty $node_label] || \
				[string_is_empty $unit_addr]} {
				continue
			}
			dict set ps_mapping $unit_addr label $node_label
			dict set ps_mapping $unit_addr name $node_name
			dict set ps_mapping $unit_addr status $status_prop
		}
	}
	if {[string_is_empty $ps_mapping]} {
		return $def_ps_mapping
	} else {
		return $ps_mapping
	}
}

proc ps_node_mapping {ip_name prop} {
	if {[is_ps_ip [get_drivers $ip_name]]} {
		set unit_addr [get_ps_node_unit_addr $ip_name]
		if {$unit_addr == -1} {return $ip_name}
		set ps7_mapping [gen_ps7_mapping]

		if {[catch {set tmp [dict get $ps7_mapping $unit_addr $prop]} msg]} {
			continue
		}
		return $tmp
	}
	return $ip_name
}

proc get_ps_node_unit_addr {ip_name {prop "label"}} {
	set ip [get_cells -hier $ip_name]
	set ip_mem_handle [hsi::utils::get_ip_mem_ranges [get_cells -hier $ip]]

	# loop through the base addresses: workaround for intc
	foreach handler ${ip_mem_handle} {
		set unit_addr [string tolower [get_property BASE_VALUE $handler]]
		regsub -all {^0x} $unit_addr {} unit_addr
		set ps7_mapping [gen_ps7_mapping]
		if {[is_ps_ip [get_drivers $ip_name]]} {
			if {[catch {set tmp [dict get $ps7_mapping $unit_addr $prop]} msg]} {
				continue
			}
			return $unit_addr
		}
	}
	return -1
}

proc remove_empty_reference_node {} {
	# check for ps_ips
	global zynq_soc_dt_tree
	set dts_files [list_remove_element [get_dt_trees] $zynq_soc_dt_tree]
	foreach dts_file $dts_files {
		set_cur_working_dts $dts_file
		foreach node [get_all_tree_nodes $dts_file] {
			if {[regexp "^&.*" $node matched]} {
				# check if it has child node
				set child_nodes [get_dt_nodes -of_objects $node]
				if {![string_is_empty $child_nodes]} {
					continue
				}
				set prop_list [list_property -regexp $node "CONFIG.*"]
				if {[string_is_empty $prop_list]} {
					dtg_debug "removing $node"
					delete_objs $node
				}
			}
		}
	}
}

proc add_dts_header {dts_file str_add} {
	set cur_dts [current_dt_tree]
	set dts_obj [set_cur_working_dts ${dts_file}]
	set header [get_property HEADER $dts_obj]
	append header "\n" $str_add
	set_property HEADER $header $dts_obj
	set_cur_working_dts $cur_dts
}

proc zynq_gen_pl_clk_binding {drv_handle} {
	# add dts binding for required nodes
	#   clock-names = "ref_clk";
	#   clocks = <&clkc 0>;
	global bus_clk_list
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	# Assuming these device supports the clocks
	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
	if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		set valid_ip_list "axi_timer axi_uartlite axi_uart16550 axi_gpio axi_traffic_gen axi_ethernet axi_ethernet_buffer can canfd axi_iic xadc_wiz vcu"
	} else {
		set valid_ip_list "xadc_wiz"
	}
	set valid_proc_list "ps7_cortexa9 psu_cortexa53"
	if {[lsearch  -nocase $valid_proc_list $proctype] >= 0} {
		set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
		if {[lsearch $valid_ip_list $iptype] >= 0} {
			# FIXME: this is hardcoded - maybe dynamic detection
			# Keep the below logic, until we have clock frame work for ZynqMP
			if {[string match -nocase $iptype "can"] || [string match -nocase $iptype "canfd"]} {
				set clks "can_clk s_axi_aclk"
			} elseif {[string match -nocase $iptype "vcu"]} {
				set clks "pll_ref_clk s_axi_lite_aclk"
			} else {
				set clks "s_axi_aclk"
			}
			foreach pin $clks {
			if {[string match -nocase $proctype "psu_cortexa53"] } {
				set dts_file [current_dt_tree]
				set bus_node [add_or_get_bus_node $drv_handle $dts_file]
				set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] $pin]
				if {![string equal $clk_freq ""]} {
					if {[lsearch $bus_clk_list $clk_freq] < 0} {
						set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
					# create the node and assuming reg 0 is taken by cpu
					set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
					hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
					hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
					if {[string match -nocase $iptype "can"] || [string match -nocase $iptype "vcu"] || [string match -nocase $iptype "canfd"]} {
						set clocks [lindex $clk_refs 0]
						append clocks ">, <&[lindex $clk_refs 1]"
						set_drv_prop $drv_handle "clocks" "$clocks" reference
						set_drv_prop_if_empty $drv_handle "clock-names" "$clks" stringlist
					} else {
						set_drv_prop_if_empty $drv_handle "clocks" $clk_refs reference
						set_drv_prop_if_empty $drv_handle "clock-names" "$clks" stringlist
					}
				}
			} else {
				set_drv_prop_if_empty $drv_handle "clock-names" "ref_clk" stringlist
				set_drv_prop_if_empty $drv_handle "clocks" "clkc 0" reference
			}
			}
		}
	}
}

proc gen_endpoint {drv_handle value} {
	global end_mappings
	dict append end_mappings $drv_handle $value
	set val [dict get $end_mappings $drv_handle]
}

proc gen_axis_switch_in_endpoint {drv_handle value} {
	global axis_switch_in_end_mappings
	dict append axis_switch_in_end_mappings $drv_handle $value
	set val [dict get $axis_switch_in_end_mappings $drv_handle]
}

proc gen_axis_switch_in_remo_endpoint {drv_handle value} {
	global axis_switch_in_remo_mappings
	dict append axis_switch_in_remo_mappings $drv_handle $value
	set val [dict get $axis_switch_in_remo_mappings $drv_handle]
}

proc gen_axis_switch_port1_endpoint {drv_handle value} {
	global axis_switch_port1_end_mappings
	dict append axis_switch_port1_end_mappings $drv_handle $value
	set val [dict get $axis_switch_port1_end_mappings $drv_handle]
}

proc gen_axis_switch_port2_endpoint {drv_handle value} {
	global axis_switch_port2_end_mappings
	dict append axis_switch_port2_end_mappings $drv_handle $value
	set val [dict get $axis_switch_port2_end_mappings $drv_handle]
}

proc gen_axis_switch_port3_endpoint {drv_handle value} {
	global axis_switch_port3_end_mappings
	dict append axis_switch_port3_end_mappings $drv_handle $value
	set val [dict get $axis_switch_port3_end_mappings $drv_handle]
}

proc gen_axis_switch_port4_endpoint {drv_handle value} {
	global axis_switch_port4_end_mappings
	dict append axis_switch_port4_end_mappings $drv_handle $value
	set val [dict get $axis_switch_port4_end_mappings $drv_handle]
}

proc gen_axis_switch_port1_remote_endpoint {drv_handle value} {
	global axis_switch_port1_remo_mappings
	dict append axis_switch_port1_remo_mappings $drv_handle $value
	set val [dict get $axis_switch_port1_remo_mappings $drv_handle]
}

proc gen_axis_switch_port2_remote_endpoint {drv_handle value} {
	global axis_switch_port2_remo_mappings
	dict append axis_switch_port2_remo_mappings $drv_handle $value
	set val [dict get $axis_switch_port2_remo_mappings $drv_handle]
}

proc gen_axis_switch_port3_remote_endpoint {drv_handle value} {
	global axis_switch_port3_remo_mappings
	dict append axis_switch_port3_remo_mappings $drv_handle $value
	set val [dict get $axis_switch_port3_remo_mappings $drv_handle]
}

proc gen_axis_switch_port4_remote_endpoint {drv_handle value} {
	global axis_switch_port4_remo_mappings
	dict append axis_switch_port4_remo_mappings $drv_handle $value
	set val [dict get $axis_switch_port4_remo_mappings $drv_handle]
}

proc gen_axis_port1_endpoint {drv_handle value} {
	global port1_end_mappings
	dict append port1_end_mappings $drv_handle $value
	set val [dict get $port1_end_mappings $drv_handle]
}

proc gen_axis_port2_endpoint {drv_handle value} {
	global port2_end_mappings
	dict append port2_end_mappings $drv_handle $value
	set val [dict get $port2_end_mappings $drv_handle]
}

proc gen_axis_port3_endpoint {drv_handle value} {
	global port3_end_mappings
	dict append port3_end_mappings $drv_handle $value
	set val [dict get $port3_end_mappings $drv_handle]
}

proc gen_axis_port4_endpoint {drv_handle value} {
	global port4_end_mappings
	dict append port4_end_mappings $drv_handle $value
	set val [dict get $port4_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port1 {drv_handle value} {
        global port1_broad_end_mappings
        dict append port1_broad_end_mappings $drv_handle $value
        set val [dict get $port1_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port2 {drv_handle value} {
        global port2_broad_end_mappings
        dict append port2_broad_end_mappings $drv_handle $value
        set val [dict get $port2_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port3 {drv_handle value} {
        global port3_broad_end_mappings
        dict append port3_broad_end_mappings $drv_handle $value
        set val [dict get $port3_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port4 {drv_handle value} {
        global port4_broad_end_mappings
        dict append port4_broad_end_mappings $drv_handle $value
        set val [dict get $port4_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port5 {drv_handle value} {
        global port5_broad_end_mappings
        dict append port5_broad_end_mappings $drv_handle $value
        set val [dict get $port5_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port6 {drv_handle value} {
        global port6_broad_end_mappings
        dict append port6_broad_end_mappings $drv_handle $value
        set val [dict get $port6_broad_end_mappings $drv_handle]
}

proc get_endpoint_mapping {inip mappings} {
	#search the inip in mappings and return value if found
	set endpoint ""
	if {[dict exists $mappings $inip]} {
		set endpoint [dict get $mappings $inip]
	}
	return "$endpoint"
}

proc add_endpoint_mapping {drv_handle port_node in_end remo_in_end} {
	#Add the endpoint/remote-endpoint for given drv_handle
	if {[regexp -nocase $drv_handle "$remo_in_end" match]} {
		if {[llength $remo_in_end]} {
			set node [add_or_get_dt_node -n "endpoint" -l $remo_in_end -p $port_node]
		}
		if {[llength $in_end]} {
			hsi::utils::add_new_dts_param "$node" "remote-endpoint" $in_end reference
		}
	}
}

proc update_axis_switch_endpoints {inip port_node drv_handle} {
	#Read all the non memorymapped axis_switch global variables to get the
	#inip value corresponding to drv_handle
	global port1_end_mappings
	global port2_end_mappings
	global port3_end_mappings
	global port4_end_mappings
	global axis_port1_remo_mappings
	global axis_port2_remo_mappings
	global axis_port3_remo_mappings
	global axis_port4_remo_mappings
	if {[info exists port1_end_mappings] && [info exists axis_port1_remo_mappings]} {
		set in1_end [get_endpoint_mapping $inip $port1_end_mappings]
		set remo_in1_end [get_endpoint_mapping $inip $axis_port1_remo_mappings]
	}
	if {[info exists port2_end_mappings] && [info exists axis_port2_remo_mappings]} {
		set in2_end [get_endpoint_mapping $inip $port2_end_mappings]
		set remo_in2_end [get_endpoint_mapping $inip $axis_port2_remo_mappings]
	}
	if {[info exists port3_end_mappings] && [info exists axis_port3_remo_mappings]} {
		set in3_end [get_endpoint_mapping $inip $port3_end_mappings]
		set remo_in3_end [get_endpoint_mapping $inip $axis_port3_remo_mappings]
	}
	if {[info exists port4_end_mappings] && [info exists axis_port4_remo_mappings]} {
		set in4_end [get_endpoint_mapping $inip $port4_end_mappings]
		set remo_in4_end [get_endpoint_mapping $inip $axis_port4_remo_mappings]
	}

	if {[info exists remo_in1_end] && [info exists in1_end]} {
		dtg_verbose "$port_node $remo_in1_end"
		add_endpoint_mapping $drv_handle $port_node $in1_end $remo_in1_end
	}
	if {[info exists remo_in2_end] && [info exists in2_end]} {
		dtg_verbose "$port_node $remo_in2_end"
		add_endpoint_mapping $drv_handle $port_node $in2_end $remo_in2_end
	}
	if {[info exists remo_in3_end] && [info exists in3_end]} {
		dtg_verbose "$port_node $remo_in3_end"
		add_endpoint_mapping $drv_handle $port_node $in3_end $remo_in3_end
	}
	if {[info exists remo_in4_end] && [info exists in4_end]} {
		dtg_verbose "$port_node $remo_in4_end"
		add_endpoint_mapping $drv_handle $port_node $in4_end $remo_in4_end
	}
}

proc update_endpoints {drv_handle} {
	global end_mappings
	global remo_mappings
	global set port1_end_mappings
	global set port2_end_mappings
	global set port3_end_mappings
	global set port4_end_mappings
	global set axis_port1_remo_mappings
	global set axis_port2_remo_mappings
	global set axis_port3_remo_mappings
	global set axis_port4_remo_mappings
	global set port1_broad_end_mappings
	global set port2_broad_end_mappings
	global set port3_broad_end_mappings
	global set port4_broad_end_mappings
	global set port5_broad_end_mappings
	global set port6_broad_end_mappings
	global set broad_port1_remo_mappings
	global set broad_port2_remo_mappings
	global set broad_port3_remo_mappings
	global set broad_port4_remo_mappings
	global set broad_port5_remo_mappings
	global set broad_port6_remo_mappings
	global set axis_switch_in_end_mappings
	global set axis_switch_in_remo_mappings
	global set axis_switch_port1_end_mappings
	global set axis_switch_port2_end_mappings
	global set axis_switch_port3_end_mappings
	global set axis_switch_port4_end_mappings
	global set axis_switch_port1_remo_mappings
	global set axis_switch_port2_remo_mappings
	global set axis_switch_port3_remo_mappings
	global set axis_switch_port4_remo_mappings

	set broad [hsi::utils::get_os_parameter_value "broad"]
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
        if {[is_pl_ip $drv_handle] && $remove_pl} {
                return 0
        }

	set node [gen_peripheral_nodes $drv_handle]
	set ip [get_cells -hier $drv_handle]
	if {[string match -nocase [get_property IP_NAME $ip] "v_proc_ss"]} {
		set topology [get_property CONFIG.C_TOPOLOGY [get_cells -hier $drv_handle]]
		if {$topology == 0} {
			set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
			hsi::utils::add_new_dts_param "${node}" "xlnx,video-width" $max_data_width int
			set ports_node [add_or_get_dt_node -n "ports" -l scaler_ports$drv_handle -p $node]
			hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
			set port_node [add_or_get_dt_node -n "port" -l scaler_port0$drv_handle -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "${port_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
			hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 3 int
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" $max_data_width int

			set scaninip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis"]
			# Get next IN IP if axis_slice connected
			if {[llength "$scaninip"] && \
				[string match -nocase [get_property IP_NAME $scaninip] "axis_register_slice"]} {
				set intf "S_AXIS"
				set scaninip [get_connected_stream_ip [get_cells -hier $scaninip] "$intf"]
			}
			foreach inip $scaninip {
				if {[llength $inip]} {
					set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
					if {![llength $ip_mem_handles]} {
						# Add endpoints if IN IP is axis_switch and non memory mapped
						if {[string match -nocase [get_property IP_NAME $inip] "axis_switch"]} {
							update_axis_switch_endpoints $inip $port_node $drv_handle
						}
						set broad_ip [get_broad_in_ip $inip]
						if {[llength $broad_ip]} {
							if {[string match -nocase [get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
								set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
								set intlen [llength $master_intf]
								set sca_in_end ""
								set sca_remo_in_end ""
								switch $intlen {
									"1" {
										if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
											set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
											dtg_verbose "sca_in_end:$sca_in_end"
										}
										if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
											set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
										}
										if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
											if {[llength $sca_remo_in_end]} {
												set sca_node [add_or_get_dt_node -n "endpoint" -l $sca_remo_in_end -p $port_node]
											}
											if {[llength $sca_in_end]} {
													hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $sca_in_end reference
											}
										}

									}
									"2" {
										if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
											set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
										}
										if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
											set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
										}
										if {[info exists port1_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
											set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
										}
										if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
											set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
										}
										if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
											if {[llength $sca_remo_in_end]} {
												set sca_node [add_or_get_dt_node -n "endpoint" -l $sca_remo_in_end -p $port_node]
										}
											if {[llength $sca_in_end]} {
												hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $sca_in_end reference
											}
										}
										if {[regexp -nocase $drv_handle "$sca_remo_in1_end" match]} {
											if {[llength $sca_remo_in1_end]} {
												set sca_node [add_or_get_dt_node -n "endpoint" -l $sca_remo_in1_end -p $port_node]
											}
											if {[llength $sca_in1_end]} {
												hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $sca_in1_end reference
											}
										}
								}
								"3" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
										set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
										set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
									}

									if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
										set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
										set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
									}

									if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
										set sca_in2_end [dict get $port3_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
										set sca_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
										if {[llength $sca_remo_in_end]} {
											set sca_node [add_or_get_dt_node -n "endpoint" -l $sca_remo_in_end -p $port_node]
										}
										if {[llength $sca_in_end]} {
											hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $sca_in_end reference
										}
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in1_end" match]} {
										if {[llength $sca_remo_in1_end]} {
											set sca_node [add_or_get_dt_node -n "endpoint" -l $sca_remo_in1_end -p $port_node]
										}
										if {[llength $sca_in1_end]} {
											hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $sca_in1_end reference
										}
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in2_end" match]} {
										if {[llength $sca_remo_in2_end]} {
											set sca_node [add_or_get_dt_node -n "endpoint" -l $sca_remo_in2_end -p $port_node]
										}
										if {[llength $sca_in2_end]} {
											hsi::utils::add_new_dts_param "$sca_node" "remote-endpoint" $sca_in2_end reference
										}
									}
								}
							"4" {
								if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
									set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
								}
								if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
									set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
								}

								if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
									set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
								}
								if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
									set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
								}

								if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
									set sca_in2_end [dict get $port3_broad_end_mappings $broad_ip]
								}
								if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
									set sca_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
								}
								if {[info exists port4_broad_end_mappings] && [dict exists $port4_broad_end_mappings $broad_ip]} {
									set sca_in3_end [dict get $port4_broad_end_mappings $broad_ip]
								}
								if {[info exists broad_port4_remo_mappings] && [dict exists $broad_port4_remo_mappings $broad_ip]} {
									set sca_remo_in3_end [dict get $broad_port4_remo_mappings $broad_ip]
								}
							}
						}
						return
					}
				}
				}
			}
		}

			foreach inip $scaninip {
				if {[llength $inip]} {
					if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
					set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
					if {[llength $ip_mem_handles]} {
						set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
					} else {
						set inip [get_in_connect_ip $inip $master_intf]
						if {[llength $inip]} {
							if {[string match -nocase [get_property IP_NAME $inip] "axi_vdma"]} {
								gen_frmbuf_rd_node $inip $drv_handle $port_node
							}
						}
					}
					if {[llength $inip]} {
						set sca_in_end ""
						set sca_remo_in_end ""
						if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
							set sca_in_end [dict get $end_mappings $inip]
							dtg_verbose "drv:$drv_handle inend:$sca_in_end"
						}
						if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
							set sca_remo_in_end [dict get $remo_mappings $inip]
							dtg_verbose "drv:$drv_handle inremoend:$sca_remo_in_end"
						}
						if {[llength $sca_remo_in_end]} {
							set scainnode [add_or_get_dt_node -n "endpoint" -l $sca_remo_in_end -p $port_node]
						}
						if {[llength $sca_in_end]} {
							hsi::utils::add_new_dts_param "$scainnode" "remote-endpoint" $sca_in_end reference
						}
					}
				} else {
					dtg_warning "$drv_handle pin s_axis is not connected..check your design"
				}
			}
		}
		if {$topology == 3} {
			set ports_node [add_or_get_dt_node -n "ports" -l csc_ports$drv_handle -p $node]
			hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
			set port_node [add_or_get_dt_node -n "port" -l csc_port0$drv_handle -u 0 -p $ports_node]
			hsi::utils::add_new_dts_param "${port_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
			hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 3 int
			set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
			hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" $max_data_width int

			set cscinip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis"]
			if {[llength $cscinip]} {
				foreach inip $cscinip {
					set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
					set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
					if {[llength $ip_mem_handles]} {
						set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
						if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
							gen_frmbuf_rd_node $inip $drv_handle $port_node
						}
					} else {
						set inip [get_in_connect_ip $inip $master_intf]
						if {[llength $inip]} {
							if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
								continue
							}
							if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
								gen_frmbuf_rd_node $inip $drv_handle $port_node
							}
						}
					}
					if {[llength $inip]} {
						set csc_in_end ""
						set csc_remo_in_end ""
						if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
							set csc_in_end [dict get $end_mappings $inip]
							dtg_verbose "drv:$drv_handle inend:$csc_in_end"
						}
						if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
							set csc_remo_in_end [dict get $remo_mappings $inip]
							dtg_verbose "drv:$drv_handle inremoend:$csc_remo_in_end"
						}
						if {[llength $csc_remo_in_end]} {
							set cscinnode [add_or_get_dt_node -n "endpoint" -l $csc_remo_in_end -p $port_node]
						}
						if {[llength $csc_in_end]} {
							hsi::utils::add_new_dts_param "$cscinnode" "remote-endpoint" $csc_in_end reference
						}
					}
				}
			} else {
				dtg_warning "$drv_handle pin s_axis is not connected..check your design"
			}
		}
	}
	if {[string match -nocase [get_property IP_NAME $ip] "v_demosaic"]} {
		set ports_node [add_or_get_dt_node -n "ports" -l demosaic_ports$drv_handle -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set port_node [add_or_get_dt_node -n "port" -l demosaic_port0$drv_handle -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
		hsi::utils::add_new_dts_param "${port_node}" "/* For cfa-pattern=rggb user needs to fill as per BAYER format */" "" comment
		hsi::utils::add_new_dts_param "$port_node" "xlnx,cfa-pattern" rggb string
		set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" $max_data_width int
		set demo_inip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video"]
		set len [llength $demo_inip]
		if {$len > 1} {
			for {set i 0 } {$i < $len} {incr i} {
				set temp_ip [lindex $demo_inip $i]
				if {[regexp -nocase "ila" $temp_ip match]} {
					continue
				}
				set demo_inip "$temp_ip"
			}
		}
		foreach inip $demo_inip {
			if {[llength $inip]} {
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
				if {![llength $ip_mem_handles]} {
					set broad_ip [get_broad_in_ip $inip]
					if {[llength $broad_ip]} {
						if {[string match -nocase [get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
							set intlen [llength $master_intf]
							set mipi_in_end ""
							set mipi_remo_in_end ""
							switch $intlen {
								"1" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
										set mipi_in_end [dict get $port1_broad_end_mappings $broad_ip]
								}
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
										set mipi_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
								}
								if {[info exists sca_remo_in_end] && [regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
									if {[llength $mipi_remo_in_end]} {
										set mipi_node [add_or_get_dt_node -n "endpoint" -l $mipi_remo_in_end -p $port_node]
									}
									if {[llength $mipi_in_end]} {
										hsi::utils::add_new_dts_param "$mipi_node" "remote-endpoint" $mipi_in_end reference
									}
								}

								}
								"2" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
										set mipi_in_end [dict get $port1_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
										set mipi_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
									}
									if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
										set mipi_in1_end [dict get $port2_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
										set mipi_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
									}
									if {[info exists mipi_remo_in_end] && [regexp -nocase $drv_handle "$mipi_remo_in_end" match]} {
										if {[llength $mipi_remo_in_end]} {
											set mipi_node [add_or_get_dt_node -n "endpoint" -l $mipi_remo_in_end -p $port_node]
									}
									if {[llength $mipi_in_end]} {
										hsi::utils::add_new_dts_param "$mipi_node" "remote-endpoint" $mipi_in_end reference
									}
									}
									if {[info exists mipi_remo_in1_end] && [regexp -nocase $drv_handle "$mipi_remo_in1_end" match]} {
										if {[llength $mipi_remo_in1_end]} {
											set mipi_node [add_or_get_dt_node -n "endpoint" -l $mipi_remo_in1_end -p $port_node]
									}
									if {[llength $mipi_in1_end]} {
										hsi::utils::add_new_dts_param "$mipi_node" "remote-endpoint" $mipi_in1_end reference
									}
									}
								}
							}
							return
						}
					}
				}
			}
		}
		if {[llength $demo_inip]} {
			if {[string match -nocase [get_property IP_NAME $demo_inip] "axis_switch"]} {
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $demo_inip]
			if {![llength $ip_mem_handles]} {
				set demo_in_end ""
				set demo_remo_in_end ""
				if {[info exists port1_end_mappings] && [dict exists $port1_end_mappings $demo_inip]} {
					set demo_in_end [dict get $port1_end_mappings $demo_inip]
					dtg_verbose "demo_in_end:$demo_in_end"
				}
				if {[info exists axis_port1_remo_mappings] && [dict exists $axis_port1_remo_mappings $demo_inip]} {
					set demo_remo_in_end [dict get $axis_port1_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
				}
				if {[info exists port2_end_mappings] && [dict exists $port2_end_mappings $demo_inip]} {
					set demo_in1_end [dict get $port2_end_mappings $demo_inip]
					dtg_verbose "demo_in1_end:$demo_in1_end"
				}
				if {[info exists axis_port2_remo_mappings] && [dict exists $axis_port2_remo_mappings $demo_inip]} {
					set demo_remo_in1_end [dict get $axis_port2_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in1_end:$demo_remo_in1_end"
				}
				if {[info exists port3_end_mappings] && [dict exists $port3_end_mappings $demo_inip]} {
					set demo_in2_end [dict get $port3_end_mappings $demo_inip]
					dtg_verbose "demo_in2_end:$demo_in2_end"
				}
				if {[info exists axis_port3_remo_mappings] && [dict exists $axis_port3_remo_mappings $demo_inip]} {
					set demo_remo_in2_end [dict get $axis_port3_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in2_end:$demo_remo_in2_end"
				}
				if {[info exists port4_end_mappings] && [dict exists $port4_end_mappings $demo_inip]} {
					set demo_in3_end [dict get $port4_end_mappings $demo_inip]
					dtg_verbose "demo_in3_end:$demo_in3_end"
				}
				if {[info exists axis_port4_remo_mappings] && [dict exists $axis_port4_remo_mappings $demo_inip]} {
					set demo_remo_in3_end [dict get $axis_port4_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in3_end:$demo_remo_in3_end"
				}
				set drv [split $demo_remo_in_end "-"]
				set handle [lindex $drv 0]
				if {[info exists demo_remo_in_end] && [regexp -nocase $drv_handle "$demo_remo_in_end" match]} {
					if {[llength $demo_remo_in_end]} {
						set demosaic_node [add_or_get_dt_node -n "endpoint" -l $demo_remo_in_end -p $port_node]
					}
					if {[llength $demo_in_end]} {
						hsi::utils::add_new_dts_param "$demosaic_node" "remote-endpoint" $demo_in_end reference
					}
					dtg_verbose "****DEMO_END1****"
				}
				if {[info exists demo_remo_in1_end] && [regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
					if {[llength $demo_remo_in1_end]} {
						set demosaic_node1 [add_or_get_dt_node -n "endpoint" -l $demo_remo_in1_end -p $port_node]
					}
					if {[llength $demo_in1_end]} {
						hsi::utils::add_new_dts_param "$demosaic_node1" "remote-endpoint" $demo_in1_end reference
					}
					dtg_verbose "****DEMO_END2****"
				}
				if {[info exists demo_remo_in2_end] && [regexp -nocase $drv_handle "$demo_remo_in2_end" match]} {
					if {[llength $demo_remo_in2_end]} {
						set demosaic_node2 [add_or_get_dt_node -n "endpoint" -l $demo_remo_in2_end -p $port_node]
					}
					if {[llength $demo_in2_end]} {
						hsi::utils::add_new_dts_param "$demosaic_node2" "remote-endpoint" $demo_in2_end reference
					}
					dtg_verbose "****DEMO_END3****"
				}
				if {[info exists demo_remo_in3_end] && [regexp -nocase $drv_handle "$demo_remo_in3_end" match]} {
					if {[llength $demo_remo_in3_end]} {
						set demosaic_node3 [add_or_get_dt_node -n "endpoint" -l $demo_remo_in3_end -p $port_node]
					}
					if {[llength $demo_in3_end]} {
						hsi::utils::add_new_dts_param "$demosaic_node3" "remote-endpoint" $demo_in3_end reference
					}
					dtg_verbose "****DEMO_END3****"
				}
				return
			} else {
				set demo_in_end ""
				set demo_remo_in_end ""
				if {[info exists axis_switch_port1_end_mappings] && [dict exists $axis_switch_port1_end_mappings $demo_inip]} {
					set demo_in_end [dict get $axis_switch_port1_end_mappings $demo_inip]
					dtg_verbose "demo_in_end:$demo_in_end"
				}
				if {[info exists axis_switch_port1_remo_mappings] && [dict exists $axis_switch_port1_remo_mappings $demo_inip]} {
					set demo_remo_in_end [dict get $axis_switch_port1_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
				}
				if {[info exists axis_switch_port2_end_mappings] && [dict exists $axis_switch_port2_end_mappings $demo_inip]} {
					set demo_in1_end [dict get $axis_switch_port2_end_mappings $demo_inip]
					dtg_verbose "demo_in1_end:$demo_in1_end"
				}
				if {[info exists axis_switch_port2_remo_mappings] && [dict exists $axis_switch_port2_remo_mappings $demo_inip]} {
					set demo_remo_in1_end [dict get $axis_switch_port2_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in1_end:$demo_remo_in1_end"
				}
				if {[info exists axis_switch_port3_end_mappings] && [dict exists $axis_switch_port3_end_mappings $demo_inip]} {
					set demo_in2_end [dict get $axis_switch_port3_end_mappings $demo_inip]
					dtg_verbose "demo_in2_end:$demo_in2_end"
				}
				if {[info exists axis_switch_port3_remo_mappings] && [dict exists $axis_switch_port3_remo_mappings $demo_inip]} {
					set demo_remo_in2_end [dict get $axis_switch_port3_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in2_end:$demo_remo_in2_end"
				}
				if {[info exists axis_switch_port4_end_mappings] && [dict exists $axis_switch_port4_end_mappings $demo_inip]} {
					set demo_in3_end [dict get $axis_switch_port4_end_mappings $demo_inip]
					dtg_verbose "demo_in3_end:$demo_in3_end"
				}
				if {[info exists axis_switch_port4_remo_mappings] && [dict exists $axis_switch_port4_remo_mappings $demo_inip]} {
					set demo_remo_in3_end [dict get $axis_switch_port4_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in3_end:$demo_remo_in3_end"
				}
				set drv [split $demo_remo_in_end "-"]
				set handle [lindex $drv 0]
				if {[regexp -nocase $drv_handle "$demo_remo_in_end" match]} {
					if {[llength $demo_remo_in_end]} {
						set demosaic_node [add_or_get_dt_node -n "endpoint" -l $demo_remo_in_end -p $port_node]
					}
					if {[llength $demo_in_end]} {
						hsi::utils::add_new_dts_param "$demosaic_node" "remote-endpoint" $demo_in_end reference
					}
					dtg_verbose "****DEMO_END1****"
				}
				if {[regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
					if {[llength $demo_remo_in1_end]} {
						set demosaic_node1 [add_or_get_dt_node -n "endpoint" -l $demo_remo_in1_end -p $port_node]
					}
					if {[llength $demo_in1_end]} {
						hsi::utils::add_new_dts_param "$demosaic_node1" "remote-endpoint" $demo_in1_end reference
					}
					dtg_verbose "****DEMO_END2****"
				}
			}
			}
		}
		set inip ""
		if {[llength $demo_inip]} {
			foreach inip $demo_inip {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
				} else {
					if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
				}
				if {[llength $inip]} {
					set demo_in_end ""
					set demo_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set demo_in_end [dict get $end_mappings $inip]
						dtg_verbose "demo_in_end:$demo_in_end"
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set demo_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
					}
					if {[llength $demo_remo_in_end]} {
						set demosaic_node [add_or_get_dt_node -n "endpoint" -l $demo_remo_in_end -p $port_node]
					}
					if {[llength $demo_in_end]} {
						hsi::utils::add_new_dts_param "$demosaic_node" "remote-endpoint" $demo_in_end reference
					}
				}
			}
		} else {
			dtg_warning "$drv_handle pin s_axis is not connected..check your design"
		}
		dtg_verbose "***************DEMOEND****************"
	}
	if {[string match -nocase [get_property IP_NAME $ip] "v_gamma_lut"]} {
		set ports_node [add_or_get_dt_node -n "ports" -l gamma_ports$drv_handle -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int

		set port_node [add_or_get_dt_node -n "port" -l gamma_port0$drv_handle -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
		set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" $max_data_width int
		set gamma_inip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video"]
		set inip ""
		if {[llength $gamma_inip]} {
			foreach inip $gamma_inip {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
				} else {
					if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
				}
				if {[llength $inip]} {
					set gamma_in_end ""
					set gamma_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set gamma_in_end [dict get $end_mappings $inip]
						dtg_verbose "gamma_in_end:$gamma_in_end"
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set gamma_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "gamma_remo_in_end:$gamma_remo_in_end"
					}
					if {[llength $gamma_remo_in_end]} {
						set gamma_node [add_or_get_dt_node -n "endpoint" -l $gamma_remo_in_end -p $port_node]
					}
					if {[llength $gamma_in_end]} {
						hsi::utils::add_new_dts_param "$gamma_node" "remote-endpoint" $gamma_in_end reference
					}
				}
			}
		} else {
			dtg_warning "$drv_handle pin s_axis_video is not connected..check your design"
		}
	}

	if {[string match -nocase [get_property IP_NAME $ip] "mipi_dsi_tx_subsystem"]} {
		set dsitx_inip [get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS"]
		if {![llength $dsitx_inip]} {
			dtg_warning "$drv_handle pin S_AXIS is not connected ..check your design"
		}
		set port_node [add_or_get_dt_node -n "port" -l encoder_dsi_port$drv_handle -u 0 -p $node]
		hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
		set inip ""
		foreach inip $dsitx_inip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port_node
					}
				} else {
					if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					puts "******************dsitx****************"
					set inip [get_in_connect_ip $inip $master_intf]
					if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port_node
					}
				}
			}
		}
		if {[llength $inip]} {
			set dsitx_in_end ""
			set dsitx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
				set dsitx_in_end [dict get $end_mappings $inip]
				dtg_verbose "dsitx_in_end:$dsitx_in_end"
			}
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
				set dsitx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "dsitx_remo_in_end:$dsitx_remo_in_end"
			}
			if {[llength $dsitx_remo_in_end]} {
				set dsitx_node [add_or_get_dt_node -n "endpoint" -l $dsitx_remo_in_end -p $port_node]
			}
			if {[llength $dsitx_in_end]} {
				hsi::utils::add_new_dts_param "$dsitx_node" "remote-endpoint" $dsitx_in_end reference
			}
		}
	}

	if {[string match -nocase [get_property IP_NAME $ip] "v_smpte_uhdsdi_tx_ss"]} {
		set ports_node [add_or_get_dt_node -n "ports" -l sditx_ports$drv_handle -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set sdi_port_node [add_or_get_dt_node -n "port" -l encoder_sdi_port$drv_handle -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "$sdi_port_node" "reg" 0 int
		set sditx_in_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_IN"]
		if {![llength $sditx_in_ip]} {
			dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
		}
		set inip ""
		foreach inip $sditx_in_ip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $sdi_port_node
					}
				} else {
					if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
					if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $sdi_port_node
					}
				}
			}
		}
		if {[llength $inip]} {
			set sditx_in_end ""
			set sditx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
				set sditx_in_end [dict get $end_mappings $inip]
				dtg_verbose "sditx_in_end:$sditx_in_end"
			}
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
				set sditx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "sditx_remo_in_end:$sditx_remo_in_end"
			}
			if {[llength $sditx_remo_in_end]} {
				set sditx_node [add_or_get_dt_node -n "endpoint" -l $sditx_remo_in_end -p $sdi_port_node]
			}
			if {[llength $sditx_in_end]} {
				hsi::utils::add_new_dts_param "$sditx_node" "remote-endpoint" $sditx_in_end reference
			}
		}
	}
	if {[string match -nocase [get_property IP_NAME $ip] "v_hdmi_tx_ss"] || [string match -nocase [get_property IP_NAME $ip] "v_hdmi_txss1"]} {
		set ports_node [add_or_get_dt_node -n "ports" -l hdmitx_ports$drv_handle -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set hdmi_port_node [add_or_get_dt_node -n "port" -l encoder_hdmi_port$drv_handle -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "$hdmi_port_node" "reg" 0 int
		set hdmitx_in_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_IN"]
		if {![llength $hdmitx_in_ip]} {
			dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
		}
		set inip ""
		set axis_sw_nm ""
		foreach inip $hdmitx_in_ip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $hdmitx_in_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node
					}
				} else {
					if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					# Check if slice is connected to axis_switch(NM)
					if {[string match -nocase [get_property IP_NAME $inip] "axis_register_slice"]} {
						set intf "S_AXIS"
						set streamin_ip [get_connected_stream_ip [get_cells -hier $inip] $intf]
						if {[llength $streamin_ip]} {
							set ip_mem_handles [hsi::utils::get_ip_mem_ranges $streamin_ip]
						}
						if {![llength $ip_mem_handles] && [string match -nocase [get_property IP_NAME $streamin_ip] "axis_switch"]} {
							set inip "$streamin_ip"
							set axis_sw_nm "1"
						}
					}
					if {![llength $axis_sw_nm]} {
						set inip [get_in_connect_ip $inip $master_intf]
					}
					if {[string match -nocase [get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node
					}
				}
			}
		}
		if {[llength $inip]} {
			set hdmitx_in_end ""
			set hdmitx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
				set hdmitx_in_end [dict get $end_mappings $inip]
				dtg_verbose "hdmitx_in_end:$hdmitx_in_end"
			}
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
				set hdmitx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "hdmitx_remo_in_end:$hdmitx_remo_in_end"
			}
			if {[llength $hdmitx_remo_in_end]} {
				set hdmitx_node [add_or_get_dt_node -n "endpoint" -l $hdmitx_remo_in_end -p $hdmi_port_node]
			}
			if {[llength $hdmitx_in_end]} {
				hsi::utils::add_new_dts_param "$hdmitx_node" "remote-endpoint" $hdmitx_in_end reference
			}
			# Add endpoints if IN IP is axis_switch and NM
			if {[llength $axis_sw_nm]} {
				update_axis_switch_endpoints $inip $hdmi_port_node $drv_handle
			}
		}
	}
	 if {[string match -nocase [get_property IP_NAME $ip] "v_scenechange"]} {
		set memory_scd [get_property CONFIG.MEMORY_BASED [get_cells -hier $drv_handle]]
		if {$memory_scd == 1} {
			#memory scd
			return
		}
		set scd_ports_node [add_or_get_dt_node -n "scd" -l scd_ports$drv_handle -p $node]
		hsi::utils::add_new_dts_param "$scd_ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$scd_ports_node" "#size-cells" 0 int
		set port_node [add_or_get_dt_node -n "port" -l scd_port0$drv_handle -u 0 -p $scd_ports_node]
		hsi::utils::add_new_dts_param "$port_node" "reg" 0 int

		set scd_inip [get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
		if {![llength $scd_inip]} {
			dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected...check your design"
		}
		set broad_ip [get_broad_in_ip $scd_inip]
		if {[llength $broad_ip]} {
		if {[string match -nocase [get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
			set scd_in_end ""
			set scd_remo_in_end ""
			if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
				set scd_in_end [dict get $port1_broad_end_mappings $broad_ip]
			}
			if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
				set scd_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
			}
			if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
				set scd_in1_end [dict get $port2_broad_end_mappings $broad_ip]
			}
			if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
				set scd_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
			}
			if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
				set scd_in2_end [dict get $port3_broad_end_mappings $broad_ip]
			}
			if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
				set scd_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
			}
			if {[info exists port4_broad_end_mappings] && [dict exists $port4_broad_end_mappings $broad_ip]} {
				set scd_in3_end [dict get $port4_broad_end_mappings $broad_ip]
			}
			if {[info exists broad_port4_remo_mappings] && [dict exists $broad_port4_remo_mappings $broad_ip]} {
				set scd_remo_in3_end [dict get $broad_port4_remo_mappings $broad_ip]
			}
			if {[info exists scd_remo_in_end] && [regexp -nocase $drv_handle "$scd_remo_in_end" match]} {
				if {[llength $scd_remo_in_end]} {
					set scd_node [add_or_get_dt_node -n "endpoint" -l $scd_remo_in_end -p $port_node]
				}
				if {[llength $scd_in_end]} {
					hsi::utils::add_new_dts_param "$scd_node" "remote-endpoint" $scd_in_end reference
				}
			}
			if {[info exists scd_remo_in1_end] && [regexp -nocase $drv_handle "$scd_remo_in1_end" match]} {
				if {[llength $scd_remo_in1_end]} {
					set scd_node [add_or_get_dt_node -n "endpoint" -l $scd_remo_in1_end -p $port_node]
				}
				if {[llength $scd_in1_end]} {
					hsi::utils::add_new_dts_param "$scd_node" "remote-endpoint" $scd_in1_end reference
				}
			}
			if {[info exists scd_remo_in2_end] && [regexp -nocase $drv_handle "$scd_remo_in2_end" match]} {
				if {[llength $scd_remo_in2_end]} {
					set scd_node [add_or_get_dt_node -n "endpoint" -l $scd_remo_in2_end -p $port_node]
				}
				if {[llength $scd_in2_end]} {
					hsi::utils::add_new_dts_param "$scd_node" "remote-endpoint" $scd_in2_end reference
				}
			}
			if {[info exists scd_remo_in3_end] && [regexp -nocase $drv_handle "$scd_remo_in3_end" match]} {
				if {[llength $scd_remo_in3_end]} {
					set scd_node [add_or_get_dt_node -n "endpoint" -l $scd_remo_in3_end -p $port_node]
				}
				if {[llength $scd_in3_end]} {
					hsi::utils::add_new_dts_param "$scd_node" "remote-endpoint" $scd_in3_end reference
				}
			}
			return
		}
		}
		foreach inip $scd_inip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
				} else {
					if {[string match -nocase [get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
				}
				if {[llength $inip]} {
					set scd_in_end ""
					set scd_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set scd_in_end [dict get $end_mappings $inip]
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set scd_remo_in_end [dict get $remo_mappings $inip]
					}
					if {[llength $scd_remo_in_end]} {
						set scd_node [add_or_get_dt_node -n "endpoint" -l $scd_remo_in_end -p $port_node]
					}
					if {[llength $scd_in_end]} {
						hsi::utils::add_new_dts_param "$scd_node" "remote-endpoint" $scd_in_end reference
					}
				}
			}
		}
	}
	if {[string match -nocase [get_property IP_NAME $ip] "v_tpg"]} {
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "ps7_cortexa9"]} {
			#TBF
			return
		}
		set ports_node [add_or_get_dt_node -n "ports" -l tpg_ports$drv_handle -p $node]
		set port0_node [add_or_get_dt_node -n "port" -l tpg_port0$drv_handle -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "$port0_node" "reg" 0 int
		hsi::utils::add_new_dts_param "${port0_node}" "/* Fill the field xlnx,video-format based on user requirement */" "" comment
		hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-format" 2 int
		set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
		hsi::utils::add_new_dts_param "$port0_node" "xlnx,video-width" $max_data_width int
		set tpg_inip [get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
                if {![llength $tpg_inip]} {
                        dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected...check your design"
                }
		set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $tpg_inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
		set inip [get_in_connect_ip $tpg_inip $master_intf]
		if {[llength $inip]} {
			set tpg_in_end ""
			set tpg_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
				set tpg_in_end [dict get $end_mappings $inip]
			}
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
				set tpg_remo_in_end [dict get $remo_mappings $inip]
			}
			if {[llength $tpg_remo_in_end]} {
				set tpg_node [add_or_get_dt_node -n "endpoint" -l $tpg_remo_in_end -p $port0_node]
			}
			if {[llength $tpg_in_end]} {
				hsi::utils::add_new_dts_param "$tpg_node" "remote-endpoint" $tpg_in_end reference
			}
		}
	}
	set ips [get_cells -hier -filter {IP_NAME == "axis_switch"}]
	foreach ip $ips {
		if {[llength $ip]} {
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $ip]
			if {![llength $ip_mem_handles]} {
			set axis_ip [get_property IP_NAME $ip]
			set default_dts [set_drv_def_dts $ip]
			set unit_addr [get_baseaddr ${ip} no_prefix]
			if { ![string equal $unit_addr "-1"] } {
				break
			}
			set label $ip
			set bus_node [add_or_get_bus_node $ip $default_dts]
			set dev_type [get_property IP_NAME [get_cell -hier [get_cells -hier $ip]]]
			if {[llength $axis_ip]} {
				set intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set inip [get_in_connect_ip $ip $intf]
				if {[llength $inip]} {
					set inipname [get_property IP_NAME $inip]
					set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_hdmi_txss1 v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
					if {[lsearch  -nocase $valid_mmip_list $inipname] >= 0} {
						set rt_node [add_or_get_dt_node -n ${dev_type} -l ${label} -u 0 -d ${default_dts} -p $bus_node -auto_ref_parent]
						set ports_node [add_or_get_dt_node -n "ports" -l axis_switch_ports$ip -p $rt_node]
						gen_axis_switch_clk_property $ip $default_dts $rt_node
						hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
						set port_node [add_or_get_dt_node -n "port" -l axis_switch_port0$ip -u 0 -p $ports_node]
						hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
						if {[llength $inip]} {
							set axis_switch_in_end ""
							set axis_switch_remo_in_end ""
							if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
								set axis_switch_in_end [dict get $end_mappings $inip]
								dtg_verbose "drv:$ip inend:$axis_switch_in_end"
							}
							if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
								set axis_switch_remo_in_end [dict get $remo_mappings $inip]
								dtg_verbose "drv:$ip inremoend:$axis_switch_remo_in_end"
							}
							if {[llength $axis_switch_remo_in_end]} {
								set axisinnode [add_or_get_dt_node -n "endpoint" -l $axis_switch_remo_in_end -p $port_node]
							}
							if {[llength $axis_switch_in_end]} {
								hsi::utils::add_new_dts_param "$axisinnode" "remote-endpoint" $axis_switch_in_end reference
							}
						}
					}
				}
			}
		}
	}
	}
	set ip [get_cells -hier $drv_handle]
	if {[string match -nocase [get_property IP_NAME $ip] "axis_switch"]} {
		set axis_ip [get_property IP_NAME $ip]
		set default_dts [set_drv_def_dts $ip]
		set unit_addr [get_baseaddr ${ip} no_prefix]
		set bus_node [add_or_get_bus_node $ip $default_dts]
		set dev_type [get_property IP_NAME [get_cell -hier [get_cells -hier $ip]]]
		set intf "S00_AXIS"
		set inips [get_axis_switch_in_connect_ip $ip $intf]
		foreach inip $inips {
			if {[llength $inip]} {
				set inipname [get_property IP_NAME $inip]
				set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_hdmi_txss1 v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
					if {[lsearch -nocase $valid_mmip_list $inipname] >= 0} {
						set ports_node [add_or_get_dt_node -n "ports" -l axis_switch_ports$drv_handle -p $node]
						hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
						hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
						set port_node [add_or_get_dt_node -n "port" -l axis_switch_port0$ip -u 0 -p $ports_node]
						hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
						if {[llength $inip]} {
							set axis_switch_in_end ""
							set axis_switch_remo_in_end ""
							if {[info exists axis_switch_in_end_mappings] && [dict exists $axis_switch_in_end_mappings $inip]} {
								set axis_switch_in_end [dict get $axis_switch_in_end_mappings $inip]
								dtg_verbose "drv:$ip inend:$axis_switch_in_end"
							}
							if {[info exists axis_switch_in_remo_mappings] && [dict exists $axis_switch_in_remo_mappings $inip]} {
								set axis_switch_remo_in_end [dict get $axis_switch_in_remo_mappings $inip]
								dtg_verbose "drv:$ip inremoend:$axis_switch_remo_in_end"
							}
							if {[llength $axis_switch_remo_in_end]} {
								set axisinnode [add_or_get_dt_node -n "endpoint" -l $axis_switch_remo_in_end -p $port_node]
							}
							if {[llength $axis_switch_in_end]} {
								hsi::utils::add_new_dts_param "$axisinnode" "remote-endpoint" $axis_switch_in_end reference
							}
						}
					}
				}
			}
		}
	set ips [get_cells -hier -filter {IP_NAME == "axis_broadcaster"}]
	foreach ip $ips {
                if {[llength $ip]} {
                        set axis_broad_ip [get_property IP_NAME $ip]
                        set default_dts [set_drv_def_dts $ip]
			# broad_ip means broadcaster input ip is connected to another ip
			set broad_ip [get_broad_in_ip $ip]
			set validate_ip 1
			if {[llength $broad_ip]} {
				if {[string match -nocase [get_property IP_NAME $broad_ip] "v_proc_ss"]} {
				# set validate ip is 0 when axis_broadcaster input ip is connect to v_proc_ss to skip the below checks
					set validate_ip 0
				}
			}
			# add unit_addr and ip_type check when axis_broadcaster input ip is connected with other ips
			if {$validate_ip} {
				set unit_addr [get_baseaddr ${ip} no_prefix]
				if { ![string equal $unit_addr "-1"] } {
					break
				}
				set ip_type [get_property IP_TYPE $ip]
				if {[string match -nocase $ip_type "BUS"]} {
					break
				}
			}
                        set label $ip
                        set bus_node [add_or_get_bus_node $ip $default_dts]
                        set dev_type [get_property IP_NAME [get_cell -hier [get_cells -hier $ip]]]
			set rt_node [add_or_get_dt_node -n "axis_broadcaster$ip" -l ${label} -u 0 -d ${default_dts} -p $bus_node -auto_ref_parent]
			if {[llength $axis_broad_ip]} {
				set intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set inip [get_in_connect_ip $ip $intf]
				if {[llength $broad]} {
				if {[llength $inip]} {
					set inipname [get_property IP_NAME $inip]
					set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_hdmi_txss1 v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
				if {[lsearch  -nocase $valid_mmip_list $inipname] >= 0} {
				set ports_node [add_or_get_dt_node -n "ports" -l axis_broadcaster_ports$ip -p $rt_node]
				hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
				hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
				set port_node [add_or_get_dt_node -n "port" -l axis_broad_port0$ip -u 0 -p $ports_node]
				hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
				if {[llength $inip]} {
					set axis_broad_in_end ""
					set axis_broad_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set axis_broad_in_end [dict get $end_mappings $inip]
						dtg_verbose "drv:$ip inend:$axis_broad_in_end"
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set axis_broad_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "drv:$ip inremoend:$axis_broad_remo_in_end"
					}
					if {[llength $axis_broad_remo_in_end]} {
						set axisinnode [add_or_get_dt_node -n "endpoint" -l $axis_broad_remo_in_end -p $port_node]
					}
					if {[llength $axis_broad_in_end]} {
						hsi::utils::add_new_dts_param "$axisinnode" "remote-endpoint" $axis_broad_in_end reference
					}
					}
				}
				}
			}
			}
		}
	}
}

proc get_axis_switch_in_connect_ip {ip intfpins} {
	puts "get_axis_switch_in_connect_ip:$ip $intfpins"
	global connectip ""
	foreach intf $intfpins {
		set connectip [get_connected_stream_ip [get_cells -hier $ip] $intf]
		puts "connectip:$connectip"
		foreach cip $connectip {
			if {[llength $cip]} {
				set ipname [get_property IP_NAME $cip]
				#puts "ipname:$ipname"
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $cip]
				if {[llength $ip_mem_handles]} {
					break
				} else {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $cip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				get_axis_switch_in_connect_ip $cip $master_intf
				}
			}
		}
	}
	return $connectip
}

proc gen_remoteendpoint {drv_handle value} {
	global remo_mappings
	dict append remo_mappings $drv_handle $value
	set val [dict get $remo_mappings $drv_handle]
}

proc gen_axis_port1_remoteendpoint {drv_handle value} {
	global axis_port1_remo_mappings
	dict append axis_port1_remo_mappings $drv_handle $value
	set val [dict get $axis_port1_remo_mappings $drv_handle]
}

proc gen_axis_port2_remoteendpoint {drv_handle value} {
	global axis_port2_remo_mappings
	dict append axis_port2_remo_mappings $drv_handle $value
	set val [dict get $axis_port2_remo_mappings $drv_handle]
}

proc gen_axis_port3_remoteendpoint {drv_handle value} {
	global axis_port3_remo_mappings
	dict append axis_port3_remo_mappings $drv_handle $value
	set val [dict get $axis_port3_remo_mappings $drv_handle]
}

proc gen_axis_port4_remoteendpoint {drv_handle value} {
	global axis_port4_remo_mappings
	dict append axis_port4_remo_mappings $drv_handle $value
	set val [dict get $axis_port4_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port1 {drv_handle value} {
        global broad_port1_remo_mappings
        dict append broad_port1_remo_mappings $drv_handle $value
        set val [dict get $broad_port1_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port2 {drv_handle value} {
        global broad_port2_remo_mappings
        dict append broad_port2_remo_mappings $drv_handle $value
        set val [dict get $broad_port2_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port3 {drv_handle value} {
        global broad_port3_remo_mappings
        dict append broad_port3_remo_mappings $drv_handle $value
        set val [dict get $broad_port3_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port4 {drv_handle value} {
        global broad_port4_remo_mappings
        dict append broad_port4_remo_mappings $drv_handle $value
        set val [dict get $broad_port4_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port5 {drv_handle value} {
        global broad_port5_remo_mappings
        dict append broad_port5_remo_mappings $drv_handle $value
        set val [dict get $broad_port5_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port6 {drv_handle value} {
        global broad_port6_remo_mappings
        dict append broad_port6_remo_mappings $drv_handle $value
        set val [dict get $broad_port6_remo_mappings $drv_handle]
}

proc gen_frmbuf_rd_node {ip drv_handle sdi_port_node} {
	set frmbuf_rd_node [add_or_get_dt_node -n "endpoint" -l encoder$drv_handle -p $sdi_port_node]
	hsi::utils::add_new_dts_param "$frmbuf_rd_node" "remote-endpoint" $ip$drv_handle reference
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}
	set pl_display [add_or_get_dt_node -n "drm-pl-disp-drv$drv_handle" -l "v_pl_disp$drv_handle" -p $bus_node]
	hsi::utils::add_new_dts_param $pl_display "compatible" "xlnx,pl-disp" string
	hsi::utils::add_new_dts_param $pl_display "dmas" "$ip 0" reference
	hsi::utils::add_new_dts_param $pl_display "dma-names" "dma0" string
	hsi::utils::add_new_dts_param "${pl_display}" "/* Fill the field xlnx,vformat based on user requirement */" "" comment
	hsi::utils::add_new_dts_param $pl_display "xlnx,vformat" "YUYV" string
	set pl_display_port_node [add_or_get_dt_node -n "port" -l pl_display_port$drv_handle -u 0 -p $pl_display]
	hsi::utils::add_new_dts_param "$pl_display_port_node" "reg" 0 int
	set pl_disp_crtc_node [add_or_get_dt_node -n "endpoint" -l $ip$drv_handle -p $pl_display_port_node]
	hsi::utils::add_new_dts_param "$pl_disp_crtc_node" "remote-endpoint" encoder$drv_handle reference
}

proc gen_broadcaster {ip} {
	dtg_verbose "+++++++++gen_broadcaster:$ip"
	set count 0
	set inputip ""
	set outip ""
	set connectip ""
	set compatible [get_comp_str $ip]
	set intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set inip [get_connected_stream_ip [get_cells -hier $ip] $intf]
	set inip [get_in_connect_ip $ip $intf]
	set default_dts [set_drv_def_dts $ip]
	set bus_node [add_or_get_bus_node $ip $default_dts]
	set broad_node [add_or_get_dt_node -n "axis_broadcaster$ip" -l $ip -u 0 -p $bus_node]
	set ports_node [add_or_get_dt_node -n "ports" -l axis_broadcaster_ports$ip -p $broad_node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	hsi::utils::add_new_dts_param "$broad_node" "compatible" "$compatible" string
	set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
	set broad 10
	hsi::utils::set_os_parameter_value "broad" $broad
	foreach intf $master_intf {
		set connectip [get_connected_stream_ip [get_cells -hier $ip] $intf]
		if {[llength $connectip]} {
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
			if {![llength $ip_mem_handles]} {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				set connectip [get_connected_stream_ip [get_cells -hier $connectip] $master_intf]
				if {[llength $connectip]} {
					set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
					if {![llength $ip_mem_handles]} {
						set master2_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
						set connectip [get_connected_stream_ip [get_cells -hier $connectip] $master2_intf]
					}
					if {[llength $connectip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
						if {![llength $ip_mem_handles]} {
							set master3_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
							set connectip [get_connected_stream_ip [get_cells -hier $connectip] $master3_intf]
						}
					}
				}
			}
			incr count
			set port_node [add_or_get_dt_node -n "port" -l axis_broad_port$count$ip -u $count -p $ports_node]
			hsi::utils::add_new_dts_param "$port_node" "reg" $count int
			set axis_node [add_or_get_dt_node -n "endpoint" -l axis_broad_out$count$ip -p $port_node]
			if {$count <= $count-1} {
				gen_broad_endpoint_port$count $ip "axis_broad_out$count$ip"
			}
			hsi::utils::add_new_dts_param "$axis_node" "remote-endpoint" $connectip$ip reference
			if {$count <= $count-1} {
				gen_broad_remoteendpoint_port$count $ip $connectip$ip
			}
			append inputip " " $connectip
			append outip " " $connectip$ip
		}
	}
	if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
		gen_broad_frmbuf_wr_node $inputip $outip $ip $count
	}
}

proc gen_axis_switch {ip} {
	set compatible [get_comp_str $ip]
	dtg_verbose "+++++++++gen_axis_switch:$ip"
	set routing_mode [get_property CONFIG.ROUTING_MODE [get_cells -hier $ip]]
	if {$routing_mode == 1} {
		# Routing_mode is 1 means it is a memory mapped
		return
	}
	set intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set inip [get_connected_stream_ip [get_cells -hier $ip] $intf]
	set intf1 [::hsi::get_intf_pins -of_objects [get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set iip [get_connected_stream_ip [get_cells -hier $inip] $intf1]
	set inip [get_in_connect_ip $ip $intf]
	set default_dts [set_drv_def_dts $ip]
	set bus_node [add_or_get_bus_node $ip $default_dts]
	set switch_node [add_or_get_dt_node -n "axis_switch_$ip" -l $ip -u 0 -p $bus_node]
	set ports_node [add_or_get_dt_node -n "ports" -l axis_switch_ports$ip -p $switch_node]
	hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
	set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
	hsi::utils::add_new_dts_param "$switch_node" "xlnx,routing-mode" $routing_mode int
	set num_si [get_property CONFIG.NUM_SI [get_cells -hier $ip]]
	hsi::utils::add_new_dts_param "$switch_node" "xlnx,num-si-slots" $num_si int
	set num_mi [get_property CONFIG.NUM_MI [get_cells -hier $ip]]
	hsi::utils::add_new_dts_param "$switch_node" "xlnx,num-mi-slots" $num_mi int
	hsi::utils::add_new_dts_param "$switch_node" "compatible" "$compatible" string
	set count 0
	foreach intf $master_intf {
		set connectip [get_connected_stream_ip [get_cells -hier $ip] $intf]
		#Get next out IP if slice connected
		if {[llength $connectip] && \
			[string match -nocase [get_property IP_NAME $connectip] "axis_register_slice"]} {
			set intf "M_AXIS"
			set connectip [get_connected_stream_ip [get_cells -hier $connectip] "$intf"]
		}
		set len [llength $connectip]
		if {$len > 1} {
			for {set i 0 } {$i < $len} {incr i} {
				set temp_ip [lindex $connectip $i]
				if {[regexp -nocase "ila" $temp_ip match]} {
					continue
				}
				set connectip "$temp_ip"
			}
		}
		if {[llength $connectip]} {
			incr count
		}
		if {$count == 1} {
			set port_node [add_or_get_dt_node -n "port" -l axis_switch_port1$ip -u 1 -p $ports_node]
			hsi::utils::add_new_dts_param "$port_node" "reg" 1 int
			set axis_node [add_or_get_dt_node -n "endpoint" -l axis_switch_out1$ip -p $port_node]
			gen_axis_port1_endpoint $ip "axis_switch_out1$ip"
			hsi::utils::add_new_dts_param "$axis_node" "remote-endpoint" $connectip$ip reference
			gen_axis_port1_remoteendpoint $ip $connectip$ip
		}
		if {$count == 2} {
			set port_node [add_or_get_dt_node -n "port" -l axis_switch_port2$ip -u 2 -p $ports_node]
			hsi::utils::add_new_dts_param "$port_node" "reg" 2 int
			set axis_node [add_or_get_dt_node -n "endpoint" -l axis_switch_out2$ip -p $port_node]
			gen_axis_port2_endpoint $ip "axis_switch_out2$ip"
			hsi::utils::add_new_dts_param "$axis_node" "remote-endpoint" $connectip$ip reference
			gen_axis_port2_remoteendpoint $ip $connectip$ip
		}
		if {$count == 3} {
			set port_node [add_or_get_dt_node -n "port" -l axis_switch_port3$ip -u 3 -p $ports_node]
			hsi::utils::add_new_dts_param "$port_node" "reg" 3 int
			set axis_node [add_or_get_dt_node -n "endpoint" -l axis_switch_out3$ip -p $port_node]
			gen_axis_port3_endpoint $ip "axis_switch_out3$ip"
			hsi::utils::add_new_dts_param "$axis_node" "remote-endpoint" $connectip$ip reference
			gen_axis_port3_remoteendpoint $ip $connectip$ip
		}
		if {$count == 4} {
			set port_node [add_or_get_dt_node -n "port" -l axis_switch_port4$ip -u 4 -p $ports_node]
			hsi::utils::add_new_dts_param "$port_node" "reg" 4 int
			set axis_node [add_or_get_dt_node -n "endpoint" -l axis_switch_out4$ip -p $port_node]
			gen_axis_port4_endpoint $ip "axis_switch_out4$ip"
			hsi::utils::add_new_dts_param "$axis_node" "remote-endpoint" $connectip$ip reference
			gen_axis_port4_remoteendpoint $ip $connectip$ip
		}
	}
}

proc gen_broad_frmbuf_wr_node {inputip outip drv_handle count} {
        set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
        if {$dt_overlay} {
                set bus_node "amba"
        } else {
                set bus_node "amba_pl"
        }
        set vcap [add_or_get_dt_node -n "vcapaxis_broad_out1$drv_handle" -p $bus_node]
        hsi::utils::add_new_dts_param $vcap "compatible" "xlnx,video" string
	set inputip [split $inputip " "]
	set j 0
	foreach ip $inputip {
		if {[llength $ip]} {
			if {$j < $count} {
				append dmasip "<&$ip 0>," " "
			}
		}
		incr j
	}
	append dmasip "<&$ip 0>"
        hsi::utils::add_new_dts_param $vcap "dmas" "$dmasip" string
	set prt ""
	for {set i 0} {$i < $count} {incr i} {
		append prt " " "port$i"
	}
        hsi::utils::add_new_dts_param $vcap "dma-names" $prt stringlist
        set vcap_ports_node [add_or_get_dt_node -n "ports" -l "vcap_portsaxis_broad_out1$drv_handle" -p $vcap]
        hsi::utils::add_new_dts_param "$vcap_ports_node" "#address-cells" 1 int
        hsi::utils::add_new_dts_param "$vcap_ports_node" "#size-cells" 0 int
	set outip [split $outip " "]
	set b 0
	for {set a 1} {$a <= $count} {incr a} {
		set vcap_port_node [add_or_get_dt_node -n "port" -l "vcap_portaxis_broad_out$a$drv_handle" -u "$b" -p "$vcap_ports_node"]
		hsi::utils::add_new_dts_param "$vcap_port_node" "reg" $b int
		hsi::utils::add_new_dts_param "$vcap_port_node" "direction" input string
		set vcap_in_node [add_or_get_dt_node -n "endpoint" -l [lindex $outip $a] -p "$vcap_port_node"]
		hsi::utils::add_new_dts_param "$vcap_in_node" "remote-endpoint" axis_broad_out$a$drv_handle reference
		incr b
	}
}

proc get_connect_ip {ip intfpins} {
        dtg_verbose "get_con_ip:$ip pins:$intfpins"
	if {[llength $intfpins]== 0} {
		return
	}
	if {[llength $ip]== 0} {
		return
	}
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $ip]] "axis_broadcaster"]} {
		gen_broadcaster $ip
		return
	}
	global connectip ""
	foreach intf $intfpins {
		set connectip [get_connected_stream_ip [get_cells -hier $ip] $intf]
		if {[llength $connectip]} {
			if {[string match -nocase [get_property IP_NAME [get_cells -hier $connectip]] "axis_broadcaster"]} {
				gen_broadcaster $connectip
				break
			}
			if {[string match -nocase [get_property IP_NAME [get_cells -hier $connectip]] "axis_switch"]} {
				gen_axis_switch $connectip
				break
			}
		}
		set len [llength $connectip]
		if {$len > 1} {
			for {set i 0 } {$i < $len} {incr i} {
				set ip [lindex $connectip $i]
				if {[regexp -nocase "ila" $ip match]} {
					continue
				}
				set connectip "$ip"
			}
		}
		if {[llength $connectip]} {
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
			if {[llength $ip_mem_handles]} {
				break
			} else {
				set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				get_connect_ip $connectip $master_intf
			}
		}
	}
	return $connectip
}

proc get_in_connect_ip {ip intfpins} {
        dtg_verbose "get_in_con_ip:$ip pins:$intfpins"
	if {[llength $intfpins]== 0} {
		return
	}
	if {[llength $ip]== 0} {
		return
	}
	global connectip ""
	foreach intf $intfpins {
			set connectip [get_connected_stream_ip [get_cells -hier $ip] $intf]
			if {[llength $connectip]} {
			set extip [get_property IP_NAME $connectip]
			if {[string match -nocase $extip "dfe_glitch_protect"] || [string match -nocase $extip "axi_interconnect"] || [string match -nocase $extip "axi_crossbar"]} {
				return
			}
			}
			set len [llength $connectip]
			if {$len > 1} {
				for {set i 0 } {$i < $len} {incr i} {
					set ip [lindex $connectip $i]
					if {[regexp -nocase "ila" $ip match]} {
						continue
					}
					set connectip "$ip"
				}
			}
			if {[llength $connectip]} {
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
				if {[llength $ip_mem_handles]} {
						break
				} else {
					if {[string match -nocase [get_property IP_NAME $connectip] "system_ila"]} {
							continue
					}
					set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
					get_in_connect_ip $connectip $master_intf
				}
			}
	}
	return $connectip
}

proc get_broad_in_ip {ip} {
	dtg_verbose "get_braod_in_ip:$ip"
	if {[llength $ip]== 0} {
		return
	}
	set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set connectip ""
	foreach intf $master_intf {
		set connect [get_connected_stream_ip [get_cells -hier $ip] $intf]
		foreach connectip $connect {
			if {[llength $connectip]} {
				if {[string match -nocase [get_property IP_NAME $connectip] "axis_broadcaster"]} {
					return $connectip
				}
				set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
				if {![llength $ip_mem_handles]} {
					set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
					foreach intf $master_intf {
						set connectip [get_connected_stream_ip [get_cells -hier $connectip] $intf]
						set len [llength $connectip]
						if {$len > 1} {
							for {set i 0 } {$i < $len} {incr i} {
							set ip [lindex $connectip $i]
							if {[regexp -nocase "ila" $ip match]} {
								continue
							}
							set connectip "$ip"
							}
						}
						foreach connect $connectip {
							if {[string match -nocase [get_property IP_NAME $connectip] "axis_broadcaster"]} {
								return $connectip
							}
						}
					}
					if {[llength $connectip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
						if {![llength $ip_mem_handles]} {
							set master2_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							foreach intf $master2_intf {
								set connectip [get_connected_stream_ip [get_cells -hier $connectip] $intf]
								if {[llength $connectip]} {
									if {[string match -nocase [get_property IP_NAME $connectip] "axis_broadcaster"]} {
										return $connectip
									}
								}
							}
						}
						if {[llength $connectip]} {
							set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connectip]
							if {![llength $ip_mem_handles]} {
								set master3_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
								set connectip [get_connected_stream_ip [get_cells -hier $connectip] $master3_intf]
							}
						}
					}
				}
			}
		}
	}
	return $connectip
}

proc get_connected_stream_ip { ip_name intf_name } {
    set ip [::hsi::get_cells -hier $ip_name]
    if { [llength $ip] == 0 } {
        return ""
    }
    set intf [::hsi::get_intf_pins -of_objects $ip "$intf_name"]
    if { [llength $intf] == 0 } {
        return ""
    }
    set intf_type [common::get_property TYPE $intf]

    set intf_net [::hsi::get_intf_nets -of_objects $intf]
    if { [llength $intf_net] == 0 } {
        return ""
    }
    set connected_intf_pins [::hsi::utils::get_other_intf_pin $intf_net $intf]
    set connected_intf_pin [::hsi::utils::get_intf_pin_oftype $connected_intf_pins $intf_type 0]

    if { [llength $connected_intf_pin] } {
        set connected_ip [::hsi::get_cells -of_objects $connected_intf_pin]
        return $connected_ip
    }
    return ""
}

proc gen_dfx_reg_property {drv_handle dfx_node} {
	set ip_name  [get_property IP_NAME [get_cells -hier $drv_handle]]
	set reg ""
	set slave [get_cells -hier ${drv_handle}]
	set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
	foreach mem_handle ${ip_mem_handles} {
		set base [string tolower [get_property BASE_VALUE $mem_handle]]
		set high [string tolower [get_property HIGH_VALUE $mem_handle]]
		set size [format 0x%x [expr {${high} - ${base} + 1}]]
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string_is_empty $reg]} {
			if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			# check if base address is 64bit and split it as MSB and LSB
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
		} else {
			if {[string match -nocase $proctype "ps7_cortexa9"] || [string match -nocase $proctype "microblaze"]} {
				set index [check_base $reg $base $size]
				if {$index == "true"} {
					continue
				}
			}
			if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
				set index [check_64_base $reg $base $size]
				if {$index == "true"} {
					continue
				}
			}
			# ensure no duplication
			if {![regexp ".*${reg}.*" "$base $size" matched]} {
				if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
					set base1 "0x0 $base"
					set size1 "0x0 $size"
					if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
						set temp $base
						set temp [string trimleft [string trimleft $temp 0] x]
						set len [string length $temp]
						set rem [expr {${len} - 8}]
						set high_base "0x[string range $temp $rem $len]"
						set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
						set low_base [format 0x%08x $low_base]
						set base1 "$low_base $high_base"
					}
					if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
						set temp $size
						set temp [string trimleft [string trimleft $temp 0] x]
						set len [string length $temp]
						set rem [expr {${len} - 8}]
						set high_size "0x[string range $temp $rem $len]"
						set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
						set low_size [format 0x%08x $low_size]
						set size1 "$low_size $high_size"
					}
					set reg "$reg $base1 $size1"
				} else {
					set reg "$reg $base $size"
				}
			}
		}
	}
	hsi::utils::add_new_dts_param "$dfx_node" "reg" "$reg" intlist
}

proc gen_dfx_clk_property {drv_handle dts_file child_node dfx_node} {
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return 0
	}
	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
	if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		return 0
	}
	set clocks ""
	set axi 0
	set is_clk_wiz 0
	set is_pl_clk 0
	set updat ""
	global bus_clk_list
	set clocknames ""
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "microblaze"]} {
		return
	}
	set clk_pins [get_pins -of_objects [get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] $clk]]
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
				dtg_warning "no s_axi_aclk for clockwizard IP block: \" $periph\"\n\r"
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
				set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
				if {[llength $clk_freq] == 0} {
					dtg_warning "clock frequency for the $clk is NULL of IP block: \" $drv_handle\"\n\r"
					continue
				}
				# if clk_freq is float convert it to int
				set clk_freq [expr int($clk_freq)]
				set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
				if {![string equal $clk_freq ""]} {
					if {[lsearch $bus_clk_list $clk_freq] < 0} {
						set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${child_node}]
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
		}
		foreach pin $pins {
			if {[lsearch $clklist $pin] >= 0} {
				set pl_clk $pin
				set is_pl_clk 1
			}
		}
		if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
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
		if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
			set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
			if {[llength $clk_freq] == 0} {
				dtg_warning "clock frequency for the $clk is NULL of IP block: \"$drv_handle\"\n\r"
				continue
			}
			# if clk_freq is float convert it to int
			set clk_freq [expr int($clk_freq)]
			set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
			if {![string equal $clk_freq ""]} {
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
				set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
				set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
				-d ${dts_file} -p ${child_node}]
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
	hsi::utils::add_new_dts_param "${dfx_node}" "clock-names" "$clocknames" stringlist
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	set len [llength $updat]
	switch $len {
		"1" {
			set refs [lindex $updat 0]
			hsi::utils::add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
		}
		"2" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]"
			hsi::utils::add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
		}
		"3" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
			hsi::utils::add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
		}
		"4" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
			hsi::utils::add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
		}
		"5" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
			hsi::utils::add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
		}
		"6" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
			hsi::utils::add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
		}
		"7" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
			hsi::utils::add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
		}
	}
}

proc gen_axis_switch_clk_property {drv_handle dts_file node} {
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return 0
	}
	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
	if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		return 0
	}
	set clocks ""
	set axi 0
	set is_clk_wiz 0
	set is_pl_clk 0
	set updat ""
	global bus_clk_list
	set clocknames ""
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "microblaze"]} {
		return
	}
	set clk_pins [get_pins -of_objects [get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] $clk]]
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
				dtg_warning "no s_axi_aclk for clockwizard IP block: \" $periph\"\n\r"
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
				set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
				if {[llength $clk_freq] == 0} {
					dtg_warning "clock frequency for the $clk is NULL of IP block: \" $drv_handle\"\n\r"
					continue
				}
				set bus_node [add_or_get_bus_node $drv_handle $dts_file]
				# if clk_freq is float convert it to int
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
		}
		foreach pin $pins {
			if {[lsearch $clklist $pin] >= 0} {
				set pl_clk $pin
				set is_pl_clk 1
			}
		}
		if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
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
		if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
			set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
			if {[llength $clk_freq] == 0} {
				dtg_warning "clock frequency for the $clk is NULL of IP block: \"$drv_handle\"\n\r"
				continue
			}
			set bus_node [add_or_get_bus_node $drv_handle $dts_file]
			# if clk_freq is float convert it to int
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
				hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int/
				hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
			}
		}
		append clocknames " " "$clk"
		set is_pl_clk 0
		set is_clk_wiz 0
		set axi 0
	}
	hsi::utils::add_new_dts_param "${node}" "clock-names" "$clocknames" stringlist
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	set len [llength $updat]
	switch $len {
		"1" {
			set refs [lindex $updat 0]
			hsi::utils::add_new_dts_param "${node}" "clocks" "$refs" reference
		}
		"2" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]"
			hsi::utils::add_new_dts_param "${node}" "clocks" "$refs" reference
		}
		"3" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
			hsi::utils::add_new_dts_param "${node}" "clocks" "$refs" reference
		}
		"4" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
			hsi::utils::add_new_dts_param "${node}" "clocks" "$refs" reference
		}
		"5" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
			hsi::utils::add_new_dts_param "${node}" "clocks" "$refs" reference
		}
		"6" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
			hsi::utils::add_new_dts_param "${node}" "clocks" "$refs" reference
		}
		"7" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
			hsi::utils::add_new_dts_param "${node}" "clocks" "$refs" reference
		}
	}
}

proc gen_clk_property {drv_handle} {
	if {[is_ps_ip $drv_handle]} {
		return 0
	}
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return 0
	}
	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
        if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		return 0
	}
	set clocks ""
	set axi 0
	set is_clk_wiz 0
	set is_pl_clk 0
	set updat ""
	global bus_clk_list
	set clocknames ""
	dtg_verbose "gen_clk_property:$drv_handle"
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "microblaze"]} {
		return
	}
	set clk_pins [get_pins -of_objects [get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
	dtg_verbose "clk_pins:$clk_pins"
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	set ignore_list "lmb_bram_if_cntlr PERIPHERAL axi_noc  axi_noc2 mrmac"
	if {[lsearch $ignore_list $ip] >= 0 } {
		return 0
        }
	if {[string match -nocase $ip "vcu"]} {
		set clk_pins "pll_ref_clk s_axi_lite_aclk"
	}
	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] $clk]]
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
					set ip_mem_handles [hsi::utils::get_ip_mem_ranges $periph]
					if {[llength $ip_mem_handles]} {
						set axi 1
					}
				}
			}

			if {[string match -nocase $axi "0"]} {
				dtg_warning "no s_axi_aclk for clockwizard IP block: \" $periph\"\n\r"
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
				set RpRm [get_rp_rm_for_drv $drv_handle]
				regsub -all { } $RpRm "" RpRm
				if {[llength $RpRm]} {
					set dts_file "pl-partial-$RpRm.dtsi"
				} else {
					set dts_file "pl.dtsi"
				}

				set bus_node [add_or_get_bus_node $drv_handle $dts_file]
				set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
				if {[llength $clk_freq] == 0} {
					dtg_warning "clock frequency for the $clk is NULL of IP block: \" $drv_handle\"\n\r"
					continue
				}
				# if clk_freq is float convert it to int
				set clk_freq [expr int($clk_freq)]
				set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
				if {![string equal $clk_freq ""]} {
					if {[lsearch $bus_clk_list $clk_freq] < 0} {
						set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					if {[llength $RpRm]} {
						set misc_clk_node [add_or_get_dt_node -n "misc_clk${bus_clk_cnt}" -l "misc_clk_$RpRm${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
					} else {
						set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
					}

					set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
					if {[llength $RpRm]} {
						set updat [lappend updat misc_clk_$RpRm${bus_clk_cnt}]
					} else {
						set updat [lappend updat misc_clk_${bus_clk_cnt}]
					}
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
		if {[string match -nocase $proctype "psu_cortexa53"] } {
			set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
		} elseif {[string match -nocase $proctype "ps7_cortexa9"]} {
			set clklist "FCLK_CLK0 FCLK_CLK1 FCLK_CLK2 FCLK_CLK3"
		}
		if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			if {[string match -nocase $proctype "psv_cortexa72"]} {
				set versal_periph [get_cells -hier -filter {IP_NAME == versal_cips}]
			} else {
				set versal_periph [get_cells -hier -filter {IP_NAME == psx_wizard}]
			}
			set ver [get_comp_ver $versal_periph]
			if {$ver >= 3.0} {
				set clklist "pl0_ref_clk pl1_ref_clk pl2_ref_clk pl3_ref_clk"
			} else {
				set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
			}
		}
		foreach pin $pins {
			if {[lsearch $clklist $pin] >= 0} {
				set pl_clk $pin
				set is_pl_clk 1
			}
		}
		if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			if {[string match -nocase $proctype "psv_cortexa72"]} {
				set versal_periph [get_cells -hier -filter {IP_NAME == versal_cips}]
			} else {
				set versal_periph [get_cells -hier -filter {IP_NAME == psx_wizard}]
			}

			set ver [get_comp_ver $versal_periph]
			if {$ver >= 3.0} {
			switch $pl_clk {
				"pl0_ref_clk" {
						set pl_clk0 "versal_clk 65"
						set clocks [lappend clocks $pl_clk0]
						set updat  [lappend updat $pl_clk0]
				}
				"pl1_ref_clk" {
						set pl_clk1 "versal_clk 66"
						set clocks [lappend clocks $pl_clk1]
						set updat  [lappend updat $pl_clk1]
				}
				"pl2_ref_clk" {
						set pl_clk2 "versal_clk 67"
						set clocks [lappend clocks $pl_clk2]
						set updat [lappend updat $pl_clk2]
				}
				"pl3_ref_clk" {
						set pl_clk3 "versal_clk 68"
						set clocks [lappend clocks $pl_clk3]
						set updat [lappend updat $pl_clk3]
				}
				default {
						dtg_warning  "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"\n\r"
				}
			}
			} else {
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
						set updat  [lappend updat  $pl_clk2]
				}
				"pl_clk3" {
						set pl_clk3 "versal_clk 68"
						set clocks [lappend clocks $pl_clk3]
						set updat  [lappend updat $pl_clk3]
				}
				default {
						dtg_warning "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"n\r"
				}
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
						dtg_warning  "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"\n\r"
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
						dtg_warning  "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"\n\r"
				}
			}
		}
		if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
			set RpRm [get_rp_rm_for_drv $drv_handle]
			regsub -all { } $RpRm "" RpRm
			if {[llength $RpRm]} {
				set dts_file "pl-partial-$RpRm.dtsi"
			} else {
				set dts_file "pl.dtsi"
                        }
			set bus_node [add_or_get_bus_node $drv_handle $dts_file]
			set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
			if {[llength $clk_freq] == 0} {
				dtg_warning "clock frequency for the $clk is NULL of IP block: \"$drv_handle\"\n\r"
				continue
			}
			# if clk_freq is float convert it to int
			set clk_freq [expr int($clk_freq)]
			set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
			if {![string equal $clk_freq ""]} {
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
				set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
				if {[llength $RpRm]} {
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_$RpRm${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
				} else {
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
				}
				set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
				if {[llength $RpRm]} {
					set updat [lappend updat misc_clk_$RpRm${bus_clk_cnt}]
				} else {
					set updat [lappend updat misc_clk_${bus_clk_cnt}]
				}
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
	set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
	set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
	if {[string match -nocase $ip "vcu"]} {
		set vcu_label $drv_handle
		set vcu_clk1 "$drv_handle 0"
		set updat [lappend updat $vcu_clk1]
		set vcu_clk2 "$drv_handle 1"
		set updat [lappend updat $vcu_clk2]
		set vcu_clk3 "$drv_handle 2"
		set updat [lappend updat $vcu_clk3]
		set vcu_clk4 "$drv_handle 3"
		set updat [lappend updat $vcu_clk4]
		set len [llength $updat]
		set refs [lindex $updat 0]
		append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
		set_drv_prop $drv_handle "clocks" "$refs" reference
		return
	}
	set len [llength $updat]
	switch $len {
		"1" {
			set refs [lindex $updat 0]
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"2" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"3" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"4" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"5" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"6" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"7" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"8" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"9" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"10" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"11" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"12" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"13" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"14" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"15" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"16" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
	}
}

proc overwrite_clknames {clknames drv_handle} {
	set_drv_prop $drv_handle "clock-names" $clknames stringlist
}
proc get_comp_ver {drv_handle} {
	set slave [get_cells -hier ${drv_handle}]
	set vlnv  [split [get_property VLNV $slave] ":"]
	set ver   [lindex $vlnv 3]
	return $ver
}

proc get_comp_str {drv_handle} {
	set slave [get_cells -hier ${drv_handle}]
	set vlnv [split [get_property VLNV $slave] ":"]
	set ver [lindex $vlnv 3]
	set name [lindex $vlnv 2]
	set ver [lindex $vlnv 3]
	set comp_prop "xlnx,${name}-${ver}"
	regsub -all {_} $comp_prop {-} comp_prop
	return $comp_prop
}

proc get_intr_type {intc_name ip_name port_name} {
	set intc [get_cells -hier $intc_name]
	set ip [get_cells -hier $ip_name]
	if {[llength $intc] == 0 && [llength $ip] == 0} {
		return -1
	}
	if {[llength $intc] == 0} {
		return -1
	}
	set intr_pin [get_pins -of_objects $ip $port_name]
	set sensitivity ""
	if {[llength $intr_pin] >= 1} {
		# TODO: check with HSM dev and see if this is a bug
		set sensitivity [get_property SENSITIVITY $intr_pin]
	}
	set intc_type [get_property IP_NAME $intc ]
	set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic"
	if {[lsearch  -nocase $valid_intc_list $intc_type] >= 0} {
		if {[string match -nocase $sensitivity "EDGE_FALLING"]} {
				return 2;
		} elseif {[string match -nocase $sensitivity "EDGE_RISING"]} {
				return 1;
		} elseif {[string match -nocase $sensitivity "LEVEL_HIGH"]} {
				return 4;
		} elseif {[string match -nocase $sensitivity "LEVEL_LOW"]} {
				return 8;
		}
	} else {
		# Follow the openpic specification
		if {[string match -nocase $sensitivity "EDGE_FALLING"]} {
				return 3;
		} elseif {[string match -nocase $sensitivity "EDGE_RISING"]} {
				return 0;
		} elseif {[string match -nocase $sensitivity "LEVEL_HIGH"]} {
				return 2;
		} elseif {[string match -nocase $sensitivity "LEVEL_LOW"]} {
				return 1;
		}
	}
	return -1
}

proc get_drv_conf_prop_list {ip_name {def_pattern "CONFIG.*"}} {
	set drv_handle [get_ip_handler $ip_name]
	if {[catch {set rt [list_property -regexp $drv_handle ${def_pattern}]} msg]} {
		set rt ""
	}
	return $rt
}

proc get_ip_conf_prop_list {ip_name {def_pattern "CONFIG.*"}} {
	set ip [get_cells -hier $ip_name]
	if {[catch {set rt [list_property -regexp $ip ${def_pattern}]} msg]} {
		set rt ""
	}
	return $rt
}

proc get_ip_handler {ip_name} {
	# check if it is processor
	if {[string equal -nocase [get_sw_processor] $ip_name]} {
		return [get_sw_processor]
	}
	# check if it is the target processor
	# get it from drvers
	return [get_drivers $ip_name]
}

proc set_drv_prop args {
	set drv_handle [lindex $args 0]
	set prop_name [lindex $args 1]
	set value [lindex $args 2]

	# check if property exists if not create it
	set list [get_drv_conf_prop_list $drv_handle]
	if {[lsearch -glob ${list} ${prop_name}] < 0} {
		hsi::utils::add_new_property $drv_handle $prop_name string "$value"
	}

	if {[llength $args] >= 4} {
		set type [lindex $args 3]
		set_property ${prop_name} $value $drv_handle
		set prop [get_comp_params ${prop_name} $drv_handle]
		set_property CONFIG.TYPE $type $prop
	} else {
		set_property ${prop_name} $value $drv_handle
	}
	return 0
}

proc set_drv_prop_if_empty args {
	set drv_handle [lindex $args 0]
	set prop_name [lindex $args 1]
	set value [lindex $args 2]
	set cur_prop_value [get_property CONFIG.$prop_name $drv_handle]
	if {[string_is_empty $cur_prop_value] == 0} {
		dtg_debug "$drv_handle $prop_name property is not empty, current value is '$cur_prop_value'"
		return -1
	}
	if {[llength $args] >= 4} {
		set type [lindex $args 3]
		set_drv_prop $drv_handle $prop_name $value $type
	} else {
		set_drv_prop $drv_handle $prop_name $value
	}
	return 0
}

proc gen_mb_interrupt_property {cpu_handle {intr_port_name ""}} {
	# generate interrupts and interrupt-parent properties for soft IP
	proc_called_by
	if {[is_ps_ip $cpu_handle]} {
		return 0
	}

	set slave [get_cells -hier ${cpu_handle}]
	set intc ""

	if {[string_is_empty $intr_port_name]} {
		set intr_port_name [get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
	}
	set cpin [hsi::utils::get_interrupt_sources [get_cells -hier $cpu_handle]]
	set intc [get_cells -of_objects $cpin]
        if { [::hsi::utils::is_intr_cntrl $intc] != 1 } {
		set intf_pins [::hsi::get_intf_pins -of_objects $intc]
		foreach intp $intf_pins {
			set connectip [get_connected_stream_ip [get_cells -hier $intc] $intp]
			if { [::hsi::utils::is_intr_cntrl $connectip] == 1 } {
				set intc $connectip
			}
		}
	}
	if {[string_is_empty $intc]} {
		error "no interrupt controller found"
	}

	set_drv_prop $cpu_handle interrupt-handle $intc reference
}

proc get_interrupt_parent {  periph_name intr_pin_name } {
    lappend intr_cntrl
    if { [llength $intr_pin_name] == 0 } {
        return $intr_cntrl
    }

    if { [llength $periph_name] != 0 } {
        set periph [::hsi::get_cells -hier -filter "NAME==$periph_name"]
        if { [llength $periph] == 0 } {
            return $intr_cntrl
        }
        set intr_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intr_pin_name"]
        if { [llength $intr_pin] == 0 } {
            return $intr_cntrl
        }
        set pin_dir [common::get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "I"] } {
          return $intr_cntrl
        }
    } else {
        set intr_pin [::hsi::get_ports $intr_pin_name]
        if { [llength $intr_pin] == 0 } {
            return $intr_cntrl
        }
        set pin_dir [common::get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "O"] } {
          return $intr_cntrl
        }
    }
    set intr_sink_pins [::hsi::utils::get_sink_pins $intr_pin]
    foreach intr_sink $intr_sink_pins {
        set sink_periph [lindex [::hsi::get_cells -of_objects $intr_sink] 0]
        if { [llength $sink_periph ] && [::hsi::utils::is_intr_cntrl $sink_periph] == 1 } {
            lappend intr_cntrl $sink_periph
        } elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "xlconcat"] } {
           set intr_cntrl [list {*}$intr_cntrl {*}[::hsi::utils::get_connected_intr_cntrl $sink_periph "dout"]]
        } elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "xlslice"] } {
            set intr_cntrl [list {*}$intr_cntrl {*}[::hsi::utils::get_connected_intr_cntrl $sink_periph "Dout"]]
        } elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "util_reduced_logic"] } {
            set intr_cntrl [list {*}$intr_cntrl {*}[::hsi::utils::get_connected_intr_cntrl $sink_periph "Res"]]
        } elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
		    set intr [get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
		    set intr_cntrl [list {*}$intr_cntrl {*}[::hsi::utils::get_connected_intr_cntrl $sink_periph "$intr"]]
	    } elseif {[llength $sink_periph] &&  [string match -nocase [common::get_property IP_NAME $sink_periph] "util_ff"]} {
            set intr_cntrl [list {*}$intr_cntrl {*}[::hsi::utils::get_connected_intr_cntrl $sink_periph "Q"]]
        }
    }
    return $intr_cntrl
}


proc gen_interrupt_property {drv_handle {intr_port_name ""}} {
	# generate interrupts and interrupt-parent properties for soft IP
	proc_called_by
	if {[is_ps_ip $drv_handle]} {
		return 0
	}
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	set slave [get_cells -hier ${drv_handle}]
	set intr_id -1
	set intc ""
	set intr_info ""
	set intc_names ""
	set intr_par   ""
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return 0
	}
	if {[string_is_empty $intr_port_name]} {
		if {[string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"]} {
			set val [get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
			set intr_port_name [get_pins -of_objects $slave -filter {TYPE==INTERRUPT&&DIRECTION==O}]
			set single [get_property CONFIG.C_IRQ_CONNECTION [get_cells -hier $slave]]
			if {$single == 0} {
				dtg_warning "The axi_intc Interrupt Output connection is Bus. Change it to Single"
			}
		} else {
			set intr_port_name [get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
		}
	}
	# TODO: consolidation with get_intr_id proc
	foreach pin ${intr_port_name} {
		set connected_intc [get_intr_cntrl_name $drv_handle $pin]
		regsub -all {\{|\}} $connected_intc "" connected_intc
		if {[llength $connected_intc] == 0 } {
			if {![string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"]} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected to any interrupt controller\n\r"
			}
			continue
		}
		set connected_intc [get_cells -hier $connected_intc]
		set connected_intc_name [get_property IP_NAME $connected_intc]
		set valid_gpio_list "ps7_gpio axi_gpio"
		set valid_cascade_proc "microblaze ps7_cortexa9 psu_cortexa53 psv_cortexa72 psx_cortexa78"
		# check whether intc is gpio or other
		if {[lsearch  -nocase $valid_gpio_list $connected_intc_name] >= 0} {
			set cur_intr_info ""
			generate_gpio_intr_info $connected_intc $drv_handle $pin
		} else {
			set intc [get_interrupt_parent $drv_handle $pin]
			if { [string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0 } {
				set pins [::hsi::get_pins -of_objects [::hsi::get_cells -hier -filter "NAME==$drv_handle"] -filter "NAME==irq"]
				set intc [get_interrupt_parent $drv_handle $pins]
			} else {
				set intc [get_interrupt_parent $drv_handle $pin]
			}
			if {[string_is_empty $intc] == 1} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected\n\r"
				continue
			}
			set ip_name $intc
			if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
				if {[llength $intc] > 1} {
					foreach intr_cntr $intc {
						if { [::hsi::utils::is_ip_interrupting_current_proc $intr_cntr] } {
							set intc $intr_cntr
						}
					}
				}
				if {[string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "psu_cortexa53"] && [string match -nocase $intc "axi_intc"] } {
					set intc [::hsi::utils::get_interrupt_parent $drv_handle $pin]
				}
				if {[string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "psv_cortexa72"] && [string match -nocase $intc "axi_intc"] } {
					set intc [get_interrupt_parent $drv_handle $pin]
				}
				if {[string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "psx_cortexa78"] && [string match -nocase $intc "axi_intc"] } {
					set intc [get_interrupt_parent $drv_handle $pin]
				}
			}

			if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
				if { [string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"] } {
					set intr_id [get_psu_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_psu_interrupt_id $drv_handle $pin]
				}
			}
			if { [string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "ps7_cortexa9"]} {
				if { [string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"] } {
					set intr_id [::hsi::utils::get_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [::hsi::utils::get_interrupt_id $drv_handle $pin]
				}
			}
			if { [string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "microblaze"]} {
				if {[string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"] } {
					set intr_id [get_psu_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_psu_interrupt_id $drv_handle $pin]
				}
			}

			if {[string match -nocase $intr_id "-1"] && ![string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"]} {
				continue
			}
			set intr_type [get_intr_type $intc $slave $pin]
			if {[string match -nocase $intr_type "-1"]} {
				continue
			}

			set cur_intr_info ""
			set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic"
			global intrpin_width
			if { [string match -nocase $proctype "ps7_cortexa9"] }  {
				if {[string match "[get_property IP_NAME $intc]" "ps7_scugic"] } {
					if {$intr_id > 32} {
						set intr_id [expr $intr_id - 32]
					}
					set cur_intr_info "0 $intr_id $intr_type"
				} elseif {[string match "[get_property IP_NAME $intc]" "axi_intc"] } {
					set cur_intr_info "$intr_id $intr_type"
				}
			} elseif {[string match -nocase $intc "psu_acpu_gic"] || [string match -nocase [get_property IP_NAME $intc] "psv_acpu_gic"]} {

			    set cur_intr_info "0 $intr_id $intr_type"
			    for { set i 1 } {$i < $intrpin_width} {incr i} {
				    set intr_id_inc [expr $intr_id + $i]
				    append cur_intr_info ">, <0 $intr_id_inc $intr_type"
		            }
			} else {
				set cur_intr_info "$intr_id $intr_type"
				for { set i 1 } {$i < $intrpin_width} {incr i} {
					set intr_id_inc [expr $intr_id + $i]
					append cur_intr_info ">, <$intr_id_inc $intr_type"
				}
			}
			if {[string_is_empty $intr_info]} {
				set intr_info "$cur_intr_info"
			} else {
				append intr_info " " $cur_intr_info
			}
		}
			append intr_names " " "$pin"
			append intr_par   " " "$intc"
			lappend intc_names "$intc" "$cur_intr_info"
	}
	if {[llength $intr_par] > 1 } {
		set int_ext 0
		set intc0 [lindex $intr_par 0]
		for {set i 1} {$i < [llength $intr_par]} {incr i} {
			set intc [lindex $intr_par $i]
			if {![string match -nocase $intc0 $intc]} {
				set int_ext 1
			}
		}
		if {$int_ext == 1} {
			set intc_names [string map {psu_acpu_gic gic} $intc_names]
			set ref [lindex $intc_names 0]
			append ref " [lindex $intc_names 1]>, <&[lindex $intc_names 2] [lindex $intc_names 3]>, <&[lindex $intc_names 4] [lindex $intc_names 5]>,<&[lindex $intc_names 6] [lindex $intc_names 7]>, <&[lindex $intc_names 8] [lindex $intc_names 9]"
			if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "v_hdmi_tx_ss"] \
				|| [string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "v_hdmi_txss1"]} {
				set_drv_prop_if_empty $drv_handle "interrupts-extended" $ref reference
			}
		}
	}

	if {[string_is_empty $intr_info]} {
		return -1
	}
    global drv_handlers_mapping
    if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "vdu"]} {
        dict lappend drv_handlers_mapping $drv_handle "interrupts" "$intr_info"
    } else {
	    set_drv_prop $drv_handle interrupts $intr_info intlist
    }

	if {[string_is_empty $intc]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]

	if { [string match -nocase $intc "psu_acpu_gic"] || [string match -nocase $intc "psv_acpu_gic"]} {
		set intc "gic"
	}
    set add_intr_parent ""
	if { $intc == "gic" && ([string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"])} {
		set add_intr_parent "1"
	} elseif { $intc == "intc" && [string match -nocase $proctype "ps7_cortexa9" ] } {
		set add_intr_parent "1"
	} else {
		set index [lsearch [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $intc]
		if {$index != -1 } {
		    set add_intr_parent "1"
		}
	}
    if {[llength $add_intr_parent]} {
        if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "vdu"]} {
            dict lappend drv_handlers_mapping $drv_handle "interrupt-parent" "$intc"
        } else {
            set_drv_prop $drv_handle interrupt-parent $intc reference
        }
    }
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "xdma"]} {
		set msi_rx_pin_en [get_property CONFIG.msi_rx_pin_en [get_cells -hier $drv_handle]]
		if {[string match -nocase $msi_rx_pin_en "true"]} {
			set_drv_prop_if_empty $drv_handle "interrupt-names" $intr_names stringlist
		}
	} elseif {[string match -nocase [get_property IP_NAME [get_cells -hier $drv_handle]] "vdu"]} {
        dict lappend drv_handlers_mapping $drv_handle "interrupt-names" "$intr_names"
    } else {
		set_drv_prop_if_empty $drv_handle "interrupt-names" $intr_names stringlist
	}
}

proc gen_reg_property {drv_handle {skip_ps_check ""}} {
	proc_called_by

	if {[string_is_empty $skip_ps_check]} {
		if {[is_ps_ip $drv_handle]} {
			return 0
		}
	}
	set ip_name  [get_property IP_NAME [get_cells -hier $drv_handle]]
	if {$ip_name == "xxv_ethernet" || $ip_name == "ddr4" || $ip_name == "mrmac" || $ip_name == "vdu"} {
		return
	}

	set reg ""
	#set ip_skip_list "ddr4_*"
	set slave [get_cells -hier ${drv_handle}]
	set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
	foreach mem_handle ${ip_mem_handles} {
	#	if {![regexp $ip_skip_list $mem_handle match]} {
			set base [string tolower [get_property BASE_VALUE $mem_handle]]
			set ips [get_cells -hier -filter {IP_NAME == "mrmac"}]
			if {[llength $ips]} {
				if {[string match -nocase $base "0xa4010000"] && $ip_name == "axi_gpio"} {
					return
				}
			}
			set high [string tolower [get_property HIGH_VALUE $mem_handle]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
			if {[string_is_empty $reg]} {
				if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
					# check if base address is 64bit and split it as MSB and LSB
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
			} else {
				if {[string match -nocase $proctype "ps7_cortexa9"] || [string match -nocase $proctype "microblaze"]} {
					set index [check_base $reg $base $size]
					if {$index == "true"} {
						continue
					}
				}
				if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
					set index [check_64_base $reg $base $size]
					if {$index == "true"} {
						continue
					}
				}
				# ensure no duplication
				if {![regexp ".*${reg}.*" "$base $size" matched]} {
					if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
						set base1 "0x0 $base"
						set size1 "0x0 $size"
						if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
					                set temp $base
					                set temp [string trimleft [string trimleft $temp 0] x]
					                set len [string length $temp]
					                set rem [expr {${len} - 8}]
					                set high_base "0x[string range $temp $rem $len]"
					                set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
					                set low_base [format 0x%08x $low_base]
							set base1 "$low_base $high_base"
						}
						if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
							set temp $size
							set temp [string trimleft [string trimleft $temp 0] x]
							set len [string length $temp]
							set rem [expr {${len} - 8}]
							set high_size "0x[string range $temp $rem $len]"
							set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
							set low_size [format 0x%08x $low_size]
							set size1 "$low_size $high_size"
						}
						set reg "$reg $base1 $size1"
					} else {
						set reg "$reg $base $size"
					}
				}
			}
	#	}
	}
	set_drv_prop_if_empty $drv_handle reg $reg intlist
}

proc check_64_base {reg base size} {
	set high_base 0xdeadbeef
	set low_base  0
	if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		set temp $base
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_base "0x[string range $temp $rem $len]"
		set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_base [format 0x%08x $low_base]
	}
	set len [llength $reg]
	switch $len {
		"4" {
			set base_index0 [lindex $reg 0]
			set base_index1 [lindex $reg 1]
			if {$high_base != 0xdeadbeef} {
				if {$base_index0 == $low_base && $base_index1 == $high_base} {
					return true
				}
			} else {
				if {$base_index1 == $base} {
					return true
				}
			}
		}
		"8" {
			set base_index0 [lindex $reg 0]
			set base_index1 [lindex $reg 1]
			set base_index4 [lindex $reg 4]
			set base_index5 [lindex $reg 5]
			if {$high_base != 0xdeadbeef} {
				if {$base_index0 == $low_base && $base_index1 == $high_base} {
					return true
				}
				if {$base_index4 == $low_base && $base_index5 == $high_base} {
					return true
				}
			} else {
				if {$base_index1 == $base} {
					return true
				}
				if {$base_index5 == $base} {
					return true
				}
			}
		}
		"12" {
			set base_index0 [lindex $reg 0]
			set base_index1 [lindex $reg 1]
			set base_index4 [lindex $reg 4]
			set base_index5 [lindex $reg 5]
			set base_index8 [lindex $reg 8]
			set base_index9 [lindex $reg 9]
			if {$high_base != 0xdeadbeef} {
				if {$base_index0 == $low_base && $base_index1 == $high_base} {
					return true
				}
				if {$base_index4 == $low_base && $base_index5 == $high_base} {
					return true
				}
				if {$base_index8 == $low_base && $base_index9 == $high_base} {
					return true
				}
			} else {
				if {$base_index1 == $base} {
					return true
				}
				if {$base_index5 == $base} {
					return true
				}
				if {$base_index9 == $base} {
					return true
				}
			}
		}
	}
}

proc check_base {reg base size} {
	set len [llength $reg]
	switch $len {
		"2" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			if {$base_index0 == $base || $size_index0 == $size} {
				return true
			}
		}
		"4" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			if {$base_index0 == $base || $base_index1 == $base} {
				if {$size_index0 == $size || $size_index1 == $size} {
					return true
				}
			}
		}
		"6" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base} {
				if {$size_index0 == $size || $size_index1 == $size || $size_index2 == $size} {
					return true
				}
			}
		}
		"8" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base} {
				if {$size_index0 == $size || $size_index1 == $size || $size_index2 == $size || $size_index3 == $size} {
					return true
				}
			}
		}
		"10" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base} {
				if {$size_index0 == $size || $size_index1 == $size || $size_index2 == $size || $size_index3 == $size || $size_index4 == $size} {
					return true
				}
			}
		}
		"12" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			set base_index5 [lindex $reg 10]
			set size_index5 [lindex $reg 11]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base || $base_index5 == $base} {
				if {$size_index0 == $size || $size_index1 == $size || $size_index2 == $size || $size_index3 == $size || $size_index4 == $size || $size_index5 == $size} {
					return true
				}
			}
		}
		"14" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			set base_index5 [lindex $reg 10]
			set size_index5 [lindex $reg 11]
			set base_index6 [lindex $reg 12]
			set size_index6 [lindex $reg 13]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base || $base_index5 == $base || $base_index6 == $base} {
				if {$size_index0 == $size || $size_index1 == $size || $size_index2 == $size || $size_index3 == $size || $size_index4 == $size || $size_index5 == $size || $size_index6 == $size} {
					return true
				}
			}
		}
		"16" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			set base_index5 [lindex $reg 10]
			set size_index5 [lindex $reg 11]
			set base_index6 [lindex $reg 12]
			set size_index6 [lindex $reg 13]
			set base_index7 [lindex $reg 14]
			set size_index7 [lindex $reg 15]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base || $base_index5 == $base || $base_index6 == $base || $base_index7 == $base} {
				if {$size_index0 == $size || $size_index1 == $size || $size_index2 == $size || $size_index3 == $size || $size_index4 == $size || $size_index5 == $size || $size_index6 == $size || $size_index7 == $size} {
					return true
				}
			}
		}
	}
}

proc gen_compatible_property {drv_handle} {
	proc_called_by

	if {[is_ps_ip $drv_handle]} {
		return 0
	}

	set reg ""
	set slave [get_cells -hier ${drv_handle}]
	set vlnv [split [get_property VLNV $slave] ":"]
	set name [lindex $vlnv 2]
	set ver [lindex $vlnv 3]
	set comp_prop "xlnx,${name}-${ver}"
	regsub -all {_} $comp_prop {-} comp_prop
	set_drv_prop_if_empty $drv_handle compatible $comp_prop stringlist
}

proc is_property_set {value} {
       if {[string compare -nocase $value "true"] == 0} {
               return 1
       }
       return 0
}

proc ip2drv_prop {ip_name ip_prop_name} {
	set drv_handle [get_ip_handler $ip_name]
	set ip [get_cells -hier $ip_name]
	set emac [get_property IP_NAME $ip]

	if { $emac == "axi_ethernet"} {
		# remove CONFIG.
		set prop [get_property $ip_prop_name [get_cells -hier $ip_name]]
		set drv_prop_name $ip_prop_name
		regsub -all {CONFIG.} $drv_prop_name {xlnx,} drv_prop_name
		regsub -all {_} $drv_prop_name {-} drv_prop_name
		set drv_prop_name [string tolower $drv_prop_name]
		add_cross_property $ip $ip_prop_name $drv_handle ${drv_prop_name} hexint
		return
	}

	# remove CONFIG.C_
	set drv_prop_name $ip_prop_name
	regsub -all {CONFIG.C_} $drv_prop_name {xlnx,} drv_prop_name
	regsub -all {_} $drv_prop_name {-} drv_prop_name
	set drv_prop_name [string tolower $drv_prop_name]
	add_cross_property $ip $ip_prop_name $drv_handle ${drv_prop_name} hexint
}

proc gen_drv_prop_from_ip {drv_handle} {
	# check if we should generating the ip properties or not
	set gen_ip_prop [get_drv_conf_prop_list $drv_handle "CONFIG.dtg.ip_params"]
	if {[string_is_empty $gen_ip_prop]} {
		return 0
	}
	set prop_name_list [default_parameters $drv_handle]
	foreach prop_name ${prop_name_list} {
		ip2drv_prop $drv_handle $prop_name
	}
}

# based on libgen dtg
proc default_parameters {ip_handle {dont_generate ""}} {
	set par_handles [get_ip_conf_prop_list $ip_handle "CONFIG.C_.*"]
	set valid_prop_names {}
	foreach par $par_handles {
		regsub -all {CONFIG.} $par {} tmp_par
		# Ignore some parameters that are always handled specially
		switch -glob $tmp_par {
			$dont_generate - \
			"INSTANCE" - \
			"C_INSTANCE" - \
			"*BASEADDR" - \
			"*HIGHADDR" - \
			"C_SPLB*" - \
			"C_DPLB*" - \
			"C_IPLB*" - \
			"C_PLB*" - \
			"M_AXI*" - \
			"C_M_AXI*" - \
			"S_AXI_ADDR_WIDTH" - \
			"C_S_AXI_ADDR_WIDTH" - \
			"S_AXI_DATA_WIDTH" - \
			"C_S_AXI_DATA_WIDTH" - \
			"S_AXI_ACLK_FREQ_HZ" - \
			"C_S_AXI_ACLK_FREQ_HZ" - \
			"S_AXI_LITE*" - \
			"C_S_AXI_LITE*" - \
			"S_AXI_PROTOCOL" - \
			"C_S_AXI_PROTOCOL" - \
			"*INTERCONNECT_?_AXI*" - \
			"*S_AXI_ACLK_PERIOD_PS" - \
			"M*_AXIS*" - \
			"C_M*_AXIS*" - \
			"S*_AXIS*" - \
			"C_S*_AXIS*" - \
			"PRH*" - \
			"C_FAMILY" - \
			"FAMILY" - \
			"*CLK_FREQ_HZ" - \
			"*ENET_SLCR_*Mbps_DIV?" - \
			"HW_VER" { } \
			default {
				lappend valid_prop_names $par
			}
		}
	}
	return $valid_prop_names
}

proc ps7_reset_handle {drv_handle reset_pram conf_prop} {
	set src_ip -1
	set value -1
	set ip [get_cells -hier $drv_handle]
	set value [get_property ${reset_pram} $ip]
	# workaround for reset not been selected and show as "<Select>"
	regsub -all "<Select>" $value "" value
	if {[llength $value]} {
		# if MIO, assume gpio0 (bad assumption as this needs to match zynq-7000.dtsi)
		if {[regexp "^MIO" $value matched]} {
			# switch with kernel version
			set kernel_ver [get_property CONFIG.kernel_version [get_os]]
			switch -exact $kernel_ver {
				default {
					set src_ip "gpio0"
				}
			}
		}
		regsub -all "MIO( |)" $value "" value
		if {$src_ip != "-1"} {
			if {$value != "-1" && [llength $value] !=0} {
				regsub -all "CONFIG." $conf_prop "" conf_prop
				set_drv_property $drv_handle ${conf_prop} "$src_ip $value 0" reference
			}
		}
	} else {
		dtg_warning "$drv_handle: No reset found"
		return -1
	}
}

proc gen_peripheral_nodes {drv_handle {node_only ""}} {
	# Check if the peripheral is in Secure or Non-secure zone
	if {[check_ip_trustzone_state $drv_handle] == 1} {
		return
	}
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return 0
	}
	set status_enable_flow 0
	set ip [get_cells -hier $drv_handle]
	# TODO: check if the base address is correct
	set unit_addr [get_baseaddr ${ip} no_prefix]
	if { [string equal $unit_addr "-1"] } {
		return 0
	}
	set label $drv_handle
	set label_len [string length $label]
	if {$label_len >= 31} {
		# As per the device tree specification the label length should be maximum of 31 characters
		dtg_verbose "the label \"$label\" length is $label_len characters which is greater than default 31 characters as per DT SPEC...user need to fix the label\n\r"
	}
	set dev_type [get_property CONFIG.dev_type $drv_handle]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type [get_property IP_NAME [get_cell -hier $ip]]
	}
	set proc_type [get_sw_proc_prop IP_NAME]
	if {[string match -nocase $proc_type "psv_cortexa72"] } {
		set ip_type [get_property IP_NAME $ip]
		if {[string match -nocase $ip_type "psv_cpm_slcr"]} {
			set versal_periph [get_cells -hier -filter {IP_NAME == versal_cips}]
			if {[llength $versal_periph]} {
				set avail_param [list_property [get_cells -hier $versal_periph]]
				if {[lsearch -nocase $avail_param "CONFIG.CPM_PCIE0_PORT_TYPE"] >= 0} {
					set val [get_property CONFIG.CPM_PCIE0_PORT_TYPE [get_cells -hier $versal_periph]]
					if {[string match -nocase $val "Root_Port_of_PCI_Express_Root_Complex"]} {
						#For Root port device tree entry should be set Okay
					} else {
						# For Non-Root port(PCI_Express_Endpoint_device) there should not be any device tree entry in DTS
						return 0
					}
				}
			}
		}
	}
	# TODO: more ignore ip list?
	set ip_type [get_property IP_NAME $ip]
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set ignore_list "lmb_bram_if_cntlr PERIPHERAL axi_noc axi_noc2"
	} else {
		set ignore_list "lmb_bram_if_cntlr PERIPHERAL axi_noc axi_noc2"
	}
	if {[string match -nocase $ip_type "psu_pcie"]} {
		set pcie_config [get_property CONFIG.C_PCIE_MODE [get_cells -hier $drv_handle]]
		if {[string match -nocase $pcie_config "Endpoint Device"]} {
			lappend ignore_list $ip_type
		}
	}
	if {[lsearch $ignore_list $ip_type] >= 0  \
		} {
		return 0
	}
	set default_dts [set_drv_def_dts $drv_handle]

	set ps7_mapping [gen_ps7_mapping]
	set bus_node [add_or_get_bus_node $ip $default_dts]

	set status_enable_flow 0
	set status_disabled 0
	if {[is_ps_ip $drv_handle]} {
		set tmp [get_ps_node_unit_addr $drv_handle]
		if {$tmp != -1} {set unit_addr $tmp}
		if {[catch {set tmp [dict get $ps7_mapping $unit_addr label]} msg]} {
			# CHK: if PS IP that's not in the zynq-7000 dtsi, do not generate it
			return 0
		}
		if {![string_is_empty $tmp]} {
			set status_enable_flow 1
		}
		if {[catch {set tmp [dict get $ps7_mapping $unit_addr status]} msg]} {
			set status_disabled 0
		}
		if {[string equal -nocase "disabled" $tmp]} {
			set status_disabled 1
		}
	}
	if {$status_enable_flow} {
		set label [dict get $ps7_mapping $unit_addr label]
		set dev_type [dict get $ps7_mapping $unit_addr name]
		set bus_node ""
		# check if it has status property
		set rt_node [add_or_get_dt_node -n ${dev_type} -l ${label} -u ${unit_addr} -d ${default_dts} -p $bus_node -auto_ref_parent]
		if {[string match -nocase $rt_node "&dwc3_0"]} {
			set proc_type [get_sw_proc_prop IP_NAME]
				if {[string match -nocase $proc_type "psu_cortexa53"] } {
					set zynq_periph [get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
					set avail_param [list_property [get_cells -hier $zynq_periph]]
					if {[lsearch -nocase $avail_param "CONFIG.PSU__USB0__PERIPHERAL__ENABLE"] >= 0} {
						set value [get_property CONFIG.PSU__USB0__PERIPHERAL__ENABLE [get_cells -hier $zynq_periph]]
						if {$value == 1} {
							if {[lsearch -nocase $avail_param "CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE"] >= 0} {
								set val [get_property CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE [get_cells -hier $zynq_periph]]
								if {$val == 0} {
									hsi::utils::add_new_dts_param "${rt_node}" "maximum-speed" "high-speed" stringlist
									hsi::utils::add_new_dts_param "${rt_node}" "snps,dis_u2_susphy_quirk" "" boolean
									hsi::utils::add_new_dts_param "${rt_node}" "snps,dis_u3_susphy_quirk" "" boolean
									hsi::utils::add_new_dts_param "${rt_node}" "/delete-property/ phy-names" "" boolean
									hsi::utils::add_new_dts_param "${rt_node}" "/delete-property/ phys" "" boolean
								}
							}
						}
					}
				}
		}
		if {[string match -nocase $rt_node "&dwc3_1"]} {
			set proc_type [get_sw_proc_prop IP_NAME]
				if {[string match -nocase $proc_type "psu_cortexa53"] } {
					set zynq_periph [get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
					set avail_param [list_property [get_cells -hier $zynq_periph]]
					if {[lsearch -nocase $avail_param "CONFIG.PSU__USB1__PERIPHERAL__ENABLE"] >= 0} {
						set value [get_property CONFIG.PSU__USB1__PERIPHERAL__ENABLE [get_cells -hier $zynq_periph]]
						if {$value == 1} {
							if {[lsearch -nocase $avail_param "CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE"] >= 0} {
								set val [get_property CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE [get_cells -hier $zynq_periph]]
								if {$val == 0} {
									hsi::utils::add_new_dts_param "${rt_node}" "maximum-speed" "high-speed" stringlist
									hsi::utils::add_new_dts_param "${rt_node}" "snps,dis_u2_susphy_quirk" "" boolean
									hsi::utils::add_new_dts_param "${rt_node}" "snps,dis_u3_susphy_quirk" "" boolean
									hsi::utils::add_new_dts_param "${rt_node}" "/delete-property/ phy-names" "" boolean
									hsi::utils::add_new_dts_param "${rt_node}" "/delete-property/ phys" "" boolean
								}
							}
						}
					}
				}
		}
		if {$status_disabled} {
			if {[string match -nocase $ip_type "psu_smmu_gpv"]} {
				return
			}
			hsi::utils::add_new_dts_param "${rt_node}" "status" "okay" string
		}
	} else {
		if {[string match -nocase $ip_type "tsn_endpoint_ethernet_mac"]} {
			set rt_node [add_or_get_dt_node -n tsn_endpoint_ip_0 -l tsn_endpoint_ip_0 -d ${default_dts} -p $bus_node -auto_ref_parent]
		} else {
			set rt_node [add_or_get_dt_node -n ${dev_type} -l ${label} -u ${unit_addr} -d ${default_dts} -p $bus_node -auto_ref_parent]
		}
	}

	if {![string_is_empty $node_only]} {
		return $rt_node
	}

	zynq_gen_pl_clk_binding $drv_handle
	# generate mb ccf node
	generate_mb_ccf_node $drv_handle

	generate_cci_node $drv_handle $rt_node
	set dts_file_list ""
	if {[catch {set rt [report_property -return_string -regexp $drv_handle "CONFIG.*\\.dts(i|)"]} msg]} {
		set rt ""
	}
	foreach line [split $rt "\n"] {
		regsub -all {\s+} $line { } line
		if {[regexp "CONFIG.*\\.dts(i|)" $line matched]} {
			lappend dts_file_list [lindex [split $line " "] 0]
		}
	}
	regsub -all {CONFIG.} $dts_file_list {} dts_file_list

	set drv_dt_prop_list [get_driver_conf_list $drv_handle]
	foreach dts_file ${dts_file_list} {
		set dts_prop_list [get_property CONFIG.${dts_file} $drv_handle]
		set dt_node ""
		if {[string_is_empty ${dts_prop_list}] == 0} {
			set dt_node [add_or_get_dt_node -n ${dev_type} -l ${label} -u ${unit_addr} -d ${dts_file} -p $bus_node]
			foreach prop ${dts_prop_list} {
				add_driver_prop $drv_handle $dt_node CONFIG.${prop}
				# remove from default list
				set drv_dt_prop_list [list_remove_element $drv_dt_prop_list "CONFIG.${prop}"]
			}
		}
	}

	# update rest of properties to dt node
	foreach drv_prop_name $drv_dt_prop_list {
		add_driver_prop $drv_handle $rt_node ${drv_prop_name}
	}
	return $rt_node
}

proc detect_bus_name {ip_drv} {
	# FIXME: currently use single bus assumption
	# TODO: detect bus connection
	# 	zynq: uses amba base zynq-7000.dtsi
	#		pl ip creates amba_pl
	# 	mb: detection is required (currently always call amba_pl)
	set valid_buses [get_cells -hier -filter { IP_TYPE == "BUS" && IP_NAME != "axi_protocol_converter" && IP_NAME != "lmb_v10"}]

	set proc_name [get_property IP_NAME [get_cell -hier [get_sw_processor]]]
	set valid_proc_list "ps7_cortexa9 psu_cortexa53 psv_cortexa72 psx_cortexa78"
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {[is_pl_ip $ip_drv] && $remove_pl} {
		return 0
	}
	if {[lsearch  -nocase $valid_proc_list $proc_name] >= 0} {
		if {[is_pl_ip $ip_drv]} {
			# create the parent_node for pl.dtsi
			set default_dts [set_drv_def_dts $ip_drv]
			if {!$dt_overlay} {
				set root_node [add_or_get_dt_node -n / -d ${default_dts}]
			}
			return "amba_pl"
		}
		return "amba"
	}

	return "amba_pl"
}

proc get_afi_val {val} {
	set afival ""
	switch $val {
		"128" {
			set afival 0
		} "64" {
			set afival 1
		} "32" {
			set afival 2
		} default {
			dtg_warning "invalid value:$val"
		}
	}
	return $afival
}

proc get_max_afi_val {val} {
	set max_afival ""
	switch $val {
		"128" {
			set max_afival 2
		} "64" {
			set max_afival 1
		} "32" {
			set max_afival 0
		} default {
			dtg_warning "invalid value:$val"
		}
	}
	return $max_afival
}

proc get_axi_datawidth {val} {
	set data_width ""
	switch $val {
		"32" {
			set data_width 1
		} "64" {
			set data_width 0
		} default {
			dtg_warning "invalid data_width:$val"
		}
	}
	return $data_width
}

proc add_or_get_bus_node {ip_drv dts_file} {
	set bus_name [detect_bus_name $ip_drv]
	dtg_debug "bus_name: $bus_name"
	dtg_debug "bus_label: $bus_name"

	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $ip_drv] && $remove_pl} {
		return 0
	}
	if {$dt_overlay && [string match -nocase $dts_file "pl.dtsi"]} {
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			set zynq_periph [get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
			set avail_param [list_property [get_cells -hier $zynq_periph]]
			set targets "amba"
			set fpga_node [add_or_get_dt_node -n "&$targets" -d [get_dt_tree ${dts_file}]]
			set bus_node "$fpga_node"
			set RpRm [get_rp_rm_for_drv $ip_drv]
			regsub -all { } $RpRm "" RpRm
			set afi_node [add_or_get_dt_node -n "afi0" -l "afi0" -p $bus_node]
			hsi::utils::add_new_dts_param "${afi_node}" "compatible" "xlnx,afi-fpga" string
			set config_afi " "
			if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP0_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_SAXIGP0_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival [get_afi_val $val]
				append config_afi "0 $afival>, <1 $afival>,"
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP1_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_SAXIGP1_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival [get_afi_val $val]
				append config_afi " <2 $afival>, <3 $afival>,"
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP2_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_SAXIGP2_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival [get_afi_val $val]
				append config_afi " <4 $afival>, <5 $afival>,"
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP3_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_SAXIGP3_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival [get_afi_val $val]
				append config_afi " <6 $afival>, <7 $afival>,"
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP4_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_SAXIGP4_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival [get_afi_val $val]
				append config_afi " <8 $afival>, <9 $afival>,"
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP5_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_SAXIGP5_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival [get_afi_val $val]
				append config_afi " <10 $afival>, <11 $afival>,"
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP6_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_SAXIGP6_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival [get_afi_val $val]
				append config_afi " <12 $afival>, <13 $afival>,"
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_MAXIGP0_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_MAXIGP0_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival0 [get_max_afi_val $val]
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_MAXIGP1_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_MAXIGP1_DATA_WIDTH [get_cells -hier $zynq_periph]]
				set afival1 [get_max_afi_val $val]
			}
			set afi0 [expr $afival0 <<8]
			set afi1 [expr $afival1 << 10]
			set afival [expr {$afi0} | {$afi1}]
			set afi_hex [format %x $afival]
			append config_afi " <14 0x$afi_hex>,"
			if {[lsearch -nocase $avail_param "CONFIG.C_MAXIGP2_DATA_WIDTH"] >= 0} {
				set val [get_property CONFIG.C_MAXIGP2_DATA_WIDTH [get_cells -hier $zynq_periph]]
				switch $val {
					"128" {
						set afival 0x200
					} "64" {
						set afival 0x100
					} "32" {
						set afival 0x000
					} default {
						dtg_warning "invalid value:$val"
					}
				}
				append config_afi " <15 $afival"
			}
			hsi::utils::add_new_dts_param "${afi_node}" "config-afi" "$config_afi" int
			if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK0_BUF"] >= 0} {
				set val [get_property CONFIG.C_PL_CLK0_BUF [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "true"]} {
					set clocking_node [add_or_get_dt_node -n "clocking0" -l "clocking0" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "zynqmp_clk 71" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "zynqmp_clk 71" reference
					set freq [get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK1_BUF"] >= 0} {
				set val [get_property CONFIG.C_PL_CLK1_BUF [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "true"]} {
					set clocking_node [add_or_get_dt_node -n "clocking1" -l "clocking1" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "zynqmp_clk 72" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "zynqmp_clk 72" reference
					set freq [get_property CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK2_BUF"] >= 0} {
				set val [get_property CONFIG.C_PL_CLK2_BUF [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "true"]} {
					set clocking_node [add_or_get_dt_node -n "clocking2" -l "clocking2" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "zynqmp_clk 73" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "zynqmp_clk 73" reference
					set freq [get_property CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK3_BUF"] >= 0} {
				set val [get_property CONFIG.C_PL_CLK3_BUF [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "true"]} {
					set clocking_node [add_or_get_dt_node -n "clocking3" -l "clocking3" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "zynqmp_clk 74" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "zynqmp_clk 74" reference
					set freq [get_property CONFIG.PSU__CRL_APB__PL3_REF_CTRL__ACT_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
		}
		if {[string match -nocase $proctype "ps7_cortexa9"]} {
			set zynq_periph [get_cells -hier -filter {IP_NAME == processing_system7}]
			set avail_param [list_property [get_cells -hier $zynq_periph]]
			set targets "amba"
			set fpga_node [add_or_get_dt_node -n "&$targets" -d [get_dt_tree ${dts_file}]]
			set bus_node "$fpga_node"
			if {[lsearch -nocase $avail_param "CONFIG.C_USE_S_AXI_HP0"] >= 0} {
				set val [get_property CONFIG.C_USE_S_AXI_HP0 [get_cells -hier $zynq_periph]]
				if {$val == 1} {
					set afi0 [get_cells -hier -filter {NAME == "ps7_afi_0"}]
					set afi0_param [list_property [get_cells -hier $afi0]]
					if {[lsearch -nocase $afi0_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
						set base_addr [get_property CONFIG.C_S_AXI_BASEADDR [get_cells -hier $afi0]]
					}
					if {[lsearch -nocase $afi0_param "CONFIG.C_S_AXI_HIGHADDR"] >= 0} {
						set high_addr [get_property CONFIG.C_S_AXI_HIGHADDR [get_cells -hier $afi0]]
					}
					set size [format 0x%x [expr {${high_addr} - ${base_addr} + 1}]]
					set reg "$base_addr $size"
					regsub -all {^0x} $base_addr {} addr
					set addr [string tolower $addr]
					set afi_node [add_or_get_dt_node -n "afi0" -l "afi0" -u $addr -p $bus_node]
					hsi::utils::add_new_dts_param "${afi_node}" "compatible" "xlnx,afi-fpga" string
					hsi::utils::add_new_dts_param "${afi_node}" "#address-cells" "1" int
					hsi::utils::add_new_dts_param "${afi_node}" "#size-cells" "0" int
					hsi::utils::add_new_dts_param "${afi_node}" "reg" "$reg" intlist
					if {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_HP0_DATA_WIDTH"] >= 0} {
						set val [get_property CONFIG.C_S_AXI_HP0_DATA_WIDTH [get_cells -hier $zynq_periph]]
						set bus_width [get_axi_datawidth $val]
						hsi::utils::add_new_dts_param "${afi_node}" "xlnx,afi-width" "$bus_width" int
					}
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_USE_S_AXI_HP1"] >= 0} {
				set val [get_property CONFIG.C_USE_S_AXI_HP1 [get_cells -hier $zynq_periph]]
				if {$val == 1} {
					set afi1 [get_cells -hier -filter {NAME == "ps7_afi_1"}]
					set afi1_param [list_property [get_cells -hier $afi1]]
					if {[lsearch -nocase $afi1_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
						set base_addr [get_property CONFIG.C_S_AXI_BASEADDR [get_cells -hier $afi1]]
					}
					if {[lsearch -nocase $afi1_param "CONFIG.C_S_AXI_HIGHADDR"] >= 0} {
						set high_addr [get_property CONFIG.C_S_AXI_HIGHADDR [get_cells -hier $afi1]]
					}
					set size [format 0x%x [expr {${high_addr} - ${base_addr} + 1}]]
					set reg "$base_addr $size"
					regsub -all {^0x} $base_addr {} addr
					set addr [string tolower $addr]
					set afi_node [add_or_get_dt_node -n "afi1" -l "afi1" -u $addr -p $bus_node]
					hsi::utils::add_new_dts_param "${afi_node}" "compatible" "xlnx,afi-fpga" string
					hsi::utils::add_new_dts_param "${afi_node}" "#address-cells" "1" int
					hsi::utils::add_new_dts_param "${afi_node}" "#size-cells" "0" int
					hsi::utils::add_new_dts_param "${afi_node}" "reg" "$reg" intlist
					if {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_HP1_DATA_WIDTH"] >= 0} {
						set val [get_property CONFIG.C_S_AXI_HP1_DATA_WIDTH [get_cells -hier $zynq_periph]]
						set bus_width [get_axi_datawidth $val]
						hsi::utils::add_new_dts_param "${afi_node}" "xlnx,afi-width" "$bus_width" int
					}
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_USE_S_AXI_HP2"] >= 0} {
				set val [get_property CONFIG.C_USE_S_AXI_HP2 [get_cells -hier $zynq_periph]]
				if {$val == 1} {
					set afi2 [get_cells -hier -filter {NAME == "ps7_afi_2"}]
					set afi2_param [list_property [get_cells -hier $afi2]]
					if {[lsearch -nocase $afi2_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
						set base_addr [get_property CONFIG.C_S_AXI_BASEADDR [get_cells -hier $afi2]]
					}
					if {[lsearch -nocase $afi2_param "CONFIG.C_S_AXI_HIGHADDR"] >= 0} {
						set high_addr [get_property CONFIG.C_S_AXI_HIGHADDR [get_cells -hier $afi2]]
					}
					set size [format 0x%x [expr {${high_addr} - ${base_addr} + 1}]]
					set reg "$base_addr $size"
					regsub -all {^0x} $base_addr {} addr
					set addr [string tolower $addr]
					set afi_node [add_or_get_dt_node -n "afi2" -l "afi2" -u $addr -p $bus_node]
					hsi::utils::add_new_dts_param "${afi_node}" "compatible" "xlnx,afi-fpga" string
					hsi::utils::add_new_dts_param "${afi_node}" "#address-cells" "1" int
					hsi::utils::add_new_dts_param "${afi_node}" "#size-cells" "0" int
					hsi::utils::add_new_dts_param "${afi_node}" "reg" "$reg" intlist
					if {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_HP2_DATA_WIDTH"] >= 0} {
						set val [get_property CONFIG.C_S_AXI_HP2_DATA_WIDTH [get_cells -hier $zynq_periph]]
						set bus_width [get_axi_datawidth $val]
						hsi::utils::add_new_dts_param "${afi_node}" "xlnx,afi-width" "$bus_width" int
					}
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.C_USE_S_AXI_HP3"] >= 0} {
				set val [get_property CONFIG.C_USE_S_AXI_HP3 [get_cells -hier $zynq_periph]]
				if {$val == 1} {
					set afi3 [get_cells -hier -filter {NAME == "ps7_afi_3"}]
					set afi3_param [list_property [get_cells -hier $afi3]]
					if {[lsearch -nocase $afi3_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
						set base_addr [get_property CONFIG.C_S_AXI_BASEADDR [get_cells -hier $afi2]]
					}
					if {[lsearch -nocase $afi3_param "CONFIG.C_S_AXI_HIGHADDR"] >= 0} {
						set high_addr [get_property CONFIG.C_S_AXI_HIGHADDR [get_cells -hier $afi2]]
					}
					set size [format 0x%x [expr {${high_addr} - ${base_addr} + 1}]]
					set reg "$base_addr $size"
					regsub -all {^0x} $base_addr {} addr
					set addr [string tolower $addr]
					set afi_node [add_or_get_dt_node -n "afi3" -l "afi3" -u $addr -p $bus_node]
					hsi::utils::add_new_dts_param "${afi_node}" "compatible" "xlnx,afi-fpga" string
					hsi::utils::add_new_dts_param "${afi_node}" "#address-cells" "1" int
					hsi::utils::add_new_dts_param "${afi_node}" "#size-cells" "0" int
					hsi::utils::add_new_dts_param "${afi_node}" "reg" "$reg" intlist
					if {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_HP3_DATA_WIDTH"] >= 0} {
						set val [get_property CONFIG.C_S_AXI_HP3_DATA_WIDTH [get_cells -hier $zynq_periph]]
						set bus_width [get_axi_datawidth $val]
						hsi::utils::add_new_dts_param "${afi_node}" "xlnx,afi-width" "$bus_width" int
					}
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PCW_FPGA_FCLK0_ENABLE"] >= 0} {
				set val [get_property CONFIG.PCW_FPGA_FCLK0_ENABLE [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "1"]} {
					set clocking_node [add_or_get_dt_node -n "clocking0" -l "clocking0" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "clkc 15" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "clkc 15" reference
					set freq [get_property CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PCW_FPGA_FCLK1_ENABLE"] >= 0} {
				set val [get_property CONFIG.PCW_FPGA_FCLK1_ENABLE [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "1"]} {
					set clocking_node [add_or_get_dt_node -n "clocking1" -l "clocking1" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "clkc 16" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "clkc 16" reference
					set freq [get_property CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PCW_FPGA_FCLK2_ENABLE"] >= 0} {
				set val [get_property CONFIG.PCW_FPGA_FCLK2_ENABLE [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "1"]} {
					set clocking_node [add_or_get_dt_node -n "clocking2" -l "clocking2" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "clkc 17" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "clkc 17" reference
					set freq [get_property CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PCW_FPGA_FCLK3_ENABLE"] >= 0} {
				set val [get_property CONFIG.PCW_FPGA_FCLK3_ENABLE [get_cells -hier $zynq_periph]]
				if {[string match -nocase $val "1"]} {
					set clocking_node [add_or_get_dt_node -n "clocking3" -l "clocking3" -p $bus_node]
					hsi::utils::add_new_dts_param "${clocking_node}" "compatible" "xlnx,fclk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "clocks" "clkc 18" reference
					hsi::utils::add_new_dts_param "${clocking_node}" "clock-output-names" "fabric_clk" string
					hsi::utils::add_new_dts_param "${clocking_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clocks" "clkc 18" reference
					set freq [get_property CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ [get_cells -hier $zynq_periph]]
					hsi::utils::add_new_dts_param "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int
				}
			}
		}
	}
	if {[is_pl_ip $ip_drv] && $dt_overlay} {
		set targets "amba"
		set fpga_node [add_or_get_dt_node -n "&$targets" -d [get_dt_tree ${dts_file}]]
		set RpRm [get_rp_rm_for_drv $ip_drv]
		regsub -all { } $RpRm "" RpRm
		if {[llength $RpRm]} {
			set default_dts "pl-partial-$RpRm.dtsi"
		}
		set bus_node "$fpga_node"
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			hsi::utils::add_new_dts_param "${bus_node}" "#address-cells" 2 int
			hsi::utils::add_new_dts_param "${bus_node}" "#size-cells" 2 int
		} else {
			hsi::utils::add_new_dts_param "${bus_node}" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "${bus_node}" "#size-cells" 1 int
		}
	} else {
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
			set bus_node [add_or_get_dt_node -n ${bus_name} -l ${bus_name} -u 0 -d [get_dt_tree ${dts_file}] -p "/" -disable_auto_ref -auto_ref_parent]
		} else {
			set bus_node [add_or_get_dt_node -n ${bus_name} -l ${bus_name} -d [get_dt_tree ${dts_file}] -p "/" -disable_auto_ref -auto_ref_parent]
		}

		if {![string match "&*" $bus_node]} {
			set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
			if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
				hsi::utils::add_new_dts_param "${bus_node}" "#address-cells" 2 int
				hsi::utils::add_new_dts_param "${bus_node}" "#size-cells" 2 int
			} else {
				hsi::utils::add_new_dts_param "${bus_node}" "#address-cells" 1 int
				hsi::utils::add_new_dts_param "${bus_node}" "#size-cells" 1 int
			}
			hsi::utils::add_new_dts_param "${bus_node}" "compatible" "simple-bus" stringlist
			hsi::utils::add_new_dts_param "${bus_node}" "ranges" "" boolean
		}
	}
	return $bus_node
}

proc gen_root_node {drv_handle} {
	set default_dts [set_drv_def_dts $drv_handle]
	# add compatible
	set ip_name [get_property IP_NAME [get_cell -hier ${drv_handle}]]
	switch $ip_name {
		"ps7_cortexa9" {
			create_dt_tree_from_dts_file
			global dtsi_fname
			update_system_dts_include [file tail ${dtsi_fname}]
			# no root_node required as zynq-7000.dtsi
			return 0
		}
		"psu_cortexa53" {
			create_dt_tree_from_dts_file
			global dtsi_fname
			set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
			set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
			if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
				update_system_dts_include [file tail ${dtsi_fname}]
				update_system_dts_include [file tail "zynqmp-clk.dtsi"]
				return 0
			}
			update_system_dts_include [file tail ${dtsi_fname}]
			update_system_dts_include [file tail "zynqmp-clk-ccf.dtsi"]
			# no root_node required as zynqmp.dtsi
			return 0
		}
		"psv_cortexa72" {
			create_dt_tree_from_dts_file
			global dtsi_fname
			update_system_dts_include [file tail ${dtsi_fname}]
			set overrides [get_property CONFIG.periph_type_overrides [get_os]]
			set dtsi_file " "
			foreach override $overrides {
				if {[lindex $override 0] == "BOARD"} {
					set dtsi_file [lindex $override 1]
				}
			}
			if {[string match -nocase $dtsi_file "versal-spp-itr8-cn13940875"] || [string match -nocase $dtsi_file "versal-vc-p-a2197-00-reva-x-prc-01-reva-pm"]} {
				update_system_dts_include [file tail "versal-spp-pm.dtsi"]
			} else {
				update_system_dts_include [file tail "versal-clk.dtsi"]
			}
			return 0
		}
		"psx_cortexa78" {
			create_dt_tree_from_dts_file
			global dtsi_fname
            update_system_dts_include [file tail ${dtsi_fname}]
			set overrides [get_property CONFIG.periph_type_overrides [get_os]]
			set dtsi_file " "
            set board_dtsi_file ""
			foreach override $overrides {
				if {[lindex $override 0] == "BOARD"} {
					set board_dtsi_file [lindex $override 1]
				}
			}
            #TMP fix to support ipp fixed clocks
            if {[string match -nocase $board_dtsi_file "versal-net-ipp-rev1.9"]} {
                set dtsi_file $board_dtsi_file
            } else {
                update_system_dts_include [file tail "versal-net-clk.dtsi"]
            }
			return 0
		}
		"microblaze" {
			set compatible "xlnx,microblaze"
			set model "Xilinx MicroBlaze"
		}
		default {
			return -code error "Unknown arch"
		}
	}
	set root_node [add_or_get_dt_node -n / -d ${default_dts}]
	hsi::utils::add_new_dts_param "${root_node}" "#address-cells" 1 int ""
	hsi::utils::add_new_dts_param "${root_node}" "#size-cells" 1 int ""
	hsi::utils::add_new_dts_param "${root_node}" model $model string ""
	hsi::utils::add_new_dts_param "${root_node}" compatible $compatible string ""

	return $root_node
}

proc cortexa9_opp_gen {drv_handle} {
	# generate opp overlay for cpu
	if {[catch {set cpu_max_freq [get_property CONFIG.C_CPU_CLK_FREQ_HZ [get_cells -hier $drv_handle]]} msg]} {
		set cpu_max_freq ""
	}
	if {[string_is_empty ${cpu_max_freq}]} {
		dtg_warning "DTG failed to detect the CPU clock frequency"
		return -1
	}
	set cpu_max_freq [expr int([expr $cpu_max_freq/1000])]
	set processor [get_sw_processor]
	set default_dts [set_drv_def_dts $processor]
	set root_node [add_or_get_dt_node -n / -d ${default_dts}]

	set cpu_root_node [add_or_get_dt_node -n cpus -d ${default_dts} -p $root_node]
	set cpu_node [add_or_get_dt_node -n cpu -u 0 -d ${default_dts} -p ${cpu_root_node} -disable_auto_ref -force]

	set tmp_opp $cpu_max_freq
	set opp ""
	set i 0
	# do not generate opp for freq lower than 200MHz and use fix voltage
	# 1000000uv
	while {$tmp_opp >= 200000} {
		append opp " " "$tmp_opp 1000000"
		incr i
		set tmp_opp [expr int([expr $cpu_max_freq / pow(2, $i)])]
	}
	if {![string_is_empty $opp]} {
		hsi::utils::add_new_dts_param $cpu_node "operating-points" "$opp" intlist
	}
}

# Q: common function for all processor or one for each driver lib
proc gen_cpu_nodes {drv_handle} {
	set ip_name [get_property IP_NAME [get_cell -hier [get_sw_processor]]]
	switch $ip_name {
		"ps7_cortexa9" {
			# skip node generation for static zynq-7000 dtsi
			# TODO: this needs to be fixed to allow override
			cortexa9_opp_gen $drv_handle
			return 0
		}
		"psu_cortexa53" {
			# skip node generation for static zynqmp dtsi
			return 0
		}
		"psv_cortexa72" {
			return 0
		}
		"psx_cortexa78" {
			return 0
		} "microblaze" {}
		default {
			error "Unknown arch"
		}
	}

	set processor [get_sw_processor]
	set dev_type [get_property CONFIG.dev_type $processor]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type $drv_handle
	}
	gen_compatible_property $processor
	gen_mb_interrupt_property $processor
	gen_drv_prop_from_ip $processor

	set default_dts [set_drv_def_dts $processor]
	set cpu_root_node [add_or_get_dt_node -n cpus -d ${default_dts} -p /]
	hsi::utils::add_new_dts_param "${cpu_root_node}" "#address-cells" 1 int ""
	hsi::utils::add_new_dts_param "${cpu_root_node}" "#size-cells" 0 int ""

	set processor_type [get_property IP_NAME [get_cell -hier ${processor}]]
	set processor_list [eval "get_cells -hier -filter { IP_TYPE == \"PROCESSOR\" && IP_NAME == \"${processor_type}\" }"]

	set drv_dt_prop_list [get_driver_conf_list $processor]

	# generate mb ccf node
	generate_mb_ccf_node $processor

	set bus_node [add_or_get_bus_node $drv_handle $default_dts]
	set cpu_no 0
	foreach cpu ${processor_list} {
		# Generate the node only for the single core
		if {$cpu_no >= 1} {
			break
		}
		set bus_label [get_property NODE_LABEL $bus_node]
		set cpu_node [add_or_get_dt_node -n ${dev_type} -l ${cpu} -u ${cpu_no} -d ${default_dts} -p ${cpu_root_node}]
		hsi::utils::add_new_dts_param "${cpu_node}" "bus-handle" $bus_label reference
		foreach drv_prop_name $drv_dt_prop_list {
			add_driver_prop $processor $cpu_node ${drv_prop_name}
		}
			hsi::utils::add_new_dts_param "${cpu_node}" "reg" $cpu_no int ""
		incr cpu_no
	}
	hsi::utils::add_new_dts_param "${cpu_root_node}" "#cpus" $cpu_no int ""
}

proc remove_all_tree {} {
	# for testing
	set test_dummy "for_test_dummy.dts"
	if {[lsearch [get_dt_trees] ${test_dummy}] < 0} {
		create_dt_tree -dts_file $test_dummy
	}
	set_cur_working_dts $test_dummy

	foreach tree [get_dt_trees] {
		if {[string equal -nocase $test_dummy $tree]} {
			continue
		}
		catch {delete_objs $tree} msg
	}
}

proc gen_mdio_node {drv_handle parent_node} {
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {[is_pl_ip $drv_handle] && $remove_pl} {
		return
	}
	set mdio_node [add_or_get_dt_node -l ${drv_handle}_mdio -n mdio -p $parent_node]
	hsi::utils::add_new_dts_param "${mdio_node}" "#address-cells" 1 int ""
	hsi::utils::add_new_dts_param "${mdio_node}" "#size-cells" 0 int ""
	return $mdio_node
}

proc add_memory_node {drv_handle} {
	set master_dts [get_property CONFIG.master_dts [get_os]]
	set cur_dts [current_dt_tree]
	set master_dts_obj [get_dt_trees ${master_dts}]
	set_cur_working_dts $master_dts

	# assuming single memory region
	#  - single memory region
	#  - / node is created
	#  - reg property is generated
	# CHECK node naming
	set ddr_ip ""
	set main_memory  [get_property CONFIG.main_memory [get_os]]
	if {![string match -nocase $main_memory "none"]} {
		set ddr_ip [get_property IP_NAME [get_cells -hier $main_memory]]
	}
	set ddr_list "psu_ddr ps7_ddr axi_emc mig_7series psv_ddr"
	if {[lsearch -nocase $ddr_list $ddr_ip] >= 0} {
		set parent_node [add_or_get_dt_node -n / -d ${master_dts}]
        set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		set reg_value [get_property CONFIG.reg $drv_handle]
        # Append base address to memory node.
        if {[llength "$reg_value"]} {
            if {[string match -nocase $proctype "psu_cortexa53"] || \
                [string match -nocase $proctype "psv_cortexa72"] || \
                [string match -nocase $proctype "psx_cortexa78"]} {
                set higheraddr [expr [lindex $reg_value 0] << 32]
                set loweraddr [lindex $reg_value 1]
                set unitaddr [format 0x%x [expr {${higheraddr} + ${loweraddr}}]]
            } else {
                set unitaddr [lindex $reg_value 0]
            }
            regsub -all {^0x} $unitaddr {} unitaddr
            set memory_node [add_or_get_dt_node -n memory -p $parent_node -u $unitaddr]
            hsi::utils::add_new_dts_param "${memory_node}" "reg" $reg_value inthexlist
        }
		# maybe hardcoded
		if {[catch {set dev_type [get_property CONFIG.device_type $drv_handle]} msg]} {
			set dev_type memory
		}
		if {[string_is_empty $dev_type]} {set dev_type memory}
		hsi::utils::add_new_dts_param "${memory_node}" "device_type" $dev_type string

		set_cur_working_dts $cur_dts
		return $memory_node
	}
}

proc gen_mb_ccf_subnode {drv_handle name freq reg} {
	set cur_dts [current_dt_tree]
	set default_dts [set_drv_def_dts $drv_handle]

	set clk_node [add_or_get_dt_node -n clocks -p / -d ${default_dts}]
	hsi::utils::add_new_dts_param "${clk_node}" "#address-cells" 1 int
	hsi::utils::add_new_dts_param "${clk_node}" "#size-cells" 0 int

	set clk_subnode_name "clk_${name}"
	set clk_subnode [add_or_get_dt_node -l ${clk_subnode_name} -n ${clk_subnode_name} -u $reg -p ${clk_node} -d ${default_dts}]
	# clk subnode data
	hsi::utils::add_new_dts_param "${clk_subnode}" "compatible" "fixed-clock" stringlist
	hsi::utils::add_new_dts_param "${clk_subnode}" "#clock-cells" 0 int

	hsi::utils::add_new_dts_param $clk_subnode "clock-output-names" $clk_subnode_name string
	hsi::utils::add_new_dts_param $clk_subnode "reg" $reg int
	hsi::utils::add_new_dts_param $clk_subnode "clock-frequency" $freq int

	set_cur_working_dts $cur_dts
}

proc generate_mb_ccf_node {drv_handle} {
	global bus_clk_list

	set sw_proc [get_sw_processor]
	set proc_ip [get_cells -hier $sw_proc]
	set proctype [get_property IP_NAME $proc_ip]
	if {[string match -nocase $proctype "microblaze"]} {
		set cpu_clk_freq [get_clock_frequency $proc_ip "CLK"]
		# issue:
		# - hardcoded reg number cpu clock node
		# - assume clk_cpu for mb cpu
		# - only applies to master mb cpu
		gen_mb_ccf_subnode $sw_proc cpu $cpu_clk_freq 0
	}
}

proc gen_dev_ccf_binding args {
	set drv_handle [lindex $args 0]
	set pins [lindex $args 1]
	set binding_list "clocks clock-frequency"
	if {[llength $args] >= 3} {
		set binding_list [lindex $args 2]
	}
	# list of ip should have the clocks property
	global bus_clk_list

	set sw_proc [get_sw_processor]
	set proc_ip [get_cells -hier $sw_proc]
	set proctype [get_property IP_NAME $proc_ip]
	if {[string match -nocase $proctype "microblaze"]} {
		set clk_refs ""
		set clk_names ""
		set clk_freqs ""
		foreach p $pins {
			set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$p"]
			if {![string equal $clk_freq ""]} {
				# FIXME: bus clk source count should based on the clock generator not based on clk freq diff
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
				set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
				# create the node and assuming reg 0 is taken by cpu
				gen_mb_ccf_subnode $drv_handle bus_${bus_clk_cnt} $clk_freq [expr ${bus_clk_cnt} + 1]
				set clk_refs [lappend clk_refs &clk_bus_${bus_clk_cnt}]
				set clk_names [lappend clk_names "$p"]
				set clk_freqs [lappend clk_freqs "$clk_freq"]
			}
		}
		if {[lsearch $binding_list "clocks"] >= 0} {
			hsi::utils::add_new_property $drv_handle "clocks" referencelist $clk_refs
		}
		if {[lsearch $binding_list "clock-names"] >= 0} {
			hsi::utils::add_new_property $drv_handle "clock-names" stringlist $clk_names
		}
		if {[lsearch $binding_list "clock-frequency"] >= 0} {
			hsi::utils::add_new_property $drv_handle "clock-frequency" hexintlist $clk_freqs
		}
	}
}

proc update_eth_mac_addr {drv_handle} {
	set eth_count [get_os_dev_count "eth_mac_count"]
	set tmp [list_property $drv_handle CONFIG.local-mac-address]
	if {![string_is_empty $tmp]} {
		set def_mac [get_property CONFIG.local-mac-address $drv_handle]
	} else {
		set def_mac ""
	}
	if {[string_is_empty $def_mac]} {
		set def_mac "00 0a 35 00 00 00"
	}
	set mac_addr_data [split $def_mac " "]
	set last_value [format %02x [expr [lindex $mac_addr_data 5] + $eth_count ]]
	set mac_addr [lreplace $mac_addr_data 5 5 $last_value]
	dtg_debug "${drv_handle}:set mac addr to $mac_addr"
	incr eth_count
	hsi::utils::set_os_parameter_value "eth_mac_count" $eth_count
	hsi::utils::add_new_property $drv_handle "local-mac-address" bytelist ${mac_addr}
}

proc get_os_dev_count {count_para {drv_handle ""} {os_para ""}} {
	set dev_count [hsi::utils::get_os_parameter_value "${count_para}"]
	if {[llength $dev_count] == 0} {
		set dev_count 0
	}
	if {[string_is_empty $os_para] || [string_is_empty $drv_handle]} {
		return $dev_count
	}
	set ip [get_cells -hier $drv_handle]
	set chosen_ip [hsi::utils::get_os_parameter_value "${os_para}"]
	if {[string match -nocase "$ip" "$chosen_ip"]} {
		hsi::utils::set_os_parameter_value $count_para 1
		return 0
	} else {
		return $dev_count
	}
}

proc get_hw_version {} {
	set hw_ver_data [split [get_property VIVADO_VERSION [get_hw_designs]] "."]
	set hw_ver [lindex $hw_ver_data 0].[lindex $hw_ver_data 1]
	return $hw_ver
}

proc get_hsi_version {} {
	set hsi_ver_data [split [version -short] "."]
	set hsi_ver [lindex $hsi_ver_data 0].[lindex $hsi_ver_data 1]
	return $hsi_ver
}

proc get_sw_proc_prop {prop_name} {
	set sw_proc [get_sw_processor]
	set proc_ip [get_cells -hier $sw_proc]
	set property_value [get_property $prop_name $proc_ip]
	return $property_value
}

# Get the interrupt controller name, which the ip is connected
proc get_intr_cntrl_name { periph_name intr_pin_name } {
	lappend intr_cntrl
	if { [llength $intr_pin_name] == 0 } {
		return $intr_cntrl
	}
	if { [llength $periph_name] != 0 } {
	# This is the case where IP pin is interrupting
	set periph [::hsi::get_cells -hier -filter "NAME==$periph_name"]

	if { [llength $periph] == 0 } {
		return $intr_cntrl
	}
	set intr_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intr_pin_name"]
	if { [llength $intr_pin] == 0 } {
		return $intr_cntrl
	}
	set valid_cascade_proc "microblaze ps7_cortexa9 psu_cortexa53 psv_cortexa72 psx_cortexa78"
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if { [string match -nocase [common::get_property IP_NAME $periph] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0 } {
		set sinks [::hsi::utils::get_sink_pins $intr_pin]
		foreach intr_sink ${sinks} {
			set sink_periph [::hsi::get_cells -of_objects $intr_sink]
			if { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "axi_intc"] } {
				# this the case where interrupt port is connected to axi_intc.
				lappend intr_cntrl [get_intr_cntrl_name $sink_periph "irq"]
			} elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "xlconcat"] } {
				# this the case where interrupt port is connected to XLConcat IP.
				lappend intr_cntrl [get_intr_cntrl_name $sink_periph "dout"]
			} elseif { [llength $sink_periph ] && [::hsi::utils::is_intr_cntrl $sink_periph] == 1 } {
				lappend intr_cntrl $sink_periph
			} elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "microblaze"] } {
				lappend intr_cntrl $sink_periph
			} elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "tmr_voter"] } {
				lappend intr_cntrl $sink_periph
			} elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
				set intr [get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
				lappend intr_cntrl [get_intr_cntrl_name $sink_periph "$intr"]
			}
			if {[llength $intr_cntrl] > 1} {
				foreach intc $intr_cntrl {
					if { [::hsi::utils::is_ip_interrupting_current_proc $intc] } {
						set intr_cntrl $intc
					}
				}
			}
		}
		return $intr_cntrl
	}
	set pin_dir [common::get_property DIRECTION $intr_pin]
	if { [string match -nocase $pin_dir "I"] } {
		return $intr_cntrl
	}
	} else {
		# This is the case where External interrupt port is interrupting
		set intr_pin [::hsi::get_ports $intr_pin_name]
		if { [llength $intr_pin] == 0 } {
			return $intr_cntrl
		}
		set pin_dir [common::get_property DIRECTION $intr_pin]
		if { [string match -nocase $pin_dir "O"] } {
			return $intr_cntrl
		}
	}

	set intr_sink_pins [::hsi::utils::get_sink_pins $intr_pin]
	if { [llength $intr_sink_pins] == 0 || [string match $intr_sink_pins "{}"]} {
		return $intr_cntrl
	}
	set valid_cascade_proc "microblaze ps7_cortexa9 psu_cortexa53 psv_cortexa72 psx_cortexa78"
	foreach intr_sink ${intr_sink_pins} {
		if {[llength $intr_sink] == 0} {
			continue
		}
		set sink_periph [::hsi::get_cells -of_objects $intr_sink]
		if { [llength $sink_periph ] && [::hsi::utils::is_intr_cntrl $sink_periph] == 1 } {
			if { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0} {
				lappend intr_cntrl [get_intr_cntrl_name $sink_periph "irq"]
			} else {
				lappend intr_cntrl $sink_periph
			}
		} elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "xlconcat"] } {
			# this the case where interrupt port is connected to XLConcat IP.
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "dout"]
		} elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "xlslice"]} {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Dout"]
		} elseif {[llength $sink_periph] &&  [string match -nocase [common::get_property IP_NAME $sink_periph] "util_reduced_logic"]} {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Res"]
		} elseif {[llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "axi_gpio"]} {
			set intr_present [get_property CONFIG.C_INTERRUPT_PRESENT $sink_periph]
			if {$intr_present == 1} {
				lappend intr_cntrl $sink_periph
			}
		} elseif {[llength $sink_periph] &&  [string match -nocase [common::get_property IP_NAME $sink_periph] "util_ff"]} {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Q"]
		} elseif { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
			set intr [get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "$intr"]
		}
		if {[llength $intr_cntrl] > 1} {
			foreach intc $intr_cntrl {
				if { [::hsi::utils::is_ip_interrupting_current_proc $intc] } {
					set intr_cntrl $intc
				}
			}
		}
	}
	set val [string trim $intr_cntrl \{\}]
	if {[llength $val] == 0} {
		return
	}
	return $intr_cntrl
}

# Generate interrupt info for the ips which are using gpio
# as interrupt.
proc generate_gpio_intr_info {connected_intc drv_handle pin} {
	set intr_info ""
	global ps_gpio_pincount
	if {[string_is_empty $connected_intc]} {
		return -1
	}
	# Get the gpio channel number to which the ip is connected
	set channel_nr [get_gpio_channel_nr $drv_handle $pin]
	set slave [get_cells -hier ${drv_handle}]
	set ip_name $connected_intc
	set intr_type [get_intr_type $connected_intc $slave $pin]
	if {[string match -nocase $intr_type "-1"]} {
		return -1
	}
	set sinkpin [::hsi::utils::get_sink_pins [get_pins -of [get_cells -hier $drv_handle] -filter {TYPE==INTERRUPT}]]
	set dual [get_property CONFIG.C_IS_DUAL $connected_intc]
	regsub -all {[^0-9]} $sinkpin "" gpio_pin_count
	set gpio_cho_pin_lcnt [get_property LEFT [get_pins -of_objects [get_cells -hier $connected_intc] gpio_io_i]]
	set gpio_cho_pin_rcnt [get_property RIGHT [get_pins -of_objects [get_cells -hier $connected_intc] gpio_io_i]]
	set gpio_cho_pin_rcnt [expr $gpio_cho_pin_rcnt + 1]
	set gpio_ch0_pin_cnt [expr {$gpio_cho_pin_lcnt + $gpio_cho_pin_rcnt}]
	if {[string match $channel_nr "0"]} {
		# Check for ps7_gpio else check for axi_gpio
		if {[string match $sinkpin "GPIO_I"]} {
			set intr_info "$ps_gpio_pincount $intr_type"
			expr ps_gpio_pincount 1
		} elseif {[regexp "gpio_io_i" $sinkpin match]} {
			set intr_info "0 $intr_type"
		} else {
			# if channel width is more than one
			set intr_info "$gpio_pin_count $intr_type "
		}
	} else {
		if {[string match $dual "1"]} {
			# gpio channel 2 width is one
			if {[regexp "gpio2_io_i" $sinkpin match]} {
				set intr_info "32 $intr_type"
			} else {
				# if channel width is more than one
				set intr_pin [::hsi::get_pins -of_objects $connected_intc -filter "NAME==$pin"]
				set gpio_channel [::hsi::utils::get_sink_pins $intr_pin]
				set intr_id [expr $gpio_pin_count + $gpio_ch0_pin_cnt]
				set intr_info "$intr_id $intr_type"
			}
		}
	}
	set intc $connected_intc
	if {[string_is_empty $intr_info]} {
		return -1
	}
	set_drv_prop $drv_handle interrupts $intr_info intlist
	if {[string_is_empty $intc]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]
	set_drv_prop $drv_handle interrupt-parent $intc reference
}

# Get the gpio channel number to which the ip is connected
# if pin is gpio_io_* then channel is 1
# if pin is gpio2_io_* then channel is 2
proc get_gpio_channel_nr { periph_name intr_pin_name } {
	lappend intr_cntrl
	if { [llength $intr_pin_name] == 0 } {
		return $intr_cntrl
	}
	if { [llength $periph_name] != 0 } {
		set periph [::hsi::get_cells -hier -filter "NAME==$periph_name"]

		if { [llength $periph] == 0 } {
			return $intr_cntrl
		}
		set intr_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intr_pin_name"]
		if { [llength $intr_pin] == 0 } {
			return $intr_cntrl
		}
		set pin_dir [common::get_property DIRECTION $intr_pin]
		if { [string match -nocase $pin_dir "I"] } {
			return $intr_cntrl
		}
		set intr_sink_pins [::hsi::utils::get_sink_pins $intr_pin]
		set sink_periph [::hsi::get_cells -of_objects $intr_sink_pins]
		if { [llength $sink_periph] && [string match -nocase [common::get_property IP_NAME $sink_periph] "xlconcat"] } {
			# this the case where interrupt port is connected to XLConcat IP.
			return [get_gpio_channel_nr $sink_periph "dout"]
		}
		if {[regexp "gpio[2]_*" $intr_sink_pins match]} {
			return 1
		} else {
			return 0
		}
	}
}

proc is_interrupt { IP_NAME } {
	if { [string match -nocase $IP_NAME "ps7_scugic"] } {
		return true
	} elseif { [string match -nocase $IP_NAME "psu_acpu_gic"] || [string match -nocase $IP_NAME "psv_acpu_gic"] || [string match -nocase $IP_NAME "psx_acpu_gic"]} {
		return true
	} elseif { [string match -nocase $IP_NAME "psu_rcpu_gic"] } {
		return true
	}
	return false;

}

proc is_orgate { intc_src_port ip_name} {
	set ret -1

	set intr_sink_pins [::hsi::utils::get_sink_pins $intc_src_port]
	set sink_periph [::hsi::get_cells -of_objects $intr_sink_pins]
	set ipname [get_property IP_NAME $sink_periph]
	if { $ipname == "xlconcat" } {
		set intf "dout"
		set intr1_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$intf"]
		set intr_sink_pins [::hsi::utils::get_sink_pins $intr1_pin]
		set sink_periph [::hsi::get_cells -of_objects $intr_sink_pins]
		set ipname [get_property IP_NAME $sink_periph]
		if {$ipname == "util_reduced_logic"} {
			set width [get_property CONFIG.C_SIZE $sink_periph]
			return $width
		}
	}

	return $ret
}

proc get_psu_interrupt_id { ip_name port_name } {
    global or_id
    global or_cnt

    set ret -1
    set periph ""
    set intr_pin ""
    if { [llength $port_name] == 0 } {
        return $ret
    }
    global pl_ps_irq1
    global pl_ps_irq0
    if { [llength $ip_name] != 0 } {
        #This is the case where IP pin is interrupting
        set periph [::hsi::get_cells -hier -filter "NAME==$ip_name"]
        if { [llength $periph] == 0 } {
            return $ret
        }
        set intr_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$port_name"]
        if { [llength $intr_pin] == 0 } {
            return $ret
        }
        set pin_dir [common::get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "I"] } {
          return $ret
        }
    } else {
        #This is the case where External interrupt port is interrupting
        set intr_pin [::hsi::get_ports $port_name]
        if { [llength $intr_pin] == 0 } {
            return $ret
        }
        set pin_dir [common::get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "O"] } {
          return $ret
        }
    }
    set intc_periph [get_interrupt_parent $ip_name $port_name]
    if {[llength $intc_periph] > 1} {
        foreach intr_cntr $intc_periph {
            if { [::hsi::utils::is_ip_interrupting_current_proc $intr_cntr] } {
                set intc_periph $intr_cntr
            }
        }
    }
    if { [llength $intc_periph]  ==  0 } {
        return $ret
    }

    set intc_type [common::get_property IP_NAME $intc_periph]
    #set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[llength $intc_type] > 1} {
        foreach intr_cntr $intc_type {
            if { [::hsi::utils::is_ip_interrupting_current_proc $intr_cntr] } {
                set intc_type $intr_cntr
            }
        }
    }

    set intc_src_ports [::hsi::utils::get_interrupt_sources $intc_periph]

    #Special Handling for cascading case of axi_intc Interrupt controller
    set cascade_id 0

    set i $cascade_id
    set found 0
    set j $or_id
    foreach intc_src_port $intc_src_ports {
	# Check whether externel port is interrupting not peripheral
        # like externel[7:0] port to gic
        set pin_dir [common::get_property DIRECTION $intc_src_port]
        if { [string match -nocase $pin_dir "I"] } {
		incr i
                continue
        }
        if { [llength $intc_src_port] == 0 } {
            incr i
            continue
        }
        set intr_width [::hsi::utils::get_port_width $intc_src_port]
        set intr_periph [::hsi::get_cells -of_objects $intc_src_port]
        if { [llength $intr_periph] && [is_interrupt $intc_type] } {
            if {[common::get_property IS_PL $intr_periph] == 0 } {
                continue
            }
        }
        set width [is_orgate $intc_src_port $ip_name]
        if { [string compare -nocase "$port_name"  "$intc_src_port" ] == 0 } {
            if { [string compare -nocase "$intr_periph" "$periph"] == 0  && $width != -1} {
		set or_cnt [expr $or_cnt + 1]
                if { $or_cnt == $width} {
                    set or_cnt 0
                    set or_id [expr $or_id + 1]
                }
                set ret $i
                set found 1
                break
            } elseif { [string compare -nocase "$intr_periph" "$periph"] == 0 } {
                set ret $i
                set found 1
                break
            }
        }
        if { $width != -1} {
            set i [expr $or_id]
        } else {
            set i [expr $i + $intr_width]
        }
    }
    set intr_list_irq0 [list 89 90 91 92 93 94 95 96]
    set intr_list_irq1 [list 104 105 106 107 108 109 110 111]
    set sink_pins [::hsi::utils::get_sink_pins $intr_pin]
    if { [llength $sink_pins] == 0 } {
        return
    }
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[string match -nocase $proctype "microblaze"]} {
         if {[string match -nocase "[get_property IP_NAME $periph]" "axi_intc"]} {
             set ip [get_property IP_NAME $periph]
             set cascade_master [get_property CONFIG.C_CASCADE_MASTER [get_cells -hier $periph]]
             set en_cascade_mode [get_property CONFIG.C_EN_CASCADE_MODE [get_cells -hier $periph]]
             set sink_pn [::hsi::utils::get_sink_pins $intr_pin]
             set peri [::hsi::get_cells -of_objects $sink_pn]
             set periph_ip [get_property IP_NAME [get_cells -hier $peri]]
             if {[string match -nocase $periph_ip "xlconcat"]} {
                 set dout "dout"
                 set intr_pin [::hsi::get_pins -of_objects $peri -filter "NAME==$dout"]
                 set pins [::hsi::utils::get_sink_pins "$intr_pin"]
                 set perih [::hsi::get_cells -of_objects $pins]
                 if {[string match -nocase "[get_property IP_NAME $perih]" "axi_intc"]} {
                     set cascade_master [get_property CONFIG.C_CASCADE_MASTER [get_cells -hier $perih]]
                     set en_cascade_mode [get_property CONFIG.C_EN_CASCADE_MODE [get_cells -hier $perih]]
                }
           }
           set number [regexp -all -inline -- {[0-9]+} $sink_pn]
           return $number
       }
    }

    if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psu_cortexa53"]
	|| [string match -nocase $proctype "ps7_cortexa9"] || [string match -nocase $proctype "psx_cortexa78"]} {
	if {[string match -nocase "[get_property IP_NAME $periph]" "axi_intc"]} {
		set ip [get_property IP_NAME $periph]
		set cascade_master [get_property CONFIG.C_CASCADE_MASTER [get_cells -hier $periph]]
		set en_cascade_mode [get_property CONFIG.C_EN_CASCADE_MODE [get_cells -hier $periph]]
		set sink_pn [::hsi::utils::get_sink_pins $intr_pin]
		set peri [::hsi::get_cells -of_objects $sink_pn]
		set periph_ip [get_property IP_NAME [get_cells -hier $peri]]
		if {[string match -nocase $periph_ip "xlconcat"]} {
			set dout "dout"
			set intr_pin [::hsi::get_pins -of_objects $peri -filter "NAME==$dout"]
			set pins [::hsi::utils::get_sink_pins "$intr_pin"]
			set periph [::hsi::get_cells -of_objects $pins]
			if {[string match -nocase "[get_property IP_NAME $periph]" "axi_intc"]} {
				set cascade_master [get_property CONFIG.C_CASCADE_MASTER [get_cells -hier $periph]]
				set en_cascade_mode [get_property CONFIG.C_EN_CASCADE_MODE [get_cells -hier $periph]]
			}
			if {$en_cascade_mode == 1} {
				set number [regexp -all -inline -- {[0-9]+} $sink_pn]
				return $number
			}
		}
	}
    }

    set concat_block 0
    foreach sink_pin $sink_pins {
        set sink_periph [::hsi::get_cells -of_objects $sink_pin]
	if {[llength $sink_periph] == 0 } {
		continue
	}
        set connected_ip [get_property IP_NAME [get_cells -hier $sink_periph]]
	if {[llength $connected_ip]} {
		if {[string compare -nocase "$connected_ip" "dfx_decoupler"] == 0} {
			set dfx_intr [get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
			set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dfx_intr"]
			set sink_pins [::hsi::utils::get_sink_pins "$intr_pin"]
			foreach pin $sink_pins {
				set sink_pin $pin
				if {[string match -nocase $sink_pin "IRQ0_F2P"]} {
					set sink_pin "IRQ0_F2P"
					break
				}
				if {[string match -nocase $sink_pin "IRQ1_F2P"]} {
					set sink_pin "IRQ1_F2P"
					break
				}
			}
		}
	}
	if {[llength $connected_ip]} {
		# check for direct connection or concat block connected
		if { [string compare -nocase "$connected_ip" "xlconcat"] == 0 } {
			set pin_number [regexp -all -inline -- {[0-9]+} $sink_pin]
			set number 0
			global intrpin_width
			for { set i 0 } {$i <= $pin_number} {incr i} {
				set pin_wdth [get_property LEFT [ lindex [ get_pins -of_objects [get_cells -hier $sink_periph ] ] $i ] ]
				if { $i == $pin_number } {
					set intrpin_width [expr $pin_wdth + 1]
				} else {
					set number [expr $number + {$pin_wdth + 1}]
				}
			}
			dtg_debug "Full pin width for $sink_periph of $sink_pin:$number intrpin_width:$intrpin_width"
			set dout "dout"
			set concat_block 1
			set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
			set sink_pins [::hsi::utils::get_sink_pins "$intr_pin"]
			set sink_periph [::hsi::get_cells -of_objects $sink_pins]
			set connected_ip [get_property IP_NAME [get_cells -hier $sink_periph]]
			while {[llength $connected_ip]} {
				if {![string match -nocase "$connected_ip" "xlconcat"]} {
					break
				}
				set dout "dout"
				set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
				set sink_pins [::hsi::utils::get_sink_pins $intr_pin]
				set sink_periph [::hsi::get_cells -of_objects $sink_pins]
				set connected_ip [get_property IP_NAME [get_cells -hier $sink_periph]]
			}
			foreach pin $sink_pins {
				set sink_pin $pin
				if {[string match -nocase $sink_pin "IRQ0_F2P"]} {
					set sink_pin "IRQ0_F2P"
					break
				}
				if {[string match -nocase $sink_pin "IRQ1_F2P"]} {
					set sink_pin "IRQ1_F2P"
					break
				}
			}
		}
	}
	# check for ORgate or util_ff
	if { [string compare -nocase "$sink_pin" "Op1"] == 0 || [string compare -nocase "$sink_pin" "D"] == 0 } {
        if { [string compare -nocase "$sink_pin" "Op1"] == 0 } {
		    set dout "Res"
        } elseif { [string compare -nocase "$sink_pin" "D"] == 0 } {
            set dout "Q"
        }
		set sink_periph [::hsi::get_cells -of_objects $sink_pin]
		if {[llength $sink_periph]} {
			set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
			if {[llength $intr_pin]} {
				set sink_pins [::hsi::utils::get_sink_pins "$intr_pin"]
				foreach pin $sink_pins {
					set sink_pin $pin
				}
				set sink_periph [::hsi::get_cells -of_objects $sink_pin]
				if {[llength $sink_periph]} {
					set connected_ip [get_property IP_NAME [get_cells -hier $sink_periph]]
					if { [string compare -nocase "$connected_ip" "xlconcat"] == 0 } {
						set number [regexp -all -inline -- {[0-9]+} $sink_pin]
						set dout "dout"
						set concat_block 1
						set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
						if {[llength $intr_pin]} {
							set sink_pins [::hsi::utils::get_sink_pins "$intr_pin"]
							foreach pin $sink_pins {
								set sink_pin $pin
							}
						}
					}
				}
			}
		}
	}

        # generate irq id for IRQ1_F2P
        if { [string compare -nocase "$sink_pin" "IRQ1_F2P"] == 0 } {
            if {$found == 1} {
                set irqval $pl_ps_irq1
                set pl_ps_irq1 [expr $pl_ps_irq1 + 1]
                if {$concat_block == "0"} {
                    return [lindex $intr_list_irq1 $irqval]
                } else {
                    set ret [expr 104 + $number]
                    return $ret
                }
            }
        } elseif { [string compare -nocase "$sink_pin" "IRQ0_F2P"] == 0 } {
            # generate irq id for IRQ0_F2P
            if {$found == 1} {
                set irqval $pl_ps_irq0
                set pl_ps_irq0 [expr $pl_ps_irq0 + 1]
                if {$concat_block == "0"} {
                    return [lindex $intr_list_irq0 $irqval]
                } else {
                    set ret [expr 89 + $number]
                    return $ret
                }
             }
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq0"] == 0} {
		set ret 84
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq1"] == 0} {
		set ret 85
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq2"] == 0} {
		set ret 86
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq3"] == 0} {
		set ret 87
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq4"] == 0} {
		set ret 88
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq5"] == 0} {
		set ret 89
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq6"] == 0} {
		set ret 90
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq7"] == 0} {
		set ret 91
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq8"] == 0} {
		set ret 92
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq9"] == 0} {
		set ret 93
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq10"] == 0} {
		set ret 94
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq11"] == 0} {
		set ret 95
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq12"] == 0} {
		set ret 96
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq13"] == 0} {
		set ret 97
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq14"] == 0} {
		set ret 98
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq15"] == 0} {
		set ret 99
        } else {

            set sink_periph [::hsi::get_cells -of_objects $sink_pin]
	    if {[llength $sink_periph] == 0 } {
		break
	    }
            set connected_ip [get_property IP_NAME [get_cells -hier $sink_periph]]
            if {[string match -nocase $connected_ip "axi_intc"] } {
                set sink_pin [::hsi::get_pins -of_objects $periph -filter {TYPE==INTERRUPT && DIRECTION==O}]
            }
            if {[llength $sink_pin] == 1} {
                set port_width [::hsi::utils::get_port_width $sink_pin]
            } else {
	            foreach pin $sink_pin {
                            set port_width [::hsi::utils::get_port_width $pin]
	            }
            }
        }
    }

    set id $ret
    return $ret
}

proc check_ip_trustzone_state { drv_handle } {
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[string match -nocase $proctype "psu_cortexa53"]} {
        set index [lsearch [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $drv_handle]
	if {$index == -1 } {
		return 0
	}
        set avail_param [list_property [lindex [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $index]]
        if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
            set state [get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $index]]
            # Don't generate status okay when the peripheral is in Secure Trustzone
            if {[string match -nocase $state "Secure"]} {
                return 1
            }
        }
   } elseif {[string match -nocase $proctype "psv_cortexa72"]} {
        set index [lsearch [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $drv_handle]
	if {$index == -1 } {
		return 0
	}
        set avail_param [list_property [lindex [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $index]]
        if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
                set state [get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $index]]
                # Don't generate status okay when the peripheral is in Secure Trustzone
                if {[string match -nocase $state "Secure"]} {
                        return 1
                }
          }
   } elseif {[string match -nocase $proctype "psx_cortexa78"]} {
        set index [lsearch [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $drv_handle]
	if {$index == -1 } {
		return 0
	}
        set avail_param [list_property [lindex [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $index]]
        if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
                set state [get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $index]]
                # Don't generate status okay when the peripheral is in Secure Trustzone
                if {[string match -nocase $state "Secure"]} {
                        return 1
                }
          }
   } else {
	return 0
   }
}

proc generate_cci_node { drv_handle rt_node} {
	set avail_param [list_property [get_cells -hier $drv_handle]]
	if {[lsearch -nocase $avail_param "CONFIG.IS_CACHE_COHERENT"] >= 0} {
		set cci_enable [get_property CONFIG.IS_CACHE_COHERENT [get_cells -hier $drv_handle]]
		set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
		set nodma_coherent_list "psu_sata"
		if {[lsearch $nodma_coherent_list $iptype] >= 0} {
			#CR 974156, as per 2017.1 PCW update
			return
		}
		if {[string match -nocase $cci_enable "1"]} {
			hsi::utils::add_new_dts_param $rt_node "dma-coherent" "" boolean
		}
	}
}

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

#
# common procedures
#

# global variables
global def_string zynq_soc_dt_tree bus_clk_list pl_ps_irq1 pl_ps_irq0
set pl_ps_irq1 0
set pl_ps_irq0 0
set def_string "__def_none"
set zynq_soc_dt_tree "dummy.dtsi"
set bus_clk_list ""
global or_id
global or_cnt
set or_id 0
set or_cnt 0

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
		if {[string match -nocase $proctype "psu_cortexa53"] } {
			set intc [get_property IP_NAME $intc]
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
		}
		if {[string match -nocase $proctype "psu_cortexa53"] } {
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
			}
		} elseif {[string match -nocase $intc "psu_acpu_gic"]} {
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

proc update_system_dts_include {include_file} {
	# where should we get master_dts data
	set master_dts [get_property CONFIG.master_dts [get_os]]
	set cur_dts [current_dt_tree]
	set master_dts_obj [get_dt_trees ${master_dts}]

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
			append cur_inc_list "," $include_file
			set field [split $cur_inc_list ","]
			set cur_inc_list [lsort -decreasing $field]
			set cur_inc_list [join $cur_inc_list ","]
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

proc set_drv_def_dts {drv_handle} {
	# optional dts control by adding the following line in mdd file
	# PARAMETER name = def_dts, default = ps.dtsi, type = string;
	set default_dts [get_property CONFIG.def_dts $drv_handle]
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {[string_is_empty $default_dts]} {
		if {[is_pl_ip $drv_handle]} {
			set default_dts "pl.dtsi"
		} else {
			# PS IP, read pcw_dts property
			set default_dts [get_property CONFIG.pcw_dts [get_os]]
		}
	}
	set default_dts [set_cur_working_dts $default_dts]
	if {[is_pl_ip $drv_handle] && $dt_overlay} {
		set master_dts_obj [get_dt_trees ${default_dts}]
		set_property DTS_VERSION "/dts-v1/;\n/plugin/" $master_dts_obj
		set root_node [add_or_get_dt_node -n / -d ${default_dts}]
		set fpga_node [add_or_get_dt_node -n "fragment@0" -d ${default_dts} -p ${root_node}]
		set pl_file $default_dts
		set targets "fpga_full"
		hsi::utils::add_new_dts_param $fpga_node target "$targets" reference
		set child_name "__overlay__"
		set child_node [add_or_get_dt_node -l "overlay0" -n $child_name -p $fpga_node]
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			hsi::utils::add_new_dts_param "${child_node}" "#address-cells" 2 int
			hsi::utils::add_new_dts_param "${child_node}" "#size-cells" 2 int
		} else {
			hsi::utils::add_new_dts_param "${child_node}" "#address-cells" 1 int
			hsi::utils::add_new_dts_param "${child_node}" "#size-cells" 1 int
		}
		hsi::utils::add_new_dts_param "${child_node}" "firmware-name" "design_1_wrapper.bit.bin" string

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
			dtg_warning "label '$node_label' found in existing tree, rename to dtg_$node_label"
			set node_label "dtg_${node_label}"
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
					error "$pattern :: $node_label : $node_name @ $node_unit_addr, is differ to the node object $node"
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
			if {[regexp $pattern $node match]} {
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
	if {![regexp "ps._*" "$ip_name" match]} {
		return 1
	}
	return 0
}

proc is_ps_ip {ip_inst} {
	# check if the IP is a soft IP (not PS7)
	# return 1 if it is soft ip
	# return 0 if not
	set ip_obj [get_cells -hier $ip_inst]
	if {[llength [get_cells -hier $ip_inst]] < 1} {
		return 0
	}
	set ip_name [get_property IP_NAME $ip_obj]
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

	regsub -all {CONFIG.} $prop {} prop
	set conf_prop [lindex [get_comp_params ${prop} $drv_handle] 0 ]
	if {[string_is_empty ${conf_prop}] == 0} {
		set type [lindex [get_property CONFIG.TYPE $conf_prop] 0]
	} else {
		error "Unable to add the $prop property for $drv_handle due to missing valid type"
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
	set kernel_ver [get_property CONFIG.kernel_version [get_os]]
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

	global zynq_soc_dt_tree
	set default_dts [create_dt_tree -dts_file $zynq_soc_dt_tree]
	set fp [open $kernel_dtsi r]
	set file_data [read $fp]
	set data [split $file_data "\n"]

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
	if {[string match -nocase $proctype "psu_cortexa53"]} {
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
	set valid_ip_list "axi_ethernet axi_ethernet_buffer xadc_wiz"
	set valid_proc_list "ps7_cortexa9 psu_cortexa53"
	if {[lsearch  -nocase $valid_proc_list $proctype] >= 0} {
		set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
		if {[lsearch $valid_ip_list $iptype] >= 0} {
			# FIXME: this is hardcoded - maybe dynamic detection
			# Keep the below logic, until we have clock frame work for ZynqMP
			if {[string match -nocase $iptype "can"]} {
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
					if {[string match -nocase $iptype "can"] || [string match -nocase $iptype "vcu"]} {
						set clocks [lindex $clk_refs 0]
						append clocks ">, <&[lindex $clk_refs 1]"
						set_drv_prop $drv_handle "clocks" "$clocks" reference
					} else {
						set_drv_prop_if_empty $drv_handle "clocks" $clk_refs reference
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

proc overwrite_clknames {clknames drv_handle} {
	set_drv_prop $drv_handle "clock-names" $clknames stringlist
}

proc update_zynq_clk_node args {
	set drv_handle [lindex $args 0]
	set clk_pins [lindex $args 1]
	set clkname_len [lindex $args 2]
	set is_clk_wiz 0
	set clocks ""
	set bus_clk_list ""
	set axi 0

	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $ip $clk]]]
		set clk_list1 "clk_out*"
		set fclk_clk ""
		set clkout ""
		foreach pin $pins {
			if {[regexp $clk_list1 $pin match]} {
				set clkout $pin
				set is_clk_wiz 1
			}
		}
		if {[llength $clkout]} {
			set number [regexp -all -inline -- {[0-9]+} $clkout]
			set periph [::hsi::get_cells -of_objects $clkout]
			set clkk_pins [::hsi::get_pins -of_objects $periph]
			set clk_wiz [get_pins -of_objects [get_cells $periph] -filter TYPE==clk]
			set axi_clk "s_axi_aclk"
			foreach clk1 $clk_wiz {
				if {[regexp $axi_clk $clk1 match]} {
					set axi 1
				}
			}

			if {[string match -nocase $axi "0"]} {
				dtg_warning "no s_axi_aclk for clockwizard"
				set pins [get_pins -of_objects [get_cells $periph] -filter TYPE==clk]
				set clk_list "FCLK_CLK*"
				set clk_fclk ""
				set num ""
				foreach clk_wiz_pin $pins {
					set clk_wiz_pins [get_pins -of_objects [get_nets -of_objects $clk_wiz_pin]]
					foreach pin $clk_wiz_pins {
						if {[regexp $clk_list $pin match]} {
							set clk_fclk $pin
						}
					}
				}
				if {[llength $clk_fclk]} {
					set num [regexp -all -inline -- {[0-9]+} $clk_fclk]
				}
				set dts_file "pl.dtsi"
				set bus_node [add_or_get_bus_node $drv_handle $dts_file]
				set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
				set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
				if {![string equal $clk_freq ""]} {
					if {[lsearch $bus_clk_list $clk_freq] < 0} {
						set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
					set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
					hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
					hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
					if {[string match -nocase $iptype "canfd"] || [string match -nocase $iptype "vcu"] || [string match -nocase $iptype "can"]} {
						set clocks [lindex $clk_refs 0]
						append clocks ">, <&[lindex $clk_refs 1]"
						set_drv_prop $drv_handle "clocks" "$clocks" reference
					} elseif {[string match -nocase $iptype "axi_dma"] } {
						switch $clkname_len {
							"1" {
								set clocks [lindex $clk_refs 0]
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"2" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"3" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"4" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]>, <&[lindex $clk_refs 3]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
						}
					} elseif {[string match -nocase $iptype "axi_vdma"] } {
						switch $clkname_len {
							"1" {
								set clocks [lindex $clk_refs 0]
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"2" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"3" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"4" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]>, <&[lindex $clk_refs 3]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"5" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]>, <&[lindex $clk_refs 3]>, <&[lindex $clk_refs 4]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
                                                }
					} else {
						set_drv_prop_if_empty $drv_handle "clocks" $clk_refs reference
					}
					append clocknames " " "$clk_pins"
					set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
				}
			}

			if {[string match -nocase $periph "clk_wiz_1"] && [string match -nocase $axi "1"]} {
				switch $number {
					"0" {
						set peri "clk_wiz_1 0"
						set clocks [lappend clocks $peri]
					}
					"1" {
						set peri "clk_wiz_1 1"
						set clocks [lappend clocks $peri]
					}
					"2" {
						set peri "clk_wiz_1 2"
						set clocks [lappend clocks $peri]
					}
					"3" {
						set peri "clk_wiz_1 3"
						set clocks [lappend clocks $peri]
					}
					"4" {
						set peri "clk_wiz_1 4"
						set clocks [lappend clocks $peri]
					}
					"5" {
						set peri "clk_wiz_1 5"
						set clocks [lappend clocks $peri]
					}
					"6" {
						set peri "clk_wiz_1 6"
						set clocks [lappend clocks $peri]
					}
					"7" {
						set peri "clk_wiz_1 7"
						set clocks [lappend clocks $peri]
					}
				}
			}
			if {[string match -nocase $periph "clk_wiz_0"] && [string match -nocase $axi "1"]} {
				switch $number {
					"0" {
						set peri "clk_wiz_0 0"
						set clocks [lappend clocks $peri]
					}
					"1" {
						set peri "clk_wiz_0 1"
						set clocks [lappend clocks $peri]
					}
					"2" {
						set peri "clk_wiz_0 2"
						set clocks [lappend clocks $peri]
					}
					"3" {
						set peri "clk_wiz_0 3"
						set clocks [lappend clocks $peri]
					}
					"4" {
						set peri "clk_wiz_0 4"
						set clocks [lappend clocks $peri]
					}
					"5" {
						set peri "clk_wiz_0 5"
						set clocks [lappend clocks $peri]
					}
					"6" {
						set peri "clk_wiz_0 6"
						set clocks [lappend clocks $peri]
					}
					"7" {
						set peri "clk_wiz_0 7"
						set clocks [lappend clocks $peri]
					}
				}
			}

	}

		set clk_fclk_list "FCLK_CLK*"
		foreach pin $pins {
			if {[regexp $clk_fclk_list $pin match]} {
				set fclk_clk $pin
			}
		}
		switch $fclk_clk {
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
			default {
					dtg_warning "not supported fclk_clk:$fclk_clk"
			}
		}
		if {[string match -nocase $is_clk_wiz "0"] || [string match -nocase $axi "1"]} {
			append clocknames " " "$clk_pins"
			set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
		}
	}
		if {[string match -nocase $is_clk_wiz "0"] || [string match -nocase $axi "1"]} {
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
				"3" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
				"4" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]>, <&[lindex $clocks 3]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
				"5" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]>, <&[lindex $clocks 3]>, <&[lindex $clocks 4]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
			}
		}
}

proc update_clk_node args {
	set drv_handle [lindex $args 0]
	set clk_pins   [lindex $args 1]
	set clkname_len [lindex $args 2]
	set clocks ""
	set bus_clk_list ""
	set dma_clk_count ""
	set axi 0
	set is_clk_wiz 0
	set is_pl_clk 0
	set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
	if {[string match -nocase $iptype "vcu"] || [string match -nocase $iptype "can"] || [string match -nocase $iptype "canfd"] || [string match -nocase $iptype "axi_cdma"]} {
		set vcu_clk_count [hsi::utils::get_os_parameter_value "vcu_clk_count"]
		if { [llength $vcu_clk_count] == 0 } {
			set vcu_clk_count 1
		}
	}
	if {[string match -nocase $iptype "axi_dma"]} {
		set dma_pl_clk_count [hsi::utils::get_os_parameter_value "dma_pl_clk_count"]
		if { [llength $dma_pl_clk_count] == 0 } {
			set dma_pl_clk_count 0
		}
	}
	if {[string match -nocase $iptype "axi_dma"] || [string match -nocase $iptype "axi_vdma"]} {
		set dma_clk_count [hsi::utils::get_os_parameter_value "dma_clk_count"]
		if { [llength $dma_clk_count] == 0 } {
			set dma_clk_count 1
		}
	}
	foreach clk $clk_pins {
		set ip [get_cells -hier $drv_handle]
		set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $ip $clk]]]
		set clk_list1 "clk_out*"
		set pl_clk ""
		set clkout ""
		foreach pin $pins {
			if {[regexp $clk_list1 $pin match]} {
				set clkout $pin
				set is_clk_wiz 1
			}
		}
		if {[llength $clkout]} {
			set number [regexp -all -inline -- {[0-9]+} $clkout]
			set periph [::hsi::get_cells -of_objects $clkout]
			set clk_wiz [get_pins -of_objects [get_cells $periph] -filter TYPE==clk]
			set axi_clk "s_axi_aclk"
			foreach clk1 $clk_wiz {
				if {[regexp $axi_clk $clk1 match]} {
					set axi 1
				}
			}

			if {[string match -nocase $axi "0"]} {
				dtg_warning "no s_axi_aclk for clockwizard"
				set pins [get_pins -of_objects [get_cells $periph] -filter TYPE==clk]
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

				set frq [get_property CONFIG.PRIM_IN_FREQ [get_cells -hier $drv_handle]]
				set dts_file "pl.dtsi"
				set bus_node [add_or_get_bus_node $drv_handle $dts_file]
				set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
				set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
				if {![string equal $clk_freq ""]} {
					if {[lsearch $bus_clk_list $clk_freq] < 0} {
						set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
						-d ${dts_file} -p ${bus_node}]
					set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
					hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
					hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
					hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
					if {$is_pl_clk == 1} {
						if {[string match -nocase $iptype "can"]} {
							set clk2 [lindex $clk_refs 0]
							append clocks " $clk2"
						} elseif {[string match -nocase $iptype "axi_dma"]} {
							switch $dma_clk_count {
                                                        "1" {
                                                                set clocks [lindex $clk_refs 0]
                                                                set_drv_prop $drv_handle "clocks" "$clocks" reference
                                                        }
                                                        "2" {
                                                                set clocks [lindex $clk_refs 0]
                                                                append clocks ">, <&[lindex $clk_refs 1]"
                                                                set_drv_prop $drv_handle "clocks" "$clocks" reference
                                                        }
                                                        "3" {
                                                                set clocks [lindex $clk_refs 0]
                                                                append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]"
                                                                set_drv_prop $drv_handle "clocks" "$clocks" reference
                                                        }
                                                        "4" {
                                                                set clocks [lindex $clk_refs 0]
                                                                append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]>, <&[lindex $clk_refs 3]"
                                                                set_drv_prop $drv_handle "clocks" "$clocks" reference
                                                        }
                                                }
                                                incr dma_clk_count
					    }
					} else {
					if {[string match -nocase $iptype "canfd"] || [string match -nocase $iptype "vcu"] || [string match -nocase $iptype "can"] || [string match -nocase $iptype "axi_cdma"]} {
						switch $vcu_clk_count {
							"1" {
								set clocks [lindex $clk_refs 0]
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"2" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
						}
						incr vcu_clk_count
					} elseif {[string match -nocase $iptype "axi_dma"] } {
						switch $dma_clk_count {
							"1" {
								set clocks [lindex $clk_refs 0]
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"2" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"3" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"4" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]>, <&[lindex $clk_refs 3]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
						}
						incr dma_clk_count
					} elseif {[string match -nocase $iptype "axi_vdma"] } {
						switch $dma_clk_count {
							"1" {
								set clocks [lindex $clk_refs 0]
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"2" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"3" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"4" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]>, <&[lindex $clk_refs 3]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
							"5" {
								set clocks [lindex $clk_refs 0]
								append clocks ">, <&[lindex $clk_refs 1]>, <&[lindex $clk_refs 2]>, <&[lindex $clk_refs 3]>, <&[lindex $clk_refs 4]"
								set_drv_prop $drv_handle "clocks" "$clocks" reference
							}
						}
						incr dma_clk_count
					} else {
						set_drv_prop_if_empty $drv_handle "clocks" $clk_refs reference
					}
				}
					append clocknames " " "$clk_pins"
					set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
				}

			}

			if {[string match -nocase $periph "clk_wiz_1"] && ![string match -nocase $axi "0"]} {
				switch $number {
					"0" {
						set peri "clk_wiz_1 0"
						set clocks [lappend clocks $peri]
					}
					"1" {
						set peri "clk_wiz_1 1"
						set clocks [lappend clocks $peri]
					}
					"2" {
						set peri "clk_wiz_1 2"
						set clocks [lappend clocks $peri]
					}
					"3" {
						set peri "clk_wiz_1 3"
						set clocks [lappend clocks $peri]
					}
					"4" {
						set peri "clk_wiz_1 4"
						set clocks [lappend clocks $peri]
					}
					"5" {
						set peri "clk_wiz_1 5"
						set clocks [lappend clocks $peri]
					}
					"6" {
						set peri "clk_wiz_1 6"
						set clocks [lappend clocks $peri]
					}
					"7" {
						set peri "clk_wiz_1 7"
						set clocks [lappend clocks $peri]
					}
				}
			}
			if {[string match -nocase $periph "clk_wiz_0"] && ![string match -nocase $axi "0"]} {
				switch $number {
					"0" {
						set peri "clk_wiz_0 0"
						set clocks [lappend clocks $peri]
					}
					"1" {
						set peri "clk_wiz_0 1"
						set clocks [lappend clocks $peri]
					}
					"2" {
						set peri "clk_wiz_0 2"
						set clocks [lappend clocks $peri]
					}
					"3" {
						set peri "clk_wiz_0 3"
						set clocks [lappend clocks $peri]
					}
					"4" {
						set peri "clk_wiz_0 4"
						set clocks [lappend clocks $peri]
					}
					"5" {
						set peri "clk_wiz_0 5"
						set clocks [lappend clocks $peri]
					}
					"6" {
						set peri "clk_wiz_0 6"
						set clocks [lappend clocks $peri]
					}
					"7" {
						set peri "clk_wiz_0 7"
						set clocks [lappend clocks $peri]
					}
				}
			}
		}

		set clklist "pl_clk*"
		foreach pin $pins {
			if {[regexp $clklist $pin match]} {
				set pl_clk $pin
				set is_pl_clk 1
				if {[string match -nocase $iptype "axi_dma"]} {
					incr dma_pl_clk_count
				}
			}
		}
		switch $pl_clk {
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
			default {
					dtg_warning "not supported pl_clk:$pl_clk"
			}
		}
		if {[string match -nocase $is_clk_wiz "0"] || [string match -nocase $axi "1"]} {
			append clocknames " " "$clk_pins"
			set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
		}
		if {[string match -nocase $is_clk_wiz "0"] && [string match -nocase $is_pl_clk "0"]} {
			set dts_file "pl.dtsi"
			incr vcu_clk_count
			set bus_node [add_or_get_bus_node $drv_handle $dts_file]
			set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
			set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
			if {![string equal $clk_freq ""]} {
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
			set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
			set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
				-d ${dts_file} -p ${bus_node}]
			set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
			hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
			hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
			hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
			if {[string match -nocase $iptype "vcu"]} {
				set clocks [lindex $clk_refs 0]
				if {$vcu_clk_count == 2} {
					set_drv_prop $drv_handle "clocks" "$clocks" reference
				} elseif {$vcu_clk_count == 3} {
				append clocks ">, <&[lindex $clk_refs 1]"
				set_drv_prop $drv_handle "clocks" "$clocks" reference
				}
			} else {
				set_drv_prop_if_empty $drv_handle "clocks" $clk_refs reference
			}
			append clocknames " " "$clk_pins"
			set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
			}
		}
	}

		if {[string match -nocase $is_clk_wiz "0"] || [string match -nocase $axi "1"]} {
			if {[string match -nocase $is_pl_clk "1"]} {
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
				"3" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
				"4" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]>, <&[lindex $clocks 3]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
				"5" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]>, <&[lindex $clocks 3]>, <&[lindex $clocks 4]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
			}
		}
		}
		if {[string match -nocase $is_pl_clk "1"]} {
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
				"3" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
				"4" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]>, <&[lindex $clocks 3]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
				"5" {
					set clk_refs [lindex $clocks 0]
					append clk_refs ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]>, <&[lindex $clocks 3]>, <&[lindex $clocks 4]"
					set_drv_prop $drv_handle "clocks" "$clk_refs" reference
				}
			}
		}
		if {[string match -nocase $iptype "axi_dma"]} {
			if {$clkname_len == 1} {
				return
			}
			set count [expr ${clkname_len} - ${dma_clk_count}]
			if {$dma_pl_clk_count} {
				set count [expr ${clkname_len} - ${dma_pl_clk_count}]
			}
			switch $count {
				"0" {
					if {$dma_pl_clk_count} {
						return
					}
					set clk_pins "m_axi_s2mm_aclk"
					foreach clk $clk_pins {
						set dts_file "pl.dtsi"
						set bus_node [add_or_get_bus_node $drv_handle $dts_file]
						set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
						set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
						if {![string equal $clk_freq ""]} {
							if {[lsearch $bus_clk_list $clk_freq] < 0} {
								set bus_clk_list [lappend bus_clk_list $clk_freq]
						}
						set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
						set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
							-d ${dts_file} -p ${bus_node}]
						set clkrefs [lappend clkrefs misc_clk_${bus_clk_cnt}]
						hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
						hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
						hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
						set clk [lindex $clocks 0]
						append clk " [lindex $clocks 1] [lindex $clocks 2]>, <&[lindex $clkrefs 0]"
						set_drv_prop $drv_handle "clocks" "$clk" reference
						}
					}

				}
				"1" {
					if {$clkname_len == 2} {
					set clk_pins "m_axi_sg_aclk"
					foreach clk $clk_pins {
						set dts_file "pl.dtsi"
						set bus_node [add_or_get_bus_node $drv_handle $dts_file]
						set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
						set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
						if {![string equal $clk_freq ""]} {
							if {[lsearch $bus_clk_list $clk_freq] < 0} {
								set bus_clk_list [lappend bus_clk_list $clk_freq]
						}
						set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
						set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
							-d ${dts_file} -p ${bus_node}]
						set clkrefs [lappend clkrefs misc_clk_${bus_clk_cnt}]
						hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
						hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
						hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
						set clk [lindex $clocks 0]
						append clk ">, <&[lindex $clkrefs 0]"
						set_drv_prop $drv_handle "clocks" "$clk" reference
						}
					}
					} else {
						set clk_pins "m_axi_s2mm_aclk"
						foreach clk $clk_pins {
							set dts_file "pl.dtsi"
							set bus_node [add_or_get_bus_node $drv_handle $dts_file]
							set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
							set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
							if {![string equal $clk_freq ""]} {
								if {[lsearch $bus_clk_list $clk_freq] < 0} {
									set bus_clk_list [lappend bus_clk_list $clk_freq]
							}
							set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
							set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
								-d ${dts_file} -p ${bus_node}]
							set clkrefs [lappend clkrefs misc_clk_${bus_clk_cnt}]
							hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
							hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
							hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
							set clk [lindex $clocks 0]
							append clk ">, <&[lindex $clocks 1]>, <&[lindex $clocks 2]>, <&[lindex $clkrefs 0]"
							set_drv_prop $drv_handle "clocks" "$clk" reference
							}
						}
					}
                                }
				"3" {
					set clk_pins "s_axi_lite_aclk m_axi_sg_aclk m_axi_mm2s_aclk m_axi_s2mm_aclk"
						foreach clk $clk_pins {
						set dts_file "pl.dtsi"
						set bus_node [add_or_get_bus_node $drv_handle $dts_file]
						set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "$clk"]
						set iptype [get_property IP_NAME [get_cells -hier $drv_handle]]
						if {![string equal $clk_freq ""]} {
							if {[lsearch $bus_clk_list $clk_freq] < 0} {
								set bus_clk_list [lappend bus_clk_list $clk_freq]
						}
						set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
						set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
							-d ${dts_file} -p ${bus_node}]
						set clkrefs [lappend clkrefs misc_clk_${bus_clk_cnt}]
						hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
						hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
						hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
                                                set clk [lindex $clkrefs 0]
						append clk ">, <&[lindex $clkrefs 0]>, <&[lindex $clkrefs 1]>, <&[lindex $clkrefs 2]"
						set_drv_prop $drv_handle "clocks" "$clk" reference
						}
					}
				}
				default {
				}
			}
		}
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
	set valid_intc_list "ps7_scugic psu_acpu_gic"
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

	foreach pin ${intr_port_name} {
		set mb_net [get_nets -of_objects $pin]
		set connected_pin_names [get_pins -of_objects $mb_net]
		foreach cpin ${connected_pin_names} {
			if {[string equal -nocase $pin $cpin]} {
				continue
			}
			set intc [get_cells -of_objects $cpin]
			if {![string_is_empty $intc]} {
				break
			}
		}
	}
	if {[string_is_empty $intc]} {
		error "no interrupt controller found"
	}

	set_drv_prop $cpu_handle interrupt-handle $intc reference
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

	if {[string_is_empty $intr_port_name]} {
		if {[string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"]} {
			set val [get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
			set intr_port_name [get_pins -of_objects $slave -filter {TYPE==INTERRUPT&&DIRECTION==O}]
		} else {
			set intr_port_name [get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
		}
	}

	# TODO: consolidation with get_intr_id proc
	foreach pin ${intr_port_name} {
		set connected_intc [get_intr_cntrl_name $drv_handle $pin]
		if {[llength $connected_intc] == 0 || [string match $connected_intc "{}"] } {
			if {![string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"]} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected to any interrupt controller\n\r"
			}
			continue
		}
		set connected_intc_name [get_property IP_NAME $connected_intc]
		set valid_gpio_list "ps7_gpio axi_gpio"
		set valid_cascade_proc "ps7_cortexa9 psu_cortexa53"
		# check whether intc is gpio or other
		if {[lsearch  -nocase $valid_gpio_list $connected_intc_name] >= 0} {
			generate_gpio_intr_info $connected_intc $drv_handle $pin
		} else {
			set intc [::hsi::utils::get_interrupt_parent $drv_handle $pin]
			if { [string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0 } {
				set pins [::hsi::get_pins -of_objects [::hsi::get_cells -hier -filter "NAME==$drv_handle"] -filter "NAME==irq"]
				set intc [::hsi::utils::get_interrupt_parent $drv_handle $pins]
			} else {
				set intc [::hsi::utils::get_interrupt_parent $drv_handle $pin]
			}
			if {[string_is_empty $intc] == 1} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected\n\r"
				continue
			}
			set ip_name $intc
			if {[string match -nocase $proctype "psu_cortexa53"] } {
				set intc [get_property IP_NAME $intc]
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
			}

			if {[string match -nocase $proctype "psu_cortexa53"] } {
				if { [string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"] } {
					set intr_id [get_psu_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_psu_interrupt_id $drv_handle $pin]
				}
			} else {
				if { [string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"] && [string match -nocase [get_property IP_NAME [get_cells -hier [get_sw_processor]]] "ps7_cortexa9"]} {
					set intr_id [::hsi::utils::get_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [::hsi::utils::get_interrupt_id $drv_handle $pin]
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
			set valid_intc_list "ps7_scugic psu_acpu_gic"

			if { [string match -nocase $proctype "ps7_cortexa9"] }  {
				if {[string match "[get_property IP_NAME $intc]" "ps7_scugic"] } {
					if {$intr_id > 32} {
						set intr_id [expr $intr_id - 32]
					}
					set cur_intr_info "0 $intr_id $intr_type"
				} elseif {[string match "[get_property IP_NAME $intc]" "axi_intc"] } {
					set cur_intr_info "$intr_id $intr_type"
				}
			} elseif {[string match -nocase $intc "psu_acpu_gic"]} {

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
			append intr_names " " "$pin"
	}
	if {[string_is_empty $intr_info]} {
		return -1
	}
	set_drv_prop $drv_handle interrupts $intr_info intlist
	if {[string_is_empty $intc]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]

	if { [string match -nocase $intc "psu_acpu_gic"] } {
		set intc "gic"
	}
	set_drv_prop $drv_handle interrupt-parent $intc reference
	set_drv_prop_if_empty $drv_handle "interrupt-names" $intr_names stringlist
}

proc gen_reg_property {drv_handle {skip_ps_check ""}} {
	proc_called_by

	if {[string_is_empty $skip_ps_check]} {
		if {[is_ps_ip $drv_handle]} {
			return 0
		}
	}

	set reg ""
	set ip_skip_list "ddr4_*"
	set slave [get_cells -hier ${drv_handle}]
	set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
	foreach mem_handle ${ip_mem_handles} {
		if {![regexp $ip_skip_list $mem_handle match]} {
			set base [string tolower [get_property BASE_VALUE $mem_handle]]
			set high [string tolower [get_property HIGH_VALUE $mem_handle]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
			if {[string_is_empty $reg]} {
				if {[string match -nocase $proctype "psu_cortexa53"]} {
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
				# ensure no duplication
				if {![regexp ".*${reg}.*" "$base $size" matched]} {
					if {[string match -nocase $proctype "psu_cortexa53"]} {
						set reg "$reg 0x0 $base 0x0 $size"
					} else {
						set reg "$reg $base $size"
					}
				}
			}
		}
	}
	set_drv_prop_if_empty $drv_handle reg $reg intlist
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
	set status_enable_flow 0
	set ip [get_cells -hier $drv_handle]
	# TODO: check if the base address is correct
	set unit_addr [get_baseaddr ${ip} no_prefix]
	if { [string equal $unit_addr "-1"] } {
		return 0
	}
	set label $drv_handle
	set dev_type [get_property CONFIG.dev_type $drv_handle]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type [get_property IP_NAME [get_cell -hier $ip]]
	}
	# TODO: more ignore ip list?
	set ip_type [get_property IP_NAME $ip]
	set ignore_list "lmb_bram_if_cntlr"
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
	set valid_proc_list "ps7_cortexa9 psu_cortexa53"
	if {[lsearch  -nocase $valid_proc_list $proc_name] >= 0} {
		if {[is_pl_ip $ip_drv]} {
			# create the parent_node for pl.dtsi
			set default_dts [set_drv_def_dts $ip_drv]
			set root_node [add_or_get_dt_node -n / -d ${default_dts}]
			return "amba_pl"
		}
		if {[string match -nocase $ip_drv "psu_acpu_gic"]} {
			return "amba_apu"
		}
		return "amba"
	}

	return "amba_pl"
}

proc add_or_get_bus_node {ip_drv dts_file} {
	set bus_name [detect_bus_name $ip_drv]
	dtg_debug "bus_name: $bus_name"
	dtg_debug "bus_label: $bus_name"

	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {[is_pl_ip $ip_drv] && $dt_overlay} {
		set root_node [add_or_get_dt_node -n / -d ${dts_file}]
		set fpga_node [add_or_get_dt_node -n "fragment@1" -d [get_dt_tree ${dts_file}] -p ${root_node}]
		set targets "amba"
		hsi::utils::add_new_dts_param $fpga_node target "$targets" reference
		set child_name "__overlay__"
		set bus_node [add_or_get_dt_node -l "overlay1" -n $child_name -p $fpga_node]
	} else {
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			set bus_node [add_or_get_dt_node -n ${bus_name} -l ${bus_name} -u 0 -d [get_dt_tree ${dts_file}] -p "/" -disable_auto_ref -auto_ref_parent]
		} else {
			set bus_node [add_or_get_dt_node -n ${bus_name} -l ${bus_name} -d [get_dt_tree ${dts_file}] -p "/" -disable_auto_ref -auto_ref_parent]
		}

		if {![string match "&*" $bus_node]} {
			set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
			if {[string match -nocase $proctype "psu_cortexa53"]} {
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
			update_system_dts_include [file tail ${dtsi_fname}]
			update_system_dts_include [file tail "zynqmp-clk-ccf.dtsi"]
			# no root_node required as zynqmp.dtsi
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
	set add_reg 0
	set cpu0_only ""
	if {![string equal -nocase ${processor_type} "microblaze"]} {
		set add_reg 1
		set cpu0_only [get_property CONFIG.cpu0_only $processor]
		foreach prop "${cpu0_only} cpu0_only" {
			set drv_dt_prop_list [list_remove_element $drv_dt_prop_list "CONFIG.${prop}"]
		}
	}

	# generate mb ccf node
	generate_mb_ccf_node $processor

	set bus_node [add_or_get_bus_node $drv_handle $default_dts]
	set cpu_no 0
	foreach cpu ${processor_list} {
		set bus_label [get_property NODE_LABEL $bus_node]
		set cpu_node [add_or_get_dt_node -n ${dev_type} -l ${cpu} -u ${cpu_no} -d ${default_dts} -p ${cpu_root_node}]
		hsi::utils::add_new_dts_param "${cpu_node}" "bus-handle" $bus_label reference
		foreach drv_prop_name $drv_dt_prop_list {
			add_driver_prop $processor $cpu_node ${drv_prop_name}
		}
		if {[string equal -nocase ${cpu} ${drv_handle}]} {
			set rt_node $cpu_node
			foreach cpu_prop ${cpu0_only} {
				add_driver_prop $processor $cpu_node CONFIG.${cpu_prop}
			}
		}
		if {$add_reg == 1} {
			hsi::utils::add_new_dts_param "${cpu_node}" "reg" $cpu_no int ""
		}
		incr cpu_no
	}
	hsi::utils::add_new_dts_param "${cpu_root_node}" "#cpus" $cpu_no int ""
	return $rt_node
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
	set ddr_list "psu_ddr ps7_ddr axi_emc mig_7series"
	if {[lsearch -nocase $ddr_list $ddr_ip] >= 0} {
		set parent_node [add_or_get_dt_node -n / -d ${master_dts}]
		set unit_addr [get_baseaddr $drv_handle]
		set memory_node [add_or_get_dt_node -n memory -p $parent_node]
		set reg_value [get_property CONFIG.reg $drv_handle]
		hsi::utils::add_new_dts_param "${memory_node}" "reg" $reg_value inthexlist
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
	set valid_cascade_proc "ps7_cortexa9 psu_cortexa53"
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
	if { [llength $intr_sink_pins] == 0 } {
		return $intr_cntrl
	}
	set valid_cascade_proc "ps7_cortexa9 psu_cortexa53"
	foreach intr_sink ${intr_sink_pins} {
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
				set intr_id [expr $gpio_pin_count + 32]
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
	} elseif { [string match -nocase $IP_NAME "psu_acpu_gic"] } {
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

    set intc_periph [::hsi::utils::get_interrupt_parent $ip_name $port_name]
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
    set concat_block 0
    foreach sink_pin $sink_pins {
        set sink_periph [::hsi::get_cells -of_objects $sink_pin]
	if {[llength $sink_periph] == 0 } {
		continue
	}
        set connected_ip [get_property IP_NAME [get_cells $sink_periph]]
        # check for direct connection or concat block connected
        if { [string compare -nocase "$connected_ip" "xlconcat"] == 0 } {
            set number [regexp -all -inline -- {[0-9]+} $sink_pin]
            set dout "dout"
            set concat_block 1
            set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
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
        # check for ORgate
        if { [string compare -nocase "$sink_pin" "Op1"] == 0 } {
            set dout "Res"
            set sink_periph [::hsi::get_cells -of_objects $sink_pin]
            set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
            set sink_pins [::hsi::utils::get_sink_pins "$intr_pin"]
            foreach pin $sink_pins {
                set sink_pin $pin
            }
            set sink_periph [::hsi::get_cells -of_objects $sink_pin]
            set connected_ip [get_property IP_NAME [get_cells $sink_periph]]
            if { [string compare -nocase "$connected_ip" "xlconcat"] == 0 } {
                set number [regexp -all -inline -- {[0-9]+} $sink_pin]
                set dout "dout"
                set concat_block 1
                set intr_pin [::hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
                set sink_pins [::hsi::utils::get_sink_pins "$intr_pin"]
                foreach pin $sink_pins {
                    set sink_pin $pin
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
        } else {

            set sink_periph [::hsi::get_cells -of_objects $sink_pin]
	    if {[llength $sink_periph] == 0 } {
		break
	    }
            set connected_ip [get_property IP_NAME [get_cells $sink_periph]]
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
            set id $ret
            return $ret
        }
    }

    return $ret
}

proc check_ip_trustzone_state { drv_handle } {
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[string match -nocase $proctype "psu_cortexa53"]} {
        set index [lsearch [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] $drv_handle]
        set avail_param [list_property [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] $index]]
        if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
            set state [get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexa53_0]] $index]]
            # Don't generate status okay when the peripheral is in Secure Trustzone
            if {[string match -nocase $state "Secure"]} {
                return 1
            }
        }
    }
    return 0
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

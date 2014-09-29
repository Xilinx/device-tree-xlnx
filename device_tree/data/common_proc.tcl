#
# common procedures
#

# global variables
global def_string zynq_soc_dt_tree zynq_7000_fname
set def_string "__def_none"
set zynq_soc_dt_tree "dummy.dtsi"
set zynq_7000_fname "zynq-7000.dtsi"

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
			set_property ${conf_prop} $value $drv_handle
			set prop [get_comp_params ${conf_prop} $drv_handle]
			set_property CONFIG.TYPE $type $prop
		}
	}
}

proc set_drv_conf_prop args {
	set drv_handle [lindex $args 0]
	set pram [lindex $args 1]
	set conf_prop [lindex $args 2]
	set ip [get_cells $drv_handle]
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
			set_property ${conf_prop} $value $drv_handle
			set prop [get_comp_params ${conf_prop} $drv_handle]
			set_property CONFIG.TYPE $type $prop
		}
	}
}

proc add_cross_property args {
	set src_handle [lindex $args 0]
	set src_prams [lindex $args 1]
	set dest_handle [lindex $args 2]
	set dest_prop [lindex $args 3]
	set ip [get_cells $src_handle]
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
				hsm::utils::add_new_property $dest_handle $dest_prop $type $value
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
	set ip [get_cells $src_handle]
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
	set ip [get_cells $drv_handle]
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
	if {![regexp "ps7_*" "$ip_type" match]} {
		return 1
	}
	return -1
}

proc get_intr_id {drv_handle intr_port_name} {
	set slave [get_cells $drv_handle]
	set intr_info ""
	foreach pin ${intr_port_name} {
		set intc [::hsm::utils::get_interrupt_parent $drv_handle $pin]
		set intr_id [::hsm::utils::get_interrupt_id $drv_handle $pin]
		if {[string match -nocase $intr_id "-1"]} {continue}
		if {[string_is_empty $intc] == 1} {continue}

		set intr_type [get_intr_type $intc $slave $pin]
		if {[string match -nocase $intr_type "-1"]} {
			continue
		}

		set cur_intr_info ""
		if {[string match "[get_property IP_NAME $intc]" "ps7_scugic"]} {
			if {$intr_id > 32} {
				set intr_id [expr $intr_id - 32]
			}
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
		lappend pattern "^${node_label}:${node_name}@${node_unit_addr}"
		lappend pattern "^${node_name}@${node_unit_addr}"
	}

	if {![string equal -nocase ${node_label} ${def_string}]} {
		lappend pattern "^&${node_label}"
		lappend pattern "^${node_label}"
	}
	if {![string equal -nocase ${node_name} ${def_string}] && \
		![string equal -nocase ${node_unit_addr} ${def_string}]} {
		lappend pattern "^${node_name}@${node_unit_addr}"
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
	set ip_mem_handle [lindex [hsi::utils::get_ip_mem_ranges [get_cells $slave_ip]] 0]
	set addr [string tolower [get_property BASE_VALUE $ip_mem_handle]]
	if {![string_is_empty $no_prefix]} {
		regsub -all {^0x} $addr {} addr
	}
	return $addr
}

proc get_highaddr {slave_ip {no_prefix ""}} {
	set ip_mem_handle [lindex [hsi::utils::get_ip_mem_ranges [get_cells $slave_ip]] 0]
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
	if {[regexp "^&.*" "$node" match] || [regexp "amba" "$node" match]} {
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
	if {[string_is_empty $default_dts]} {
		if {[is_pl_ip $drv_handle]} {
			set default_dts "pl.dtsi"
		} else {
			# PS IP, read pcw_dts property
			set default_dts [get_property CONFIG.pcw_dts [get_os]]
		}
	}
	set default_dts [set_cur_working_dts $default_dts]
	update_system_dts_include $default_dts
	return $default_dts
}

proc dt_node_def_checking {node_label node_name node_ua node_obj} {
	# check if the node_object has matching label, name and unit_address properties
	# ignore reference node as it does not have label and unit_addr
	if {![regexp "^&.*" "$node_obj" match]} {
		set old_label [get_property "NODE_LABEL" $node_obj]
		set old_name [get_property "NODE_NAME" $node_obj]
		set old_ua [get_property "UNIT_ADDRESS" $node_obj]
		if {![string equal -nocase $node_label $old_label] || \
			![string equal -nocase $node_ua $old_ua] || \
			![string equal -nocase $node_name $old_name]} {
			dtg_debug "dt_node_def_checking($node_obj): label: ${node_label} - ${old_label}, name: ${node_name} - ${old_name}, unit addr: ${node_ua} - ${old_ua}"
			return 0
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
	while {[string match -* [lindex $args 0]]} {
		switch -glob -- [lindex $args 0] {
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
	if {$found_node == 1} {
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
	set ip_obj [get_cells $ip_inst]
	if {[llength [get_cells $ip_inst]] < 1} {
		return 0
	}
	set ip_name [get_property IP_NAME $ip_obj]
	if {![regexp "ps[7]_*" "$ip_name" match]} {
		return 1
	}
	return 0
}

proc is_ps_ip {ip_inst} {
	# check if the IP is a soft IP (not PS7)
	# return 1 if it is soft ip
	# return 0 if not
	set ip_obj [get_cells $ip_inst]
	if {[llength [get_cells $ip_inst]] < 1} {
		return 0
	}
	set ip_name [get_property IP_NAME $ip_obj]
	if {[regexp "ps[7]_*" "$ip_name" match]} {
		return 1
	}
	return 0
}

proc get_node_name {drv_handle} {
	# FIXME: handle node that is not an ip
	# what about it is a bus node
	set ip [get_cells $drv_handle]
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
		continue
	}

	regsub -all {CONFIG.} $prop {} prop
	set conf_prop [lindex [get_comp_params ${prop} $drv_handle] 0 ]
	if {[string_is_empty ${conf_prop}] == 0} {
		set type [lindex [get_property CONFIG.TYPE $conf_prop] 0]
	} else {
		error "Unable to add the $prop property for $drv_handle due to missing valid type"
	}
	# CHK: skip if empty? when conf_prop is not referencelist
	# if {[string_is_empty ${value}] == 1} {
	# 	continue
	# }
	# TODO: sanity check is missing
	dtg_debug "${dt_node} - ${prop} - ${value} - ${type}"
	hsm::utils::add_new_dts_param "${dt_node}" "${prop}" "${value}" "${type}"
}

proc create_dt_tree_from_dts_file {} {
	global def_string zynq_7000_fname
	set kernel_dtsi ""
	set kernel_ver [get_property CONFIG.kernel_version [get_os]]
	foreach i [get_sw_cores device_tree] {
		set kernel_dtsi "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/${zynq_7000_fname}"
		if {[file exists $kernel_dtsi]} {
			foreach file [glob [get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/*] {
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
			hsm::utils::add_new_dts_param "${cur_node}" "status" $value string
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
	set def_ps7_mapping [dict create]
	dict set def_ps7_mapping f8891000 label pmu
	dict set def_ps7_mapping f8007100 label adc
	dict set def_ps7_mapping e0008000 label can0
	dict set def_ps7_mapping e0009000 label can1
	dict set def_ps7_mapping e000a000 label gpio0
	dict set def_ps7_mapping e0004000 label i2c0
	dict set def_ps7_mapping e0005000 label i2c1
	dict set def_ps7_mapping f8f01000 label intc
	dict set def_ps7_mapping f8f00100 label intc
	dict set def_ps7_mapping f8f02000 label L2
	dict set def_ps7_mapping f8006000 label memory-controller
	dict set def_ps7_mapping f800c000 label ocmc
	dict set def_ps7_mapping e0000000 label uart0
	dict set def_ps7_mapping e0001000 label uart1
	dict set def_ps7_mapping e0006000 label spi0
	dict set def_ps7_mapping e0007000 label spi1
	dict set def_ps7_mapping e000d000 label qspi
	dict set def_ps7_mapping e000e000 label smcc
	dict set def_ps7_mapping e1000000 label nand0
	dict set def_ps7_mapping e2000000 label nor
	dict set def_ps7_mapping e000b000 label gem0
	dict set def_ps7_mapping e000c000 label gem1
	dict set def_ps7_mapping e0100000 label sdhci0
	dict set def_ps7_mapping e0101000 label sdhci1
	dict set def_ps7_mapping f8000000 label slcr
	dict set def_ps7_mapping f8003000 label dmac_s
	dict set def_ps7_mapping f8007000 label devcfg
	dict set def_ps7_mapping f8f00200 label global_timer
	dict set def_ps7_mapping f8001000 label ttc0
	dict set def_ps7_mapping f8002000 label ttc1
	dict set def_ps7_mapping f8f00600 label scutimer
	dict set def_ps7_mapping f8005000 label watchdog0
	dict set def_ps7_mapping f8f00620 label scuwatchdog
	dict set def_ps7_mapping e0002000 label usb0
	dict set def_ps7_mapping e0003000 label usb1

	set ps7_mapping [dict create]
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
			set node_name [get_property NODE_NAME $node]
			set node_label [get_property NODE_LABEL $node]
			if {[catch {set status_prop [get_property CONFIG.status $node]} msg]} {
				set status_prop "enable"
			}
			if {[string_is_empty $node_label] || \
				[string_is_empty $unit_addr]} {
				continue
			}
			dict set ps7_mapping $unit_addr label $node_label
			dict set ps7_mapping $unit_addr name $node_name
			dict set ps7_mapping $unit_addr status $status_prop
		}
	}
	if {[string_is_empty $ps7_mapping]} {
		return $def_ps7_mapping
	} else {
		return $ps7_mapping
	}
}

proc ps_node_mapping {ip_name prop} {
	set unit_addr [get_ps_node_unit_addr $ip_name]
	if {$unit_addr == -1} {return $ip_name}
	set ps7_mapping [gen_ps7_mapping]
	if {[is_ps_ip [get_drivers $ip_name]]} {
		if {[catch {set tmp [dict get $ps7_mapping $unit_addr $prop]} msg]} {
			continue
		}
		return $tmp
	}
	return $ip_name
}

proc get_ps_node_unit_addr {ip_name {prop "label"}} {
	set ip [get_cells $ip_name]
	set ip_mem_handle [hsi::utils::get_ip_mem_ranges [get_cells $ip]]

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
	set proctype [get_property IP_NAME [get_cells [get_sw_processor]]]
	# Assuming these device supports the clocks
	set valid_ip_list "axi_timer axi_uartlite axi_uart16550 axi_ethernet axi_ethernet_buffer axi_can can"
	if {[string match -nocase $proctype "ps7_cortexa9"]} {
		set iptype [get_property IP_NAME [get_cells $drv_handle]]
		if {[lsearch $valid_ip_list $iptype] >= 0} {
			# FIXME: this is hardcoded - maybe dynamic detection
			hsi::utils::add_new_property $drv_handle "clock-names" stringlist "ref_clk"
			hsi::utils::add_new_property $drv_handle "clocks" reference "clkc 0"
		}
	}
}

proc get_intr_type {intc_name ip_name port_name} {
	set intc [get_cells $intc_name]
	set ip [get_cells $ip_name]
	if {[llength $intc] == 0 && [llength $ip] == 0} {
		return -1
	}
	set intr_pin [get_pins -of_objects $ip $port_name]
	set sensitivity ""
	if {[llength $intr_pin] >= 1} {
		# TODO: check with HSM dev and see if this is a bug
		set sensitivity [get_property SENSITIVITY $intr_pin]
	}
	set intc_type [get_property IP_NAME $intc ]
	if {[string match -nocase $intc_type "ps7_scugic"]} {
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
	set ip [get_cells $ip_name]
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
		hsm::utils::add_new_property $drv_handle $prop_name string "$value"
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

	set slave [get_cells ${cpu_handle}]
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

	set slave [get_cells ${drv_handle}]
	set intr_id -1
	set intc ""
	set intr_info ""

	if {[string_is_empty $intr_port_name]} {
		set intr_port_name [get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
	}

	foreach pin ${intr_port_name} {
		set intc [::hsm::utils::get_interrupt_parent $drv_handle $pin]
		set intr_id [::hsm::utils::get_interrupt_id $drv_handle $pin]
		if {[string match -nocase $intr_id "-1"]} {continue}
		if {[string_is_empty $intc] == 1} {continue}

		set intr_type [get_intr_type $intc $slave $pin]
		if {[string match -nocase $intr_type "-1"]} {
			continue
		}

		set cur_intr_info ""
		if {[string match "[get_property IP_NAME $intc]" "ps7_scugic"]} {
			if {$intr_id > 32} {
				set intr_id [expr $intr_id - 32]
			}
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
		return -1
	}
	set_drv_prop $drv_handle interrupts $intr_info intlist
	if {[string_is_empty $intc]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]
	set_drv_prop $drv_handle interrupt-parent $intc reference
}

proc gen_reg_property {drv_handle} {
	proc_called_by

	if {[is_ps_ip $drv_handle]} {
		return 0
	}

	set reg ""
	set slave [get_cells ${drv_handle}]
	set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
	foreach mem_handle ${ip_mem_handles} {
		set base [string tolower [get_property BASE_VALUE $mem_handle]]
		set high [string tolower [get_property HIGH_VALUE $mem_handle]]
		set size [format 0x%x [expr {${high} - ${base} + 1}]]
		if {[string_is_empty $reg]} {
			set reg "$base $size"
		} else {
			# ensure no duplication
			if {![regexp ".*${reg}.*" "$base $size" matched]} {
				set reg "$reg $base $size"
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
	set slave [get_cells ${drv_handle}]
	set vlnv [split [get_property VLNV $slave] ":"]
	set name [lindex $vlnv 2]
	set ver [lindex $vlnv 3]
	set comp_prop "xlnx,${name}-${ver}"
	regsub -all {_} $comp_prop {-} comp_prop
	set_drv_prop_if_empty $drv_handle compatible $comp_prop stringlist
}

proc ip2drv_prop {ip_name ip_prop_name} {
	set drv_handle [get_ip_handler $ip_name]
	set ip [get_cells $ip_name]

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
	set ip [get_cells $drv_handle]
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
		if {$value != "-1" && [llength $value] !=0} {
			set_property ${conf_prop} "$src_ip $value 0" $drv_handle
		}
	}
}

proc gen_peripheral_nodes {drv_handle {node_only ""}} {
	set status_enable_flow 0
	set ip [get_cells $drv_handle]
	# TODO: check if the base address is correct
	set unit_addr [get_baseaddr ${ip} no_prefix]
	set label $drv_handle
	set dev_type [get_property CONFIG.dev_type $drv_handle]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type $drv_handle
	}

	# TODO: more ignore ip list?
	set ip_type [get_property IP_NAME $ip]
	set ignore_list "lmb_bram_if_cntlr"
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
		if {$status_disabled} {
			hsm::utils::add_new_dts_param "${rt_node}" "status" "okay" string
		}
	} else {
		set rt_node [add_or_get_dt_node -n ${dev_type} -l ${label} -u ${unit_addr} -d ${default_dts} -p $bus_node -auto_ref_parent]
	}

	if {![string_is_empty $node_only]} {
		return $rt_node
	}

	zynq_gen_pl_clk_binding $drv_handle
	# generate mb ccf node
	generate_mb_ccf_node $drv_handle

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
	# 	mb: detection is required
	set valid_buses [get_cells -filter { IP_TYPE == "BUS" && IP_NAME != "axi_protocol_converter" && IP_NAME != "lmb_v10"}]

	set proc_name [get_property IP_NAME [get_cell [get_sw_processor]]]
	if {[string equal -nocase "ps7_cortexa9" $proc_name]} {
		return "amba 0"
	}

	if {[llength $valid_buses] == 1} {
		return "[lindex $valid_buses 0] 0"
	}
	return "amba 0"
}

proc add_or_get_bus_node {ip_drv dts_file} {
	set bus_info [detect_bus_name $ip_drv]
	set bus_label [lindex $bus_info 0]
	set bus_uaddr [lindex $bus_info 1]

	dtg_debug "bus_label: $bus_label"
	dtg_debug "bus_uaddr: $bus_uaddr"

	set bus_node [add_or_get_dt_node -n "amba" -l ${bus_label} -u ${bus_uaddr} -d [get_dt_tree ${dts_file}] -p "/" -disable_auto_ref -auto_ref_parent]
	if {![string match "&*" $bus_node]} {
		hsm::utils::add_new_dts_param "${bus_node}" "#address-cells" 1 int
		hsm::utils::add_new_dts_param "${bus_node}" "#size-cells" 1 int
		hsm::utils::add_new_dts_param "${bus_node}" "compatible" "simple-bus" stringlist
		hsm::utils::add_new_dts_param "${bus_node}" "ranges" "" boolean
	}
	return $bus_node
}

proc gen_root_node {drv_handle} {
	set default_dts [set_drv_def_dts $drv_handle]
	# add compatible
	set ip_name [get_property IP_NAME [get_cell ${drv_handle}]]
	switch $ip_name {
		"ps7_cortexa9" {
			create_dt_tree_from_dts_file
			global zynq_7000_fname
			update_system_dts_include ${zynq_7000_fname}
			# no root_node required as zynq-7000.dtsi
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
	hsm::utils::add_new_dts_param "${root_node}" "#address-cells" 1 int ""
	hsm::utils::add_new_dts_param "${root_node}" "#size-cells" 1 int ""
	hsm::utils::add_new_dts_param "${root_node}" model $model string ""
	hsm::utils::add_new_dts_param "${root_node}" compatible $compatible string ""

	return $root_node
}

# Q: common function for all processor or one for each driver lib
proc gen_cpu_nodes {drv_handle} {
	set ip_name [get_property IP_NAME [get_cell [get_sw_processor]]]
	switch $ip_name {
		"ps7_cortexa9" {
			# skip node generation for static zynq-7000 dtsi
			# TODO: this needs to be fixed to allow override
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
	hsm::utils::add_new_dts_param "${cpu_root_node}" "#address-cells" 1 int ""
	hsm::utils::add_new_dts_param "${cpu_root_node}" "#size-cells" 0 int ""

	set processor_type [get_property IP_NAME [get_cell ${processor}]]
	set processor_list [eval "get_cells -filter { IP_TYPE == \"PROCESSOR\" && IP_NAME == \"${processor_type}\" }"]

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
		hsm::utils::add_new_dts_param "${cpu_node}" "bus-handle" $bus_label reference
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
			hsm::utils::add_new_dts_param "${cpu_node}" "reg" $cpu_no int ""
		}
		incr cpu_no
	}
	hsm::utils::add_new_dts_param "${cpu_root_node}" "#cpus" $cpu_no int ""
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
	set mdio_node [add_or_get_dt_node -n ${drv_handle}_mdio -p $parent_node]
	hsm::utils::add_new_dts_param "${mdio_node}" "#address-cells" 1 int ""
	hsm::utils::add_new_dts_param "${mdio_node}" "#size-cells" 0 int ""
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
	set parent_node [add_or_get_dt_node -n / -d ${master_dts}]
	set unit_addr [get_baseaddr $drv_handle]
	set memory_node [add_or_get_dt_node -n memory -p $parent_node]
	set reg_value [get_property CONFIG.reg $drv_handle]
	hsm::utils::add_new_dts_param "${memory_node}" "reg" $reg_value inthexlist
	# maybe hardcoded
	if {[catch {set dev_type [get_property CONFIG.device_type $drv_handle]} msg]} {
		set dev_type memory
	}
	if {[string_is_empty $dev_type]} {set dev_type memory}
	hsm::utils::add_new_dts_param "${memory_node}" "device_type" $dev_type string

	set_cur_working_dts $cur_dts
	return $memory_node
}

proc gen_mb_ccf_subnode {drv_handle name freq reg} {
	set cur_dts [current_dt_tree]
	set default_dts [set_drv_def_dts $drv_handle]

	set clk_node [add_or_get_dt_node -n clocks -p / -d ${default_dts}]
	hsm::utils::add_new_dts_param "${clk_node}" "#address-cells" 1 int
	hsm::utils::add_new_dts_param "${clk_node}" "#size-cells" 0 int

	set clk_subnode_name "clk_${name}"
	set clk_subnode [add_or_get_dt_node -l ${clk_subnode_name} -n ${clk_subnode_name} -u $reg -p ${clk_node} -d ${default_dts}]
	# clk subnode data
	hsm::utils::add_new_dts_param "${clk_subnode}" "compatible" "fixed-clock" stringlist
	hsm::utils::add_new_dts_param "${clk_subnode}" "#clock-cells" 0 int

	hsm::utils::add_new_dts_param $clk_subnode "clock-output-names" $clk_subnode_name string
	hsm::utils::add_new_dts_param $clk_subnode "reg" $reg int
	hsm::utils::add_new_dts_param $clk_subnode "clock-frequency" $freq int

	set_cur_working_dts $cur_dts
}

proc generate_mb_ccf_node {drv_handle} {
	# list of ip should have the clocks property
	set valid_ip_list "axi_timer axi_uartlite axi_uart16550 axi_ethernet axi_ethernet_buffer axi_can can mdm"

	set sw_proc [get_sw_processor]
	set proc_ip [get_cells $sw_proc]
	set proctype [get_property IP_NAME $proc_ip]
	if {[string match -nocase $proctype "microblaze"]} {
		set bus_clk_list ""
		set hwinst [get_property HW_INSTANCE $drv_handle]
		set iptype [get_property IP_NAME [get_cells $hwinst]]
		if {[lsearch $valid_ip_list $iptype] >= 0} {
			# get bus clock frequency
			set clk_freq [get_clock_frequency [get_cells $drv_handle] "S_AXI_ACLK"]
			if {![string equal $clk_freq ""]} {
				# FIXME: bus clk source count should based on the clock generator not based on clk freq diff
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend $bus_clk_list $clk_freq]
				}
				set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
				# create the node and assuming reg 0 is taken by cpu
				gen_mb_ccf_subnode $drv_handle bus_${bus_clk_cnt} $clk_freq [expr ${bus_clk_cnt} + 1]
				# set bus clock frequency (current it is there)
				set_property CONFIG.clock-frequency $clk_freq $drv_handle
				hsm::utils::add_new_property $drv_handle "clocks" int &clk_bus_${bus_clk_cnt}
			}
		}
		set cpu_clk_freq [get_clock_frequency $proc_ip "CLK"]
		# issue:
		# - hardcoded reg number cpu clock node
		# - assume clk_cpu for mb cpu
		# - only applies to master mb cpu
		gen_mb_ccf_subnode $sw_proc cpu $cpu_clk_freq 0
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
	set ip [get_cells $drv_handle]
	set chosen_ip [hsi::utils::get_os_parameter_value "${os_para}"]
	if {[string match -nocase "$ip" "$chosen_ip"]} {
		hsi::utils::set_os_parameter_value $count_para 1
		return 0
	} else {
		return $dev_count
	}
}

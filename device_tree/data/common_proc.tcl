#
# common procedures
#

# global variables
global def_string
set def_string "__def_none"
proc get_clock_frequency {ip_handle portname} {
	set clk ""
	set clkhandle [get_pins -of_objects $ip_handle $portname]
	if {[string compare -nocase $clkhandle ""] != 0} {
		set clk [get_property CLK_FREQ $clkhandle ]
	}
	return $clk
}

proc set_drv_conf_prop args {
	set drv_handle [lindex $args 0]
	set pram [lindex $args 1]
	set conf_prop [lindex $args 2]
	set ip [get_cells $drv_handle]
	set value [get_property CONFIG.${pram} $ip]
	if { [llength $value] } {
		regsub -all "MIO( |)" $value "" value
		if { $value != "-1" && [llength $value] !=0  } {
			if {[llength $args] >= 4} {
				set type [lindex $args 3]
				if {[string equal -nocase $type "boolean"]} {
					set_boolean_property $drv_handle $value ${conf_prop}
					return 0
				}
				set_property ${conf_prop} $value $drv_handle
				set prop [get_comp_params ${conf_prop} $drv_handle]
				set_property CONFIG.TYPE $type $prop
				return 0
			}
			set_property ${conf_prop} $value $drv_handle
		}
	}
}

proc set_boolean_property {drv_handle value conf_prop} {
	if {[expr $value >= 1]} {
		set_property ${conf_prop} "" $drv_handle
		set prop [get_comp_params ${conf_prop} $drv_handle]
		set_property CONFIG.TYPE referencelist $prop
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
		if { [llength $value] } {
			if { $value != "-1" && [llength $value] !=0  } {
				set type "hexint"
				if {[llength $args] >= 5} {
					set type [lindex $args 4]
					if {[string equal -nocase $type "boolean"]} {
						set type referencelist
						if {[expr $value >= 1]} {
							hsm::utils::add_new_property $dest_handle $dest_prop $type ""
						}
						return 0
					}
				}
				hsm::utils::add_new_property $dest_handle $dest_prop $type $value
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

#
# HSM 2014.2 workaround
# This proc is designed to generated the correct interrupt cells for both
# MB and Zynq
proc get_intr_id { periph_name intr_port_name } {
	set intr_info -1
	set ip [get_cells $periph_name]

	set intr_pin [get_pins -of_objects $ip $intr_port_name -filter "TYPE==INTERRUPT"]
	if { [llength $intr_pin] == 0 } {
		return -1
	}

	# identify the source controller port
	set intc_port ""
	set intc_periph ""
	set intr_sink_pins [xget_sink_pins $intr_pin]
	foreach intr_sink $intr_sink_pins {
		set sink_periph [get_cells -of_objects $intr_sink]
		if { [is_interrupt_controller $sink_periph] == 1} {
			set intc_port $intr_sink
			set intc_periph $sink_periph
			break
		}
	}
	if {$intc_port == ""} {
		return -1
	}

	# workaround for 2014.2
	# get_interrupt_id returns incorrect id for Zynq
	# issue: the xget_interrupt_sources returns all interrupt signals
	# connected to the interrupt controller, which is not limited to IP
	# in PL
	set intc_type [get_property IP_NAME $intc_periph]
	# CHECK with Heera for zynq the intc_src_ports are in reverse order
	if { [string match -nocase $intc_type "ps7_scugic"] } {
		set ip_param [get_property CONFIG.C_IRQ_F2P_MODE $intc_periph]
		if { [string match -nocase "$ip_param" "REVERSE"]} {
			set intc_src_ports [xget_interrupt_sources $intc_periph]
		} else {
			set intc_src_ports [lreverse [xget_interrupt_sources $intc_periph]]
		}
		set total_intr_count -1
		foreach intc_src_port $intc_src_ports {
			set intr_periph [get_cells -of_objects $intc_src_port]
			if { [string match -nocase $intc_type "ps7_scugic"] } {
				if {[is_it_in_pl "$intr_periph"] == 1} {
					incr total_intr_count
					continue
				}
			}
		}
	} else {
		set intc_src_ports [xget_interrupt_sources $intc_periph]
	}

	set i 0
	set intr_id -1
	set ret -1
	foreach intc_src_port $intc_src_ports {
		if { [llength $intc_src_port] == 0 } {
			incr i
			continue
		}
		set intr_periph [get_cells -of_objects $intc_src_port]
		set ip_type [get_property IP_NAME $intr_periph]
		if { [string compare -nocase "$intr_port_name"  "$intc_src_port" ] == 0 } {
			if { [string compare -nocase "$intr_periph" "$ip"] == 0 } {
				set ret $i
				break
			}
		}
		if { [string match -nocase $intc_type "ps7_scugic"] } {
			if {[is_it_in_pl "$intr_periph"] == 1} {
				incr i
				continue
			}
		} else {
			incr i
		}
	}

	if { [string match -nocase $intc_type "ps7_scugic"] && [string match -nocase $intc_port "IRQ_F2P"] } {
		set ip_param [get_property CONFIG.C_IRQ_F2P_MODE $intc_periph]
		if { [string match -nocase "$ip_param" "REVERSE"]} {
			set diff [expr $total_intr_count - $ret]
			if { $diff < 8 } {
				set intr_id [expr 91 - $diff]
			} elseif { $diff  < 16} {
				set intr_id [expr 68 - ${diff} + 8 ]
			}
		} else {
			if { $ret < 8 } {
				set intr_id [expr 61 + $ret]
			} elseif { $ret  < 16} {
				set intr_id [expr 84 + $ret - 8 ]
			}
		}
	} else {
		set intr_id $ret
	}

	if { [string match -nocase $intr_id "-1"] } {
		set intr_id [xget_port_interrupt_id "$periph_name" "$intr_port_name" ]
	}

	if { [string match -nocase $intr_id "-1"] } {
		return -1
	}

	# format the interrupt cells
	set intc [get_connected_interrupt_controller $periph_name $intr_port_name]
	set intr_type [hsm::utils::get_dtg_interrupt_type $intc $ip $intr_port_name]
	if {[string match "[get_property IP_NAME $intc]" "ps7_scugic"]} {
		if { $intr_id > 32 } {
			set intr_id [expr $intr_id - 32]
		}
		set intr_info "0 $intr_id $intr_type"
	} else {
		set intr_info "$intr_id $intr_type"
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
			-- { Pop args ; break }
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
		![string equal -nocase ${node_unit_addr} ${def_string}] } {
		lappend pattern "${node_label}:${node_name}@${node_unit_addr}"
		lappend pattern "${node_name}@${node_unit_addr}"
	}

	if {![string equal -nocase ${node_label} ${def_string}]} {
		lappend pattern "&${node_label}"
		lappend pattern "^${node_label}"
	}
	if {![string equal -nocase ${node_name} ${def_string}] && \
		![string equal -nocase ${node_unit_addr} ${def_string}] } {
		lappend pattern "${node_name}@${node_unit_addr}"
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
	if { $dt_idx >= 0 } {
		set dt_tree_obj [current_dt_tree [lindex [get_dt_trees] $dt_idx]]
	} else {
		set dt_tree_obj [create_dt_tree -dts_file $dts_file]
	}
	return $dt_tree_obj
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

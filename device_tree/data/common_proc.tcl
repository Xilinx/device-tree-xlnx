#
# common procedures
#
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

proc get_intr_id { periph_name intr_port_name } {
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

	# now get the interrupt id
	set intr_id [hsm::utils::get_interrupt_id "$periph_name" "$intr_port_name"]
	if { [string match -nocase $intr_id "-1"] } {
		set intr_id [xget_port_interrupt_id "$periph_name" "$intr_port_name" ]
	}

	set intc [get_connected_interrupt_controller $periph_name $intr_port_name]
	set intr_type [hsm::utils::get_dtg_interrupt_type $intc $ip $intr_port_name]
	# interrupt id conversion for ps7_scugic
	if { [string match -nocase "[get_property IP_NAME $intc]" "ps7_scugic"] && [string match -nocase $intc_port "IRQ_F2P"]} {
		set intr_id [expr $intr_id - 1]
		set ip_param [get_property CONFIG.C_IRQ_F2P_MODE $ip]
		if { [string match -nocase "$ip_param" "REVERSE"]} {
			set $intr_id [expr 15 -$intr_id]
		}
		if { $intr_id < 8 } {
			set intr_id [expr $intr_id + 60]
		} elseif { $intr_id  < 16} {
			set intr_id [expr $intr_id + 83 - 8]
		}
	}

	if {[string match "[get_property IP_NAME $intc]" "ps7_scugic"]} {
		if { $intr_id > 32 } {
			set intr_id [expr $intr_id -32]
		}
		set intr_info "0 $intr_id $intr_type"
	} else {
		set intr_info "$intr_id $intr_type"
	}
	return $intr_info
}

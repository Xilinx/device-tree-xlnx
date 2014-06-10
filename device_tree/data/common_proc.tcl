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

proc get_ip_property {drv_handle parameter} {
	set ip [get_cells $drv_handle]
	return [get_property ${parameter} $ip]
}

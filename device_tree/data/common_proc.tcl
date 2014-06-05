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

proc set_drv_conf_prop {drv_handle pram conf_prop} {
	set ip [get_cells $drv_handle]
	set value [get_property CONFIG.${pram} $ip]
	if { [llength $value] } {
		regsub -all "MIO( |)" $value "" value
		if { $value != "-1" && [llength $value] !=0  } {
			set_property CONFIG.${conf_prop} $value $drv_handle
		}
	}
}

proc get_ip_property {drv_handle parameter} {
	set ip [get_cells $drv_handle]
	return [get_property ${parameter} $ip]
}

proc generate {drv_handle} {
    set consoleip [get_property CONFIG.console_device [get_os] ]
    set port_number 0
    if { [string match -nocase "$drv_handle" "$consoleip"]  == 0 }  {
        set serial_count [hsm::utils::get_os_parameter_value "serial_count"]
        if { [llength $serial_count]  == 0 } {
            set serial_count 0
        }
        incr serial_count
        hsm::utils::set_os_parameter_value "serial_count" $serial_count
        set port_number $serial_count
    }
    set_property CONFIG.port-number $port_number $drv_handle
}

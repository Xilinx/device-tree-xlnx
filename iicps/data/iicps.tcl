proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }

    set i2c_count [hsi::utils::get_os_parameter_value "i2c_count"]
    if { [llength $i2c_count] == 0 } {
        set i2c_count 0
    }
    set_property CONFIG.bus-id "$i2c_count" $drv_handle
    incr i2c_count
    hsi::utils::set_os_parameter_value "i2c_count" $i2c_count
    set i2c_count [hsi::utils::get_os_parameter_value "i2c_count"]

    ps7_reset_handle $drv_handle CONFIG.C_I2C_RESET CONFIG.i2c-reset
}

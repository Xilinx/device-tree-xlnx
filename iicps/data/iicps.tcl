proc ps7_reset_handle {drv_handle reset_pram conf_prop} {
    set ip [get_cells $drv_handle]
    set value [get_property CONFIG.${reset_pram} $ip]
    # workaround for reset not been selected
    regsub -all "<Select>" $value "" value
    if { [llength $value] } {
        regsub -all "MIO( |)" $value "" value
        if { $value != "-1" && [llength $value] !=0  } {
            set_property CONFIG.${conf_prop} "ps7_gpio_0 $value 0" $drv_handle
        }
    }
}

proc generate {drv_handle} {
    set i2c_count [hsm::utils::get_os_parameter_value "i2c_count"]
    if { [llength $i2c_count] == 0 } {
        set i2c_count 0
    }
    set_property CONFIG.bus-id "$i2c_count" $drv_handle
    incr i2c_count
    hsm::utils::set_os_parameter_value "i2c_count" $i2c_count
    set i2c_count [hsm::utils::get_os_parameter_value "i2c_count"]

    ps7_reset_handle $drv_handle C_I2C_RESET i2c-reset
}

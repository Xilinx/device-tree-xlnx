proc ps7_reset_handle {drv_handle reset_pram conf_prop} {
    set ip [get_cells $drv_handle]
    set value [get_property CONFIG.${reset_pram} $ip]
    # workaround for reset not been selected and show as "<Select>"
    regsub -all "<Select>" $value "" value
    if { [llength $value] } {
        regsub -all "MIO( |)" $value "" value
        if { $value != "-1" && [llength $value] !=0  } {
            set_property CONFIG.${conf_prop} "ps7_gpio_0 $value 0" $drv_handle
        }
    }
}

proc generate {drv_handle} {
    ps7_reset_handle $drv_handle C_USB_RESET usb-reset
}


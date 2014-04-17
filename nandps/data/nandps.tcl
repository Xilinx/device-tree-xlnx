proc set_drv_conf_prop {drv_handle pram conf_prop} {
    set ip [get_cells $drv_handle]
    set value [get_property CONFIG.${pram} $ip]
    #puts $value
    if { [llength $value] } {
        regsub -all "MIO( |)" $value "" value
        if { $value != "-1" && [llength $value] !=0  } {
            set_property CONFIG.${conf_prop} $value $drv_handle
        }
    }
}

proc generate {drv_handle} {
    set_drv_conf_prop $drv_handle C_NAND_WIDTH nand-bus-width
    # FIXME: once the timing data is exported by Vivado. We should update the timing data
}

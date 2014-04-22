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

proc generate {drv_handle} {
    set_drv_conf_prop $drv_handle "C_ADDR25" "arm,addr25"
    set_drv_conf_prop $drv_handle "C_NOR_CHIP_SEL0" "arm,nor-chip-sel0"
    set_drv_conf_prop $drv_handle "C_NOR_CHIP_SEL1" "arm,nor-chip-sel1"
    set_drv_conf_prop $drv_handle "C_SRAM_CHIP_SEL0" "arm,sram-chip-sel0"
    set_drv_conf_prop $drv_handle "C_SRAM_CHIP_SEL1" "arm,sram-chip-sel1"
}